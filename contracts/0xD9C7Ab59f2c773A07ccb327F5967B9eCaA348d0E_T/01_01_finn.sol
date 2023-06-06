// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract T {
    uint256[] public l1 = [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ];
    uint256[] public l2;
	
	uint256 public z = 0;

	function tt(uint256 ti) public returns (uint256) {
		z = z + 1;
	
		uint256 t = 0;

		uint256 s = 0;
		uint256 e = 0;

		for (uint256 i = 0; i < 100; i++) {
			if(ti > i * 1000 && ti <= (i + 1) * 1000) {
				s = (i * 1000) + 1;
				e = s + 1000;

				break;
			}
		}

		for (uint256 i = s; i < e; i++) {
			t++;

			if (i == ti) {
				break;
			}

			if (t == 1000) {
				t = 0;
			}
		}
		
		return t;
	}

	function pl(uint256 t) public returns (uint256) {
		z = z + 1;
	
		uint256 c = 100000;
		uint256 u = 0;

		for (uint256 i = 0; i < 100; i++) {
			if (c >= (t + (i * 1000))) {
				u++;
			} else {
				break;
			}
		}

		return u;
	}

	function rt(uint256 ti) public returns(uint256) {
		z = z + 1;
	
		uint256 t = tt(ti);
		uint256 p = 1000;

		for (uint256 i = 0; i < l1.length; i++) {
			if(l1[i] == t) {
				p = i;
				break;
			}
		}

		return p;
	}

	function tp(uint256 ti) public returns (uint256) {
		z = z + 1;
	
		uint256 t = tt(ti);
		uint256 p = rt(ti);

		if(p < l2.length) {
			return l2[p] / pl(t);
		}

		return 0;
	}
	
	function pu() public {
		z = z + 1;
	
		delete l2;

		uint256 a = 5000 ether;

		for(uint256 i = 0; i < 100; i++) {
			a /= 2;

			if(a < 100000000000000) {
				break;
			}

			l2.push(a);
		}
    }
}