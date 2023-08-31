// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract HoneyBB is ERC20, ERC20Burnable, AccessControl {
    /* ----- CONSTANTS ----- */
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    uint256 public constant ONE_HUNDRED_PERCENT = 10000;

    /* ----- ENUM ----- */
    enum SwapRouterVersion {
        V2,
        V3,
        NotSupported
    }

    /* ----- STATE VARIABLES ----- */
    uint256 public sellAndBuyTaxRate;
    uint256 public maxAmountPerTx;
    bool public isAntiWhaleEnabled;
    address public sellAndBuyTaxRecipient;
    uint256 public transferTxCount = 1; // start from 1 to avoid swap on first tx
    uint256 public numberOfTxToSwap = 5; // swap every 5 tx
    bool private isSwapping;
    address public WETH9;

    ISwapRouter public swapRouterV3;
    IUniswapV2Router02 public swapRouterV2;

    /* ----- MAPPING ----- */
    mapping(address => bool) public isTokenPairV2;
    mapping(address => bool) public isTokenPairV3;

    /* ----- EVENTS ----- */
    event SellAndBuyTaxRateUpdated(uint256 newRate);
    event MaxAmountPerTxUpdated(uint256 newAmount);
    event AntiWhaleSwitched(bool isAntiWhaleEnabled);
    event SellAndBuyTaxRecipientUpdated(address newRecipient);
    event SwapRouterUpdated(address newSwapRouter, SwapRouterVersion version);
    event AddTokenPair(address tokenPair, SwapRouterVersion version);
    event RemoveTokenPair(address tokenPair, SwapRouterVersion version);

    constructor(
        uint256 _sellAndBuyTaxRate,
        uint256 _maxAmountPerTx,
        bool _isAntiWhaleEnabled,
        address _sellAndBuyTaxRecipient,
        uint256 _totalSupply,
        address _WETH9
    ) ERC20("HoneyBB", "HoneyBB") {
        require(_sellAndBuyTaxRate <= ONE_HUNDRED_PERCENT, "Sell and buy tax rate must be less than 100%");
        require(_maxAmountPerTx > 0, "Max amount per tx must be greater than 0");
        require(_sellAndBuyTaxRecipient != address(0), "Sell and buy tax recipient cannot be zero address");
        require(_WETH9 != address(0), "WETH9 cannot be zero address");

        sellAndBuyTaxRate = _sellAndBuyTaxRate;
        maxAmountPerTx = _maxAmountPerTx;
        isAntiWhaleEnabled = _isAntiWhaleEnabled;
        sellAndBuyTaxRecipient = _sellAndBuyTaxRecipient;
        WETH9 = _WETH9;

        _mint(msg.sender, _totalSupply);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    /* ----- CONFIG FUNCTIONS ----- */
    function setSellAndBuyTaxRate(uint256 _sellAndBuyTaxRate) external onlyRole(ADMIN_ROLE) {
        require(_sellAndBuyTaxRate <= ONE_HUNDRED_PERCENT, "Sell and buy tax rate must be less than 100%");
        sellAndBuyTaxRate = _sellAndBuyTaxRate;
        emit SellAndBuyTaxRateUpdated(_sellAndBuyTaxRate);
    }

    function setMaxAmountPerTx(uint256 _maxAmountPerTx) external onlyRole(ADMIN_ROLE) {
        require(_maxAmountPerTx > 0, "Max amount per tx must be greater than 0");
        maxAmountPerTx = _maxAmountPerTx;
        emit MaxAmountPerTxUpdated(_maxAmountPerTx);
    }

    function antiWhaleSwitch(bool _isAntiWhaleEnabled) external onlyRole(ADMIN_ROLE) {
        isAntiWhaleEnabled = _isAntiWhaleEnabled;
        emit AntiWhaleSwitched(_isAntiWhaleEnabled);
    }

    function setSellAndBuyTaxRecipient(address _sellAndBuyTaxRecipient) external onlyRole(ADMIN_ROLE) {
        require(_sellAndBuyTaxRecipient != address(0), "Sell and buy tax recipient cannot be zero address");
        sellAndBuyTaxRecipient = _sellAndBuyTaxRecipient;
        emit SellAndBuyTaxRecipientUpdated(_sellAndBuyTaxRecipient);
    }

    function setSwapRouter(address _swapRouter, SwapRouterVersion _version) external onlyRole(ADMIN_ROLE) {
        require(_swapRouter != address(0), "Swap router cannot be zero address");
        if (_version == SwapRouterVersion.V3) {
            swapRouterV3 = ISwapRouter(_swapRouter);
        } else {
            swapRouterV2 = IUniswapV2Router02(_swapRouter);
        }
        emit SwapRouterUpdated(_swapRouter, _version);
    }

    function addTokenPair(address _tokenPair, SwapRouterVersion _version) external onlyRole(ADMIN_ROLE) {
        require(_tokenPair != address(0), "Token pair cannot be zero address");
        if (_version == SwapRouterVersion.V3) {
            isTokenPairV3[_tokenPair] = true;
        } else {
            isTokenPairV2[_tokenPair] = true;
        }
        emit AddTokenPair(_tokenPair, _version);
    }

    function removeTokenPair(address _tokenPair, SwapRouterVersion _version) external onlyRole(ADMIN_ROLE) {
        require(_tokenPair != address(0), "Token pair cannot be zero address");
        if (_version == SwapRouterVersion.V3) {
            isTokenPairV3[_tokenPair] = false;
        } else {
            isTokenPairV2[_tokenPair] = false;
        }
        emit RemoveTokenPair(_tokenPair, _version);
    }

    function setNumberOfTxBeforeSwap(uint256 _numberOfTxToSwap) external onlyRole(ADMIN_ROLE) {
        require(_numberOfTxToSwap > 0, "Number of tx to swap must be greater than 0");
        numberOfTxToSwap = _numberOfTxToSwap;
    }

    /* ----- OVERRIDE FUNCTIONS ----- */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        if (isAntiWhaleEnabled) {
            require(amount <= maxAmountPerTx, "Transfer amount exceeds the maximum amount per transaction");
        }
        super._transfer(sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool success) {
        SwapRouterVersion swapVersion = whichSwapCalled();
        if (swapVersion == SwapRouterVersion.NotSupported || isSwapping) {
            if (isSwapping) {
                transferTxCount++;
                isSwapping = false;
            }

            return super.transferFrom(sender, recipient, amount);
        }

        if (swapVersion == SwapRouterVersion.V2 && (isTokenPairV2[recipient] || isTokenPairV2[sender]) && !isSwapping) {
            uint256 taxAmount = (amount * sellAndBuyTaxRate) / ONE_HUNDRED_PERCENT;
            uint256 transferAmount = amount - taxAmount;

            super.transferFrom(sender, address(this), taxAmount);
            super.transferFrom(sender, recipient, transferAmount);

            bool isSwappingTime = transferTxCount % numberOfTxToSwap == 0;
            if (isSwappingTime) {
                uint256 balance = balanceOf(address(this));

                if (balance > 0) {
                    isSwapping = true;
                    swapTokenForEthV2(balance);
                }
            }

            transferTxCount++;
            return true;
        }

        if (swapVersion == SwapRouterVersion.V3 && (isTokenPairV3[recipient] || isTokenPairV3[sender]) && !isSwapping) {
            uint256 taxAmount = (amount * sellAndBuyTaxRate) / ONE_HUNDRED_PERCENT;
            uint256 transferAmount = amount - taxAmount;

            super.transferFrom(sender, address(this), taxAmount);
            super.transferFrom(sender, recipient, transferAmount);

            bool isSwappingTime = transferTxCount % numberOfTxToSwap == 0;
            if (isSwappingTime) {
                uint256 balance = balanceOf(address(this));

                if (balance > 0) {
                    isSwapping = true;
                    swapTokenForEthV3(balance);
                }
            }

            transferTxCount++;
            return true;
        }

        return true;
    }

    /* ----- HELPER FUNCTIONS ----- */
    function whichSwapCalled() private view returns (SwapRouterVersion version) {
        address sender = _msgSender();
        if (sender == address(swapRouterV3)) {
            return SwapRouterVersion.V3;
        } else if (sender == address(swapRouterV2)) {
            return SwapRouterVersion.V2;
        }
        return SwapRouterVersion.NotSupported;
    }

    function swapTokenForEthV2(uint256 tokenAmount) private {
        // Approve the uniswapV2Router to spend the tokenAmount
        _approve(address(this), address(swapRouterV2), tokenAmount);

        // Define the path for token -> weth swap
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = swapRouterV2.WETH();

        uint256 amountOutMin = swapRouterV2.getAmountsOut(tokenAmount, path)[1];

        swapRouterV2.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            amountOutMin,
            path,
            sellAndBuyTaxRecipient,
            block.timestamp
        );
    }

    function swapTokenForEthV3(uint256 tokenAmount) private {
        // Approve the uniswapV3Router to spend the tokenAmount
        _approve(address(this), address(swapRouterV3), tokenAmount);

        // Define token and weth address
        swapRouterV3.exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: address(this),
                tokenOut: WETH9,
                fee: 3000,
                recipient: sellAndBuyTaxRecipient,
                deadline: block.timestamp,
                amountIn: tokenAmount,
                amountOutMinimum: 0, // accept any amount of ETH
                sqrtPriceLimitX96: 0
            })
        );
    }

    receive() external payable {}
}