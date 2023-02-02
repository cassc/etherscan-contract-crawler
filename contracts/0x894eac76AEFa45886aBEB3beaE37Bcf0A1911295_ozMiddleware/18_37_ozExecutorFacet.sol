// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.14;


import '@rari-capital/solmate/src/utils/FixedPointMathLib.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { IMulCurv } from '../../interfaces/arbitrum/ICurve.sol';
import { ModifiersARB } from '../Modifiers.sol';
import '../../interfaces/arbitrum/ozIExecutorFacet.sol';


/**
 * @title Executor of main system functions
 * @notice In charge of swapping to the account's stablecoin and modifying 
 * state for pegged OZL rebase
 */
contract ozExecutorFacet is ozIExecutorFacet, ModifiersARB { 

    using FixedPointMathLib for uint;

    //@inheritdoc ozIExecutorFacet
    function executeFinalTrade( 
        TradeOps calldata swap_, 
        uint slippage_,
        address user_,
        uint lockNum_
    ) external payable isAuthorized(lockNum_) noReentrancy(3) {
        address pool = swap_.pool;
        int128 tokenIn = swap_.tokenIn;
        int128 tokenOut = swap_.tokenOut;
        address baseToken = swap_.baseToken;
        uint inBalance = IERC20(baseToken).balanceOf(address(this));
        uint minOut;
        uint slippage;

        IERC20(s.USDT).approve(pool, inBalance);

        for (uint i=1; i <= 2; i++) {
            if (pool == s.crv2Pool) {
                
                minOut = IMulCurv(pool).get_dy(
                    tokenIn, tokenOut, inBalance / i
                );
                slippage = calculateSlippage(minOut, slippage_ * i);

                try IMulCurv(pool).exchange(
                    tokenIn, tokenOut, inBalance / i, slippage
                ) {
                    if (i == 2) {
                        try IMulCurv(pool).exchange(
                            tokenIn, tokenOut, inBalance / i, slippage
                        ) {
                            break;
                        } catch {
                            IERC20(baseToken).transfer(user_, inBalance / 2); 
                        }
                    }
                    break;
                } catch {
                    if (i == 1) {
                        continue;
                    } else {
                        IERC20(baseToken).transfer(user_, inBalance); 
                    }
                }
            } else {
                minOut = IMulCurv(pool).get_dy_underlying(
                    tokenIn, tokenOut, inBalance / i
                );
                slippage = calculateSlippage(minOut, slippage_ * i);
                
                try IMulCurv(pool).exchange_underlying(
                    tokenIn, tokenOut, inBalance / i, slippage
                ) {
                    if (i == 2) {
                        try IMulCurv(pool).exchange_underlying(
                            tokenIn, tokenOut, inBalance / i, slippage
                        ) {
                            break;
                        } catch {
                            IERC20(baseToken).transfer(user_, inBalance / 2);
                        }
                    }
                    break;
                } catch {
                    if (i == 1) {
                        continue;
                    } else {
                        IERC20(baseToken).transfer(user_, inBalance); 
                    }
                }
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                    Updates state for OZL calculations
    //////////////////////////////////////////////////////////////*/

    //@inheritdoc ozIExecutorFacet
    function updateExecutorState(
        uint amount_, 
        address user_,
        uint lockNum_
    ) external payable isAuthorized(lockNum_) noReentrancy(2) {
        s.usersPayments[user_] += amount_;
        s.totalVolume += amount_;
        _updateIndex();
    }

    /**
     * @dev Balances the Ozel Index using different invariants and regulators, based 
     *      in the amount of volume have flowed through the system.
     */
    function _updateIndex() private { 
        uint oneETH = 1 ether;

        if (s.ozelIndex < 20 * oneETH && s.ozelIndex != 0) { 
            uint nextInQueueRegulator = s.invariantRegulator * 2; 

            if (nextInQueueRegulator <= s.invariantRegulatorLimit) { 
                s.invariantRegulator = nextInQueueRegulator; 
                s.indexRegulator++; 
            } else {
                s.invariantRegulator /= (s.invariantRegulatorLimit / 2);
                s.indexRegulator = 1; 
                s.indexFlag = s.indexFlag ? false : true;
                s.regulatorCounter++;
            }
        } 

        s.ozelIndex = 
            s.totalVolume != 0 ? 
            oneETH.mulDivDown((s.invariant2 * s.invariantRegulator), s.totalVolume) * (s.invariant * s.invariantRegulator) : 
            0; 

        s.ozelIndex = s.indexFlag ? s.ozelIndex : s.ozelIndex * s.stabilizer;
    }

    //@inheritdoc ozIExecutorFacet
    function modifyPaymentsAndVolumeExternally(
        address user_, 
        uint newAmount_,
        uint lockNum_
    ) external isAuthorized(lockNum_) noReentrancy(5) {
        s.usersPayments[user_] -= newAmount_;
        s.totalVolume -= newAmount_;
        _updateIndex();
    }

    //@inheritdoc ozIExecutorFacet
    function transferUserAllocation( 
        address sender_, 
        address receiver_, 
        uint amount_, 
        uint senderBalance_,
        uint lockNum_
    ) external isAuthorized(lockNum_) noReentrancy(7) { 
        uint percentageToTransfer = (amount_ * 10000) / senderBalance_;
        uint amountToTransfer = percentageToTransfer.mulDivDown(s.usersPayments[sender_] , 10000);

        s.usersPayments[sender_] -= amountToTransfer;
        s.usersPayments[receiver_] += amountToTransfer;
    }

    /*///////////////////////////////////////////////////////////////
                    Updates state for OZL calculations
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Calculates the minimum amount to receive on swaps based on a given slippage
     * @param amount_ Amount of tokens in
     * @param basisPoint_ Slippage in basis point
     * @return minAmountOut Minimum amount to receive
     */
    function calculateSlippage(
        uint amount_, 
        uint basisPoint_
    ) public pure returns(uint minAmountOut) {
        minAmountOut = amount_ - amount_.mulDivDown(basisPoint_, 10000);
    }
}