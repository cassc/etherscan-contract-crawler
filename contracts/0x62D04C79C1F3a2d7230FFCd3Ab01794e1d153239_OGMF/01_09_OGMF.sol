pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

/**
 * @title OGMF Token
 * @dev Implementation of the OGMF Token.
 */
contract OGMF is ERC20, Ownable {
    mapping (address => bool) private _isExcludedFromFee; // keeps track of addresses excluded from fees
    mapping (address => bool) private _isExcludedFromBotProtection; // keeps track of addresses excluded from bot protection
    mapping (address => bool) private _isExcludedFromMaxTxAmount; // keeps track of addresses excluded from the maximum transaction amount
    mapping (address => uint) private _lastTx; // keeps track of the timestamp of the last transaction of each address

    uint256 public constant MAX_SUPPLY = 75000000000 ether; // token supply
    uint256 public constant TAX = 15; // tax rate (1.5%)
    uint256 public constant BUY_BURN = 70; // 70% of buy taxes are burned daily
    uint256 public constant MAX_TX_AMOUNT = 3000000000 ether; // maximum amount of tokens that can be bought or sold in a transaction
    
    address private _uniswapV2Router; // address of the Uniswap v2 router
    mapping (address => bool) public pairs; // all pairs
    
    address private _poolWallet; // fees from sells
    address private _burnWallet; // fees from buys
    address private _teamWallet; // fees from buys

    uint256 public swapTokensAtAmount = 50000000 ether; // minimum amount of tokens to be swapped for ETH - if 0 won't swap

    bool public isTaxActive = true; // determines whether the tax is active or not
    bool public botDetectionActive = false; // determines whether bot detection is active or not
    bool public maxTransactionActive = true; // determines whether the maximum transaction amount is active or not

    bool private swapping; // determines whether a swap is in progress or not

    /**
     * @dev Sets the values for {uniswapV2Router}, {poolWallet}, {burnWallet} and {teamWallet}.
     *
     * construction.
     */
    constructor(
        address uniswapV2Router_,
        address poolWallet_,
        address burnWallet_,
        address teamWallet_
    ) ERC20("CryptoPirates", "OGMF") {
        _uniswapV2Router = uniswapV2Router_;
        _poolWallet = poolWallet_;
        _burnWallet = burnWallet_;
        _teamWallet = teamWallet_;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromBotProtection[owner()] = true;
        _isExcludedFromMaxTxAmount[owner()] = true;
        _mint(owner(), MAX_SUPPLY);
    }

    /**
     * @dev See {ERC20-_transfer}.
     * 
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "Can't transfer from zero address");
        require(to != address(0), "can't transfer to zero address");
        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (!swapping) {
            // if max transaction amount is set to 0, there is no maximum transaction amount
            if (maxTransactionActive) {
                if ((pairs[to] || pairs[from]) && !_isExcludedFromMaxTxAmount[tx.origin]) {
                    require(amount <= MAX_TX_AMOUNT, "Amount exceeds the maximum transaction amount");
                }
            }
            if (botDetectionActive) { // bot detection
                if (pairs[to] && !_isExcludedFromBotProtection[from]) { // SELL 
                    require(_lastTx[from] < block.number, "Only one transaction per block allowed");
                    _lastTx[from] = block.number;
                } else if (pairs[from] && !_isExcludedFromBotProtection[to]) { // BUY
                    require(_lastTx[to] < block.number, "Only one transaction per block allowed");
                    _lastTx[to] = block.number;
                }
            }
            if (isTaxActive) { // tax
                uint256 taxAmount = amount * TAX / 1000; // 1.5% of the transaction
                if (pairs[to] && !_isExcludedFromFee[from]) { // SELL
                    amount -= taxAmount; // remove tax from the amount
                    super._transfer(from, _poolWallet, taxAmount); // send the tax to the pool wallet
                    // swap tokens for ETH
                    swapping = true;
                    splitAndSwapBack();
                    swapping = false;
                } else if (pairs[from] && !_isExcludedFromFee[to]) { // BUY
                    amount -= taxAmount; // remove tax from the amount
                    super._transfer(from, address(this), taxAmount); // send the tax to the contract
                }
            }
        }
        
        super._transfer(from, to, amount);
    }

    function splitAndSwapBack() private {
        uint256 contractTokenBalance = balanceOf(address(this));

        uint256 burnAmount = contractTokenBalance * BUY_BURN / 100; // 70% of the tokens goes to the burn wallet
        uint256 teamAmount = contractTokenBalance - burnAmount; // 30% of the tokens goes to the team wallet

        if (swapTokensAtAmount > 0 && teamAmount >= swapTokensAtAmount) {
            super._transfer(address(this), _burnWallet, burnAmount);
            _swapTokensForEth(teamAmount);
        }
    }

    function _swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = IUniswapV2Router02(_uniswapV2Router).WETH();

        _approve(address(this), _uniswapV2Router, tokenAmount);

        // make the swap
        IUniswapV2Router02(_uniswapV2Router).swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            _teamWallet,
            block.timestamp
        );
    }

    /**
    * @dev Burns `amount` tokens from the caller.
    * See {ERC20-_burn}.
    */
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    function emergencyTransfer() public onlyOwner {
        super._transfer(address(this), _msgSender(), balanceOf(address(this)));
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function excludeFromBotProtection(address account) public onlyOwner {
        _isExcludedFromBotProtection[account] = true;
    }

    function includeInBotProtection(address account) public onlyOwner {
        _isExcludedFromBotProtection[account] = false;
    }

    function excludeFromMaxTxAmount(address account) public onlyOwner {
        _isExcludedFromMaxTxAmount[account] = true;
    }

    function includeInMaxTxAmount(address account) public onlyOwner {
        _isExcludedFromMaxTxAmount[account] = false;
    }

    function setTeamWallet(address teamWallet) public onlyOwner {
        _teamWallet = teamWallet;
    }

    function setPoolWallet(address poolWallet) public onlyOwner {
        _poolWallet = poolWallet;
    }

    function setBurnWallet(address burnWallet) public onlyOwner {
        _burnWallet = burnWallet;
    }

    function setSwapTokensAtAmount(uint256 amount) public onlyOwner {
        swapTokensAtAmount = amount;
    }

    function deactivateMaxTransaction() public onlyOwner {
        maxTransactionActive = false;
    }

    function setTaxStatus(bool status) public onlyOwner {
        isTaxActive = status;
    }

    function setBotDetectionStatus(bool status) public onlyOwner {
        botDetectionActive = status;
    }

    function setUniswapV2Router(address uniswapV2Router) public onlyOwner {
        _uniswapV2Router = uniswapV2Router;
    }

    function addPair(address pair) public onlyOwner {
        pairs[pair] = true;
    }

    function removePair(address pair) public onlyOwner {
        pairs[pair] = false;
    }

    function createPair() public onlyOwner {
        pairs[IUniswapV2Factory(IUniswapV2Router02(_uniswapV2Router).factory()).createPair(address(this), IUniswapV2Router02(_uniswapV2Router).WETH())] = true;
    }
}