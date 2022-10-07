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
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IMinoDistributor.sol";
import "../../pcs/interfaces/IPancakeswapRouter.sol";
import "../../libraries/Math.sol";

contract MinoDistributor is Ownable {
    using SafeERC20 for IERC20;

    struct FarmedToken {
        IERC20 token;
        address[] pathToCnc;
        address[] pathToMino;
        bool enabled;
    }

    struct DistributeeInfo {
        address distributeeAddress;
        IERC20 token;
        uint256 share;
        uint256 accReward;
    }

    /* ========== CONSTANTS ============= */

    // Mino token.
    IERC20 public immutable mino;

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    // Maximum slippage for swaps
    uint256 public constant SLIPPAGE_FACTOR_MAX = 10000;

    // Maximum fees distribution
    uint256 public constant TOTAL_FEE_MAX = 10000;

    /* ========== STATE VARIABLES ========== */

    // Address of the AMM Pool Router.
    address public uniRouterAddress;

    uint256 public devShare;

    address public devAddress;

    uint256 public harvestShare;

    // Slippage factor for swaps
    uint256 public slippageFactor;

    uint256 public burnShare;

    uint256 public minoStakingShare;

    FarmedToken[] public farmedTokens;

    /**
    * 0 - CNC Pool
    * 1 - Mino Supporter Pool
    * 2 - Mino Staking Pool
    * 3 - NFT Staking Pool
    * 4 - Booster Pool
    */
    DistributeeInfo[5] public distributees;

    /* ========== CONSTRUCTOR ========== */

    constructor (
        address _mino,
        address _uniRouterAddress,
        address[] memory _addresses,
        uint256[] memory _shares,
        address[] memory _tokenAddresses,
        address _devAddress,
        uint256 _devShare,
        uint256 _harvestShare,
        uint256 _burnShare,
        uint256 _slippageFactor
    ) {
        mino = IERC20(_mino);
        uniRouterAddress = _uniRouterAddress;
        require(_addresses.length == 5 && _shares.length == 5 && _tokenAddresses.length == 5);

        for (uint256 i = 0; i < _addresses.length; i++) {
            distributees[i] = DistributeeInfo({
                distributeeAddress: _addresses[i],
                token: IERC20(_tokenAddresses[i]),
                share: _shares[i],
                accReward: 0
            });
        }
        devAddress = _devAddress;
        devShare = _devShare;
        harvestShare = _harvestShare;
        burnShare = _burnShare;
        slippageFactor = _slippageFactor;
    }

    /* ========== VIEWS ========== */

    /* ========== MUTATIVE FUNCTIONS ========== */

    function harvest() external {
        for (uint256 i = 0; i < farmedTokens.length; i++) {
            if (farmedTokens[i].enabled) {
                uint256 balance = farmedTokens[i].token.balanceOf(address(this));

                // Handle cnc
                distributees[0].accReward += _safeSwap(
                    uniRouterAddress,
                    balance * distributees[0].share / TOTAL_FEE_MAX,
                    slippageFactor,
                    farmedTokens[i].pathToCnc,
                    address(this),
                    block.timestamp + 60
                );
                
                // Handle supporter
                distributees[1].accReward += _safeSwap(
                    uniRouterAddress,
                    balance * distributees[1].share / TOTAL_FEE_MAX,
                    slippageFactor,
                    farmedTokens[i].pathToMino,
                    address(this),
                    block.timestamp + 60
                );

                farmedTokens[i].token.safeTransfer(devAddress, balance * devShare / TOTAL_FEE_MAX);

                if (msg.sender != distributees[1].distributeeAddress) {
                    farmedTokens[i].token.safeTransfer(msg.sender, balance * harvestShare / TOTAL_FEE_MAX);
                }

                _safeSwap(
                    uniRouterAddress,
                    farmedTokens[i].token.balanceOf(address(this)),
                    slippageFactor,
                    farmedTokens[i].pathToMino,
                    address(this),
                    block.timestamp + 60
                );
            }
        }
        // @todo Check mino balance for supporter
        uint256 _mino = mino.balanceOf(address(this));

        mino.safeTransfer(BURN_ADDRESS, _mino * burnShare / TOTAL_FEE_MAX);
        distributees[2].accReward += _mino * distributees[2].share / TOTAL_FEE_MAX;
        distributees[3].accReward += _mino * distributees[3].share / TOTAL_FEE_MAX;
        distributees[4].accReward += _mino * distributees[4].share / TOTAL_FEE_MAX;
        
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function addFarmToken(
        address _token,
        address[] calldata _pathToCnc,
        address[] calldata _pathToMino
    ) external onlyOwner {
        farmedTokens.push(FarmedToken({
            token: IERC20(_token),
            pathToCnc: _pathToCnc,
            pathToMino: _pathToMino,
            enabled: true
        }));
    }

    function removeFarmedToken(uint256 _pid) external onlyOwner {
        farmedTokens[_pid].enabled = false;
    }

    function withdrawReward(uint256 _pid) external returns (uint256 _reward) {
        require(msg.sender == distributees[_pid].distributeeAddress);
        distributees[_pid].token.safeTransfer(distributees[_pid].distributeeAddress, distributees[_pid].accReward);
        _reward = distributees[_pid].accReward;
        distributees[_pid].accReward = 0;
    }


    // function withdrawStakingReward() external returns (uint256 _stakingReward) {
    //     require(msg.sender == minoStakingAddress, "MinoDistributor::withdrawStakingReward: !minoStaking");
    //     mino.safeTransfer(minoStakingAddress, minoStakingReward);
    //     _stakingReward = minoStakingReward;
    //     minoStakingReward = 0;
    // }

    // function withdrawSupporterReward() external returns (uint256 _minoSupporterReward) {
    //     require(msg.sender == minoSupporterAddress, "MinoDistributor::withdrawSupporterReward: !minoSupporter");
    //     mino.safeTransfer(minoSupporterAddress, minoSupporterReward);
    //     _minoSupporterReward = minoSupporterReward;
    //     minoSupporterReward = 0;
    // }

    // function withdrawGovReward() external returns (uint256 _govReward) {
    //     require(msg.sender == govAddress, "MinoDistributor::withdrawGovReward: !govAddress");
    //     cnc.safeTransfer(govAddress, govReward);
    //     _govReward = govReward;
    //     govReward = 0;
    // }

    function updateSlippageFactor(uint256 _slippageFactor) external onlyOwner {
        require(_slippageFactor <= SLIPPAGE_FACTOR_MAX, "MinoDistributor::updateSlippageFactor: Slippage > max");
        slippageFactor = _slippageFactor;
    } 

    /* ========== UTILITY FUNCTIONS ========== */

    function _safeSwap(
        address _uniRouterAddress,
        uint256 _amountIn,
        uint256 _slippageFactor,
        address[] memory _path,
        address _to,
        uint256 _deadline
    ) internal returns (uint256) {
        uint256 amountOut;
        try IPancakeRouter02(_uniRouterAddress)
            .getAmountsOut(_amountIn, _path) 
            returns (uint256[] memory amounts) {
            amountOut = amounts[amounts.length - 1];
            if (amountOut == 0) return 0;
        } catch {
            return 0;
        }

        IERC20(_path[0]).safeIncreaseAllowance(_uniRouterAddress, _amountIn);

        uint256[] memory _amounts = IPancakeRouter02(_uniRouterAddress)
            .swapExactTokensForTokens(
            _amountIn,
            amountOut * _slippageFactor / SLIPPAGE_FACTOR_MAX,
            _path,
            _to,
            _deadline
        );

        return _amounts[_amounts.length - 1];
    }
}