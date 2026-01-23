# Danh mục Tài liệu Tìm hiểu BMAD (BMAD Knowledge Base Index)

> Chào mừng bạn đến với kho lưu trữ kiến thức về **BMAD Method**. Các tài liệu dưới đây được sắp xếp theo trình tự từ tổng quan đến chi tiết kỹ thuật để bạn có thể nắm bắt hệ thống một cách hiệu quả nhất.

---

## 🌟 Khóa học Master BMAD (Dành cho người mới)
Nếu bạn muốn bắt đầu áp dụng ngay vào dự án thực tế, hãy theo dõi bộ giáo trình này:
- **[LÀM CHỦ BMAD METHOD TRONG CLAUDE CODE](./course/index.md)** (Đầy đủ Case Studies & Diagram)

---

## 📂 Lộ trình Tìm hiểu (Learning Path)

Hãy đọc các tài liệu theo thứ tự dưới đây để hiểu về cách BMAD vận hành:

### 1️⃣ Cấp độ Tổng quan: Kiến trúc Hệ thống
Hiểu về cấu trúc thư mục, các lớp (layers) và cách BMAD được tích hợp vào Claude Code.
- **Tài liệu**: [Phân tích Kiến trúc BMAD](./BMAD-Architecture-Analysis-VN.md)
- **Nội dung chính**: Cấu trúc thư mục `_bmad/`, mô hình Dispatch, và bảng phân loại lệnh sơ bộ.

### 2️⃣ Cấp độ Quy trình: Luồng làm việc (Workflows)
Tìm hiểu về hành trình người dùng, các giai đoạn phát triển (Phases) và sự khác biệt giữa dự án mới (Greenfield) vs dự án cũ (Brownfield).
- **Tài liệu**: [Đi sâu vào Quy trình BMAD](./BMAD-Workflow-Deep-Dive-VN.md)
- **Nội dung chính**: Hành trình 5 giai đoạn, sơ đồ luồng hoạt động, và hệ thống tài liệu đầu ra (Artifacts).

### 3️⃣ Cấp độ Kỹ thuật: Cơ chế Thực thi
Phân tích sâu về cách các câu lệnh slash chuyển hóa thành hành động thực tế của AI thông qua các động cơ thực thi.
- **Tài liệu**: [Chi tiết Cơ chế Lệnh và Thực thi](./BMAD-Command-Execution-Logic-VN.md)
- **Nội dung chính**: Anatomy của một Command, so sánh Step-file Workflow vs XML Task Engine (`workflow.xml`).

---

## 🛠 Tài liệu Tham khảo Gốc (Original Reference)
Dành cho việc đối chiếu với nội dung gốc bằng tiếng Anh.
- [BMAD Architecture Analysis (English)](./BMAD-Architecture-Analysis.md)

---

## 📌 Ghi chú nhanh cho Kỹ sư
| Mục tiêu | Tài liệu cần đọc |
| :--- | :--- |
| Muốn hiểu cách cài đặt & tổ chức file | [Kiến trúc](./BMAD-Architecture-Analysis-VN.md) |
| Muốn biết nên chạy lệnh nào tiếp theo | [Quy trình](./BMAD-Workflow-Deep-Dive-VN.md) |
| Muốn debug hoặc sửa đổi cách lệnh hoạt động | [Cơ chế thực thi](./BMAD-Command-Execution-Logic-VN.md) |

---
*Tài liệu này được biên soạn và cập nhật tự động bởi Astragentic.*
