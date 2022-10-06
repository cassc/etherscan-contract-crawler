// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

pragma solidity ^0.8.6;

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

pragma solidity ^0.8.6;

interface IPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function sync() external;
}

pragma solidity ^0.8.6;

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;
}

contract CrewFive is ERC20, Ownable {
    using Address for address payable;

    mapping(address => bool) public isExcludedFromFees;

    IRouter public router;
    address public pair;

    address public feeWalletAddress;

    bool private _swapping;
    bool public swapEnabled;
    bool public transfersEnabled;

    uint256 public swapTokensThreshold;
    uint256 public maxWallet;

    uint256 public buyFee = 6;
    uint256 public sellFee = 6;
    uint256 public transferFee = 6;

    modifier inSwap() {
        if (!_swapping) {
            _swapping = true;
            _;
            _swapping = false;
        }
    }

    event TaxRecipientsUpdated(address newfeeWalletAddress);
    event FeesUpdated();
    event SwapEnabled(bool state);
    event SwapTokensThresholdUpdated(uint256 amount);
    event MaxWalletUpdated(uint256 amount);
    event RouterUpdated(address newRouter);
    event ExemptFromFeeUpdated(address user, bool state);
    event PairUpdated(address newPair);

    constructor(address _routerAddress, string memory _name_, string memory _symbol_) ERC20(_name_, _symbol_) {
        require(_routerAddress != address(0), "Router address cannot be zero address");
        IRouter _router = IRouter(_routerAddress);

        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());

        router = _router;
        pair = _pair;

        swapEnabled = true;
        swapTokensThreshold = 500_000_000_000 * 10**18;
        maxWallet = 10_000_000_000_000 * 10**18;

        feeWalletAddress = msg.sender;

        isExcludedFromFees[msg.sender] = true;
        isExcludedFromFees[address(this)] = true;

        _mint(msg.sender, 1_000_000_000_000_000 * 10**18);
    }

    function setTaxRecipients(address _feeWalletAddress) external onlyOwner {
        require(_feeWalletAddress != address(0), "feeWalletAddress cannot be the zero address");
        feeWalletAddress = _feeWalletAddress;

        isExcludedFromFees[feeWalletAddress] = true;

        emit TaxRecipientsUpdated(_feeWalletAddress);
    }

    function setTransferFee(uint256 _transferFee) external onlyOwner {
        require(_transferFee < 10, "Transfer fee must be less than 10");
        transferFee = _transferFee;
        emit FeesUpdated();
    }

    function setBuyFee(uint256 _buyFee) external onlyOwner {
        require(_buyFee < 10, "Buy fee must be less than 10");
        buyFee = _buyFee;
        emit FeesUpdated();
    }

    function setSellFee(uint256 _sellFee) external onlyOwner {
        require(_sellFee < 10, "Sell fee must be less than 10");
        sellFee = _sellFee;
        emit FeesUpdated();
    }

    function setSwapEnabled(bool state) external onlyOwner {
        swapEnabled = state;
        emit SwapEnabled(state);
    }

    function setSwapTokensThreshold(uint256 amount) external onlyOwner {
        swapTokensThreshold = amount * 10**18;
        emit SwapTokensThresholdUpdated(amount);
    }

    function setMaxWallet(uint256 amount) external onlyOwner {
        require(amount >= 1_000_000_000_000, "Max wallet amount must be >= 1,000,000,000,000");
        maxWallet = amount * 10**18;
        emit MaxWalletUpdated(amount);
    }

    function exemptFromFee(address user, bool state) external onlyOwner {
        require(isExcludedFromFees[user] != state, "State already set");
        isExcludedFromFees[user] = state;
        emit ExemptFromFeeUpdated(user, state);
    }

    function rescueETH() external onlyOwner {
        require(address(this).balance > 0, "Insufficient ETH balance");
        payable(owner()).sendValue(address(this).balance);
    }

    function rescueERC20(address tokenAdd, uint256 amount) external onlyOwner {
        require(tokenAdd != address(this), "Cannot rescue itself");
        require(IERC20(tokenAdd).balanceOf(address(this)) >= amount, "Insufficient token balance");
        IERC20(tokenAdd).transfer(owner(), amount);
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(amount > 0, "Transfer amount must be greater than zero");

        if(!isExcludedFromFees[from] && !isExcludedFromFees[to]) {
            require(transfersEnabled, "Transactions are not enable");
            if(to != pair) require(balanceOf(to) + amount <= maxWallet, "Receiver balance is exceeding maxWallet");
        }

        uint256 taxAmt;

        if(!_swapping && !isExcludedFromFees[from] && !isExcludedFromFees[to]) {
            if(to == pair) {
                taxAmt = amount * sellFee / 100;
            } else if(from == pair) {
                taxAmt = amount * buyFee / 100;
            } else {
                taxAmt = amount * transferFee / 100;
            }
        }

        if (!_swapping && swapEnabled && to == pair && sellFee > 0) {
            _handle_fees();
        }

        super._transfer(from, to, amount - taxAmt);
        if(taxAmt > 0) {
            super._transfer(from, address(this), taxAmt);
        }
    }

    function _handle_fees() internal inSwap {
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance >= swapTokensThreshold) {
            if(swapTokensThreshold > 1) {
                contractBalance = swapTokensThreshold;
            }

            _swapTokensForETH(contractBalance);
        }
    }

    function _swapTokensForETH(uint256 tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, feeWalletAddress, block.timestamp);

    }

    function setTurnOnTransfers() external onlyOwner {
        transfersEnabled = true;
    }

    receive() external payable {}
    fallback() external payable {}
}