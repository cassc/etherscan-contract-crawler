// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/*
 _____ _         _____               
|     |_|___ ___|   __|_ _ _ ___ ___ 
| | | | |   | . |__   | | | | .'| . |
|_|_|_|_|_|_|___|_____|_____|__,|  _|
                                |_| 
*
* MIT License
* ===========
*
* Copyright (c) 2022 MinoSwap
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE

*/
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract MinoVault is Ownable {
    using SafeERC20 for IERC20;

    /* ========== CONSTANTS ============= */

    // Mino token
    IERC20 public immutable mino;

    /* ========== STATE VARIABLES ========== */

    address public minoFarm;
    address public minoSupporterFarm;

    // Developer address.
    address public devAddress;

    /* ========== CONSTRUCTOR ========== */

    constructor (
        address _mino,
        address _devAddress
    ) {
        mino = IERC20(_mino);
        devAddress = _devAddress; 
    }

    /* ========== VIEWS ========== */

    /* ========== MUTATIVE FUNCTIONS ========== */

    function minoFarmWithdraw(uint256 amount) external returns (uint256) {
        require(msg.sender == minoFarm, "MinoVault::minoFarmWithdraw: !minoFarm");
        return safeTokenTransfer(msg.sender, amount);
    }

    function minoSupporterWithdraw(uint256 amount) external returns (uint256) {
        require(msg.sender == minoSupporterFarm, "MinoVault::minoSupporterWithdraw: !minoSupporterFarm");
        return safeTokenTransfer(msg.sender, amount);
    }

    // @todo modifier
    function setMinoFarm(address _minoFarm) external onlyOwner {
        minoFarm = _minoFarm;
    }

    function setMinoSupporterFarm(address _minoSupporterFarm) external onlyOwner {
        minoSupporterFarm = _minoSupporterFarm;
    }

    /* ========== UTILITY FUNCTIONS ========== */

    function safeTokenTransfer(address _to, uint256 _amount)
        internal
        returns (uint256)
    {
        uint256 balance = mino.balanceOf(address(this));
        if (_amount > balance) {
            _amount = balance;
        }

        require(
            mino.transfer(_to, _amount),
            "MinoVault::safeTokenTransfer: Transfer failed"
        );
        return _amount;
    }

}