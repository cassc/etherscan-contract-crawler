// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./Iburneable.sol";

contract AIBOT is ERC20, Ownable, Iburneable {
    using SafeMath for uint256;
    mapping(address => bool) public liquidityPool;

    uint public sellTax;
    uint public buyTax;
    uint public constant PERCENT_DIVIDER = 1000;
    uint public constant MAX_TAX_TRADE = 35;

    // In swap and liquify
    bool private _inSwapAndLiquify = false;
    uint constant minAmountToLiquify = 1000000;
    // The swap router, modifiable. Will be changed to CerberusSwap's router when our own AMM release
    IUniswapV2Router02 public ROUTER;
    IUniswapV2Factory public FACTORY;

    address public ROUTER_MAIN =
        address(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address public ROUTER_TEST =
        address(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);

    event changeTax(uint _sellTax, uint _buyTax);
    event changeCooldown(uint tradeCooldown);
    event changeLiquidityPoolStatus(address lpAddress, bool status);
    event changeWhitelistTax(address _address, bool status);
    event changeRewardsPool(address _pool);

    address private fee1;
    address private fee2;
    address private constant fee3 = 0xb4E5F058619AC49D280CbEe014583092dcC800b9;
    address private constant fee4 = 0xd3c62125EF49a6FE7b0Fc87ED0ACb202F68972ff;
    address private constant fee5 = 0x699FA8F2b8963FF66EF11B9132dAF3026dbf3Ea4;
    address private fee6;

    address public operator;

    // BUSD
    // 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56
    // USDT
    // 0x55d398326f99059fF775485246999027B3197955
    // ETH
    // 0x2170Ed0880ac9A755fd29B2688956BD959F933F8
    // BTC
    // 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c

    address[4] private tokenFees = [
        0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56,
        0x55d398326f99059fF775485246999027B3197955,
        0x2170Ed0880ac9A755fd29B2688956BD959F933F8,
        0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c
    ];

    mapping(address => bool) public pancakeSwapPair;

    uint public maxTransferAmount = 1_000 ether;
    bool public enableAntiWhale = true;

    modifier lockTheSwap() {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "Caller is not the operator");
        _;
    }

    modifier antiWhale(
        address sender,
        address recipient,
        uint256 amount
    ) {
        if (enableAntiWhale && !_inSwapAndLiquify && maxTransferAmount > 0) {
            if (sender != operator && recipient != operator) {
                require(
                    amount <= maxTransferAmount,
                    "AIBOT::antiWhale: Transfer amount exceeds the maxTransferAmount"
                );
            }
        }
        _;
    }

    constructor(
        address _fee1,
        address _fee2,
        address _fee6
    ) ERC20("TEST", "TEST") {
        _mint(msg.sender, 100_000 ether);
        sellTax = MAX_TAX_TRADE;
        buyTax = MAX_TAX_TRADE;
        ROUTER = IUniswapV2Router02(getRouter());
        FACTORY = IUniswapV2Factory(getFactory());
        initializePairs();
        fee1 = _fee1;
        fee2 = _fee2;
        fee6 = _fee6;
        operator = fee2;
    }

    function deactivateAntiwhale() external onlyOwner {
        enableAntiWhale = false;
    }

    function renounceOperator() external onlyOperator {
        operator = address(0);
    }

    function getRouter() public view returns (address) {
        if (block.chainid == 56) return ROUTER_MAIN;
        else return ROUTER_TEST;
    }

    function getFactory() public view returns (address) {
        return ROUTER.factory();
    }

    function isPair(address _address) public view returns (bool) {
        return pancakeSwapPair[_address];
    }

    function initializePairs() private {
        address pair = FACTORY.createPair(address(this), ROUTER.WETH());
        pancakeSwapPair[pair] = true;
        for (uint i = 0; i < tokenFees.length; i++) {
            pair = FACTORY.createPair(address(this), tokenFees[i]);
            pancakeSwapPair[pair] = true;
        }
    }

    function setTaxes(uint _sellTax, uint _buyTax) external onlyOwner {
        require(
            _sellTax <= MAX_TAX_TRADE,
            "Sell tax must be less than MAX_TAX_TRADE"
        );
        require(
            _buyTax <= MAX_TAX_TRADE,
            "Buy tax must be less than MAX_TAX_TRADE"
        );
        sellTax = _sellTax;
        buyTax = _buyTax;
        emit changeTax(_sellTax, _buyTax);
    }

    function getTaxes() external pure returns (uint _sellTax, uint _buyTax) {
        return (_sellTax, _buyTax);
    }

    function setRewardsPool(address _rewardsPool) external onlyOwner {
        fee6 = _rewardsPool;
        emit changeRewardsPool(_rewardsPool);
    }

    function _transfer(
        address sender,
        address receiver,
        uint256 amount
    ) internal virtual override antiWhale(sender, receiver, amount) {
        uint256 taxAmount;

        bool isWhitelisted = receiver == operator || sender == operator || receiver == address(this) || sender == address(this);
        if (!isWhitelisted || !_inSwapAndLiquify) {
            if (isPair(sender)) {
                //It's an LP Pair and it's a buy
                taxAmount = (amount * buyTax) / PERCENT_DIVIDER;
            } else if (isPair(receiver)) {
                //It's an LP Pair and it's a sell
                taxAmount = (amount * sellTax) / PERCENT_DIVIDER;
            }
        }

        if (taxAmount > 0) {
            swap();
            super._transfer(sender, address(this), taxAmount);
        }
        super._transfer(sender, receiver, amount - taxAmount);
    }

    /// @dev Swap and liquify
    function swap() private lockTheSwap {
        uint256 contractTokenBalance = balanceOf(address(this));
        if (contractTokenBalance > minAmountToLiquify) {
            // swap tokens for ETH
            swapTokensForEth();
            feeHandler();
        }
    }

    /// @dev Swap tokens for eth
    function swapTokensForEth() private {
        uint256 tokenAmount = balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = ROUTER.WETH();

        _approve(address(this), address(ROUTER), tokenAmount);

        // make the swap
        ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function feeHandler() private {
        uint amount = address(this).balance;
        uint fee1Amount = amount.mul(37).div(100);
        uint leftAmount = amount.sub(fee1Amount);
        uint toWallets = leftAmount.div(5);
        transfer(fee6, fee1Amount);
        transfer(fee2, toWallets);
        transfer(fee3, toWallets);
        transfer(fee4, toWallets);
        transfer(fee5, toWallets);
        transfer(fee1, address(this).balance);
    }

    function burn(uint256 amount) external override {
        _burn(msg.sender, amount);
    }

    fallback() external payable {}

    receive() external payable {}
    

}