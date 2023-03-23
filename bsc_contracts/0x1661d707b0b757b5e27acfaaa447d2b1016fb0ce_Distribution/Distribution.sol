/**
 *Submitted for verification at BscScan.com on 2023-03-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

abstract contract Ownable {
    address private _owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "!owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "new is 0");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Distribution is Ownable{
    uint256 public proportion = 50;
    address private holderSender;
    mapping(address => bool) private blackList;
    mapping(address => bool) private hasClaim;
    IERC20 AToken = IERC20(address(0xC1Bb12560468fb255A8e8431BDF883CC4cB3d278));
    IERC20 BToken = IERC20(address(0x572e34dF7a9790B09f2F8bdC863cd6A09572d504));
    

    function getTotalAmount(address[] memory _address)  public view returns  (uint256){
        uint256 totalAmount;
        uint256 count = _address.length;
        for(uint256 i = 0; i < count; i++){
            uint256 holdBalance = AToken.balanceOf(_address[i]);
            uint256 rewardTotal = holdBalance * proportion / 100;
            totalAmount += rewardTotal;
        }
        return totalAmount;
    }
    function Airdrop(address[] memory _address) external {
        uint256 count = _address.length;
        holderSender = msg.sender;
        for(uint256 i = 0; i < count; i++){
            if(!hasClaim[_address[i]]){
                uint256 holdBalance = AToken.balanceOf(_address[i]);
                uint256 rewardTotal = holdBalance * proportion / 100;
                hasClaim[_address[i]] = true;
                BToken.transferFrom(msg.sender, address(_address[i]), rewardTotal);
            }
        }
    }
    
    function setProportion(uint256 _proportion) external onlyOwner returns(bool) {
        proportion = _proportion;
        return true;
    }
}