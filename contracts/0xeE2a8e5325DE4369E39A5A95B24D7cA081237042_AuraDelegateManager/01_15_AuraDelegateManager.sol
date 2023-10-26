// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { ERC20Burnable } from "@openzeppelin/token/ERC20/extensions/ERC20Burnable.sol";
import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/access/Ownable.sol";
import { IUniswapV2Router } from "./interfaces/univ2/IUniswapV2Router.sol";
import { IExtraRewardsMultiMerkle } from "./interfaces/paladin/IExtraRewardsMultiMerkle.sol";

import { IBalancerVault } from "./interfaces/balancer/IBalancerVault.sol";
import { IAsset } from "./interfaces/balancer/IAsset.sol";

import { IVlAura } from "./interfaces/aura/IVlAura.sol";

import { IClOracle } from "./interfaces/chainlink/IClOracle.sol";

import "./libraries/Errors.sol";

/// @title AuraDelegateManager
/// @notice Contract handles the locked AURA, rewards claim from Paladin and its processing. PERMISSIONLESS GOLD BABYZZZ
/// ;)
contract AuraDelegateManager is Ownable {
    /*//////////////////////////////////////////////////////////////////////////
                           INTERNAL CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    uint256 internal constant HARVESTER_FEE = 50;
    uint256 internal constant SLIPPAGE = 9750;
    uint256 internal constant BASE = 10_000;

    address internal constant BAL_ETH_BPT = 0x5c6Ee304399DBdB9C8Ef030aB642B10820DB8F56;
    address internal constant BAL = 0xba100000625a3754423978a60c9317c58a424e3D;
    IUniswapV2Router internal constant UNI_V2 = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IERC20 internal constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 internal constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 internal constant AURABAL = IERC20(0x616e8BfA43F920657B3497DBf40D6b1A02D4608d);

    // 0.5 WETH
    uint256 public constant WETH_BUYBACK_THRESHOLD = 0.5 ether;

    // https://docs.aura.finance/developers/deployed-addresses
    IVlAura internal constant AURA_LOCKER = IVlAura(0x3Fa73f1E5d8A792C80F426fc8F84FBF7Ce9bBCAC);

    // https://docs.balancer.fi/reference/contracts/deployment-addresses/mainnet.html#core
    IBalancerVault internal constant BALANCER_VAULT = IBalancerVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    // https://app.balancer.fi/#/ethereum/pool/0x3dd0843a028c86e0b760b1a76929d1c5ef93a2dd000200000000000000000249
    bytes32 internal constant POOL_ID_AURABAL_STABLE =
        0x3dd0843a028c86e0b760b1a76929d1c5ef93a2dd000200000000000000000249;
    // https://app.balancer.fi/#/ethereum/pool/0x5c6ee304399dbdb9c8ef030ab642b10820db8f56000200000000000000000014
    bytes32 internal constant POOL_ID_BAL_ETH = 0x5c6ee304399dbdb9c8ef030ab642b10820db8f56000200000000000000000014;

    // https://doc.paladin.vote/warden-quest/delegating-your-vote#addresses
    address internal constant PALADING_VOTER_ETH = 0x68378fCB3A27D5613aFCfddB590d35a6e751972C;
    IExtraRewardsMultiMerkle internal constant PALADING_REWARDS_MERKLE =
        IExtraRewardsMultiMerkle(0x997523eF97E0b0a5625Ed2C197e61250acF4e5F1);

    uint256 internal constant CL_FEED_ETH_USD_MAX_STALENESS = 1 hours;
    IClOracle internal constant CL_FEED_ETH_USD = IClOracle(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    /*//////////////////////////////////////////////////////////////////////////
                                USER-FACING STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    address public gacToken;

    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    event RewardsClaimed(
        address indexed harvester, address indexed token, uint256 amount, uint256 timestamp, uint256 fee
    );
    event GACBurned(uint256 amount, uint256 timestamp);
    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor() Ownable(msg.sender) {
        // Increase allowance on aurabal for balancer vault
        AURABAL.approve(address(BALANCER_VAULT), type(uint256).max);
        // Approve WETH to uniswap
        WETH.approve(address(UNI_V2), type(uint256).max);
    }

    function initialize(address _gacToken) external onlyOwner {
        gacToken = _gacToken;
        renounceOwnership();
    }

    /// @notice Sets a delegate in the locker (hardcoded to be Paladin)
    function setAuraDelegate() external {
        // Make sure caller is gac token:
        if (msg.sender != gacToken) {
            revert Errors.Unauthorized();
        }
        AURA_LOCKER.delegate(PALADING_VOTER_ETH);
    }

    /// @notice Simply as the name says, keep me safe and locked! :)
    function keepMeLockedBaby() external {
        (, uint256 unlockable,,) = AURA_LOCKER.lockedBalances(address(this));
        if (unlockable > 0) AURA_LOCKER.processExpiredLocks(true);
    }

    /// @notice Process the rewards from vlAURA (AURABAL is received!)
    function processLockerRewards() external {
        AURA_LOCKER.getReward(address(this));

        uint256 aurabalClaimed = AURABAL.balanceOf(address(this));

        // NOTE: Swap AURABAL -> BAL_ETH BPT -> (withdraw) WETH
        if (aurabalClaimed > 0) {
            IBalancerVault.SingleSwap memory singleSwap = IBalancerVault.SingleSwap({
                poolId: POOL_ID_AURABAL_STABLE,
                kind: IBalancerVault.SwapKind.GIVEN_IN,
                assetIn: IAsset(address(AURABAL)),
                assetOut: IAsset(BAL_ETH_BPT),
                amount: aurabalClaimed,
                userData: new bytes(0)
            });

            IBalancerVault.FundManagement memory funds = IBalancerVault.FundManagement({
                sender: address(this),
                fromInternalBalance: false,
                recipient: payable(address(this)),
                toInternalBalance: false
            });

            uint256 balEthBptReceived = BALANCER_VAULT.swap(singleSwap, funds, 0, block.timestamp);

            IAsset[] memory assets = new IAsset[](2);
            assets[0] = IAsset(BAL);
            assets[1] = IAsset(address(WETH));

            IBalancerVault.ExitPoolRequest memory exitPoolRequest = IBalancerVault.ExitPoolRequest({
                assets: assets,
                minAmountsOut: new uint256[](2),
                userData: abi.encode(IBalancerVault.ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, balEthBptReceived, 1),
                toInternalBalance: false
            });

            BALANCER_VAULT.exitPool(POOL_ID_BAL_ETH, address(this), payable(address(this)), exitPoolRequest);
        }
    }

    /// @notice Claims rewards from Paladin using merkle proofs and queue rewards. If you trigger me, i will reward you
    /// ;)
    function claimPaladinAndQueueRewards(
        bool claimFromPaladin,
        IExtraRewardsMultiMerkle.ClaimParams[] calldata claims
    )
        external
    {
        // NOTE: in some ocassion rewards may need to be queue without claiming from Paladin
        if (claimFromPaladin) {
            PALADING_REWARDS_MERKLE.multiClaim(address(this), claims);

            // Sell all additional rewards to WETH
            for (uint256 i; i < claims.length; i++) {
                IERC20 reward_token = IERC20(claims[i].token);
                // Skip if reward token is USDC or WETH
                if (address(reward_token) == address(WETH)) continue;

                uint256 reward_amount = reward_token.balanceOf(address(this));
                // Approve reward token to uniswap, if rewards are 0 skip
                if (reward_amount == 0) continue;
                else if (reward_amount > 0) reward_token.approve(address(UNI_V2), reward_amount);

                uint256 minOut =
                    claims[i].token == address(USDC) ? (_getMinOutUsdcToWeth(reward_amount) * SLIPPAGE) / BASE : 0;

                address[] memory path = new address[](2);
                path[0] = address(reward_token);
                path[1] = address(WETH);
                try UNI_V2.swapExactTokensForTokens(reward_amount, minOut, path, address(this), block.timestamp)
                returns (uint256[] memory amounts) { } catch {
                    // If univ2 pair wasn't found this means tokens are locked forever in this contract
                    continue;
                }
            }
        }

        // use current weth balance
        uint256 wethBal = WETH.balanceOf(address(this));
        bool success;
        // NOTE: avoid extractive harvester agent enforcing `claimFromPaladin = true`
        if (wethBal > 0 && claimFromPaladin) {
            // fee to harvester
            uint256 fee = (wethBal * HARVESTER_FEE) / BASE;
            wethBal -= fee;
            success = WETH.transfer(msg.sender, fee);
            if (!success) revert Errors.TokenTransferFailure();
            emit RewardsClaimed(msg.sender, address(WETH), wethBal, block.timestamp, fee);
        }
    }

    /// @notice call this to buy back and burn GAC tokens through the GAC-WETH pair
    function buyBackAndBurn() external returns (uint256 gacBurned) {
        // Check if there is enough WETH in the contract
        uint256 wethBal = WETH.balanceOf(address(this));
        if (wethBal < WETH_BUYBACK_THRESHOLD) return 0;

        // Swap WETH -> GAC
        address[] memory path = new address[](2);
        path[0] = address(WETH);
        path[1] = gacToken;
        UNI_V2.swapExactTokensForTokens(wethBal, uint256(0), path, address(this), block.timestamp);

        // Burn GAC
        gacBurned = IERC20(gacToken).balanceOf(address(this));
        ERC20Burnable(gacToken).burn(gacBurned);
        emit GACBurned(gacBurned, block.timestamp);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Fetches CL price eth/usd to calculate the min amount expected for swapping
    function _getMinOutUsdcToWeth(uint256 _usdcAmount) internal view returns (uint256 minOut) {
        // NOTE: chainlink oracle (ETH/USD) answers with 8 decimals
        (, int256 answer,, uint256 updatedAt,) = CL_FEED_ETH_USD.latestRoundData();

        if (block.timestamp - updatedAt > CL_FEED_ETH_USD_MAX_STALENESS) {
            revert Errors.StaleChainlinkFeed(block.timestamp, updatedAt);
        }

        uint256 castedAnswer = uint256(answer);

        minOut = (_usdcAmount * 1e20) / castedAnswer;
    }
}