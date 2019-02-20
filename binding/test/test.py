# -*- coding: utf-8 -*-

import unittest
import foo

class MathTest(unittest.TestCase):
    def testMath(self):
        '''Test case for Math class from foo module.'''
        val = 5
        math = foo.Math('000001.sh')
        print(math.getM())
        self.assertEqual(math.squared(5), 5 * 5)

if __name__ == '__main__':
    unittest.main()
