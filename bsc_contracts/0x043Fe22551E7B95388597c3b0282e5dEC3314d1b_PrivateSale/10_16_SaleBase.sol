// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/IUniswapV2Router.sol";
import "../interfaces/ISaleBase.sol";

contract SaleBase is ISaleBase, Ownable {
    using SafeMath for uint256;

    uint256 internal _price;
    mapping(address => address) internal _vestingWallets;

    uint256 internal _startTimestamp;
    uint256 internal _endTimestamp;

    address internal _busdAddress;
    address internal _usdtAddress;
    address internal _vesAddress;
    address internal _pancakeRouterAddress;

    uint256 internal _soldToken;
    uint256 internal _maxSaleToken;

    ITreasury internal _treasury;

    function price() public view virtual override returns (uint256) {
        return _price;
    }

    function vestingWallet(
        address beneficiary
    ) public view virtual override returns (address) {
        return _vestingWallets[beneficiary];
    }

    function startTimestamp() public view virtual override returns (uint256) {
        return _startTimestamp;
    }

    function endTimestamp() public view virtual override returns (uint256) {
        return _endTimestamp;
    }

    function soldToken() public view virtual override returns (uint256) {
        return _soldToken;
    }

    function maxSaleToken() public view virtual override returns (uint256) {
        return _maxSaleToken;
    }

    function busdAddress() public view virtual override returns (address) {
        return _busdAddress;
    }

    function usdtAddress() public view virtual override returns (address) {
        return _usdtAddress;
    }

    function VesAddress() public view virtual override returns (address) {
        return _vesAddress;
    }

    function pancakeRouterAddress()
        public
        view
        virtual
        override
        returns (address)
    {
        return _pancakeRouterAddress;
    }

    function treasury() public view virtual override returns (ITreasury) {
        return _treasury;
    }

    /**
     * Buying
     */
    function buyTokenBNB(
        uint256 minAmountBusd
    ) public payable virtual override {
        _preValidate();
        _validateAmountBnb();

        uint256 amountBusd = _swapBnbToBusd(minAmountBusd);
        _validateAmountUsd(amountBusd);

        uint256 amountVes = amountBusd.mul(1000).div(price());

        _validateAmountToken(amountVes);
        _execute(msg.sender, amountVes);
    }

    function getBusdForBnb(
        uint256 amountBNB
    ) public view virtual override returns (uint256[] memory amounts) {
        IUniswapV2Router02 pancakeRouter = IUniswapV2Router02(
            pancakeRouterAddress()
        );

        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = busdAddress();

        return pancakeRouter.getAmountsOut(amountBNB, path);
    }

    function buyTokenBUSD(uint256 amountBusd) public virtual override {
        _buyTokenErc20(amountBusd, busdAddress());
    }

    function buyTokenUSDT(uint256 amountUsdt) public virtual override {
        _buyTokenErc20(amountUsdt, usdtAddress());
    }

    function _buyTokenErc20(uint256 amountUsd, address tokenAddress) private {
        _preValidate();
        _validateAmountUsd(amountUsd);

        IERC20 token = IERC20(tokenAddress);

        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= amountUsd, "Amount exceeds allowance");

        require(
            token.transferFrom(msg.sender, address(this), amountUsd),
            "Token transfer failed"
        );

        uint256 amountVes = amountUsd.mul(1000).div(price());

        _validateAmountToken(amountVes);
        _execute(msg.sender, amountVes);
    }

    function _swapBnbToBusd(
        uint256 minAmountOut
    ) private returns (uint256 amount) {
        IUniswapV2Router02 pancakeRouter = IUniswapV2Router02(
            pancakeRouterAddress()
        );

        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = busdAddress();

        IERC20 busd = IERC20(busdAddress());
        uint256 balanceBefore = busd.balanceOf(address(this));

        pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: msg.value
        }(minAmountOut, path, address(this), now());

        uint256 balanceAfter = busd.balanceOf(address(this));

        return balanceAfter.sub(balanceBefore);
    }

    function _execute(address beneficiary, uint256 amountVes) private {
        address walletAddress = _getVestingWalletAddress(
            beneficiary,
            amountVes
        );

        _soldToken = _soldToken.add(amountVes);
        emit TokenTransferred(walletAddress, amountVes);
        emit TokenSold(beneficiary, amountVes);

        _treasury.mintToken(walletAddress, amountVes);
    }

    function _getVestingWalletAddress(
        address beneficiary,
        uint256 amountVes
    ) internal virtual returns (address) {
        return address(0x00);
    }

    /**
     * Withdraw
     */
    function withdrawToken(
        address tokenAddress
    ) public virtual override onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        require(
            token.transfer(msg.sender, token.balanceOf(address(this))),
            "token transfer failed"
        );
    }

    /**
     * Validation
     */
    function _preValidate() private view {
        require(now() >= startTimestamp(), "Sale isn't running yet");

        require(now() < endTimestamp(), "Sale was already finished");
    }

    function _validateAmountBnb() private view {
        require(msg.value > 0, "Amount must be greater than 0");
    }

    function _validateAmountUsd(uint256 amountUsd) private view {
        require(amountUsd > 0, "Amount must be greater than 0");
    }

    function _validateAmountToken(uint256 amountToken) internal view {
        require(
            amountToken + _soldToken <= _maxSaleToken,
            "Already reach max amount sale this phase"
        );
    }

    function now() internal view virtual returns (uint256) {
        return block.timestamp;
    }
}