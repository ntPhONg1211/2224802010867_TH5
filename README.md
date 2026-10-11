# Ứng dụng ghi chú cá nhân

Ứng dụng Flutter lưu ghi chú trên thiết bị bằng SharedPreferences. Dữ liệu được mã hóa JSON và chạy trên Android, Web, Windows. Mỗi ghi chú gồm tiêu đề, nội dung, thời điểm tạo và thời điểm cập nhật.

## 1. Chuẩn bị môi trường

1. Cài Flutter SDK.
2. Để chạy Web, cài Microsoft Edge. Để chạy Windows desktop, cài Visual Studio 2022 với workload **Desktop development with C++**.
3. Android Studio và Android SDK chỉ cần thiết nếu muốn chạy thêm trên Android.
4. Mở Terminal tại thư mục dự án và kiểm tra cấu hình:

	```bash
	flutter doctor
	```

4. Cài các package của dự án:

	```bash
	flutter pub get
	```

## 2. Chạy ứng dụng

1. Kiểm tra các target Flutter nhận diện được:

	```bash
	flutter devices
	```

2. Chạy trên Microsoft Edge:

	```bash
	flutter run -d edge
	```

3. Chạy trên Windows desktop:

	```bash
	flutter run -d windows
	```

4. Nếu muốn chạy trên Android, khởi động emulator hoặc kết nối điện thoại rồi chạy:

	```bash
	flutter run -d android
	```

## 3. Sử dụng các chức năng

1. Ở màn hình **Ghi chú**, nhấn **Ghi chú mới**.
2. Nhập tiêu đề và nội dung, sau đó nhấn **Lưu**. Ứng dụng kiểm tra cả hai trường không được để trống.
3. Chạm vào một ghi chú trong danh sách để sửa; nhấn **Lưu** để cập nhật và trở về danh sách.
4. Vuốt ghi chú sang trái hoặc nhấn giữ ghi chú rồi chọn **Xóa ghi chú**. Xác nhận thao tác trong hộp thoại trước khi dữ liệu bị xóa.
5. Nhập từ khóa vào ô tìm kiếm để lọc theo tiêu đề hoặc nội dung.

## 4. Cấu trúc và luồng dữ liệu

- `lib/models/note.dart`: mô hình `Note`, chuyển đổi giữa đối tượng Dart và dữ liệu dạng map của SQLite.
- `lib/data/note_storage.dart`: lưu danh sách ghi chú JSON và cung cấp các hàm đọc/thêm/sửa/xóa.
- `lib/main.dart`: giao diện danh sách, form thêm/sửa, tìm kiếm và xác nhận xóa.
- `test/widget_test.dart`: kiểm tra form yêu cầu tiêu đề và nội dung.

Mỗi ghi chú được lưu thành một đối tượng JSON với các trường:

| Trường | Kiểu | Ý nghĩa |
| --- | --- | --- |
| `id` | integer | Mã ghi chú |
| `title` | string | Tiêu đề |
| `content` | string | Nội dung |
| `created_at` | integer | Thời điểm tạo, Unix milliseconds UTC |
| `updated_at` | integer | Thời điểm sửa gần nhất, Unix milliseconds UTC |

Danh sách JSON được lưu bằng `shared_preferences`; `id` được dùng để cập nhật hoặc xóa đúng ghi chú.

## 5. Kiểm tra và tạo APK

Chạy kiểm tra mã nguồn và widget test:

```bash
flutter analyze
flutter test
```

Tạo APK debug để cài thử:

```bash
flutter build apk --debug
```

APK được tạo tại `build/app/outputs/flutter-apk/app-debug.apk`.


http://127.0.0.1:5000/