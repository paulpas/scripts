import random
print "Ofical Powerball number generator"
x = int(raw_input("How many sets of numbers? "))
z = range(1,42)

for n in range(x):
  z1 = random.choice(z)
#  i = random.sample(range(1,53), 5)
  i = sorted(random.sample(range(1, 53), 5))
  q = i[0]
  w = i[1]
  e = i[2]
  r = i[3]
  t = i[4]
  print "Your numbers: " + str(q), str(w), str(e), str(r), str(t) +  " Powerball: "+ str(z1)
