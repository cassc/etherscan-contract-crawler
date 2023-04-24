// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import './IUniswapV2Router02.sol';
import './IUniswapV2Pair.sol';

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

contract FeetCoin is ERC20, Ownable {

    using SafeERC20 for IERC20;
    using Address for address payable;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    uint256 public maxTxAmount;
    uint256 public maxWallet;

    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isTxLimitExempt;
    mapping(address => bool) public isWalletLimitExempt;
    mapping(address => bool) blacklisted;

    uint256 private totalFee;
    uint256 public feeDenominator = 10000;

    // Buy Fees
    uint256 public totalFeeBuy = 0;

    // Sell Fees
    uint256 public totalFeeSell = 1000;

    uint256 public launchedAt;
    uint256 public launchedAtTimestamp;
    bool private initialized;

    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address private constant ZERO = 0x0000000000000000000000000000000000000000;
    address public PEPE = 0x6982508145454Ce325dDbE47a25d4ec3d2311933;


    constructor() ERC20("FeetCoin", "FEET") {

         IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), PEPE);


        uint256 _totalSupply = 1_000_000_000_000 * 1e18;
        maxTxAmount = (_totalSupply * 2) / 100; //2%
        maxWallet = (_totalSupply * 2) / 100; //2%

        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;
        isWalletLimitExempt[msg.sender] = true;

        isFeeExempt[address(this)] = true;
        isTxLimitExempt[address(this)] = true;
        isWalletLimitExempt[address(this)] = true;

        isFeeExempt[uniswapV2Pair] = true;
        isTxLimitExempt[uniswapV2Pair] = true;
        isWalletLimitExempt[uniswapV2Pair] = true;

        _mint(_msgSender(), _totalSupply);
    }


    receive() external payable {}

    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        return _feetTransfer(_msgSender(), to, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(sender, spender, amount);
        return _feetTransfer(sender, recipient, amount);
    }

    function _feetTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        require(!blacklisted[sender],"Sender blacklisted");
        require(!blacklisted[recipient],"Receiver blacklisted");


        checkWalletLimit(recipient, amount);
        checkTxLimit(sender, amount);

        // Set Fees
        if (sender == uniswapV2Pair) {
            buyFees();
        }
        if (recipient == uniswapV2Pair) {
            sellFees();
        }
   
        uint256 amountReceived = shouldTakeFee(sender)
            ? burnFee(sender, amount)
            : amount;
        _transfer(sender, recipient, amountReceived);
        return true;
    }

    function buyFees() internal {
        totalFee = totalFeeBuy;
    }

    function sellFees() internal {
        totalFee = totalFeeSell;
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function burnFee(
        address sender,
        uint256 amount
    ) internal returns (uint256) {
        uint256 feeAmount = (amount * totalFee) / feeDenominator;
        _burn(sender, feeAmount);
        return amount - feeAmount;
    }

   
    function checkWalletLimit(address recipient, uint256 amount) internal view {
        if (
            recipient != owner() &&
            recipient != address(this) &&
            recipient != address(DEAD) &&
            recipient != uniswapV2Pair
        ) {
            uint256 heldTokens = balanceOf(recipient);
            require(
                (heldTokens + amount) <= maxWallet || isWalletLimitExempt[recipient],
                "Total Holding is currently limited, you can not buy that much."
            );
        }
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(
            amount <= maxTxAmount || isTxLimitExempt[sender],
            "TX Limit Exceeded"
        );
    }

    // Stuck Balances Functions
    function rescueToken(address tokenAddress) external onlyOwner {
        IERC20(tokenAddress).safeTransfer(
            msg.sender,
            IERC20(tokenAddress).balanceOf(address(this))
        );
    }

    function clearStuckBalance() external onlyOwner {
        uint256 amountETH = address(this).balance;
        payable(_msgSender()).sendValue(amountETH);
    }

    function getCirculatingSupply() public view returns (uint256) {
        return totalSupply() - balanceOf(DEAD) - balanceOf(ZERO);
    }

    function setBuyFees(
        uint256 _buyFee
    ) external onlyOwner {
        totalFeeBuy =_buyFee;
    }

    function setSellFees(
        uint256 _sellFee
    ) external onlyOwner {
        totalFeeSell = _sellFee;
    }

    function setMaxWallet(uint256 amount) external onlyOwner {
        maxWallet = amount;
    }

    function setTxLimit(uint256 amount) external onlyOwner {
        maxTxAmount = amount;
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(
        address holder,
        bool exempt
    ) public onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    function setIsWalletLimitExempt(
        address holder,
        bool exempt
    ) external onlyOwner {
        isWalletLimitExempt[holder] = exempt;
    }

    function blacklist(address _black) public onlyOwner {
        blacklisted[_black] = true;
    }

    function unblacklist(address _black) public onlyOwner {
        blacklisted[_black] = false;
    }

    function isBlacklisted(address account) public view returns (bool) {
        return blacklisted[account];
    }
}