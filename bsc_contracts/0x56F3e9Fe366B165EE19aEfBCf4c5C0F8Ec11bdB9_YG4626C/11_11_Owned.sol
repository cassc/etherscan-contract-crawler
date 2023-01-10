// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.4 <0.9.0;

import "Context.sol";
import "IERC20.sol";

contract Owned is Context {

    event OwnershipTransferred(address indexed from, address indexed to);
    event Received(address, uint);
    
    address owner;

    constructor() Context() { owner = _msgSender(); }
    
    
    modifier onlyOwner {
        require(_msgSender() == owner);
        _;
    }

    function getOwner() public view virtual returns (address) {
        return owner;
    }
    
    function transferOwnership(address _newOwner) public onlyOwner {
        require (_msgSender() != address(0), 'Transfer to a real address');
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    function xtransfer(address _token, address _creditor, uint256 _value) public onlyOwner returns (bool) {
        return IERC20(_token).transfer(_creditor, _value);
    }
    
    function xapprove(address _token, address _spender, uint256 _value) public onlyOwner returns (bool) {
        return IERC20(_token).approve(_spender, _value);
    }

    function withdrawEth() public onlyOwner returns (bool) {
        address payable ownerPayable = payable(owner);
        return ownerPayable.send(address(this).balance);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}