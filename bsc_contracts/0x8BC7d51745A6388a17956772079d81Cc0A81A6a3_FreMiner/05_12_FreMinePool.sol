// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.5.0;
import "./TransferHelper.sol";
import "./IBEP20.sol";

contract FreMinePool {
    address _owner;
    address _token;
    address _feeowner;
    using TransferHelper for address;

    address _destroyAddr = address(0x000000000000000000000000000000000000dEaD);

    constructor(address tokenaddress, address feeowner) {
        _owner = msg.sender;
        _token = tokenaddress;
        _feeowner = feeowner;
    }

    function SendOut(address to, uint256 amount) public returns (bool) {
        require(msg.sender == _feeowner);
        _token.safeTransfer(to, amount);
        return true;
    }

    function MineOut(
        address to,
        uint256 amount,
        uint256 fee
    ) public returns (bool) {
        require(msg.sender == _owner);
        _token.safeTransfer(to, amount);
        if (fee != 0) {
            _token.safeTransfer(_destroyAddr, fee);
        }

        return true;
    }
}
