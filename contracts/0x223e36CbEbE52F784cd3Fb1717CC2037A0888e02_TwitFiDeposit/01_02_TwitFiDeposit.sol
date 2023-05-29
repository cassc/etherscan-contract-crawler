// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TwitFiDeposit {
    address public _owner;
    IERC20 public _twitfi;

    constructor(IERC20 _token) {
        _owner = msg.sender;
        _twitfi = _token;
    }

    function setToken(IERC20 _token) public onlyOwner {
        _twitfi = _token;
    }

    function setOwner(address _newOwner) public onlyOwner {
        _owner = _newOwner;
    }

    function transfer(address _to, uint _amount) public onlyOwner {
        require(_twitfi.balanceOf(address(this)) >= _amount, "INSUFFICIENT_BALANCE");
        _twitfi.transfer(_to, _amount);
    }

    function withdraw() public onlyOwner {
        uint amount = address(this).balance;
        require(amount > 0, "Insufficient balance");
        (bool success, ) = payable(_owner).call {
            value: amount
        }("");

        require(success, "Failed to send Matic");
    }

    function emergencyWithdraw() external onlyOwner {
        _twitfi.transfer(_owner, _twitfi.balanceOf(address(this)));
    }

    modifier onlyOwner {
        require(msg.sender == _owner, "UNAUTHORIZED");
        _;
    }

    receive() payable external {}
}