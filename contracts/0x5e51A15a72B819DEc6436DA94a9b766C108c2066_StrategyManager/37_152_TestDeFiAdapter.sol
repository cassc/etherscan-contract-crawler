// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { MultiCall } from "../../utils/MultiCall.sol";
import {
    ICurveLiquidityGauge as ICurveGauge
} from "@optyfi/defi-legos/ethereum/curve/contracts/ICurveLiquidityGauge.sol";
import { ICurveZap as ICurveDeposit } from "@optyfi/defi-legos/ethereum/curve/contracts/ICurveZap.sol";
import { ICurveSwap } from "@optyfi/defi-legos/ethereum/curve/contracts/interfacesV0/ICurveSwap.sol";

import "../../1_ethereum/interfaces/IHarvestCodeProvider.sol";

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

import { IAdapter } from "@optyfi/defi-legos/interfaces/defiAdapters/contracts/IAdapter.sol";
import { IAdapterBorrow } from "@optyfi/defi-legos/interfaces/defiAdapters/contracts/IAdapterBorrow.sol";
import "@optyfi/defi-legos/interfaces/defiAdapters/contracts/IAdapterInvestLimit.sol";
import { IAdapterHarvestReward } from "@optyfi/defi-legos/interfaces/defiAdapters/contracts/IAdapterHarvestReward.sol";
import { IAdapterStaking } from "@optyfi/defi-legos/interfaces/defiAdapters/contracts/IAdapterStaking.sol";
import { IAdapterStakingCurve } from "@optyfi/defi-legos/interfaces/defiAdapters/contracts/IAdapterStakingCurve.sol";
import { IAdapterFull } from "@optyfi/defi-legos/interfaces/defiAdapters/contracts/IAdapterFull.sol";

contract TestDeFiAdapter is MultiCall {
    using SafeMath for uint256;

    /** @notice Curve's iron bank swap contract address */
    address public constant Y_SWAP_POOL = address(0x2dded6Da1BF5DBdF597C45fcFaa3194e53EcfeAF);
    address public constant DAI = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    address public constant USDC = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address public constant USDT = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    uint256 public allAmountInTokenStakeWrite;
    uint256 public calculateRedeemableLPTokenAmountStakeWrite;
    uint256 public unclaimedRewardTokenAmountWrite;
    uint256 public underlyingTokenBalance;
    bool public isRedeemableAmountSufficientStakeWrite;

    mapping(address => bool) public yearnCurveStableCoin;

    constructor() public {
        yearnCurveStableCoin[DAI] = true;
        yearnCurveStableCoin[USDC] = true;
        yearnCurveStableCoin[USDT] = true;
    }

    function testGetDepositAllCodes(
        address _underlyingToken,
        address _liquidityPool,
        address _adapter
    ) external {
        executeCodes(
            IAdapterFull(_adapter).getDepositAllCodes(payable(address(this)), _underlyingToken, _liquidityPool),
            "depositAll"
        );
        underlyingTokenBalance = ERC20(_underlyingToken).balanceOf(address(this));
    }

    function testGetDepositSomeCodes(
        address _underlyingToken,
        address _liquidityPool,
        address _adapter,
        uint256 _amount
    ) external {
        executeCodes(
            IAdapterFull(_adapter).getDepositSomeCodes(
                payable(address(this)),
                _underlyingToken,
                _liquidityPool,
                _amount
            ),
            "depositSome"
        );
        underlyingTokenBalance = ERC20(_underlyingToken).balanceOf(address(this));
    }

    function testGetBorrowAllCodes(
        address _liquidityPool,
        address _underlyingToken,
        address _outputToken,
        address _adapter
    ) external {
        executeCodes(
            IAdapterFull(_adapter).getBorrowAllCodes(
                payable(address(this)),
                _underlyingToken,
                _liquidityPool,
                _outputToken
            ),
            "borrowAll"
        );
    }

    function testGetStakeAllCodes(
        address _liquidityPool,
        address _underlyingToken,
        address _adapter
    ) external {
        executeCodes(
            IAdapterFull(_adapter).getStakeAllCodes(payable(address(this)), _underlyingToken, _liquidityPool),
            "stakeAll!"
        );
        underlyingTokenBalance = ERC20(_underlyingToken).balanceOf(address(this));
    }

    function testGetStakeSomeCodes(
        address _liquidityPool,
        uint256 _stakeAmount,
        address _adapter
    ) external {
        executeCodes(IAdapterFull(_adapter).getStakeSomeCodes(_liquidityPool, _stakeAmount), "stakeSome!");
    }

    function testGetAllAmountInTokenStakeWrite(
        address _underlyingToken,
        address _liquidityPool,
        address _liquidityGauge,
        address _rewardToken,
        address _harvestCodeProvider,
        int128 _tokenIndex,
        address _adapter
    ) external {
        uint256 _stakedLpTokenBalance = ERC20(_liquidityGauge).balanceOf(address(this));
        uint256 _amountInToken = 0;
        if (_stakedLpTokenBalance > 0) {
            _amountInToken = _getAmountInToken(_liquidityPool, _underlyingToken, _stakedLpTokenBalance, _tokenIndex);
        }
        uint256 _curveClaimableTokensWrite = ICurveGauge(_liquidityGauge).claimable_tokens(address(this));
        uint256 _amountInTokenHarvest =
            IHarvestCodeProvider(_harvestCodeProvider).rewardBalanceInUnderlyingTokens(
                _rewardToken,
                _underlyingToken,
                _curveClaimableTokensWrite
            );
        uint256 _allAmountInToken = _amountInToken.add(_amountInTokenHarvest);
        allAmountInTokenStakeWrite = IAdapterFull(_adapter).getAllAmountInTokenStakeWrite(
            payable(address(this)),
            _underlyingToken,
            _liquidityPool
        );
        assert(_allAmountInToken == allAmountInTokenStakeWrite);
        underlyingTokenBalance = ERC20(_underlyingToken).balanceOf(address(this));
    }

    function testIsRedeemableAmountSufficientStakeWrite(
        address _underlyingToken,
        address _liquidityPool,
        address _liquidityGauge,
        address _rewardToken,
        address _harvestCodeProvider,
        int128 _tokenIndex,
        address _adapter
    ) external {
        uint256 _stakedLpTokenBalance = ERC20(_liquidityGauge).balanceOf(address(this));
        uint256 _amountInToken = 0;
        if (_stakedLpTokenBalance > 0) {
            _amountInToken = _getAmountInToken(_liquidityPool, _underlyingToken, _stakedLpTokenBalance, _tokenIndex);
        }
        uint256 _curveClaimableTokensWrite = ICurveGauge(_liquidityGauge).claimable_tokens(address(this));
        uint256 _amountInTokenHarvest =
            IHarvestCodeProvider(_harvestCodeProvider).rewardBalanceInUnderlyingTokens(
                _rewardToken,
                _underlyingToken,
                _curveClaimableTokensWrite
            );
        uint256 _allAmountInToken = _amountInToken.add(_amountInTokenHarvest);
        isRedeemableAmountSufficientStakeWrite = IAdapterFull(_adapter).isRedeemableAmountSufficientStakeWrite(
            payable(address(this)),
            _underlyingToken,
            _liquidityPool,
            _allAmountInToken
        );
        assert(isRedeemableAmountSufficientStakeWrite == true);
        uint256 _redeemAmount = _allAmountInToken.mul(2);
        isRedeemableAmountSufficientStakeWrite = IAdapterFull(_adapter).isRedeemableAmountSufficientStakeWrite(
            payable(address(this)),
            _underlyingToken,
            _liquidityPool,
            _redeemAmount
        );
        assert(isRedeemableAmountSufficientStakeWrite == false);
        underlyingTokenBalance = ERC20(_underlyingToken).balanceOf(address(this));
    }

    function testCalculateRedeemableLPTokenAmountStakeWrite(
        address _underlyingToken,
        address _liquidityPool,
        address _liquidityGauge,
        address _rewardToken,
        address _harvestCodeProvider,
        int128 _tokenIndex,
        address _adapter
    ) external {
        uint256 _stakedLpTokenBalance = ERC20(_liquidityGauge).balanceOf(address(this));
        uint256 _amountInToken;
        uint256 _allAmountInToken;
        {
            if (_stakedLpTokenBalance > 0) {
                _amountInToken = _getAmountInToken(
                    _liquidityPool,
                    _underlyingToken,
                    _stakedLpTokenBalance,
                    _tokenIndex
                );
            }
            uint256 _curveClaimableTokensWrite = ICurveGauge(_liquidityGauge).claimable_tokens(address(this));
            uint256 _amountInTokenHarvest =
                IHarvestCodeProvider(_harvestCodeProvider).rewardBalanceInUnderlyingTokens(
                    _rewardToken,
                    _underlyingToken,
                    _curveClaimableTokensWrite
                );

            _allAmountInToken = _amountInToken.add(_amountInTokenHarvest);
        }
        uint256 _redeemAmount = _allAmountInToken.mul(3).div(4);
        uint256 _calculated = _stakedLpTokenBalance.mul(_redeemAmount).div(_allAmountInToken).add(1);
        {
            calculateRedeemableLPTokenAmountStakeWrite = IAdapterFull(_adapter)
                .calculateRedeemableLPTokenAmountStakeWrite(
                payable(address(this)),
                _underlyingToken,
                _liquidityPool,
                _redeemAmount
            );
        }
        assert(_calculated == calculateRedeemableLPTokenAmountStakeWrite);

        underlyingTokenBalance = ERC20(_underlyingToken).balanceOf(address(this));
    }

    function testGetUnclaimedRewardTokenAmountWrite(
        address _liquidityPool,
        address _underlyingToken,
        address _liquidityGauge,
        address _adapter
    ) external {
        uint256 _curveClaimableTokensWrite = ICurveGauge(_liquidityGauge).claimable_tokens(address(this));
        unclaimedRewardTokenAmountWrite = IAdapterFull(_adapter).getUnclaimedRewardTokenAmountWrite(
            payable(address(this)),
            _liquidityPool,
            _underlyingToken
        );
        assert(_curveClaimableTokensWrite == unclaimedRewardTokenAmountWrite);
        underlyingTokenBalance = ERC20(_underlyingToken).balanceOf(address(this));
    }

    function testGetClaimRewardTokenCode(address _liquidityPool, address _adapter) external {
        executeCodes(
            IAdapterFull(_adapter).getClaimRewardTokenCode(payable(address(this)), _liquidityPool),
            "claimReward"
        );
    }

    function testGetHarvestAllCodes(
        address _liquidityPool,
        address _underlyingToken,
        address _adapter
    ) external {
        executeCodes(
            IAdapterFull(_adapter).getHarvestAllCodes(payable(address(this)), _underlyingToken, _liquidityPool),
            "harvestAll"
        );
        underlyingTokenBalance = ERC20(_underlyingToken).balanceOf(address(this));
    }

    function testGetHarvestSomeCodes(
        address _liquidityPool,
        address _underlyingToken,
        address _adapter,
        uint256 _rewardTokenAmount
    ) external {
        executeCodes(
            IAdapterFull(_adapter).getHarvestSomeCodes(
                payable(address(this)),
                _underlyingToken,
                _liquidityPool,
                _rewardTokenAmount
            ),
            "harvestSome"
        );
        underlyingTokenBalance = ERC20(_underlyingToken).balanceOf(address(this));
    }

    function testGetUnstakeAllCodes(address _liquidityPool, address _adapter) external {
        executeCodes(IAdapterFull(_adapter).getUnstakeAllCodes(payable(address(this)), _liquidityPool), "unstakeAll");
    }

    function testGetUnstakeSomeCodes(
        address _liquidityPool,
        uint256 _stakeAmount,
        address _adapter
    ) external {
        executeCodes(IAdapterFull(_adapter).getUnstakeSomeCodes(_liquidityPool, _stakeAmount), "unstakeAll");
    }

    function testGetWithdrawAllCodes(
        address _underlyingToken,
        address _liquidityPool,
        address _adapter
    ) external {
        executeCodes(
            IAdapterFull(_adapter).getWithdrawAllCodes(payable(address(this)), _underlyingToken, _liquidityPool),
            "withdrawAll"
        );
        underlyingTokenBalance = ERC20(_underlyingToken).balanceOf(address(this));
    }

    function testGetWithdrawSomeCodes(
        address _underlyingToken,
        address _liquidityPool,
        address _adapter,
        uint256 _amount
    ) external {
        executeCodes(
            IAdapterFull(_adapter).getWithdrawSomeCodes(
                payable(address(this)),
                _underlyingToken,
                _liquidityPool,
                _amount
            ),
            "withdrawSome"
        );
        underlyingTokenBalance = ERC20(_underlyingToken).balanceOf(address(this));
    }

    function testGetRepayAndWithdrawAllCodes(
        address _liquidityPool,
        address _underlyingToken,
        address _outputToken,
        address _adapter
    ) external {
        executeCodes(
            IAdapterFull(_adapter).getRepayAndWithdrawAllCodes(
                payable(address(this)),
                _underlyingToken,
                _liquidityPool,
                _outputToken
            ),
            "repayAndWithdrawAll"
        );
    }

    function testGetUnstakeAndWithdrawAllCodes(
        address _liquidityPool,
        address _underlyingToken,
        address _adapter
    ) external {
        executeCodes(
            IAdapterFull(_adapter).getUnstakeAndWithdrawAllCodes(
                payable(address(this)),
                _underlyingToken,
                _liquidityPool
            ),
            "unstakeAndWithdrawAll"
        );
        underlyingTokenBalance = ERC20(_underlyingToken).balanceOf(address(this));
    }

    function testGetUnstakeAndWithdrawSomeCodes(
        address _liquidityPool,
        address _underlyingToken,
        uint256 _redeemAmount,
        address _adapter
    ) external {
        executeCodes(
            IAdapterFull(_adapter).getUnstakeAndWithdrawSomeCodes(
                payable(address(this)),
                _underlyingToken,
                _liquidityPool,
                _redeemAmount
            ),
            "unstakeAndWithdrawSome"
        );
        underlyingTokenBalance = ERC20(_underlyingToken).balanceOf(address(this));
    }

    function testGetAddLiquidityCodes(address _underlyingToken, address _adapter) external {
        executeCodes(
            IAdapterFull(_adapter).getAddLiquidityCodes(payable(address(this)), _underlyingToken),
            "addLiquidity"
        );
    }

    function burnBorrowTokens(address _borrowToken) external {
        ERC20(_borrowToken).transfer(
            address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE),
            ERC20(_borrowToken).balanceOf(address(this))
        );
    }

    function _getAmountInToken(
        address _liquidityPool,
        address _underlyingToken,
        uint256 _stakedLpTokenBalance,
        int128 _tokenIndex
    ) internal view returns (uint256) {
        if (yearnCurveStableCoin[_underlyingToken] && _liquidityPool == Y_SWAP_POOL) {
            return ICurveSwap(_liquidityPool).calc_withdraw_one_coin(_stakedLpTokenBalance, _tokenIndex, true);
        } else {
            return ICurveDeposit(_liquidityPool).calc_withdraw_one_coin(_stakedLpTokenBalance, _tokenIndex);
        }
    }
}