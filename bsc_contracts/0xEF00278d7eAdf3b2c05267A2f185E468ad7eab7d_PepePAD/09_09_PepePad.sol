// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);

    function factory() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract PepePAD is Context, Ownable, ERC20 {
    using SafeERC20 for IERC20;

    IUniswapV2Router02 public router;
    address public feeRecipient;

    mapping(address => bool) taxless;

    bool public swapEnabled = false;
    uint256 public swapThreshold = 100 ether;
    mapping(address => bool) public pairs;

    // Fee have 2 decimals, so 100 is equal to 1%, 525 is 5.25% and so on
    uint256 public p2pFee;
    uint256 public buyFee;
    uint256 public sellFee;
    uint256 public constant MAX_TRANSFER_FEE = 1000; // 10%

    bool inSwap;

    event FeeHandlerUpdated(address indexed oldFeeHandler, address indexed newFeeHandler);
    event FeeUpdated(uint256 buyFee, uint256 sellFee, uint256 p2pFee);
    event FeeRecipientUpdated(address indexed oldFeeRecipient, address indexed newFeeRecipient);
    event SetPair(address indexed pair, bool enabled);

    event RouterUpdated(address indexed router);
    event SwapUpdated(bool indexed enabled);
    event SwapThresholdUpdated(uint256 indexed threshold);
    event Swapped(uint256 tokenAmount, uint256 ethAmount);

    modifier lockSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(IUniswapV2Router02 _router, address _feeRecipient) ERC20("PEPE PAD", "PEPE") {
        router = _router;
        feeRecipient = _feeRecipient;
        taxless[address(this)] = true;
        taxless[_feeRecipient] = true;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);
        pairs[IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH())] = true;

        emit FeeRecipientUpdated(address(0), _feeRecipient);
        transferOwnership(_feeRecipient);
        _mint(_feeRecipient, 420_000_000_000e18);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        if (swapEnabled && sender != address(router)) {
            _swapTokensForETH();
        }

        uint256 amountToTransfer = amount;
        uint256 fee = getFeeInfo(sender, recipient, amount);
        if (fee > 0 && fee <= MAX_TRANSFER_FEE) {
            fee = (amount * fee) / 10000;
            amountToTransfer -= fee;
            super._transfer(sender, address(this), fee);
        }
        super._transfer(sender, recipient, amountToTransfer);
    }

    function getFeeInfo(address sender, address recipient, uint256) internal view returns (uint256) {
        if (taxless[sender] || taxless[recipient] || inSwap) return 0;

        // buy
        if (pairs[sender]) {
            return buyFee;
        }

        // sell
        if (pairs[recipient]) {
            return sellFee;
        }

        // p2p
        return p2pFee;
    }

    function _swapTokensForETH() private lockSwap {
        uint256 amount = balanceOf(address(this));
        if (amount > swapThreshold) {
            address[] memory sellPath = new address[](2);
            sellPath[0] = address(this);
            sellPath[1] = router.WETH();
            _approve(address(this), address(router), amount);

            uint256 balanceBefore = feeRecipient.balance;
            try
                router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                    amount,
                    0,
                    sellPath,
                    feeRecipient,
                    block.timestamp
                )
            {
                emit Swapped(amount, feeRecipient.balance - balanceBefore);
            } catch {}
        }
    }

    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
    }

    function _setPair(address _pair, bool _enable) internal {
        pairs[_pair] = _enable;
        emit SetPair(_pair, _enable);
    }

    function setPair(address _pair, bool _enable) external onlyOwner {
        _setPair(_pair, _enable);
    }

    function setPairs(address[] memory _pairs, bool[] memory _enable) external onlyOwner {
        require(_pairs.length == _enable.length, "invalid length");
        for (uint256 i = 0; i < _pairs.length; i++) {
            _setPair(_pairs[i], _enable[i]);
        }
    }

    function setFee(uint256 _buyFee, uint256 _sellFee, uint256 _p2pFee) external onlyOwner {
        buyFee = _buyFee;
        sellFee = _sellFee;
        p2pFee = _p2pFee;
        require(buyFee <= MAX_TRANSFER_FEE, "fee to high");
        require(sellFee <= MAX_TRANSFER_FEE, "fee to high");
        require(p2pFee <= MAX_TRANSFER_FEE, "fee to high");
        emit FeeUpdated(_buyFee, _sellFee, _p2pFee);
    }

    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        emit FeeRecipientUpdated(feeRecipient, _feeRecipient);
        feeRecipient = _feeRecipient;
    }

    function includeInTax(address[] memory accounts) external onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            delete taxless[accounts[i]];
        }
    }

    function excludeFromTax(address[] memory accounts) external onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            taxless[accounts[i]] = true;
        }
    }

    function setRouter(IUniswapV2Router02 _router) external onlyOwner {
        router = _router;
        emit RouterUpdated(address(_router));
    }

    function setSwapEnabled(bool _enabled) external onlyOwner {
        swapEnabled = _enabled;
        emit SwapUpdated(_enabled);
    }

    function setSwapThreshold(uint256 _threshold) external onlyOwner {
        swapThreshold = _threshold;
        emit SwapThresholdUpdated(_threshold);
    }

    function rescue(IERC20 token, address recipient, uint256 amount) external onlyOwner {
        if (address(token) == address(0)) {
            payable(recipient).transfer(amount);
        } else {
            token.safeTransfer(recipient, amount);
        }
    }
}