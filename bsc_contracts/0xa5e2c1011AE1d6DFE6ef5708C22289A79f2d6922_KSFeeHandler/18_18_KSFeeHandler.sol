// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

// KSFeeHandler_V3
contract KSFeeHandler is UUPSUpgradeable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct RemoveLiquidityInfo {
        IUniswapV2Pair pair;
        uint256 amount;
        uint256 amountAMin;
        uint256 amountBMin;
    }

    struct SwapInfo {
        uint256 amountIn;
        uint256 amountOutMin;
        address[] path;
    }

    struct LPData {
        address lpAddress;
        address token0;
        uint256 token0Amt;
        address token1;
        uint256 token1Amt;
        uint256 userBalance;
        uint256 totalSupply;
    }

    event SwapFailure(uint256 amountIn, uint256 amountOutMin, address[] path);
    event RmoveLiquidityFailure(
        IUniswapV2Pair pair,
        uint256 amount,
        uint256 amountAMin,
        uint256 amountBMin
    );
    event NewKyotoSwapRouter(address indexed sender, address indexed router);
    event NewOperatorAddress(address indexed sender, address indexed operator);
    event NewKSwapBurnAddress(
        address indexed sender,
        address indexed burnAddress
    );
    event NewKSwapVaultAddress(
        address indexed sender,
        address indexed vaultAddress
    );
    event NewKSwapBurnRate(address indexed sender, uint256 kswapBurnRate);

    address public kswapToken;
    IUniswapV2Router02 public kyotoSwapRouter;
    address public operatorAddress; // address of the operator
    address public kswapBurnAddress;
    address public kswapVaultAddress;
    uint256 public kswapBurnRate; // rate for burn (e.g. 718750 means 71.875%)
    uint256 public constant RATE_DENOMINATOR = 1000000;
    uint256 constant UNLIMITED_APPROVAL_AMOUNT = type(uint256).max;
    mapping(address => bool) public validDestination;
    IWETH WETH;

    // Maximum amount of BNB to top-up operator
    uint256 public operatorTopUpLimit;

    // Copied from: @openzeppelin/contracts/security/ReentrancyGuard.sol
    uint256 private constant _NOT_ENTERED = 0;
    uint256 private constant _ENTERED = 1;

    uint256 private _status;

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }

    modifier onlyOwnerOrOperator() {
        require(
            msg.sender == owner() || msg.sender == operatorAddress,
            "Not owner/operator"
        );
        _;
    }

    function initialize(
        address _kswapToken,
        address _kyotoSwapRouter,
        address _operatorAddress,
        address _kswapBurnAddress,
        address _kswapVaultAddress,
        uint256 _kswapBurnRate,
        address[] memory destinations
    ) external initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        kswapToken = _kswapToken;
        kyotoSwapRouter = IUniswapV2Router02(_kyotoSwapRouter);
        operatorAddress = _operatorAddress;
        kswapBurnAddress = _kswapBurnAddress;
        kswapVaultAddress = _kswapVaultAddress;
        kswapBurnRate = _kswapBurnRate;
        for (uint256 i = 0; i < destinations.length; ++i) {
            validDestination[destinations[i]] = true;
        }
        WETH = IWETH(kyotoSwapRouter.WETH());
        operatorTopUpLimit = 100 ether;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Sell LP token, buy back $KSWAP. The amount can be specified by the caller.
     * @dev Callable by owner/operator
     */
    function processFee(
        RemoveLiquidityInfo[] calldata liquidityList,
        SwapInfo[] calldata swapList,
        bool ignoreError
    ) external onlyOwnerOrOperator {
        for (uint256 i = 0; i < liquidityList.length; ++i) {
            removeLiquidity(liquidityList[i], ignoreError);
        }
        for (uint256 i = 0; i < swapList.length; ++i) {
            swap(
                swapList[i].amountIn,
                swapList[i].amountOutMin,
                swapList[i].path,
                ignoreError
            );
        }
    }

    function removeLiquidity(
        RemoveLiquidityInfo calldata info,
        bool ignoreError
    ) internal {
        uint256 allowance = info.pair.allowance(
            address(this),
            address(kyotoSwapRouter)
        );
        if (allowance < info.amount) {
            IERC20Upgradeable(address(info.pair)).safeApprove(
                address(kyotoSwapRouter),
                UNLIMITED_APPROVAL_AMOUNT
            );
        }
        address token0 = info.pair.token0();
        address token1 = info.pair.token1();
        try
            kyotoSwapRouter.removeLiquidity(
                token0,
                token1,
                info.amount,
                info.amountAMin,
                info.amountBMin,
                address(this),
                block.timestamp
            )
        {
            // do nothing here
        } catch {
            emit RmoveLiquidityFailure(
                info.pair,
                info.amount,
                info.amountAMin,
                info.amountBMin
            );
            require(ignoreError, "remove liquidity failed");
            // if one of the swap fails, we do NOT revert and carry on
        }
    }

    /**
     * @notice Swap tokens for $KSWAP
     */
    function swap(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        bool ignoreError
    ) internal {
        require(path.length > 1, "invalid path");
        require(validDestination[path[path.length - 1]], "invalid path");
        address token = path[0];
        uint256 tokenBalance = IERC20Upgradeable(token).balanceOf(
            address(this)
        );
        amountIn = (amountIn > tokenBalance) ? tokenBalance : amountIn;
        // TODO: need to adjust `token0AmountOutMin` ?
        uint256 allowance = IERC20Upgradeable(token).allowance(
            address(this),
            address(kyotoSwapRouter)
        );
        if (allowance < amountIn) {
            IERC20Upgradeable(token).safeApprove(
                address(kyotoSwapRouter),
                UNLIMITED_APPROVAL_AMOUNT
            );
        }
        try
            kyotoSwapRouter
                .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    amountIn,
                    amountOutMin,
                    path,
                    address(this),
                    block.timestamp
                )
        {
            // do nothing here
        } catch {
            emit SwapFailure(amountIn, amountOutMin, path);
            require(ignoreError, "swap failed");
            // if one of the swap fails, we do NOT revert and carry on
        }
    }

    /**
     * @notice Send $KSWAP tokens to specified wallets(burn and vault)
     * @dev Callable by owner/operator
     */
    function sendKSwap(uint256 amount) external onlyOwnerOrOperator {
        require(amount > 0, "invalid amount");
        uint256 burnAmount = (amount * kswapBurnRate) / RATE_DENOMINATOR;
        // The rest goes to the vault wallet.
        uint256 vaultAmount = amount - burnAmount;
        IERC20Upgradeable(kswapToken).safeTransfer(
            kswapBurnAddress,
            burnAmount
        );
        IERC20Upgradeable(kswapToken).safeTransfer(
            kswapVaultAddress,
            vaultAmount
        );
    }

    /**
     * @notice Deposit ETH for WETH
     * @dev Callable by owner/operator
     */
    function depositETH(uint256 amount) external onlyOwnerOrOperator {
        WETH.deposit{value: amount}();
    }

    /**
     * @notice Set KyotoSwapRouter
     * @dev Callable by owner
     */
    function setKyotoSwapRouter(address _kyotoSwapRouter) external onlyOwner {
        kyotoSwapRouter = IUniswapV2Router02(_kyotoSwapRouter);
        emit NewKyotoSwapRouter(msg.sender, _kyotoSwapRouter);
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
     * @notice Set address for `kswap burn`
     * @dev Callable by owner
     */
    function setKSwapBurnAddress(address _kswapBurnAddress) external onlyOwner {
        kswapBurnAddress = _kswapBurnAddress;
        emit NewKSwapBurnAddress(msg.sender, _kswapBurnAddress);
    }

    /**
     * @notice Set vault address
     * @dev Callable by owner
     */
    function setKSwapVaultAddress(address _kswapVaultAddress)
        external
        onlyOwner
    {
        kswapVaultAddress = _kswapVaultAddress;
        emit NewKSwapVaultAddress(msg.sender, _kswapVaultAddress);
    }

    /**
     * @notice Set percentage of $KSWAP being sent for burn
     * @dev Callable by owner
     */
    function setKSwapBurnRate(uint256 _kswapBurnRate) external onlyOwner {
        require(_kswapBurnRate < RATE_DENOMINATOR, "invalid rate");
        kswapBurnRate = _kswapBurnRate;
        emit NewKSwapBurnRate(msg.sender, _kswapBurnRate);
    }

    /**
     * @notice Withdraw tokens from this smart contract
     * @dev Callable by owner
     */
    function withdraw(
        address tokenAddr,
        address payable to,
        uint256 amount
    ) external nonReentrant onlyOwner {
        require(to != address(0), "invalid recipient");
        if (tokenAddr == address(0)) {
            (bool success, ) = to.call{value: amount}("");
            require(success, "transfer BNB failed");
        } else {
            IERC20Upgradeable(tokenAddr).safeTransfer(to, amount);
        }
    }

    /**
     * @notice transfer some BNB to the operator as gas fee
     * @dev Callable by owner
     */
    function topUpOperator(uint256 amount) external onlyOwner {
        require(amount <= operatorTopUpLimit, "too much");
        uint256 bnbBalance = address(this).balance;
        if (amount > bnbBalance) {
            // BNB not enough, get some BNB from WBNB
            // If WBNB balance is not enough, `withdraw` will `revert`.
            WETH.withdraw(amount - bnbBalance);
        }
        payable(operatorAddress).transfer(amount);
    }

    /**
     * @notice Set top-up limit
     * @dev Callable by owner
     */
    function setOperatorTopUpLimit(uint256 _operatorTopUpLimit)
        external
        onlyOwner
    {
        operatorTopUpLimit = _operatorTopUpLimit;
    }

    function addDestination(address addr) external onlyOwner {
        validDestination[addr] = true;
    }

    function removeDestination(address addr) external onlyOwner {
        validDestination[addr] = false;
    }

    function getPairAddress(
        address factory,
        uint256 cursor,
        uint256 size
    ) external view returns (address[] memory pairs, uint256 nextCursor) {
        IUniswapV2Factory pcsFactory = IUniswapV2Factory(factory);
        uint256 maxLength = pcsFactory.allPairsLength();
        uint256 length = size;
        if (cursor >= maxLength) {
            address[] memory emptyList;
            return (emptyList, maxLength);
        }
        if (length > maxLength - cursor) {
            length = maxLength - cursor;
        }

        address[] memory values = new address[](length);
        for (uint256 i = 0; i < length; ++i) {
            address tempAddr = address(pcsFactory.allPairs(cursor + i));
            values[i] = tempAddr;
        }

        return (values, cursor + length);
    }

    function getPairTokens(address[] calldata lps, address account)
        external
        view
        returns (LPData[] memory)
    {
        LPData[] memory lpListData = new LPData[](lps.length);
        for (uint256 i = 0; i < lps.length; ++i) {
            IUniswapV2Pair pair = IUniswapV2Pair(lps[i]);
            lpListData[i].lpAddress = lps[i];
            lpListData[i].token0 = pair.token0();
            lpListData[i].token1 = pair.token1();
            (lpListData[i].token0Amt, lpListData[i].token1Amt, ) = pair
                .getReserves();
            lpListData[i].userBalance = pair.balanceOf(account);
            lpListData[i].totalSupply = pair.totalSupply();
        }
        return lpListData;
    }

    receive() external payable {}

    fallback() external payable {}

    function _authorizeUpgrade(address) internal override onlyOwner {}
}