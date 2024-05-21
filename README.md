# RoIRTC: Toward Region-of-Interest Reinforced Real-Time Video Communication

We propose a region-of-interest (RoI) reinforced real-time communication system, for improving the quality of videos delivered in real-time communication. RoIRTC uses a novel RoI magnification transformation for spatially adapting the camera-captured video frame. To automatically detect the RoI, it intelligently leverages a deep-learning-based saliency prediction model without affecting the video collector's processing throughput or the encoder's efficiency. Evaluation results based on actual remote learning videos show that RoIRTC that performs RoI magnification can improve the median PSNR by 2.6 dB compared to the naive WebRTC implementation. Compared to an approach that mimics the ``background blur'' scheme used in many real-time communication systems, RoIRTC can also improve the median PSNR by 4.2 dB.

## WebRTC_2_RoIRTC Code Base

We implement the RoI reinforcement function on the WebRTC code base.

## FastTransform360

We present our cross 2D-3D frame projection module, which accelerated by CUDA
