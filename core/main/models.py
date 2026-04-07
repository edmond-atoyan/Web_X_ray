from django.db import models


class XRayImage(models.Model):
    image = models.ImageField(upload_to='xray_images/')
    uploaded_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'xray_images'
        ordering = ['-uploaded_at']

    def __str__(self):
        return f"X-Ray #{self.pk} — {self.uploaded_at:%Y-%m-%d %H:%M}"
