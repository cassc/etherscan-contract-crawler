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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../pcs/interfaces/IPancakeswapFarm.sol";
import "../pcs/interfaces/IPancakeswapRouter.sol";

interface IWBNB is IERC20 {
    function deposit() external payable;
}

contract MinoStratMino is ReentrancyGuard, Ownable, Pausable {
    using SafeERC20 for IERC20;

    /* ========== CONSTANTS ============= */

    // Maximum buyback rate.
    uint256 public constant BUYBACK_RATE_MAX = 10000;
    
    // Address that buybacks will be sent to.
    address public constant BUYBACK_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    // Maximum slippage factor.
    uint256 public constant SLIPPAGE_FACTOR_MAX = 10000;
    
    // Mino token
    address public immutable minoAddress;

    /* ========== STATE VARIABLES ========== */

    // Address of the AMM Pool Router.
    address public uniRouterAddress;

    // Address of the LP token.
    address public wantAddress; 
    
    // Developer address.
    address public devAddress;

    // Mino Farm address.
    address public minoFarmAddress;

    // Total shares gathered by users.
    uint256 public sharesTotal = 0;

    /* ========== MODIFIERS ========== */

    modifier onlyFarms() {
        require(
            msg.sender == minoFarmAddress,
            "MinoStratX2::onlyFarms: Caller is not a farms"
        );
        _;
    }

    modifier onlyGovernance() {
        require(
            (msg.sender == devAddress || msg.sender == owner()),
            "MinoStratX2::onlyGovernance: Not gov"
        );
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address[] memory _addresses
    ) {
        minoFarmAddress = _addresses[0];
        wantAddress = _addresses[1];
        devAddress = _addresses[2];
        uniRouterAddress = _addresses[3];
        minoAddress = _addresses[4];
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function deposit(uint256 _wantAmt)
        external
        virtual
        onlyFarms
        nonReentrant
        whenNotPaused
        returns (uint256)
    {
        IERC20(wantAddress).safeTransferFrom(
            address(msg.sender),
            address(this),
            _wantAmt
        );
        sharesTotal = sharesTotal + _wantAmt;
        return _wantAmt;
    }

    function withdraw(uint256 _wantAmt)
        external
        virtual
        onlyFarms
        nonReentrant
        returns (uint256)
    {
        require(_wantAmt > 0, "MinoStratX2::withdraw: Zero _wantAmt");
        if (_wantAmt > sharesTotal) {
            _wantAmt = sharesTotal;
        }
        uint256 wantAmt = IERC20(wantAddress).balanceOf(address(this));
        if (_wantAmt > wantAmt) {
            _wantAmt = wantAmt;
        }

        IERC20(wantAddress).safeTransfer(minoFarmAddress, _wantAmt);
        sharesTotal = sharesTotal - _wantAmt;
        return _wantAmt;
    }

    function earn()
        external
        virtual
        nonReentrant
        whenNotPaused
    {}

    /* ========== RESTRICTED FUNCTIONS ========== */

    function pause() public onlyGovernance {
        _pause();
    }

    function unpause() public onlyGovernance {
        _unpause();
    }

    /* ========== UTILITY FUNCTIONS ========== */

    function _safeSwap(
        address _uniRouterAddress,
        uint256 _amountIn,
        address[] memory _path,
        address _to,
        uint256 _deadline
    ) internal virtual returns (uint256) {
        uint256[] memory _amounts = IPancakeRouter02(_uniRouterAddress)
            .swapExactTokensForTokens(
            _amountIn,
            0,
            _path,
            _to,
            _deadline
        );

        return _amounts[_amounts.length - 1];
    }
}