export CUDA_VISIBLE_DEVICES="0" && python2 grasp_train.py --batch_size=7 --epochs 300 --save_weights delta_depth_sin_cos_3 --grasp_model grasp_model_levine_2016_segmentation --optimizer SGD --load_weights "2018-01-15-21-14-49_median_depth_dataset_062_b_063_072_a_082_b_102_delta_depth_sin_cos_3-grasp_model_levine_2016_segmentation-epoch-001_evaluation_dataset_097_epoch_009_loss_0.728_acc_0.557.h5"