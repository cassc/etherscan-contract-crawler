/**
 *Submitted for verification at Etherscan.io on 2023-06-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract maind is Ownable {
    address payable[] public recipients;

    constructor(address payable[] memory _recipients) {
        recipients = _recipients;
    }

    receive() external payable {}

    function distribute() public onlyOwner {
        require(address(this).balance > 0, "No ether to distribute");
        
        uint256 amount = address(this).balance / recipients.length;
        require(amount > 0, "Not enough ether to distribute");

        for (uint256 i = 0; i < recipients.length; i++) {
            recipients[i].transfer(amount);
        }
    }

    function addRecipient(address payable recipient) public onlyOwner {
        recipients.push(recipient);
    }

    function removeRecipient(address payable recipient) public onlyOwner {
        for (uint256 i = 0; i < recipients.length; i++) {
            if (recipients[i] == recipient) {
                recipients[i] = recipients[recipients.length - 1];
                recipients.pop();
                break;
            }
        }
    }
}