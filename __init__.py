import sys
import os

# add plugin to python path
sys.path.append(os.path.abspath(os.path.dirname(__file__)))

import clang_arm_plugin.clean
import clang_arm_plugin.compile

