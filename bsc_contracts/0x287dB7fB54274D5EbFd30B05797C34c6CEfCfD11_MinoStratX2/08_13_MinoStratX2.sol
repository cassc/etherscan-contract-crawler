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
import "./interfaces/IStrategy.sol";
import "./interfaces/IMinoFarm.sol";

interface IWBNB is IERC20 {
    function deposit() external payable;
}

contract MinoStratX2 is IStrategy, ReentrancyGuard, Ownable, Pausable {
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

    // State for native platform token staking.
    bool public isCAKEStaking;

    // Address of the platform farm.
    address public farmContractAddress;

    // Address of the AMM Pool Router.
    address public uniRouterAddress;

    // Pid of the want in the platform farm.
    uint256 public pid;

    // Address of the LP token.
    address public wantAddress;

    // Address of the earned or native platform token.
    address public earnedAddress;   
    
    // Wrapped BNB.
    address public wbnbAddress;
    
    // Developer address.
    address public devAddress;

    // Address of the profit distribution contract.
    address public distributorAddress;

    // Mino Farm address.
    address public minoFarmAddress;

    // Total shares gathered by users.
    uint256 public override sharesTotal = 0;

    // Optimal path from earned to Mino  
    address[] public earnedToMinoPath;

    // Optimal path from earned to WBNB  
    address[] public earnedToWbnbPath;

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
        address[] memory _addresses,
        uint256 _pid,
        address[] memory _earnedToMinoPath,
        address[] memory _earnedToWbnbPath,
        bool _isCAKEStaking
    ) {
        wbnbAddress = _addresses[0];
        minoFarmAddress = _addresses[1];
        wantAddress = _addresses[2];
        earnedAddress = _addresses[3];
        farmContractAddress = _addresses[4];
        devAddress = _addresses[5];
        uniRouterAddress = _addresses[6];
        minoAddress = _addresses[7];
        pid = _pid;
        earnedToMinoPath = _earnedToMinoPath;
        earnedToWbnbPath = _earnedToWbnbPath;
        isCAKEStaking = _isCAKEStaking;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function deposit(uint256 _wantAmt)
        external
        virtual
        override
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
        _farm();
        _earn();
        sharesTotal = sharesTotal + _wantAmt;
        return _wantAmt;
    }

    function withdraw(uint256 _wantAmt)
        external
        override
        virtual
        onlyFarms
        nonReentrant
        returns (uint256)
    {
        require(_wantAmt > 0, "MinoStratX2::withdraw: Zero _wantAmt");
        if (_wantAmt > sharesTotal) {
            _wantAmt = sharesTotal;
        }
        _unfarm(_wantAmt);

        uint256 wantAmt = IERC20(wantAddress).balanceOf(address(this));
        if (_wantAmt > wantAmt) {
            _wantAmt = wantAmt;
        }

        IERC20(wantAddress).safeTransfer(minoFarmAddress, _wantAmt);
        sharesTotal = sharesTotal - _wantAmt;
        _earn();
        return _wantAmt;
    }

    function earn()
        external
        virtual
        override
        nonReentrant
        whenNotPaused
    {
        _unfarm(0);
        _earn();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setDevAddress(address _devAddress)
        public
        virtual
        onlyGovernance
    {
        require(_devAddress != address(0), "MinoStratX2::set: Zero address");
        devAddress = _devAddress;
        emit SetDevAddress(msg.sender, _devAddress);
    }

    function setDistributorAddress(address _distributorAddress)
        public
        virtual
        onlyGovernance
    {   
        require(_distributorAddress != address(0), "MinoStratX2::set: Zero address");
        distributorAddress = _distributorAddress;
        emit SetDistributorAddress(msg.sender, _distributorAddress);
    }

    function pause() public override onlyGovernance {
        _pause();
    }

    function unpause() public override onlyGovernance {
        _unpause();
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _farm() internal virtual {
        uint256 wantAmt = IERC20(wantAddress).balanceOf(address(this));
        IERC20(wantAddress).safeIncreaseAllowance(farmContractAddress, wantAmt);
        if (isCAKEStaking) {
            IPancakeswapFarm(farmContractAddress).enterStaking(wantAmt);
        } else {
            IPancakeswapFarm(farmContractAddress).deposit(pid, wantAmt);
        }
    }

    function _unfarm(uint256 _wantAmt) internal virtual {
        if (isCAKEStaking) {
            IPancakeswapFarm(farmContractAddress).leaveStaking(_wantAmt);
        } else {
            IPancakeswapFarm(farmContractAddress).withdraw(pid, _wantAmt);
        }
    }

    function _earn() internal {
        uint256 earnedAmt = IERC20(earnedAddress).balanceOf(address(this));
        earnedAmt = IERC20(earnedAddress).balanceOf(address(this));
        _collect();
        _farm();
    }

    function _collect() internal virtual {
        if (earnedAddress == wbnbAddress) {
            _wrapBNB();
        }

        uint256 earnedAmt = IERC20(earnedAddress).balanceOf(address(this));
        if (earnedAmt > 0 && distributorAddress != address(0)) {
            IERC20(earnedAddress).safeIncreaseAllowance(
                uniRouterAddress,
                earnedAmt
            );
            _safeSwap(
                uniRouterAddress,
                earnedAmt,
                earnedToWbnbPath,
                distributorAddress,
                block.timestamp + 60
            );
        }
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

    function _wrapBNB() internal virtual {
        uint256 bnbBal = address(this).balance;
        if (bnbBal > 0) {
            IWBNB(wbnbAddress).deposit{value: bnbBal}();
        }
    }
}