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
import "./interfaces/ICommunityStakingPool.sol";
import "./interfaces/IPresale.sol";

import "./libs/SwapSettingsLib.sol";

//import "hardhat/console.sol";

contract CommunityStakingPool is Initializable,
    ContextUpgradeable,
    IERC777RecipientUpgradeable,
    /*IERC777SenderUpgradeable, */
    ReentrancyGuardUpgradeable, 
    ICommunityStakingPool
{

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    /**
     * @custom:shortd address of token to be staked
     * @notice address of token that would be staked in the contract
     */
    address public stakingToken;

    uint64 public constant FRACTION = 100000;

    /**
     * @custom:shortd rate of rewards that can be used on external tokens like RewardsContract (multiplied by `FRACTION`)
     * @notice rate of rewards calculated by formula amount = amount * rate.
     *   means if rate == 1*FRACTION then amount left as this.
     *   means if rate == 0.5*FRACTION then amount would be in two times less then was  before. and so on
     */
    uint64 public rewardsRateFraction;

    // CommunityCoin address
    address internal stakingProducedBy;

    // if donations does not empty then after staking any tokens will obtain proportionally by donations.address(end user) in donations.amount(ratio)
    IStructs.StructAddrUint256[] internal donations;

    address internal uniswapRouter;
    address internal uniswapRouterFactory;
    address popularToken;

    IUniswapV2Router02 internal UniswapV2Router02;

    //bytes32 private constant TOKENS_SENDER_INTERFACE_HASH = keccak256("ERC777TokensSender");
    bytes32 private constant TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");

    modifier onlyStaking() {
        require(stakingProducedBy == msg.sender);
        _;
    }

    error Denied();

    event Redeemed(address indexed account, uint256 amount);
    event Donated(address indexed from, address indexed to, uint256 amount);

    ////////////////////////////////////////////////////////////////////////
    // external section ////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////

    /**
     * @notice Special function receive ether
     */
    receive() external payable {
        revert Denied();
    }

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
     * @notice initialize method. Called once by the factory at time of deployment
     * @param stakingProducedBy_ address of Community Coin token.
     * @param stakingToken_ address of token that can be staked
     * @param popularToken_ address of the other token in the main liquidity pool against which stakingToken is traded
     * @param donations_ array of tuples donations. address,uint256. if array empty when coins will obtain sender, overwise donation[i].account  will obtain proportionally by ration donation[i].amount
     * @custom:shortd initialize method. Called once by the factory at time of deployment
     */
    function initialize(
        address stakingProducedBy_,
        address stakingToken_,
        address popularToken_,
        IStructs.StructAddrUint256[] memory donations_,
        uint64 rewardsRateFraction_
    ) external override initializer {
        

        stakingProducedBy = stakingProducedBy_; //it's should ne community coin token
        stakingToken = stakingToken_;
        popularToken = popularToken_;
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
     * @notice way to redeem via approve/transferFrom. Another way is send directly to contract.
     * @param account account address will redeemed from
     * @param amount The number of shares that will be redeemed
     * @custom:calledby staking contract
     * @custom:shortd redeem stakingToken
     */
    function redeem(address account, uint256 amount)
        external
        //override
        onlyStaking
        returns (uint256 amountToRedeem, uint64 rewardsRate)
    {
        amountToRedeem = _redeem(account, amount);
        rewardsRate = rewardsRateFraction;
    }
    ////////////////////////////////////////////////////////////////////////
    // public section //////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////


    function stake(uint256 tokenAmount, address beneficiary) public nonReentrant {
        address account = _msgSender();
        IERC20Upgradeable(stakingToken).transferFrom(account, address(this), tokenAmount);
        _stake(beneficiary, tokenAmount, 0);
    }

    /**
     * @param tokenAddress token that will swap to `stakingToken`
     * @param tokenAmount amount of `tokenAddress` token
     * @param beneficiary wallet which obtain LP tokens
     * @notice method will receive `tokenAmount` of token `tokenAddress` then will swap all to `stakingToken` and finally stake it. Beneficiary will obtain shares
     * @custom:shortd  the way to receive `tokenAmount` of token `tokenAddress` then will swap all to `stakingToken` and finally stake it. Beneficiary will obtain shares
     */
    function buyAndStake(
        address tokenAddress,
        uint256 tokenAmount,
        address beneficiary
    ) public nonReentrant {
        IERC20Upgradeable(tokenAddress).transferFrom(_msgSender(), address(this), tokenAmount);

        address pair = IUniswapV2Factory(uniswapRouterFactory).getPair(stakingToken, tokenAddress);
        require(pair != address(0), "NO_UNISWAP_V2_PAIR");
        //uniswapV2Pair = IUniswapV2Pair(pair);

        uint256 stakingTokenAmount = doSwapOnUniswap(tokenAddress, stakingToken, tokenAmount);
        require(stakingTokenAmount != 0, "NO_TOKENS_RECEIVED_FROM_UNISWAP");
        _stake(beneficiary, stakingTokenAmount, 0);
    }

    /**
     * @param presaleAddress presaleAddress smart contract conducting a presale
     * @param beneficiary who will receive the CommunityCoin tokens
     * @notice method buyInPresaleAndStake
     * @custom:shortd buyInPresaleAndStake
     */
    function buyInPresaleAndStake(
        address presaleAddress,
        address beneficiary
    ) public payable nonReentrant {
        uint256 balanceBefore = IERC20Upgradeable(stakingToken).balanceOf(address(this));
        IPresale(presaleAddress).buy{value: msg.value}(); // should cause the contract to receive tokens
        uint256 balanceAfter = IERC20Upgradeable(stakingToken).balanceOf(address(this));
        uint256 balanceDiff = balanceAfter - balanceBefore;

        require(balanceDiff > 0, "insufficient amount");

        IERC20Upgradeable(stakingToken).transfer(msg.sender, balanceDiff);

        _stake(beneficiary, balanceDiff, 0);
    }

    ////////////////////////////////////////////////////////////////////////
    // internal section ////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    function _redeem(address account, uint256 amount) internal returns (uint256 amountToRedeem) {
        amountToRedeem = __redeem(account, amount);
        IERC20Upgradeable(stakingToken).transfer(account, amountToRedeem);
    }

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
            uint256 indexOut = 1;
            if (
                popularToken == address(0) ||
                (tokenIn == popularToken) ||
                (tokenOut == popularToken)
            ) {
                path[1] = address(tokenOut);
            } else {
                path[1] = popularToken;
                path[2] = address(tokenOut);
                indexOut = 2;
            }
            
            // amountOutMin is set to 0, so only do this with pairs that have deep liquidity
            uint256[] memory outputAmounts = UniswapV2Router02.swapExactTokensForTokens(
                amountIn,
                0,
                path,
                address(this),
                block.timestamp
            );
            amountOut = outputAmounts[indexOut];
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
        uint256 amount,
        uint256 priceBeforeStake
    ) internal virtual {
        uint256 left = amount;
        if (donations.length != 0) {
            uint256 tmpAmount;
            for (uint256 i = 0; i < donations.length; i++) {
                tmpAmount = (amount * donations[i].amount) / FRACTION;
                if (tmpAmount > 0) {

                    IERC20Upgradeable(stakingToken).transfer(donations[i].account, tmpAmount);

                    emit Donated(addr, donations[i].account, tmpAmount);
                    left -= tmpAmount;
                }
            }
        }

        ICommunityCoin(stakingProducedBy).issueWalletTokens(addr, left, priceBeforeStake, amount-left);
    }

    ////////////////////////////////////////////////////////////////////////
    // private section /////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    function __redeem(address sender, uint256 amount) private returns (uint256 amountToRedeem) {
        emit Redeemed(sender, amount);

        // validate free amount to redeem was moved to method _beforeTokenTransfer
        // transfer and burn moved to upper level
        // #dev strange way to point to burn tokens. means need to set lpFraction == 0 and lpFractionBeneficiary should not be address(0) so just setup as `producedBy`
        amountToRedeem = _fractionAmountSend(
            stakingToken,
            amount,
            0, // lpFraction,
            stakingProducedBy, //lpFractionBeneficiary == address(0) ? stakingProducedBy : lpFractionBeneficiary,
            address(0)
        );
    }

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