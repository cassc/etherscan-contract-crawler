// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/ILiquidSplit.sol";

contract FundsReceiver {
    /// @notice recipient of funds from primary sale (25%).
    address payable public immutable liquidSplit;
    /// @notice All Core Dev team who made The Merge happen (25%).
    address payable public constant coreDevs =
        payable(0xF29Ff96aaEa6C9A1fBa851f74737f3c069d4f1a9);
    /// @notice SongaDAO (45%).
    address payable public constant songaDao =
        payable(0x2a2C412c440Dfb0E7cae46EFF581e3E26aFd1Cd0);
    /// @notice sweetman.eth - the music nft engineer (5%).
    address payable public constant engineer =
        payable(0xcfBf34d385EA2d5Eb947063b67eA226dcDA3DC38);

    /// @notice event for funds received.
    event FundsReceived(address indexed source, uint256 amount);

    constructor(address payable _liquidSplit) {
        liquidSplit = _liquidSplit;
    }

    /// @notice receive ETH
    receive() external payable {
        emit FundsReceived(msg.sender, msg.value);
    }

    /// @notice withdraw balance of ETH
    function withdraw() public {
        uint256 balance = address(this).balance;

        coreDevs.transfer(uint256(balance / 4));
        songaDao.transfer(uint256((balance * 9) / 20));
        engineer.transfer(uint256(balance / 20));
        liquidSplit.transfer(address(this).balance);
    }

    /// @notice activate liquid split
    function withdrawLiquidSplit() public {
        ILiquidSplit(liquidSplit).withdraw();
    }
}