# lottery numbers
# demonstrates random number generation

# generate random number 1-6
#import random
#
#die1  = random.sample (range (1,  57),  5)
#die2  = random.sample (range (1,  57),  5)
#die3  = random.sample (range (1,  57),  5)
#die4  = random.sample (range (1,  57),  5)
#die5  = random.sample (range (1,  57),  5)
#
#
#die6  = random.randint (1, 46)
#die7  = random.randint (1, 46)
#die8  = random.randint (1, 46)
#die9  = random.randint (1, 46)
#die10 = random.randint (1, 46)
#
#
#print("Your Mega Millions Numbers are", die1, die2, die3, die4, die5)
#print("Your Mega Ball is", die6, die7, die8, die9, die10)
#input("/n/nPress the enter key to exit.")
#
#

import random
print "Offical Mega Millions number generator"
x = int(raw_input("How many sets of numbers? "))

for n in range(x):
#  i = random.sample(range(1,53), 5)
  i = sorted(random.sample(range(1, 57), 5))
  q = i[0]
  w = i[1]
  e = i[2]
  r = i[3]
  t = i[4]
  print "Your Megamillions numbers: " + str(q), str(w), str(e), str(r), str(t)
