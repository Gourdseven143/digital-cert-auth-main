import 'package:flutter_test/flutter_test.dart';
import 'package:digital_cert_auth_fixed/certificate_pdf_service.dart';
void main() {
  test('PDF生成测试', () async {
    // 准备测试数据
    const recipientName = "测试用户";
    const courseName = "数字证书管理";
    final issueDate = DateTime.now();
    
    // 执行测试
    final pdfBytes = await CertificatePDF.generateEnhancedCertificate(
      recipientName: recipientName,
      courseName: courseName,
      issueDate: issueDate,
    );
    
    // 验证结果
    expect(pdfBytes, isNotNull);
    expect(pdfBytes.length, greaterThan(1000)); // 确保文件大小合理
  });
}