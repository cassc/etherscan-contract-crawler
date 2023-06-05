// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./IGnGPurchase.sol";

contract GnGPurchase is IGnGPurchase, Ownable, Pausable {
    using SafeERC20 for IERC20;

    IERC20 public immutable asto;
    IERC20 public immutable sylo;
    IERC20 public immutable usdc;
    IERC20 public immutable weth;
    IUniswapV2Router02 public immutable uniswapRouter;

    // configurable maximum amount that can be purchased in 1 tx
    uint256 public maxAmountPerTx = 1;

    // goblin default price: 20 USDC
    uint256 public goblinPriceInUSDC = 20e6;

    // used orderIds
    mapping(bytes32 => bool) public purchasedOrders;

    constructor(
        address _asto,
        address _sylo,
        address _usdc,
        address _weth,
        address _uniswapRouter
    ) {
        asto = IERC20(_asto);
        sylo = IERC20(_sylo);
        usdc = IERC20(_usdc);
        weth = IERC20(_weth);
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
    }

    modifier onlyEOA() {
        if (msg.sender != tx.origin) revert InvalidInput("Only EOA is allowed.");
        _;
    }

    modifier validateAmount(uint256 amount) {
        if (amount == 0) revert InvalidInput("Amount cannot be zero.");
        if (amount > maxAmountPerTx) revert InvalidInput("Amount exceeded limit.");
        _;
    }

    modifier validateOrder(bytes32 orderId) {
        if (purchasedOrders[orderId]) revert InvalidInput("orderId already used.");
        _;
    }

    /**
     * @dev Buy `goblinAmount` Goblins with ETH
     * @param orderId The payment order id to match with backend
     * @param goblinAmount The amount of Goblins to buy
     */
    function buyWithETH(bytes32 orderId, uint256 goblinAmount)
        external
        payable
        onlyEOA
        validateOrder(orderId)
        validateAmount(goblinAmount)
        whenNotPaused
    {
        uint256 ethPrice = usdcToWETH(goblinPriceInUSDC * goblinAmount);
        if (msg.value < ethPrice) revert InvalidInput("Payment not enough");

        purchasedOrders[orderId] = true;
        emit PaymentReceived(msg.sender, orderId, goblinAmount, PaymentType.ETH, msg.value);
    }

    /**
     * @dev Buy `goblinAmount` Goblins with USDC token
     * @param orderId The payment order id to match with backend
     * @param goblinAmount The amount of Goblins to buy
     */
    function buyWithUSDC(bytes32 orderId, uint256 goblinAmount)
        external
        onlyEOA
        validateOrder(orderId)
        validateAmount(goblinAmount)
        whenNotPaused
    {
        purchasedOrders[orderId] = true;

        uint256 usdcPrice = goblinPriceInUSDC * goblinAmount;
        usdc.safeTransferFrom(msg.sender, address(this), usdcPrice);

        emit PaymentReceived(msg.sender, orderId, goblinAmount, PaymentType.USDC, usdcPrice);
    }

    /**
     * @dev Buy `goblinAmount` Goblins with ASTO token
     * @param orderId The payment order id to match with backend
     * @param goblinAmount The amount of Goblins to buy
     */
    function buyWithASTO(bytes32 orderId, uint256 goblinAmount)
        external
        onlyEOA
        validateOrder(orderId)
        validateAmount(goblinAmount)
        whenNotPaused
    {
        purchasedOrders[orderId] = true;

        uint256 astoPrice = usdcToASTO(goblinPriceInUSDC * goblinAmount);
        asto.safeTransferFrom(msg.sender, address(this), astoPrice);

        emit PaymentReceived(msg.sender, orderId, goblinAmount, PaymentType.ASTO, astoPrice);
    }

    /**
     * @dev Buy `goblinAmount` Goblins with SYLO token
     * @param orderId The payment order id to match with backend
     * @param goblinAmount The amount of Goblins to buy
     */
    function buyWithSYLO(bytes32 orderId, uint256 goblinAmount)
        external
        whenNotPaused
        onlyEOA
        validateOrder(orderId)
        validateAmount(goblinAmount)
    {
        purchasedOrders[orderId] = true;

        uint256 syloPrice = usdcToSYLO(goblinPriceInUSDC * goblinAmount);
        sylo.safeTransferFrom(msg.sender, address(this), syloPrice);

        emit PaymentReceived(msg.sender, orderId, goblinAmount, PaymentType.SYLO, syloPrice);
    }

    /**
     * @dev Convert to WETH value equivalent to `usdcValue` USDC
     * @param usdcValue The value in USDC to convert
     */
    function usdcToWETH(uint256 usdcValue) public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(usdc);
        path[1] = address(weth);
        uint256[] memory output = uniswapRouter.getAmountsOut(usdcValue, path);
        return output[1];
    }

    /**
     * @dev Convert to ASTO value equivalent to `usdcValue` USDC
     * @param usdcValue The value in USDC to convert
     */
    function usdcToASTO(uint256 usdcValue) public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(usdc);
        path[1] = address(asto);
        uint256[] memory output = uniswapRouter.getAmountsOut(usdcValue, path);
        return output[1];
    }

    /**
     * @dev Convert to SYLO value equivalent to `usdcValue` USDC
     * @param usdcValue The value in USDC to convert
     */
    function usdcToSYLO(uint256 usdcValue) public view returns (uint256) {
        address[] memory path = new address[](3);
        path[0] = address(usdc);
        path[1] = address(weth);
        path[2] = address(sylo);
        uint256[] memory output = uniswapRouter.getAmountsOut(usdcValue, path);
        return output[2];
    }

    /**
     * @dev Update maximum goblin amount that can be purchased in 1 tx
     * @dev This function can only be called from contract owner
     * @param amount The new amount to be updated
     */
    function updateMaxAmount(uint256 amount) external onlyOwner {
        maxAmountPerTx = amount;
        emit MaxAmountUpdated(msg.sender, amount);
    }

    /**
     * @dev Update Goblin price in USDC
     * @dev This function can only be called from contract owner
     * @param priceInUSDC The new Goblin price in USDC to be updated
     */
    function updatePrice(uint256 priceInUSDC) external onlyOwner {
        goblinPriceInUSDC = priceInUSDC;
        emit PriceUpdated(msg.sender, priceInUSDC);
    }

    /**
     * @dev Withdraw all ETH from this contract to the recipient `recipient`
     * @dev This function can only be called from contract owner
     * @param recipient Wallet address of the recipient
     */
    function withdrawETH(address recipient) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(recipient).call{value: balance}("");
        if (!success) revert WithdrawError("Failed to transfer.");
        emit ETHWithdrawn(msg.sender, recipient, balance);
    }

    /**
     * @dev Withdraw all ERC20 token balance to the recipient `recipient`
     * @param recipient  Wallet address of the recipient
     */
    function withdrawERC20(address contractAddress, address recipient) external onlyOwner {
        uint256 amount = IERC20(contractAddress).balanceOf(address(this));
        IERC20(contractAddress).safeTransfer(recipient, amount);
        emit ERC20Withdrawn(msg.sender, recipient, contractAddress, amount);
    }

    /**
     * @dev Pause the contract
     * @dev This function can only be called from contract owner
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause the contract
     * @dev This function can only be called from contract owner
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}