//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Ownable.sol";
import "./IERC20.sol";

contract FeeReceiver is Ownable {
    address adr1;
    address adr2;
    address adr3;
    uint256 fee1;
    uint256 fee2;

    constructor() {
        adr1 = msg.sender;
        adr2 = 0x7398Feb74fcd2C274f9c0a35B9A833a05e9a5971;
        adr3 = 0x66922a0B755176B5ae9A9256EfD1794F38d4BE47;
        fee1 = 40;
        fee2 = 10;
    }

    function setAddresses(
        address _adr1,
        address _adr2,
        address _adr3
    ) external onlyOwner {
        adr1 = _adr1;
        adr2 = _adr2;
        adr3 = _adr3;
    }

    function setFees(uint256 _fee1, uint256 _fee2)
        external
        onlyOwner
    {
        require((2 * _fee1) + _fee2 == 90, "Fees Incorrect");
        fee1 = _fee1;
        fee2 = _fee2;
    }

    function trigger() external {
        require(address(this).balance > 0, "No ETH");
        uint256 balance = address(this).balance;
        _send(adr1, (balance * fee1) / 90);
        _send(adr2, (balance * fee1) / 90);
        _send(adr3, (balance * fee2) / 90);
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