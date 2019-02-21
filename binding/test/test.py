# -*- coding: utf-8 -*-

import unittest
import foo

class MathTest(unittest.TestCase):
    def testMath(self):
        '''Test case for Math class from foo module.'''
        val = 5
        counter = foo.Counter(600001)
        print(counter.getCounter())
        self.assertEqual(counter.value(), 600001)
        counter.setValue(55)
        print(counter.getCounter())
        self.assertEqual(counter.value(), 55)
        print(counter.getCounter())
        self.assertEqual(counter.squared(5), 5 * 5)

if __name__ == '__main__':
    unittest.main()
