import random
import astropy.units as u
from astropy.table import QTable
from astropy.coordinates import SkyCoord

n = 4_000_000

ra1 = list(random.uniform(0, 360) for i in range(n)) * u.degree
ra2 = list(random.uniform(0, 360) for i in range(n)) * u.degree
dec1 = list(random.uniform(-90, 90) for i in range(n)) * u.degree
dec2 = list(random.uniform(-90, 90) for i in range(n)) * u.degree
sc1 = SkyCoord(ra=ra1, dec=dec1)
sc2 = SkyCoord(ra=ra2, dec=dec2)
idx, idx0, sep2d, _ = sc1.search_around_sky(sc2, 10*u.arcsec)
# print(len(sep2d), len(idx))
# print(idx)
# print(sep2d)
