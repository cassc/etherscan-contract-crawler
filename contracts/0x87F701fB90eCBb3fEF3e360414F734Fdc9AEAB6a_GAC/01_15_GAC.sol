// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { ERC20Burnable } from "@openzeppelin/token/ERC20/extensions/ERC20Burnable.sol";
import { ERC20 } from "@openzeppelin/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { IUniswapV2Factory } from "./interfaces/univ2/IUniswapV2Factory.sol";
import { IUniswapV2Router } from "./interfaces/univ2/IUniswapV2Router.sol";
import { IWETH } from "./interfaces/univ2/IWETH.sol";

import { IBalancerVault } from "./interfaces/balancer/IBalancerVault.sol";
import { IAsset } from "./interfaces/balancer/IAsset.sol";

import { IVlAura } from "./interfaces/aura/IVlAura.sol";
import { IAuraDelegateManager } from "./interfaces/aura/IAuraDelegateManager.sol";

import "./libraries/Errors.sol";

/// @title GAC
contract GAC is ERC20Burnable {
    /*//////////////////////////////////////////////////////////////////////////
                           INTERNAL CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    address internal constant SEED_GOD = 0x04aAfdC79925791b5e8562408159DdabACF57a38;

    uint256 public constant FEE_TAKEN = 500;
    uint256 internal constant WANT_BUY = 300;

    uint256 internal constant LP_ALLOC_SELL = 100;
    uint256 internal constant JEET_ALLOC = 100;
    uint256 internal constant LP_ALLOC_BUY = 200;

    uint256 internal constant BASE = 10_000;

    uint256 internal constant TOTAL_SUPPLY = 1_000_000e18;
    uint256 internal constant SWAP_TOKENS_AT_AMOUNT = 500e18;

    // https://docs.uniswap.org/contracts/v2/reference/smart-contracts/router-02
    IUniswapV2Router internal constant UNISWAP_V2_ROUTER = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    // https://docs.balancer.fi/reference/contracts/deployment-addresses/mainnet.html#core
    IBalancerVault internal constant BALANCER_VAULT = IBalancerVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    // https://app.balancer.fi/#/ethereum/pool/0xcfca23ca9ca720b6e98e3eb9b6aa0ffc4a5c08b9000200000000000000000274
    bytes32 internal constant POOL_ID_AURA = 0xcfca23ca9ca720b6e98e3eb9b6aa0ffc4a5c08b9000200000000000000000274;

    address internal constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IWETH internal constant WETH = IWETH(WETH_ADDRESS);
    address internal constant AURA = 0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF;

    // https://docs.aura.finance/developers/deployed-addresses
    IVlAura internal constant AURA_LOCKER = IVlAura(0x3Fa73f1E5d8A792C80F426fc8F84FBF7Ce9bBCAC);

    /*//////////////////////////////////////////////////////////////////////////
                                  PUBLIC CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    address public immutable gacWethPair;
    address public immutable auraDelegate;
    /*//////////////////////////////////////////////////////////////////////////
                                USER-FACING STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    uint256 public jeetRevShare;
    uint256 public lpShare;
    uint256 public wantBuyShare;

    /*//////////////////////////////////////////////////////////////////////////
                                  PRIVATE STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    mapping(address => bool) private _taxExempt;

    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    event ETHReceived(address indexed sender, uint256 value);
    event ExemptFromTax(address indexed account, bool isExcluded);
    event RevShareSent(uint256 amount, uint256 timestamp);
    event LiquidityAdded(uint256 tokenAmount, uint256 ethAmount, uint256 timestamp);
    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(
        address _auraDelegateManager,
        address _earlyDropFirst,
        address _earlyDropSecond
    )
        ERC20("GoldenAuraChad", "GAC")
    {
        if (_auraDelegateManager == address(0)) revert Errors.InvalidAuraDelegateManager();
        auraDelegate = _auraDelegateManager;

        _mint(address(this), TOTAL_SUPPLY);

        // pair univ2 creation
        gacWethPair = IUniswapV2Factory(UNISWAP_V2_ROUTER.factory()).createPair(address(this), WETH_ADDRESS);

        // exempt from taxes
        _exemptFromTax(address(this), true);
        _exemptFromTax(_earlyDropFirst, true);
        _exemptFromTax(_earlyDropSecond, true);

        // transfer tokens atomically to drop's sc (total: 25% of supply)
        _transfer(address(this), _earlyDropFirst, 125_000e18);
        _transfer(address(this), _earlyDropSecond, 125_000e18);

        // approvals
        _approve(address(this), address(UNISWAP_V2_ROUTER), type(uint256).max);
        WETH.approve(address(BALANCER_VAULT), type(uint256).max);
        IERC20(AURA).approve(address(AURA_LOCKER), type(uint256).max);
    }

    /// @dev Receive function accepts ETH.
    receive() external payable {
        emit ETHReceived(msg.sender, msg.value);
    }

    /// @dev Seeds univ2 pair with GAC + WETH. Callable only once.
    function seedGodlyPool() external payable {
        if (msg.sender != SEED_GOD) revert Errors.NotSeeder();
        // seed pool: 75% supply + ETH
        UNISWAP_V2_ROUTER.addLiquidityETH{ value: msg.value }(
            address(this), 750_000e18, 0, 0, address(this), block.timestamp
        );
    }

    /// @param _account The address which will be WL from the tax or remove.
    /// @param _excluded Boolean that determines if the address is WL or not from tax.
    function _exemptFromTax(address _account, bool _excluded) internal {
        _taxExempt[_account] = _excluded;
        emit ExemptFromTax(_account, _excluded);
    }

    function transfer(address _to, uint256 _amount) public override returns (bool) {
        address _from = _msgSender();
        if (_from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (_to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }

        if (_amount == 0) {
            super._transfer(_from, _to, 0);
            return true;
        }

        bool canSwap = balanceOf(address(this)) >= SWAP_TOKENS_AT_AMOUNT;

        if (canSwap && !_taxExempt[_from] && !_taxExempt[_to]) {
            _swap();
        }

        bool feeIsTaken = true;

        if (_taxExempt[_from] || _taxExempt[_to]) {
            feeIsTaken = false;
        }

        if (feeIsTaken) {
            uint256 fees = 0;

            // NOTE: sell flow
            if (_to == gacWethPair) {
                fees = (_amount * FEE_TAKEN) / BASE;
                jeetRevShare += (fees * JEET_ALLOC) / FEE_TAKEN;
                lpShare += (fees * LP_ALLOC_SELL) / FEE_TAKEN;
                wantBuyShare += (fees * WANT_BUY) / FEE_TAKEN;
            }
            // NOTE: buy flow
            if (_from == gacWethPair) {
                fees = (_amount * FEE_TAKEN) / BASE;
                lpShare += (fees * LP_ALLOC_BUY) / FEE_TAKEN;
                wantBuyShare += (fees * WANT_BUY) / FEE_TAKEN;
            }

            if (fees > 0) super._transfer(_from, address(this), fees);

            _amount -= fees;
        }

        super._transfer(_from, _to, _amount);
        return true;
    }

    /// @notice Internal updated swap logic accounting the taxes.
    function _swap() internal {
        uint256 tknBal = balanceOf(address(this));
        uint256 totalTokensToSwap = jeetRevShare + lpShare + wantBuyShare;

        if (tknBal == 0 || totalTokensToSwap == 0) return;

        uint256 tokenForLp = ((tknBal * lpShare) / totalTokensToSwap) / 2;
        uint256 amountToSwapForETH = tknBal - tokenForLp;

        uint256 initialETHBal = address(this).balance;

        _swapTokensForEth(amountToSwapForETH);

        uint256 ethBal = address(this).balance - initialETHBal;

        uint256 ethForBuyBack = (ethBal * wantBuyShare) / (totalTokensToSwap - (lpShare / 2));
        uint256 ethForRevShare = (ethBal * jeetRevShare) / (totalTokensToSwap - (lpShare / 2));

        uint256 ethForLp = ethBal - ethForBuyBack - ethForRevShare;

        jeetRevShare = 0;
        lpShare = 0;
        wantBuyShare = 0;

        if (tokenForLp > 0 && ethForLp > 0) _addLiquidity(tokenForLp, ethForLp);

        if (ethForBuyBack > 0) _auraBuyBackAndLock(ethForBuyBack);

        if (ethForRevShare > 0) {
            WETH.deposit{ value: ethForRevShare }();
            bool success = WETH.transfer(auraDelegate, ethForRevShare);
            if (!success) revert Errors.TokenTransferFailure();
        }
    }

    /// @notice Swaps token [address(this)] -> ETH
    function _swapTokensForEth(uint256 _tokenAmt) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH_ADDRESS;

        UNISWAP_V2_ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _tokenAmt, 0, path, address(this), block.timestamp
        );
    }

    /// @notice Add liquidity in GAC/WETH in behalf of the owner
    function _addLiquidity(uint256 _tokenAmt, uint256 _ethAmt) internal {
        UNISWAP_V2_ROUTER.addLiquidityETH{ value: _ethAmt }(
            address(this), _tokenAmt, 0, 0, address(this), block.timestamp
        );
        emit LiquidityAdded(_tokenAmt, _ethAmt, block.timestamp);
    }

    /// @notice Buy AURA in balancer pool with WETH and lock AURA
    function _auraBuyBackAndLock(uint256 _ethForBuyBack) internal {
        WETH.deposit{ value: _ethForBuyBack }();

        IBalancerVault.SingleSwap memory singleSwap = IBalancerVault.SingleSwap({
            poolId: POOL_ID_AURA,
            kind: IBalancerVault.SwapKind.GIVEN_IN,
            assetIn: IAsset(WETH_ADDRESS),
            assetOut: IAsset(AURA),
            amount: _ethForBuyBack,
            userData: new bytes(0)
        });

        IBalancerVault.FundManagement memory funds = IBalancerVault.FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: payable(address(this)),
            toInternalBalance: false
        });

        BALANCER_VAULT.swap(singleSwap, funds, 0, block.timestamp);

        uint256 auraBalance = IERC20(AURA).balanceOf(address(this));

        // if first buy delegate after lock
        bool _firstBuy;
        (,, uint256 locked,) = AURA_LOCKER.lockedBalances(auraDelegate);
        if (locked == 0) _firstBuy = true;

        if (auraBalance > 0) AURA_LOCKER.lock(auraDelegate, auraBalance);

        if (_firstBuy) IAuraDelegateManager(auraDelegate).setAuraDelegate();
    }
}