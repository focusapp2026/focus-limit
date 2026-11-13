# مساحة

تطبيق Flutter يساعد على تنظيم مشاهدة الفيديوهات القصيرة داخل التطبيق:

- حد يومي ثابت: 5 فيديوهات TikTok و2 فيديو YouTube.
- إضافة روابط فيديو مباشرة وتشغيلها داخل التطبيق.
- حفظ قائمة الفيديوهات والرصيد محليًا على الجهاز.
- تجديد الرصيد حسب تاريخ الجهاز عند منتصف الليل.
- إيقاف فتح الفيديوهات الجديدة عند انتهاء حد المنصة.

## التشغيل على أندرويد

1. ثبّت Flutter وAndroid Studio على جهازك، ثم افتح Android Studio وثبّت Android SDK.
2. وصّل هاتف أندرويد مع تفعيل USB debugging، أو شغّل محاكيًا من Android Studio.
3. من مجلد المشروع نفّذ:

   ```bash
   cd apps/shorts_guard
   flutter pub get
   flutter run
   ```

## التشغيل على آيفون

يتطلب بناء نسخة iPhone جهاز Mac عليه Xcode. بعد فتح المشروع على جهاز Mac:

```bash
cd apps/shorts_guard
flutter pub get
cd ios
pod install
cd ..
flutter run
```

في هذه البيئة لا يتوفر Android SDK أو Xcode، لذلك يلزم إكمال تشغيل الجهاز من جهازك المحلي. ملفات Android وiOS الأساسية موجودة في المشروع.

## معاينة واجهة الويب

تُستخدم نسخة الويب للمعاينة وتجربة القائمة والعدادات. مشغّل الفيديو في المعاينة يعرض الفيديو داخل إطار متصفح، بينما إصدار الهاتف الأصلي يتضمن متابعة تشغيل الفيديوهات الإضافية داخل مشغّل YouTube.

في Replit، افتح نافذة Preview واختر المنفذ `5173` من قائمة المنافذ إذا ظهرت صفحة فارغة على العنوان الرئيسي.

## إضافة فيديو

افتح التطبيق، اضغط «إضافة فيديو»، ثم الصق رابط TikTok أو YouTube. يقبل TikTok رابط الفيديو الكامل الذي يحتوي على `/video/`، ويقبل YouTube روابط المشاهدة وShorts و`youtu.be`.

يُخصم الفيديو من الرصيد عند فتحه داخل التطبيق. يُحتسب كل فيديو جديد يبدأ داخل مشغّل YouTube أيضًا؛ إذا لم يكن الفيديو متاحًا للتضمين فقد يعرض المشغّل رسالة خطأ. روابط TikTok المختصرة مثل `vm.tiktok.com` غير مدعومة حاليًا.

## حدود النسخة الحالية

هذا التطبيق لا يراقب ولا يغلق تطبيقَي TikTok أو YouTube المثبّتين على الهاتف. حدوده تنطبق على الفيديوهات التي تُفتح من قائمة التطبيق فقط. كما أن التخزين محلي، ويمكن تجاوزه بتغيير تاريخ الجهاز أو حذف بيانات التطبيق؛ هذه النسخة أداة مساعدة ذاتية وليست قفلًا parental أو حماية لا يمكن تجاوزها.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
