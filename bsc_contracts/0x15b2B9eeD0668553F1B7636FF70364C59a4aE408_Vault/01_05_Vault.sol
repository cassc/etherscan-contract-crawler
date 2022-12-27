// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./traits/HasEmergency.sol";

contract Vault is HasEmergency {
    event DepositBNB (address indexed from, uint qty);
    event WithdrawBNB (address indexed to, uint qty);
    event Deposit (address indexed token, address indexed from,  uint qty);
    event Withdraw (address indexed token, address indexed to, uint qty);

    constructor (
        address _receiver,
        address _reserved
    ) HasEmergency(_receiver, _reserved) {}

    receive() external payable {
        if (msg.value > 0) {
            emit DepositBNB(_msgSender(), msg.value);
        }
    }
    fallback() external payable {}

    function deposit(address _token, uint _qty) public {
        require(IERC20(_token).transferFrom(_msgSender(), address(this), _qty), 'Vault: Fail to deposit');
        emit Deposit(_token, _msgSender(), _qty);
    }

    function transfer(address _token, address _to, uint _qty) public onlyOwner {
        _payOutToken(_token, _to, _qty);
    }

    function mutiTransfer(address _token, address[] calldata _to, uint[] calldata _qty) public onlyOwner {
        require(_to.length == _qty.length, "Vault: Array Set Error");
        uint _count = _to.length;

        for (uint i = 0; i < _count; i++) {
            _payOutToken(_token, _to[i], _qty[i]);
        }
    }

    function withdrawBNB(uint _qty) public onlyOwner {
        (bool send, ) = payable(receiver).call{ value: _qty }("");
        require(send, "Vault: Fail to withdraw");
        emit WithdrawBNB(receiver, _qty);
    }

    function withdraw(address _token, uint _qty) public onlyOwner {
        _payOutToken(_token, receiver, _qty);
        emit Withdraw(_token, receiver, _qty);
    }
}