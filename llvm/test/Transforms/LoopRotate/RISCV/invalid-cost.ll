; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt -S -loop-rotate -verify-memoryssa < %s | FileCheck %s
; RUN: opt -S -passes='require<targetir>,require<assumptions>,loop(loop-rotate)' < %s | FileCheck %s

; Demonstrate handling of invalid costs in LoopRotate.  This test uses
; scalable vectors on RISCV w/o +V to create a situation where a construct
; can not be lowered, and is thus invalid regardless of what the target
; does or does not implement in terms of a cost model.

target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n64-S128"
target triple = "riscv64-unknown-unknown"

define void @valid() nounwind ssp {
; CHECK-LABEL: @valid(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    br label [[FOR_COND:%.*]]
; CHECK:       for.cond:
; CHECK-NEXT:    [[I_0:%.*]] = phi i32 [ 0, [[ENTRY:%.*]] ], [ [[INC:%.*]], [[FOR_COND]] ]
; CHECK-NEXT:    [[CMP:%.*]] = icmp slt i32 [[I_0]], 100
; CHECK-NEXT:    [[INC]] = add nsw i32 [[I_0]], 1
; CHECK-NEXT:    br i1 [[CMP]], label [[FOR_COND]], label [[FOR_END:%.*]]
; CHECK:       for.end:
; CHECK-NEXT:    ret void
;
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.body, %entry
  %i.0 = phi i32 [ 0, %entry ], [ %inc, %for.body ]
  %cmp = icmp slt i32 %i.0, 100
  br i1 %cmp, label %for.body, label %for.end


for.body:                                         ; preds = %for.cond
  %inc = add nsw i32 %i.0, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond
  ret void
}

; Despite having an invalid cost, we can rotate this because we don't
; need to duplicate any instructions or execute them more frequently.
define void @invalid_no_dup(<vscale x 1 x i8>* %p) nounwind ssp {
; CHECK-LABEL: @invalid_no_dup(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    br label [[FOR_BODY:%.*]]
; CHECK:       for.body:
; CHECK-NEXT:    [[I_01:%.*]] = phi i32 [ 0, [[ENTRY:%.*]] ], [ [[INC:%.*]], [[FOR_BODY]] ]
; CHECK-NEXT:    [[A:%.*]] = load <vscale x 1 x i8>, <vscale x 1 x i8>* [[P:%.*]], align 1
; CHECK-NEXT:    [[B:%.*]] = add <vscale x 1 x i8> [[A]], [[A]]
; CHECK-NEXT:    store <vscale x 1 x i8> [[B]], <vscale x 1 x i8>* [[P]], align 1
; CHECK-NEXT:    [[INC]] = add nsw i32 [[I_01]], 1
; CHECK-NEXT:    [[CMP:%.*]] = icmp slt i32 [[INC]], 100
; CHECK-NEXT:    br i1 [[CMP]], label [[FOR_BODY]], label [[FOR_END:%.*]]
; CHECK:       for.end:
; CHECK-NEXT:    ret void
;
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.body, %entry
  %i.0 = phi i32 [ 0, %entry ], [ %inc, %for.body ]
  %cmp = icmp slt i32 %i.0, 100
  br i1 %cmp, label %for.body, label %for.end


for.body:                                         ; preds = %for.cond
  %a = load <vscale x 1 x i8>, <vscale x 1 x i8>* %p
  %b = add <vscale x 1 x i8> %a, %a
  store <vscale x 1 x i8> %b, <vscale x 1 x i8>* %p
  %inc = add nsw i32 %i.0, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond
  ret void
}

; This demonstrates a case where a) loop rotate needs a cost estimate to
; know if rotation is profitable, and b) there is no cost estimate available
; due to invalid costs in the loop.  We can't rotate this loop.
define void @invalid_dup_required(<vscale x 1 x i8>* %p) nounwind ssp {
; CHECK-LABEL: @invalid_dup_required(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    br label [[FOR_COND:%.*]]
; CHECK:       for.cond:
; CHECK-NEXT:    [[I_0:%.*]] = phi i32 [ 0, [[ENTRY:%.*]] ], [ [[INC:%.*]], [[FOR_BODY:%.*]] ]
; CHECK-NEXT:    [[A:%.*]] = load <vscale x 1 x i8>, <vscale x 1 x i8>* [[P:%.*]], align 1
; CHECK-NEXT:    [[B:%.*]] = add <vscale x 1 x i8> [[A]], [[A]]
; CHECK-NEXT:    store <vscale x 1 x i8> [[B]], <vscale x 1 x i8>* [[P]], align 1
; CHECK-NEXT:    [[CMP:%.*]] = icmp slt i32 [[I_0]], 100
; CHECK-NEXT:    br i1 [[CMP]], label [[FOR_BODY]], label [[FOR_END:%.*]]
; CHECK:       for.body:
; CHECK-NEXT:    call void @f()
; CHECK-NEXT:    [[INC]] = add nsw i32 [[I_0]], 1
; CHECK-NEXT:    br label [[FOR_COND]]
; CHECK:       for.end:
; CHECK-NEXT:    ret void
;
entry:
  br label %for.cond

for.cond:                                         ; preds = %for.body, %entry
  %i.0 = phi i32 [ 0, %entry ], [ %inc, %for.body ]
  %a = load <vscale x 1 x i8>, <vscale x 1 x i8>* %p
  %b = add <vscale x 1 x i8> %a, %a
  store <vscale x 1 x i8> %b, <vscale x 1 x i8>* %p
  %cmp = icmp slt i32 %i.0, 100
  br i1 %cmp, label %for.body, label %for.end


for.body:                                         ; preds = %for.cond
  call void @f()
  %inc = add nsw i32 %i.0, 1
  br label %for.cond

for.end:                                          ; preds = %for.cond
  ret void
}

declare void @f()