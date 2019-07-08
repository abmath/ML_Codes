import cv2
import os

os.chdir(r"/Users/abhinavmathur/Documents/")

print(os.getcwd())

cap = cv2.VideoCapture(0)

while(True):
    ret, frame = cap.read()
    rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2BGRA)

    cv2.imshow('frame',rgb)

    if cv2.waitKey(1) & 0xFF == ord('q'):
        out = cv2.imwrite('/Users/abhinavmathur/Documents/capture.jpg', frame)
    break

cap.release()
cv2.destroyAllWindows()
