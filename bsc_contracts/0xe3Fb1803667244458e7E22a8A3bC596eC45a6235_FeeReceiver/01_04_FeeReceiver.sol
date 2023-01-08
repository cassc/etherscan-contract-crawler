//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Ownable.sol";
import "./IERC20.sol";

contract FeeReceiver is Ownable {
    address adr1;
    address adr2;
    address adr3;
    address adr4; 
    uint256 fee1;
    uint256 fee2;
    uint256 fee3;

    constructor() {
        adr1 = msg.sender;
        adr2 = 0x7398Feb74fcd2C274f9c0a35B9A833a05e9a5971; 
        adr3 = 0x7a8b19eACd08e3171ff02ecfAf7c7e108507495B; 
        adr4 = 0x7f3e88eaDaaEF8c0b8732dF8cBba20a895Ca2Da0; 
        fee1 = 20;
        fee2 = 30;
        fee3 = 20;
    }

    function setAddress4(address _adr) external onlyOwner {
        adr4 = _adr;
    }

    function trigger() external {
        require(address(this).balance > 0, "No ETH");
        uint256 balance = address(this).balance;
        _send(adr1, (balance * fee1) / 90);
        _send(adr2, (balance * fee1) / 90);
        _send(adr3, (balance * fee2) / 90);
        _send(adr4, (balance * fee3) / 90);
    }

    function _send(address _to, uint256 _amount) internal {
        (bool success, ) = payable(_to).call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function withdraw() external onlyOwner {
        (bool s, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(s);
    }

    function withdraw(address _token) external onlyOwner {
        IERC20(_token).transfer(
            msg.sender,
            IERC20(_token).balanceOf(address(this))
        );
    }

    receive() external payable {}
}