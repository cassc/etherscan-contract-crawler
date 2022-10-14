// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

//import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";
//import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
//import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
//import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
//import "@openzeppelin/contracts-upgradeable/token/ERC777/IERC777SenderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC777/IERC777RecipientUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "./interfaces/ICommunityCoin.sol";
import "./interfaces/ITrustedForwarder.sol";
import "./interfaces/IStructs.sol";

import "./libs/SwapSettingsLib.sol";

//import "hardhat/console.sol";

abstract contract CommunityStakingPoolBase is
    Initializable,
    ContextUpgradeable,
    IERC777RecipientUpgradeable,
    ReentrancyGuardUpgradeable /*, IERC777SenderUpgradeable*/
{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    uint64 public constant FRACTION = 100000;

    //bytes32 private constant TOKENS_SENDER_INTERFACE_HASH = keccak256("ERC777TokensSender");
    bytes32 private constant TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");

    // CommunityCoin address
    address internal stakingProducedBy;

    // if donations does not empty then after staking any tokens will obtain proportionally by donations.address(end user) in donations.amount(ratio)
    IStructs.StructAddrUint256[] donations;

    /**
     * @custom:shortd beneficiary's address which obtain lpFraction of LP tokens
     * @notice beneficiary's address which obtain lpFraction of LP tokens
     */
    address public lpFractionBeneficiary;

    /**
     * @custom:shortd fraction of LP token multiplied by `FRACTION`
     * @notice fraction of LP token multiplied by `FRACTION`
     */
    uint64 public lpFraction;

    /**
     * @custom:shortd rate of rewards that can be used on external tokens like RewardsContract (multiplied by `FRACTION`)
     * @notice rate of rewards calculated by formula amount = amount * rate.
     *   means if rate == 1*FRACTION then amount left as this.
     *   means if rate == 0.5*FRACTION then amount would be in two times less then was  before. and so on
     */
    uint64 public rewardsRateFraction;

    address internal uniswapRouter;
    address internal uniswapRouterFactory;

    IUniswapV2Router02 internal UniswapV2Router02;

    modifier onlyStaking() {
        require(stakingProducedBy == msg.sender);
        _;
    }

    event Redeemed(address indexed account, uint256 amount);
    event Donated(address indexed from, address indexed to, uint256 amount);

    ////////////////////////////////////////////////////////////////////////
    // external section ////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////

    // left when will be implemented
    // function tokensToSend(
    //     address operator,
    //     address from,
    //     address to,
    //     uint256 amount,
    //     bytes calldata userData,
    //     bytes calldata operatorData
    // )   override
    //     virtual
    //     external
    // {
    // }

    /**
     * @notice used to catch when used try to redeem by sending shares directly to contract
     * see more in {IERC777RecipientUpgradeable::tokensReceived}
     */
    function tokensReceived(
        address, /*operator*/
        address from,
        address to,
        uint256 amount,
        bytes calldata, /*userData*/
        bytes calldata /*operatorData*/
    ) external override {}

    /**
     * @notice initialize method. Called once by the factory at time of deployment
     * @param stakingProducedBy_ address of Community Coin token.
     * @param donations_ array of tuples [[address,uint256],...] account, ratio
     * @param lpFraction_ fraction of LP token multiplied by `FRACTION`.
     * @param lpFractionBeneficiary_ beneficiary's address which obtain lpFraction of LP tokens. if address(0) then it would be owner()
     * @custom:shortd initialize method. Called once by the factory at time of deployment
     */
    function CommunityStakingPoolBase_init(
        address stakingProducedBy_,
        IStructs.StructAddrUint256[] memory donations_,
        uint64 lpFraction_,
        address lpFractionBeneficiary_,
        uint64 rewardsRateFraction_
    ) internal onlyInitializing {
        stakingProducedBy = stakingProducedBy_; //it's should ne community coin token
        lpFraction = lpFraction_;
        lpFractionBeneficiary = lpFractionBeneficiary_;
        rewardsRateFraction = rewardsRateFraction_;

        //donations = donations_;
        // UnimplementedFeatureError: Copying of type struct IStructs.StructAddrUint256 memory[] memory to storage not yet supported.

        for (uint256 i = 0; i < donations_.length; i++) {
            donations.push(IStructs.StructAddrUint256({account: donations_[i].account, amount: donations_[i].amount}));
        }

        __ReentrancyGuard_init();

        // setup swap addresses
        (uniswapRouter, uniswapRouterFactory) = SwapSettingsLib.netWorkSettings();
        UniswapV2Router02 = IUniswapV2Router02(uniswapRouter);
    }

    ////////////////////////////////////////////////////////////////////////
    // public section //////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////

    ////////////////////////////////////////////////////////////////////////
    // internal section ////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////

    function doSwapOnUniswap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) internal returns (uint256 amountOut) {
        if (tokenIn == tokenOut) {
            // situation when WETH is a reserve token. 
            // happens when ITR/WETH and user buy liquidity to send ETH directly. System converts ETH to WETH.
            // and if WETH is a reserve token - we get here. no need to convert
            amountOut = amountIn;
        } else {
            require(IERC20Upgradeable(tokenIn).approve(address(uniswapRouter), amountIn), "APPROVE_FAILED");
            address[] memory path = new address[](2);
            path[0] = address(tokenIn);
            path[1] = address(tokenOut);
            // amountOutMin is set to 0, so only do this with pairs that have deep liquidity
            uint256[] memory outputAmounts = UniswapV2Router02.swapExactTokensForTokens(
                amountIn,
                0,
                path,
                address(this),
                block.timestamp
            );
            amountOut = outputAmounts[1];
        }
    }

    /**
     * method will send `fraction_` of `amount_` of token `token_` to address `fractionAddr_`.
     * if `fractionSendOnly_` == false , all that remaining will send to address `to`
     */
    function _fractionAmountSend(
        address token_,
        uint256 amount_,
        uint256 fraction_,
        address fractionAddr_,
        address to_
    ) internal returns (uint256 remainingAfterFractionSend) {
        bool fractionSendOnly_ = (to_ == address(0));
        remainingAfterFractionSend = 0;
        if (fraction_ == FRACTION) {
            IERC20Upgradeable(token_).transfer(fractionAddr_, amount_);
            // if (fractionSendOnly_) {} else {}
        } else if (fraction_ == 0) {
            if (fractionSendOnly_) {
                remainingAfterFractionSend = amount_;
            } else {
                IERC20Upgradeable(token_).transfer(to_, amount_);
            }
        } else {
            uint256 adjusted = (amount_ * fraction_) / FRACTION;
            IERC20Upgradeable(token_).transfer(fractionAddr_, adjusted);
            remainingAfterFractionSend = amount_ - adjusted;

            // custom case: when need to send fractions what left. (fractions that not 0% and not 100%)
            // now not used
            // if (!fractionSendOnly_) {
                // IERC20Upgradeable(token_).transfer(to_, remainingAfterFractionSend);
                // remainingAfterFractionSend = 0;
                //
            // }
        }
    }

    function _stake(
        address addr,
        uint256 amount, //lpAmount
        uint256 priceBeforeStake
    ) internal virtual {
        uint256 left = amount;
        if (donations.length != 0) {
            uint256 tmpAmount;
            for (uint256 i = 0; i < donations.length; i++) {
                tmpAmount = (amount * donations[i].amount) / FRACTION;
                if (tmpAmount > 0) {
                    ICommunityCoin(stakingProducedBy).issueWalletTokens(
                        donations[i].account,
                        tmpAmount,
                        priceBeforeStake
                    );
                    emit Donated(addr, donations[i].account, tmpAmount);
                    left -= tmpAmount;
                }
            }
        }

        ICommunityCoin(stakingProducedBy).issueWalletTokens(addr, left, priceBeforeStake);
    }

    ////////////////////////////////////////////////////////////////////////
    // private section /////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////

    /**
     * @dev implemented EIP-2771
     */
    // function _msgSender() internal view virtual override returns (address signer) {
    //     signer = msg.sender;
    //     if (msg.data.length >= 20 && ITrustedForwarder(stakingProducedBy).isTrustedForwarder(signer)) {
    //         assembly {
    //             signer := shr(96, calldataload(sub(calldatasize(), 20)))
    //         }
    //     }
    // }
}