
import os

import argh
import requests


def main(outfile, cookiepath='.cookie', year='2021', chunksize=16):
	cookie = open(cookiepath).read().strip()
	name, _ = os.path.splitext(os.path.basename(outfile))
	day = name.split("-")[0]
	resp = requests.get('https://adventofcode.com/{}/day/{}/input'.format(year, day), headers={"Cookie": cookie})
	resp.raise_for_status()
	data = resp.content
	with open(outfile, 'w') as f:
		for i in range(0, len(data), chunksize):
			f.write("db {}\n".format(",".join(str(ord(c)) for c in data[i:i+chunksize])))


if __name__ == '__main__':
	argh.dispatch_command(main)
