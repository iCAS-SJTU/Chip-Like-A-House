#!/usr/bin/env python3
"""
rng_helper.py
Small helper to produce a truncated normal (or uniform) RNG value reproducibly from an integer seed.
Usage:
  rng_helper.py --seed N [--mu 1.0] [--sigma 0.3] [--min 0.5] [--max 2.0]
Prints a single floating value to stdout.
"""
import argparse
import hashlib
import random
import sys

p = argparse.ArgumentParser()
p.add_argument('--seed', type=str, required=True, help='seed (int or string)')
p.add_argument('--mu', type=float, default=1.0)
p.add_argument('--sigma', type=float, default=0.30)
p.add_argument('--min', dest='mn', type=float, default=0.5)
p.add_argument('--max', dest='mx', type=float, default=2.0)
p.add_argument('--uniform', nargs=2, type=int, metavar=('MIN','MAX'),
               help='If provided, output a single integer uniformly between MIN and MAX (inclusive)')
args = p.parse_args()

# Create a large integer seed from provided seed string using sha256
h = hashlib.sha256(args.seed.encode('utf-8')).digest()
seed_int = int.from_bytes(h, 'big') & ((1<<63)-1)
rnd = random.Random(seed_int)
if args.uniform:
  mn, mx = args.uniform
  # randint is inclusive
  v = rnd.randint(mn, mx)
  print(str(v))
  sys.exit(0)

# Draw gaussian and truncate
while True:
  v = rnd.gauss(args.mu, args.sigma)
  if v >= args.mn and v <= args.mx:
    print(f"{v:.6f}")
    sys.exit(0)
  # If it's outside, draw again (loop until truncated)
