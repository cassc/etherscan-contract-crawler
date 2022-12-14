// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

import "./Exchange.sol";
import "./interfaces/IPoolSwapCallback.sol";
import "./interfaces/IPoolFunctionality.sol";
import "./libs/LibPool.sol";
import "./interfaces/IERC20.sol";
import "./utils/fromOZ/SafeERC20.sol";

contract ExchangeWithOrionPool is Exchange, IPoolSwapCallback {

    using SafeERC20 for IERC20;

    address public _orionpoolRouter;
    mapping (address => bool) orionpoolAllowances;

    address public WETH;

    modifier initialized {
        require(address(_orionToken)!=address(0), "E16I");
        require(_oracleAddress!=address(0), "E16I");
        require(_allowedMatcher!=address(0), "E16I");
        require(_orionpoolRouter!=address(0), "E16I");
        _;
    }

    /**
     * @dev set basic Exchange params
     * @param orionToken - base token address
     * @param priceOracleAddress - adress of PriceOracle contract
     * @param allowedMatcher - address which has authorization to match orders
     * @param orionpoolRouter - OrionPool Functionality contract address for changes through orionpool
     */
    function setBasicParams(
        address orionToken,
        address priceOracleAddress,
        address allowedMatcher,
        address orionpoolRouter
    ) public onlyOwner {
        _orionToken = IERC20(orionToken);
        _oracleAddress = priceOracleAddress;
        _allowedMatcher = allowedMatcher;
        _orionpoolRouter = orionpoolRouter;
        WETH = IPoolFunctionality(_orionpoolRouter).getWETH();
    }

    //Important catch-all a function that should only accept ethereum and don't allow do something with it
    //We accept ETH there only from out router or wrapped ethereum contract.
    //If router sends some ETH to us - it's just swap completed, and we don't need to do something
    receive() external payable {
        require(msg.sender == _orionpoolRouter || msg.sender == WETH, "NPF");
    }

    function safeAutoTransferFrom(address token, address from, address to, uint value) override external {
        require(msg.sender == _orionpoolRouter, "Only _orionpoolRouter allowed");
        SafeTransferHelper.safeAutoTransferFrom(WETH, token, from, to, value);
    }

    /**
     * @notice (partially) settle buy order with OrionPool as counterparty
     * @dev order and orionpool path are submitted, it is necessary to match them:
        check conditions in order for compliance filledPrice and filledAmount
        change tokens via OrionPool
        check that final price after exchange not worse than specified in order
        change balances on the contract respectively
     * @param order structure of buy side orderbuyOrderHash
     * @param filledAmount amount of purchaseable token
     * @param path array of assets addresses (each consequent asset pair is change pair)
     */
    function fillThroughOrionPool(
        LibValidator.Order memory order,
        uint112 filledAmount,
        uint64 blockchainFee,
        address[] calldata path
    ) public nonReentrant {
        LibPool.OrderExecutionData memory d;
        d.order = order;
        d.filledAmount = filledAmount;
        d.blockchainFee = blockchainFee;
        d.path = path;
        d.allowedMatcher = _allowedMatcher;
        d.orionpoolRouter = _orionpoolRouter;

        LibPool.doFillThroughOrionPool(
            d,
            assetBalances,
            liabilities,
            filledAmounts
        );
        require(checkPosition(order.senderAddress), order.buySide == 0 ? "E1PS" : "E1PB");
    }

    function swapThroughOrionPool(
        uint112     amount_spend,
        uint112     amount_receive,
        address[]   calldata path,
        bool        is_exact_spend
    ) public payable nonReentrant {
        bool isCheckPosition = LibPool.doSwapThroughOrionPool(
            IPoolFunctionality.SwapData({
                amount_spend: amount_spend,
                amount_receive: amount_receive,
                is_exact_spend: is_exact_spend,
                supportingFee: false,
                path: path,
                orionpool_router: _orionpoolRouter,
                isInContractTrade: false,
                isSentETHEnough: false,
                isFromWallet: false,
                asset_spend: address(0)
            }),
            assetBalances, liabilities);
        if (isCheckPosition) {
            require(checkPosition(msg.sender), "E1PS");
        }
    }

    function swapThroughOrionPoolSupportingFee(
        uint112     amount_spend,
        uint112     amount_receive,
        address[]   calldata path
    ) public payable nonReentrant {
        bool isCheckPosition = LibPool.doSwapThroughOrionPool(
            IPoolFunctionality.SwapData({
                amount_spend: amount_spend,
                amount_receive: amount_receive,
                is_exact_spend: true,
                supportingFee: true,
                path: path,
                orionpool_router: _orionpoolRouter,
                isInContractTrade: false,
                isSentETHEnough: false,
                isFromWallet: false,
                asset_spend: address(0)
            }),
            assetBalances, liabilities);
        if (isCheckPosition) {
            require(checkPosition(msg.sender), "E1PS");
        }
    }

    /**
     * @notice ZERO_ADDRESS can only be used for asset A - not for asset B
     * @dev adds Liquidity to the Orion Pool from User's deposits
     * @param assetA address of token A or Eth
     * @param asseBNotETH address of token B. Cannot be Eth
     * @param amountADesired The amount of tokenA to add as liquidity if the B/A price is <= amountBDesired/amountADesired (A depreciates).
     * @param amountBDesired The amount of tokenB to add as liquidity if the A/B price is <= amountADesired/amountBDesired (B depreciates).
     * @param amountAMin Bounds the extent to which the B/A price can go up before the transaction reverts. Must be <= amountADesired.
     * @param amountBMin Bounds the extent to which the A/B price can go up before the transaction reverts. Must be <= amountBDesired.
     */
    function withdrawToPool(
        address assetA,
        address asseBNotETH,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) external payable{
        (uint amountA, uint amountB) = LibPool.doWithdrawToPool(assetA, asseBNotETH, amountADesired, amountBDesired,
            amountAMin, amountBMin, assetBalances, liabilities, _orionpoolRouter);

        require(checkPosition(msg.sender), "E1w2");

        emit NewAssetTransaction(
            msg.sender,
            assetA,
            false,
            uint112(amountA),
            uint64(block.timestamp)
        );

        emit NewAssetTransaction(
            msg.sender,
            asseBNotETH,
            false,
            uint112(amountB),
            uint64(block.timestamp)
        );
    }
}