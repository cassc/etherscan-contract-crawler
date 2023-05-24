// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import './interfaces/IWETH.sol';
import './interfaces/V3/IPancakeV3Factory.sol';
import './interfaces/V3/IPancakeV3Pool.sol';
import './interfaces/V3/ISmartRouter.sol';
import './interfaces/IPCSV2FeeHandler.sol';
import './interfaces/IAggregationRouterV5.sol';
import './interfaces/IStargateRouter.sol';

contract PCSV3FeeHandlerETH is UUPSUpgradeable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct CollectProtocolInfo {
        IPancakeV3Pool pool;
        uint128 token0Amount;
        uint128 token1Amount;
    }

    struct SwapInfo {
        IAggregationExecutor executor;
        IAggregationRouterV5.SwapDescription desc;
        bytes data;
    }

    struct PoolProtocolFee {
        address poolAddress;
        address token0;
        uint256 token0Amt;
        address token1;
        uint256 token1Amt;
    }

    event CollectProtocolFail(address indexed pool, uint128 token0Amount, uint128 token1Amount);
    event SwapFail(address indexed srcToken, address indexed dstToken, uint256 amount);
    event NewPancakeV3Factory(address indexed sender, address indexed factory);
    event NewOperatorAddress(address indexed sender, address indexed operator);
    event NewStargateSwapSlippage(address indexed sender, uint stargateSwapSlippage);
    event UsdcSent(uint256 burn, uint256 treasury, uint256 user);

    // PCSV2FeeHandler address, for simplicity, we read some configurations from `PCSV2FeeHandler`.
    IPCSV2FeeHandler public PCSV2FeeHandler;
    // Consider: @openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol
    address public operatorAddress; // address of the operator

    uint256 constant UNLIMITED_APPROVAL_AMOUNT = type(uint256).max;
    mapping(address => bool) public validDestination;
    IWETH WETH;
    IPancakeV3Factory public PancakeV3Factory;

    IAggregationRouterV5 public constant swapAggregator = IAggregationRouterV5(0x1111111254EEB25477B68fb85Ed929f73A960582);

    // https://docs.pancakeswap.finance/products/pancakeswap-exchange/faq#what-will-be-the-trading-fee-breakdown-for-v3-exchange
    // V3 is different from V2, Fee allocation & amount: Burn, Treasury and User(through airdrop).
    // V3 trading fee breakdown
    struct FeeAllocation {
        uint32 burnRate;
        uint32 treasuryRate;
        uint32 userRate;
    }
    uint256 constant public RATE_DENOMINATOR = 1000000;
    // token => amounts
    mapping(uint24 => FeeAllocation) public feeRate;

    // Amount of tokens
    struct ProtocolFeeAmount {
        uint256 burn;
        uint256 treasury;
        uint256 user;
    }
    // token => amounts
    mapping(address => ProtocolFeeAmount) public feeAmount;
    //---------------------------------------------------------------------
    uint256 public stargateSwapSlippage;

    // following are all constant variables
    uint256 public constant DEFAULT_STARGATE_SWAP_SLIPPAGE = 50; //out of 10000. 50 = 0.5%
    uint256 public constant SLIPPAGE_DENOMINATOR = 10_000;
    // https://stargateprotocol.gitbook.io/stargate/developers/pool-ids
    uint256 internal constant stargateUsdcPoolId = 1;
    uint256 internal constant stargateBusdPoolId = 5;

    // https://etherscan.io/address/0x296F55F8Fb28E498B858d0BcDA06D955B2Cb3f97#code
    uint8 internal constant STARGATE_TYPE_SWAP_REMOTE = 1;

    // https://stargateprotocol.gitbook.io/stargate/developers/chain-ids
    uint16 internal constant stargateBnbChainId = 102; // mainnet
    // uint16 internal constant stargateBnbChainId = 10102; // testnet

    // https://stargateprotocol.gitbook.io/stargate/developers/official-erc20-addresses
    IERC20Upgradeable internal constant ETH_USDC_ADDRESS = IERC20Upgradeable(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48); // mainnet
    // IERC20Upgradeable internal constant ETH_USDC_ADDRESS = IERC20Upgradeable(0xDf0360Ad8C5ccf25095Aa97ee5F2785c8d848620); // testnet

    address internal constant bscPCSFeeHandler = 0x518D9643160cFd6FE469BFBd3BA66fC8035a68a3; // mainnet
    // address internal constant bscPCSFeeHandler = 0x78EbcF30D7e6E2ba82d0bc7921b3f0c6a4c6Fe80; // testnet

    // https://stargateprotocol.gitbook.io/stargate/developers/contract-addresses/mainnet
    IStargateRouter constant public stargateRouter = IStargateRouter(0x8731d54E9D02c286767d56ac03e8037C07e01e98); // mainnet
    // IStargateRouter constant public stargateRouter = IStargateRouter(0x7612aE2a34E5A363E137De748801FB4c86499152); // testnet

    // We need to update 3 storage slots. Strage will use some. 80K should be good enough.
    // SSTORE: "20,000 gas to set a slot from 0 to non-0"
    // gas cost: 80000 * 3 gwei = 0.00024 BNB = 0.072 USD(300 USD/BNB)
    uint256 constant public BSC_EXTRA_CALL_GAS = 80000;
    //---------------------------------------------------------------------

    modifier onlyOwnerOrOperator() {
        require(msg.sender == owner() || msg.sender == operatorAddress, "Not owner/operator");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _pancakeSwapRouter,
        IPancakeV3Factory _PancakeV3Factory,
        address _operatorAddress,
        IPCSV2FeeHandler _PCSV2FeeHandler,
        address[] memory destinations
    )
        external
        initializer
    {
        __Ownable_init();
        __UUPSUpgradeable_init();
        // __ReentrancyGuard_init
        PancakeV3Factory = _PancakeV3Factory;
        operatorAddress = _operatorAddress;
        PCSV2FeeHandler = _PCSV2FeeHandler;
        for (uint256 i = 0; i < destinations.length; ++i)
        {
            validDestination[destinations[i]] = true;
        }
        WETH = IWETH(ISmartRouter(_pancakeSwapRouter).WETH9());
    }

    /**
     * @notice collect fee from PCS V3 pools
     * @dev Callable by owner/operator
     */
    function collectFee(
        CollectProtocolInfo[] calldata poolList,
        bool ignoreError
    )
        external
        onlyOwnerOrOperator
    {
        // collect fee
        for (uint256 i = 0; i < poolList.length; ++i) {
            _collectProtocol(poolList[i], ignoreError);
        }
    }

    /**
     * @notice swap tokens
     * @dev Callable by owner/operator
     */
    function swap(
        SwapInfo[] calldata swapList,
        bool ignoreError
    )
        external
        onlyOwnerOrOperator
    {
        // sell tokens
        for (uint256 i = 0; i < swapList.length; ++i) {
            _swap(swapList[i], ignoreError);
        }
    }

    function _collectProtocol(
        CollectProtocolInfo calldata info,
        bool ignoreError
    )
        internal
    {
        IPancakeV3Pool pool = info.pool;
        IERC20Upgradeable token0 = IERC20Upgradeable(pool.token0());
        IERC20Upgradeable token1 = IERC20Upgradeable(pool.token1());
        uint24 fee = pool.fee();
        uint256 token0AmountBefore = token0.balanceOf(address(this));
        uint256 token1AmountBefore = token1.balanceOf(address(this));
        // ignore return values, as we need to handle tokens with `burn`
        try pool.collectProtocol(address(this), info.token0Amount, info.token1Amount)
        {
            uint256 token0AmountAfter = token0.balanceOf(address(this));
            uint256 token0Amount = token0AmountAfter - token0AmountBefore;
            _distributeFee(address(token0), fee, token0Amount);

            uint256 token1AmountAfter = token1.balanceOf(address(this));
            uint256 token1Amount = token1AmountAfter - token1AmountBefore;
            _distributeFee(address(token1), fee, token1Amount);
        } catch {
            emit CollectProtocolFail(address(pool), info.token0Amount, info.token1Amount);
            require(ignoreError, "collect fee failed");
        }
    }

    function _distributeFee(
        address _token,
        uint24 _fee,
        uint256 _amount
    )
        internal
    {
        FeeAllocation memory rate = feeRate[_fee];
        uint256 userAmount = rate.userRate * _amount / RATE_DENOMINATOR;
        feeAmount[_token].user += userAmount;
        uint256 burnAmount = rate.burnRate * _amount / RATE_DENOMINATOR;
        feeAmount[_token].burn += burnAmount;
        // the rest goes to `treasury`.
        uint256 treasuryAmount = _amount - userAmount - burnAmount;
        feeAmount[_token].treasury += treasuryAmount;
    }

    function _swap(
        SwapInfo calldata swapInfo,
        bool ignoreError
    )
        internal
    {
        require(swapInfo.desc.dstReceiver == address(this), "invalid desc");
        require(validDestination[swapInfo.desc.dstToken], "invalid desc");

        uint256 allowance = IERC20Upgradeable(swapInfo.desc.srcToken).allowance(address(this), address(swapAggregator));
        if (allowance < swapInfo.desc.amount) {
            // can we approve UNLIMITED_APPROVAL_AMOUNT?
            IERC20Upgradeable(swapInfo.desc.srcToken).safeIncreaseAllowance(address(swapAggregator), swapInfo.desc.amount);
        }
        uint256 srcAmountBefore = IERC20Upgradeable(swapInfo.desc.srcToken).balanceOf(address(this));
        uint256 dstAmountBefore = IERC20Upgradeable(swapInfo.desc.dstToken).balanceOf(address(this));
        bytes memory permit = new bytes(0);
        // swap can be `partially successful`
        try swapAggregator.swap(swapInfo.executor, swapInfo.desc, permit, swapInfo.data)
        {
            uint256 srcAmountAfter = IERC20Upgradeable(swapInfo.desc.srcToken).balanceOf(address(this));
            uint256 dstAmountAfter = IERC20Upgradeable(swapInfo.desc.dstToken).balanceOf(address(this));
            // this should never happen, as aggregator already validated this.
            require((dstAmountAfter - dstAmountBefore) >= swapInfo.desc.minReturnAmount, "return not enough");
            ProtocolFeeAmount memory _feeAmount = feeAmount[swapInfo.desc.srcToken];
            // sold srcToken -> dstToken
            _updateFee(swapInfo.desc.srcToken, _feeAmount, srcAmountBefore, srcAmountAfter);
            _updateFee(swapInfo.desc.dstToken, _feeAmount, dstAmountBefore, dstAmountAfter);
        } catch {
            emit SwapFail(swapInfo.desc.srcToken, swapInfo.desc.dstToken, swapInfo.desc.amount);
            require(ignoreError, "swap failed");
        }
        // do we need to clear allowance?
    }

    function _updateFee(
        address _token,
        ProtocolFeeAmount memory _feeAmount,
        uint256 _amountBefore,
        uint256 _amountAfter
    )
        internal
    {
        if (_amountAfter == _amountBefore) {
            return;
        }
        uint256 totalAmount = _feeAmount.user + _feeAmount.burn + _feeAmount.treasury;
        if (totalAmount == 0) {
            // all goes to treasury
            if (_amountAfter > _amountBefore) {
                uint256 diff = _amountAfter - _amountBefore;
                feeAmount[_token].treasury += diff;
            }
            return;
        }
        if (_amountAfter > _amountBefore) {
            uint256 diff = _amountAfter - _amountBefore;
            feeAmount[_token].user += _feeAmount.user * diff / totalAmount;
            feeAmount[_token].burn += _feeAmount.burn * diff / totalAmount;
            feeAmount[_token].treasury += _feeAmount.treasury * diff / totalAmount;
        }
        else {  // (_amountAfter < _amountBefore)
            uint256 diff = _amountBefore - _amountAfter;
            if (diff < totalAmount) {
                feeAmount[_token].user -= _feeAmount.user * diff / totalAmount;
                feeAmount[_token].burn -= _feeAmount.burn * diff / totalAmount;
                feeAmount[_token].treasury -= _feeAmount.treasury * diff / totalAmount;
            }
            else {
                // diff can be larger than total
                feeAmount[_token].user = 0;
                feeAmount[_token].burn = 0;
                feeAmount[_token].treasury = 0;
            }
        }
    }

    /**
     * @notice bridge(cross-chain-sending) token.
     *         This feature is added to ETH PCS fee to BSC network.
     *         It only supports ETH-USDC -> BSC-BUSD bridging.
     * @dev Callable by owner/operator
     */
    function sendEthUsdcToBsc(uint256 amount) external payable onlyOwnerOrOperator {
        uint allowance = ETH_USDC_ADDRESS.allowance(address(this), address(stargateRouter));
        if (allowance < amount) {
            ETH_USDC_ADDRESS.safeApprove(address(stargateRouter), UNLIMITED_APPROVAL_AMOUNT);
        }

        bytes memory data;
        {
            ProtocolFeeAmount memory usdcFee = feeAmount[address(ETH_USDC_ADDRESS)];
            uint usdcBalance = ETH_USDC_ADDRESS.balanceOf(address(this));
            require(usdcBalance >= amount, "not enough USDC");

            uint totalAmount = usdcFee.burn + usdcFee.treasury + usdcFee.user;
            if (totalAmount >= amount) {
                uint burn = amount * usdcFee.burn / totalAmount;
                uint user = amount * usdcFee.user / totalAmount;
                uint treasury = amount - burn - user;
                feeAmount[address(ETH_USDC_ADDRESS)].burn -= burn;
                feeAmount[address(ETH_USDC_ADDRESS)].treasury -= treasury;
                feeAmount[address(ETH_USDC_ADDRESS)].user -= user;
                data = abi.encode(burn, treasury, user);
                emit UsdcSent(burn, treasury, user);
            }
            else {
                uint burn = usdcFee.burn;
                uint user = usdcFee.user;
                uint treasury = amount - burn - user;
                feeAmount[address(ETH_USDC_ADDRESS)].burn = 0;
                feeAmount[address(ETH_USDC_ADDRESS)].treasury = 0;
                feeAmount[address(ETH_USDC_ADDRESS)].user = 0;
                data = abi.encode(burn, treasury, user);
                emit UsdcSent(burn, treasury, user);
            }
        }
        uint256 swapFee;
        (swapFee,) = stargateRouter.quoteLayerZeroFee(
            stargateBnbChainId,
            STARGATE_TYPE_SWAP_REMOTE,
            abi.encodePacked(bscPCSFeeHandler),
            data,
            IStargateRouter.lzTxObj(BSC_EXTRA_CALL_GAS, 0, "0x")
        );


        // do NOT require `msg.value >= swapFee` because we might want to use ETH in this smart contract.
        // require(msg.value >= swapFee, "not enough value");
        // https://stargateprotocol.gitbook.io/stargate/developers/how-to-swap
        // swap ETH-USDC -> BSC-BUSD
        //-------------------------------------------------------------------------------
        require(address(this).balance >= swapFee, "not enough ETH");
        stargateRouter.swap { value : swapFee } (
            stargateBnbChainId,
            stargateUsdcPoolId,
            stargateBusdPoolId,
            payable(address(this)),           // refund adddress. extra gas (if any) is returned to this address
            amount,                           // quantity to swap
            getStargateMinOut(amount),        // the min qty you would accept on the destination
            IStargateRouter.lzTxObj(BSC_EXTRA_CALL_GAS, 0, "0x"),  // 0 additional gasLimit increase, 0 airdrop, at 0x address
            abi.encodePacked(bscPCSFeeHandler),   // the address to send the tokens to on the destination
            data                      // bytes param, if you wish to send additional payload you can abi.encode() them here
        );
    }

    function getStargateMinOut(uint256 _amountIn) internal view returns(uint256) {
        // https://discord.com/channels/903022426856755220/903022427469139970/1072941866196160612
        // "The Stargate will take care of the conversion, so you should use the same number of decimals for both values"
        if (stargateSwapSlippage > 0) {
            return (_amountIn * (SLIPPAGE_DENOMINATOR - stargateSwapSlippage)) / SLIPPAGE_DENOMINATOR;
        }
        else {
            // this saves one multi-sig operation
            return (_amountIn * (SLIPPAGE_DENOMINATOR - DEFAULT_STARGATE_SWAP_SLIPPAGE)) / SLIPPAGE_DENOMINATOR;
        }
    }

    /**
     * @notice Set `stargate swap slipapge`
     * @dev Callable by owner
     */
    function setStargateSwapSlippage(uint _stargateSwapSlippage) external onlyOwner {
        require(_stargateSwapSlippage < SLIPPAGE_DENOMINATOR, "invalid slippage");
        stargateSwapSlippage = _stargateSwapSlippage;
        emit NewStargateSwapSlippage(msg.sender, _stargateSwapSlippage);
    }

    // WIP, team is still working on this.
    /*
    function claimAirdrop(...)
        external
    {
    }

    function sendAirdrop()
        external
        onlyOwnerOrOperator
    {
    }
    */

    /**
     * @notice Set PancakeSwapRouter
     * @dev Callable by owner
     */
    function setPancakeV3Factory(IPancakeV3Factory _PancakeV3Factory) external onlyOwner {
        PancakeV3Factory = _PancakeV3Factory;
        emit NewPancakeV3Factory(msg.sender, address(_PancakeV3Factory));
    }

    /**
     * @notice Set operator address
     * @dev Callable by owner
     */
    function setOperator(address _operatorAddress) external onlyOwner {
        operatorAddress = _operatorAddress;
        emit NewOperatorAddress(msg.sender, _operatorAddress);
    }

    /**
     * @notice Set fee distribution
     * @dev Callable by owner
     */
    function setFeeRate(uint24 _fee, FeeAllocation calldata _feeAllocation) external onlyOwner {
        uint32 total = _feeAllocation.burnRate + _feeAllocation.treasuryRate + _feeAllocation.userRate;
        require(total == RATE_DENOMINATOR, "invalid rate");
        feeRate[_fee] = _feeAllocation;
    }

    /**
     * @notice Withdraw tokens
     * @dev Callable by owner
     */
    function withdraw(address tokenAddr, address payable to, uint256 amount)
        external
        onlyOwner
    {
        _withdraw(tokenAddr, to, amount);
    }

    function _withdraw(address tokenAddr, address to, uint256 amount) internal
    {
        require(to != address(0), "invalid recipient");
        if (amount == 0) {
            return;
        }
        if (tokenAddr == address(0)) {
            uint256 bnbBalance = address(this).balance;
            if (amount > bnbBalance) {
                // BNB/ETH not enough, unwrap WBNB/WETH
                // If WBNB/WETH balance is not enough, `withdraw` will `revert`.
                WETH.withdraw(amount - bnbBalance);
            }
            //slither-disable-next-line arbitrary-send-eth
            (bool success, ) = payable(to).call{ value: amount }("");
            require(success, "call failed");
        }
        else {
            IERC20Upgradeable(tokenAddr).safeTransfer(to, amount);
        }
    }

    /**
     * @notice transfer some BNB/ETH to the operator as gas fee
     * @dev Callable by owner
     */
    function topUpOperator(uint256 amount) external onlyOwner {
        require(amount <= PCSV2FeeHandler.operatorTopUpLimit(), "too much");
        _withdraw(address(0), operatorAddress, amount);
    }

    function addDestination(address addr) external onlyOwner {
        validDestination[addr] = true;
    }

    function removeDestination(address addr) external onlyOwner {
        validDestination[addr] = false;
    }

    function getProtocolFee(
        address[] calldata pool_list
    )
        external
        view
        returns (
            PoolProtocolFee[] memory
        )
    {
        PoolProtocolFee[] memory feeData = new PoolProtocolFee[](pool_list.length);
        for (uint256 i = 0; i < pool_list.length; ++i) {
            IPancakeV3Pool pool = IPancakeV3Pool(pool_list[i]);
            feeData[i].poolAddress = pool_list[i];
            feeData[i].token0 = pool.token0();
            feeData[i].token1 = pool.token1();
            IPancakeV3Pool.ProtocolFees memory protocolFee = pool.protocolFees();
            feeData[i].token0Amt = protocolFee.token0;
            feeData[i].token1Amt = protocolFee.token1;
        }
        return feeData;
    }
    //===========================================================================================================================
    // Since `PancakeV3Factory` is immutable, to process trading fee, this smart contract will be the owner of `PancakeV3Factory`.
    // This smart contract only handles `collectProtocol` and it delegates all others to `PancakeV3Factory`.

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setFactoryOwner(address _owner) external onlyOwner {
        PancakeV3Factory.setOwner(_owner);
    }

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFactoryFeeAmount(uint24 fee, int24 tickSpacing) external onlyOwner {
        PancakeV3Factory.enableFeeAmount(fee, tickSpacing);
    }

    /// @notice Set an address into white list
    /// @dev Address can be updated by owner with boolean value false
    /// @param user The user address that add into white list
    function setFactoryWhiteListAddress(address user, bool verified) external onlyOwner
    {
        PancakeV3Factory.setWhiteListAddress(user, verified);
    }

    /// @notice Set a fee amount extra info
    /// @dev Fee amounts can be updated by owner with extra info
    /// @param whitelistRequested The flag whether should be created by owner only
    /// @param enabled The flag is the fee is enabled or not
    function setFactoryFeeAmountExtraInfo(
        uint24 fee,
        bool whitelistRequested,
        bool enabled
    ) external onlyOwner {
        PancakeV3Factory.setFeeAmountExtraInfo(fee, whitelistRequested, enabled);
    }

    function setFactoryLmPoolDeployer(address _lmPoolDeployer) external onlyOwner {
        PancakeV3Factory.setLmPoolDeployer(_lmPoolDeployer);
    }

    function setFactoryFeeProtocol(address pool, uint32 feeProtocol0, uint32 feeProtocol1) external onlyOwner {
        PancakeV3Factory.setFeeProtocol(pool, feeProtocol0, feeProtocol1);
    }

    function setFactoryLmPool(address pool, address lmPool) external onlyOwner {
        PancakeV3Factory.setLmPool(pool, lmPool);
    }
    //===========================================================================================================================
    receive() external payable {}
    fallback() external payable {}
    function _authorizeUpgrade(address) internal override onlyOwner {}
}