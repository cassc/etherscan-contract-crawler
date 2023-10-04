// SPDX-License-Identifier: MIT
/**
    Cockatoo: Dance to the groove of the blockchain
    Website: https://www.dancing-cockatoo.io
**/
// Solidity version
pragma solidity ^0.8.21;

// Importing necessary contracts and interfaces
import "./SafeMath.sol";
// Standard ERC20 interfaces
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// Uniswap interfaces
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';

/**
 * @title Cockatoo Token Contract
 * @dev This contract implements the ERC-20 standard token with additional features
 * such as transaction fees, liquidity management, and dev fees. Furthermore it includes protection for liquidation spoofing
 */
contract Cockatoo is Context, IERC20, Ownable {
    using SafeMath for uint256;
    // Various contract parameters and settings
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 1000000000 * 10**_decimals;
    string private constant _name = unicode"Cockatoo";
    string private constant _symbol = unicode"Cockatoo";
    uint256 public maxTx = 0;
    uint256 public maxWallet = 0;
    bool private limitsInPlace = true;

    // Mapping to track token balances of users
    mapping (address => uint256) private _balances;
    // Mapping to track allowed token transfers between users
    mapping (address => mapping (address => uint256)) private _allowances;

    // Contract fees and settings
    uint256 private taxFee = 3;
    // Percentage of fees (3 * 0.2) that is transfered to liquidityWallet in tokens
    uint8 private constant liquidityPercentage = 20;
    // Percentage of fees (3 * 0.8) that is swapped and paid out to dev in ETH
    uint8 private constant devPercentage = 80;
    uint256 public _taxSwapThreshold = 5000000 * 10**_decimals;
    uint256 public _maxTaxSwap = 5000000 * 10**_decimals;
    address payable private devWallet = payable(0x7765DC477945992bAD93B41a7aA48715D190e8B4);
    address payable private liquidityWallet = payable(0xD3E52484ccF885EF1e5aBdda5ce96C0E5802FDbd);

    // Fee liquidation prevention parameters
    uint256 public lastFeeBlock = 0;
    uint public feesThisBlock = 0;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private inSwap = false;
    bool private swapEnabled = false;

    // Modifier to lock token swaps while they are being executed
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    // Implementation of ERC20 allowance function
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    // Implementation of ERC20 approve function
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    // Internal function to approve token spending
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // Implementation of ERC20 transfer function
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        transfer(_msgSender(), recipient, amount);
        return true;
    }

    // Implementation of ERC20 transferFrom function
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    // ERC20 name function
    function name() public pure returns (string memory) {
        return _name;
    }

    // ERC20 symbol function
    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    // ERC20 decimals function
    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    // ERC20 totalSupply function
    function totalSupply() public pure override returns (uint256) {
        return _totalSupply;
    }

    // ERC20 balanceOf function
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    // Contract constructor
    constructor () {
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);

        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    }
    
    function cockatooLiquidityAmount(uint256 tokenAmount) private pure returns (uint256) {
        return tokenAmount.mul(liquidityPercentage).div(100);
    }


    function cockatooDevAmount(uint256 tokenAmount) private pure returns (uint256) {
        return tokenAmount.mul(devPercentage).div(100);
    }

    /**
     * @dev Updates trading limits and settings.
     * @param _limitsInPlace Whether trading limits are in place.
     * @param _maxTxPercentage Maximum transaction percentage of total supply.
     * @param _maxWalletPercentage Maximum wallet percentage of total supply.
     * @param _swapEnabled Whether token swapping is enabled for accrued taxes.
     */
    function editCockatooSettings(bool _limitsInPlace, uint256 _maxTxPercentage, uint256 _maxWalletPercentage, bool _swapEnabled) external onlyOwner {
        require(_maxTxPercentage > 1 || _limitsInPlace == false, "Max tx must be set to at least 1");
        require(_maxWalletPercentage > 1 || _limitsInPlace == false, "Max wallet must be set to at least 1");
        limitsInPlace = _limitsInPlace;
        maxTx = _totalSupply.mul(_maxTxPercentage).div(100);
        maxWallet = _totalSupply.mul(_maxWalletPercentage).div(100);
        swapEnabled = _swapEnabled;
    }

    /**
     * @dev Removes trading limits
     */
    function removeCockatooLimits() external onlyOwner {
        limitsInPlace = false;
    }

    // Private function to handle transfers and apply fees
    function transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount = 0;
        uint currentblock = block.number;

        // Calculate tax amount if it's not a transaction from or to the owner
        if (from != owner() && to != owner()) {
            // If uniswap buy or sell, levy tax, otherwise don't
            if ((from == uniswapV2Pair || to == uniswapV2Pair )
                && to != address(liquidityWallet) && to != address(devWallet) && from != address(this) ) {
                taxAmount = amount.mul(taxFee).div(100);
            }

            // If limits are in place for tx amount and wallet, check those
            if (limitsInPlace && from == uniswapV2Pair && to != address(uniswapV2Router) && to != address(devWallet) && to != address(liquidityWallet)) {
                require(amount <= maxTx, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= maxWallet, "Exceeds the maxWalletSize.");
            }

            // Get contract balance in tokens
            uint256 contractTokenBalance = balanceOf(address(this));
            // Check if the token is eligible for liquidity swap
            if (!inSwap && to == uniswapV2Pair && swapEnabled && contractTokenBalance > _taxSwapThreshold) {
                if (checkCanLiquifyThisBlock(currentblock)) {
                    // Transfer tokens to the liquidity wallet
                    uint256 liquifyAmount = cockatooLiquidityAmount(_taxSwapThreshold);
                    _balances[liquidityWallet] = _balances[liquidityWallet].add(liquifyAmount);
                    emit Transfer(from, liquidityWallet, liquifyAmount);

                    // Store the rest of the tokens on the contract for dev fees to be sold
                    uint256 devAmount = cockatooDevAmount(_taxSwapThreshold);
                    // Swap tokens for ETH
                    swapTokensForEth(devAmount);
                    // Transfer ETH to the dev wallet if balance exceeds a threshold
                    devWallet.transfer(address(this).balance);
                }
            }
        }
        // Apply tax and transfer tokens
        if (taxAmount > 0) {
            // Store tokens on the contract as tax to be sold and liquidated later
            _balances[address(this)] = _balances[address(this)].add(taxAmount);
            emit Transfer(from, address(this), taxAmount);
        }

        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }

    // Function to get the minimum of two numbers
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return (a > b) ? b : a;
    }

    // Function to swap tokens for ETH on the Uniswap V2 Router
    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    // Function to check if the token can be swapped for liquidity
    // This limits the possibility of fees triggering too often
    function checkCanLiquifyThisBlock(uint currentblock) private returns (bool) {
        require(currentblock >= lastFeeBlock, "Blockchain state invalid");
        if (inSwap) {
            return false;
        } else if (currentblock > lastFeeBlock) {
            lastFeeBlock = currentblock;
            feesThisBlock = 0;
            return true;
        } else {
            if (feesThisBlock < 2) {
                feesThisBlock += 1;
                return true;
            } else {
                return false;
            }
        }
    }

    // Fallback function to accept ETH
    receive() external payable {}
}