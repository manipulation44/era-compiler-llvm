; NOTE: Assertions have been autogenerated by utils/update_test_checks.py UTC_ARGS: --function-signature --check-attributes --check-globals
; RUN: opt -attributor -enable-new-pm=0 -attributor-manifest-internal  -attributor-max-iterations-verify -attributor-annotate-decl-cs -attributor-max-iterations=2 -S < %s | FileCheck %s --check-prefixes=CHECK,NOT_CGSCC_NPM,NOT_CGSCC_OPM,NOT_TUNIT_NPM,IS__TUNIT____,IS________OPM,IS__TUNIT_OPM
; RUN: opt -aa-pipeline=basic-aa -passes=attributor -attributor-manifest-internal  -attributor-max-iterations-verify -attributor-annotate-decl-cs -attributor-max-iterations=2 -S < %s | FileCheck %s --check-prefixes=CHECK,NOT_CGSCC_OPM,NOT_CGSCC_NPM,NOT_TUNIT_OPM,IS__TUNIT____,IS________NPM,IS__TUNIT_NPM
; RUN: opt -attributor-cgscc -enable-new-pm=0 -attributor-manifest-internal  -attributor-annotate-decl-cs -S < %s | FileCheck %s --check-prefixes=CHECK,NOT_TUNIT_NPM,NOT_TUNIT_OPM,NOT_CGSCC_NPM,IS__CGSCC____,IS________OPM,IS__CGSCC_OPM
; RUN: opt -aa-pipeline=basic-aa -passes=attributor-cgscc -attributor-manifest-internal  -attributor-annotate-decl-cs -S < %s | FileCheck %s --check-prefixes=CHECK,NOT_TUNIT_NPM,NOT_TUNIT_OPM,NOT_CGSCC_OPM,IS__CGSCC____,IS________NPM,IS__CGSCC_NPM
;
;    #include <pthread.h>
;
;    void *GlobalVPtr;
;
;    static void *foo(void *arg) { return arg; }
;    static void *bar(void *arg) { return arg; }
;
;    int main() {
;      pthread_t thread;
;      pthread_create(&thread, NULL, foo, NULL);
;      pthread_create(&thread, NULL, bar, &GlobalVPtr);
;      return 0;
;    }
;
; Verify the constant values NULL and &GlobalVPtr are propagated into foo and
; bar, respectively.
;
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"

%union.pthread_attr_t = type { i64, [48 x i8] }

@GlobalVPtr = common dso_local global i8* null, align 8

; FIXME: nocapture & noalias for @GlobalVPtr in %call1
; FIXME: nocapture & noalias for %alloc2 in %call3

;.
; CHECK: @[[GLOBALVPTR:[a-zA-Z0-9_$"\\.-]+]] = common dso_local global i8* null, align 8
;.
define dso_local i32 @main() {
; IS__TUNIT____-LABEL: define {{[^@]+}}@main() {
; IS__TUNIT____-NEXT:  entry:
; IS__TUNIT____-NEXT:    [[ALLOC1:%.*]] = alloca i8, align 8
; IS__TUNIT____-NEXT:    [[ALLOC2:%.*]] = alloca i8, align 8
; IS__TUNIT____-NEXT:    [[THREAD:%.*]] = alloca i64, align 8
; IS__TUNIT____-NEXT:    [[CALL:%.*]] = call i32 @pthread_create(i64* noundef nonnull align 8 dereferenceable(8) [[THREAD]], %union.pthread_attr_t* noalias nocapture noundef align 4294967296 null, i8* (i8*)* noundef nonnull @foo, i8* noalias nocapture nofree readnone align 4294967296 undef)
; IS__TUNIT____-NEXT:    [[CALL1:%.*]] = call i32 @pthread_create(i64* noundef nonnull align 8 dereferenceable(8) [[THREAD]], %union.pthread_attr_t* noalias nocapture noundef align 4294967296 null, i8* (i8*)* noundef nonnull @bar, i8* noalias nocapture nofree nonnull readnone align 8 dereferenceable(8) undef)
; IS__TUNIT____-NEXT:    [[CALL2:%.*]] = call i32 @pthread_create(i64* noundef nonnull align 8 dereferenceable(8) [[THREAD]], %union.pthread_attr_t* noalias nocapture noundef align 4294967296 null, i8* (i8*)* noundef nonnull @baz, i8* noalias nocapture nofree noundef nonnull readnone align 8 dereferenceable(1) [[ALLOC1]])
; IS__TUNIT____-NEXT:    [[CALL3:%.*]] = call i32 @pthread_create(i64* noundef nonnull align 8 dereferenceable(8) [[THREAD]], %union.pthread_attr_t* noalias nocapture noundef align 4294967296 null, i8* (i8*)* noundef nonnull @buz, i8* noalias nofree noundef nonnull readnone align 8 dereferenceable(1) "no-capture-maybe-returned" [[ALLOC2]])
; IS__TUNIT____-NEXT:    ret i32 0
;
; IS__CGSCC____-LABEL: define {{[^@]+}}@main() {
; IS__CGSCC____-NEXT:  entry:
; IS__CGSCC____-NEXT:    [[ALLOC1:%.*]] = alloca i8, align 8
; IS__CGSCC____-NEXT:    [[ALLOC2:%.*]] = alloca i8, align 8
; IS__CGSCC____-NEXT:    [[THREAD:%.*]] = alloca i64, align 8
; IS__CGSCC____-NEXT:    [[CALL:%.*]] = call i32 @pthread_create(i64* noundef nonnull align 8 dereferenceable(8) [[THREAD]], %union.pthread_attr_t* noalias nocapture noundef align 4294967296 null, i8* (i8*)* noundef nonnull @foo, i8* noalias nocapture nofree noundef readnone align 4294967296 null)
; IS__CGSCC____-NEXT:    [[CALL1:%.*]] = call i32 @pthread_create(i64* noundef nonnull align 8 dereferenceable(8) [[THREAD]], %union.pthread_attr_t* noalias nocapture noundef align 4294967296 null, i8* (i8*)* noundef nonnull @bar, i8* noalias nofree noundef nonnull readnone align 8 dereferenceable(8) bitcast (i8** @GlobalVPtr to i8*))
; IS__CGSCC____-NEXT:    [[CALL2:%.*]] = call i32 @pthread_create(i64* noundef nonnull align 8 dereferenceable(8) [[THREAD]], %union.pthread_attr_t* noalias nocapture noundef align 4294967296 null, i8* (i8*)* noundef nonnull @baz, i8* noalias nocapture nofree noundef nonnull readnone align 8 dereferenceable(1) [[ALLOC1]])
; IS__CGSCC____-NEXT:    [[CALL3:%.*]] = call i32 @pthread_create(i64* noundef nonnull align 8 dereferenceable(8) [[THREAD]], %union.pthread_attr_t* noalias nocapture noundef align 4294967296 null, i8* (i8*)* noundef nonnull @buz, i8* noalias nofree noundef nonnull readnone align 8 dereferenceable(1) [[ALLOC2]])
; IS__CGSCC____-NEXT:    ret i32 0
;
entry:
  %alloc1 = alloca i8, align 8
  %alloc2 = alloca i8, align 8
  %thread = alloca i64, align 8
  %call = call i32 @pthread_create(i64* nonnull %thread, %union.pthread_attr_t* null, i8* (i8*)* nonnull @foo, i8* null)
  %call1 = call i32 @pthread_create(i64* nonnull %thread, %union.pthread_attr_t* null, i8* (i8*)* nonnull @bar, i8* bitcast (i8** @GlobalVPtr to i8*))
  %call2 = call i32 @pthread_create(i64* nonnull %thread, %union.pthread_attr_t* null, i8* (i8*)* nonnull @baz, i8* nocapture %alloc1)
  %call3 = call i32 @pthread_create(i64* nonnull %thread, %union.pthread_attr_t* null, i8* (i8*)* nonnull @buz, i8* %alloc2)
  ret i32 0
}

declare !callback !0 dso_local i32 @pthread_create(i64*, %union.pthread_attr_t*, i8* (i8*)*, i8*)

define internal i8* @foo(i8* %arg) {
; CHECK: Function Attrs: nofree norecurse nosync nounwind readnone willreturn
; CHECK-LABEL: define {{[^@]+}}@foo
; CHECK-SAME: (i8* noalias nocapture nofree readnone align 4294967296 [[ARG:%.*]]) #[[ATTR0:[0-9]+]] {
; CHECK-NEXT:  entry:
; CHECK-NEXT:    ret i8* null
;
entry:
  ret i8* %arg
}

define internal i8* @bar(i8* %arg) {
; CHECK: Function Attrs: nofree norecurse nosync nounwind readnone willreturn
; CHECK-LABEL: define {{[^@]+}}@bar
; CHECK-SAME: (i8* noalias nocapture nofree nonnull readnone align 8 dereferenceable(8) [[ARG:%.*]]) #[[ATTR0]] {
; CHECK-NEXT:  entry:
; CHECK-NEXT:    ret i8* bitcast (i8** @GlobalVPtr to i8*)
;
entry:
  ret i8* %arg
}

define internal i8* @baz(i8* %arg) {
; CHECK: Function Attrs: nofree norecurse nosync nounwind readnone willreturn
; CHECK-LABEL: define {{[^@]+}}@baz
; CHECK-SAME: (i8* noalias nofree noundef nonnull readnone returned align 8 dereferenceable(1) "no-capture-maybe-returned" [[ARG:%.*]]) #[[ATTR0]] {
; CHECK-NEXT:  entry:
; CHECK-NEXT:    ret i8* [[ARG]]
;
entry:
  ret i8* %arg
}

define internal i8* @buz(i8* %arg) {
; CHECK: Function Attrs: nofree norecurse nosync nounwind readnone willreturn
; CHECK-LABEL: define {{[^@]+}}@buz
; CHECK-SAME: (i8* noalias nofree noundef nonnull readnone returned align 8 dereferenceable(1) "no-capture-maybe-returned" [[ARG:%.*]]) #[[ATTR0]] {
; CHECK-NEXT:  entry:
; CHECK-NEXT:    ret i8* [[ARG]]
;
entry:
  ret i8* %arg
}

!1 = !{i64 2, i64 3, i1 false}
!0 = !{!1}
;.
; CHECK: attributes #[[ATTR0]] = { nofree norecurse nosync nounwind readnone willreturn }
;.
; CHECK: [[META0:![0-9]+]] = !{!1}
; CHECK: [[META1:![0-9]+]] = !{i64 2, i64 3, i1 false}
;.