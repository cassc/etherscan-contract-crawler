/**
 *Submitted for verification at BscScan.com on 2023-01-30
*/

// SPDX-License-Identifier: MIT
/**
 * @title EternalLabsProxyStaker
 * @author : saad sarwar
 * @website : eternallabs.finance
 */

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IBEP20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IBananaPool {
    function deposit(uint256 _pid,uint256 _amount) external;
    function withdraw(uint256 _pid,uint256 _amount) external;
    function depositTo(
        uint256 _pid,
        uint256 _amount,
        address _to
    ) external;
}

contract EternalLabsProxyStaker is Ownable {

    address public TOKEN = 0x603c7f932ED1fc6575303D8Fb018fDCBb0f39a95;
    address public BANANA_POOL = 0x71354AC3c695dfB1d3f595AfA5D4364e9e06339B; 
    address public STAKER = 0x54BC1bE890669C2E7889500d2fA71191d3875B6A;

    uint256 MAX_INT = 2**256 - 1;
    
    constructor() {}

    function setTokenAddress(address token) public onlyOwner {
        TOKEN = token;
    }

    function stake() public onlyOwner {
        IBananaPool(BANANA_POOL).depositTo(0, IBEP20(TOKEN).balanceOf(address(this)), STAKER);
    }

    function getBananaApproved() public onlyOwner() {
        IBEP20(TOKEN).approve(BANANA_POOL, MAX_INT);
    }

    // emergency withdrawal function in case of any bug or v2
    function withdrawTokens() public onlyOwner() {
        IBEP20(TOKEN).transfer(msg.sender, IBEP20(TOKEN).balanceOf(address(this)));
    }
}