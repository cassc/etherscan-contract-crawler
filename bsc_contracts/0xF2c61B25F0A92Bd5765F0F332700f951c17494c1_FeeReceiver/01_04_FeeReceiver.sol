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
        adr3 = 0x66922a0B755176B5ae9A9256EfD1794F38d4BE47;
        adr4 = 0x39Ca735837d01f3f7D4FefDF589c0202965637F3;
        fee1 = 35;
        fee2 = 10;
        fee3 = 10;
    }

    function setAddresses(
        address _adr1,
        address _adr2,
        address _adr3,
        address _adr4
    ) external onlyOwner {
        adr1 = _adr1;
        adr2 = _adr2;
        adr3 = _adr3;
        adr4 = _adr4;
    }

    function setFees(uint256 _fee1, uint256 _fee2, uint256 _fee3)
        external
        onlyOwner
    {
        require((2 * _fee1) + _fee2 + _fee3 == 90, "Fees Incorrect");
        fee1 = _fee1;
        fee2 = _fee2;
        fee3 = _fee3;
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