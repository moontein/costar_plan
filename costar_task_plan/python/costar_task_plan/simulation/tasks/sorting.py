from abstract import AbstractTaskDefinition

import numpy as np
import os
import pybullet as pb
import rospkg


class SortingTaskDefinition(AbstractTaskDefinition):
    joint_positions = [0.30, -0.5, -1.80, -0.27, 1.50, 1.60]
    urdf_dir = "urdf"

    blue_urdf = "blue.urdf"
    red_urdf = "red.urdf"
    model = "ball"

    tray_dir = "tray"
    tray_urdf = "traybox.urdf"

    spawn_pos_min = np.array([-0.4 ,-0.25, 0.05])
    spawn_pos_max = np.array([-0.65, 0.25, 0.055])
    spawn_pos_delta = spawn_pos_max - spawn_pos_min

    tray_poses = [np.array([-0.5, 0., 0.0]),
                  np.array([0., +0.6, 0.0]),
                  np.array([-1.0, -0.6, 0.0])]

    def __init__(self, robot, red=3, blue=3, *args, **kwargs):
        '''
        Your desription here
        '''
        super(SortingTaskDefinition, self).__init__(robot, *args, **kwargs)
        self.num_red = red
        self.num_blue = blue

    def _setup(self):
        '''
        Create the mug at a random position on the ground, handle facing
        roughly towards the robot. Robot's job is to grab and lift.
        '''


        rospack = rospkg.RosPack()
        path = rospack.get_path('costar_objects')
        urdf_dir = os.path.join(path, self.urdf_dir)
        tray_filename = os.path.join(urdf_dir, self.tray_dir, self.tray_urdf)
        red_filename = os.path.join(urdf_dir, self.model, self.red_urdf)
        blue_filename = os.path.join(urdf_dir, self.model, self.blue_urdf)

        for position in self.tray_poses:
            obj_id = pb.loadURDF(tray_filename)
            pb.resetBasePositionAndOrientation(obj_id, position, (0,0,0,1))

        self._add_balls(self.num_red, red_filename)
        self._add_balls(self.num_blue, blue_filename)

    def _add_balls(self, num, filename):
        '''
        Helper function to spawn a whole bunch of random balls.
        '''
        for i in xrange(num):
            obj_id = pb.loadURDF(filename)
            random_position = np.random.rand(3)*self.spawn_pos_delta + self.spawn_pos_min
            pb.resetBasePositionAndOrientation(obj_id, random_position, (0,0,0,1))

    def _setupRobot(self, handle):
        '''
        Configure the robot so that it is ready to begin the task. Robot should
        be oriented so the gripper is near the cluttered area with the mug.
        '''
        self.robot.place([0,0,0],[0,0,0,1],self.joint_positions)
        self.robot2 = self.cloneRobot()
        self.robot2.load()
        self.robot2.place([-1,0,0],[0,0,1,0],
                self.joint_positions)
        self.robot.arm(self.joint_positions, pb.POSITION_CONTROL)
        self.robot.gripper(0, pb.POSITION_CONTROL)

