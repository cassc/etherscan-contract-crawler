pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = tx.origin;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

     /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router {
    function factory() external pure returns (address);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract BMB is Ownable, ERC20 {

    address public constant usdt = 0x55d398326f99059fF775485246999027B3197955;
    address public constant router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public marketingWallet = 0xb1970616f96404269f695c368a9F7D41CA436FA1;
    address public tokenWallet = 0x2251F5E1Be9C9C7E83Cc8d3019398C188f797E08;

    uint256 public marketingFee = 6;
    uint256 public numTokensSellToAddToLiquidity = 100000 * 1e18;
    uint256 public maxAmountPerAccount;

    mapping (address => bool) public isPair;
    mapping (address => bool) public exemptFee;
    mapping (address => bool) public isBlacklist;

    bool public enableTxLimit = true;
    bool private inSwap;
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    constructor() ERC20("Blockchain Modular Balance", "BMB") {
        IUniswapV2Router _uniswapV2Router = IUniswapV2Router(router);
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), usdt);
        isPair[_uniswapV2Pair] = true;

        exemptFee[owner()] = true;
        exemptFee[marketingWallet] = true;
        exemptFee[tokenWallet] = true;
        exemptFee[address(this)] = true;

        _approve(address(this), router, ~uint(0));
        _mint(tokenWallet, 100000000 * 1e18); 
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override{
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "ERC20: wrong amount");
        require(!isBlacklist[sender], "ERC20: Blacklist");

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwap &&
            !isPair[sender]
        ) {
            swapAndDividend(numTokensSellToAddToLiquidity);
        }
        
        bool takeFee = true;
        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(exemptFee[sender] || exemptFee[recipient]) {
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(sender, recipient, amount, takeFee);

        if (enableTxLimit
            && isPair[sender]
            && !exemptFee[recipient] 
        ) {
            require(balanceOf(recipient) <= maxAmountPerAccount, "max amount limit per account");
        }
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if(takeFee) {
            uint256 _marketingFee = marketingFee;
            if (_marketingFee > 0 && (isPair[sender] || isPair[recipient])) {
                uint256 feeAmount = amount * _marketingFee / 100;
                super._transfer(sender, address(this), feeAmount);
                amount -= feeAmount;
            }
        } 
        super._transfer(sender, recipient, amount);
    }

    function swapAndDividend(uint256 amount) private lockTheSwap {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = usdt;

        // make the swap
        IUniswapV2Router(router).swapExactTokensForTokens(
            amount,
            0, // accept any amount of usdt
            path,
            marketingWallet,
            block.timestamp
        );
    }

    function setNumTokensSellToAddToLiquidity(uint256 value) external onlyOwner { 
        numTokensSellToAddToLiquidity = value;
    }

    function setMarketingAddr(address _marketingWallet) external onlyOwner { 
        marketingWallet = _marketingWallet;
    }

    function setMarketingFee(uint256 _marketingFee) external onlyOwner { 
        marketingFee = _marketingFee;
    }

    function setExemptFee(address[] memory account, bool flag) external onlyOwner {
        require(account.length > 0, "no account");
        for(uint256 i = 0; i < account.length; i++) {
            exemptFee[account[i]] = flag;
        }
    }

    function setPair(address pair, bool flag) external onlyOwner { 
        isPair[pair] = flag;
    }

    function setBlacklist(address account, bool flag) external onlyOwner { 
        isBlacklist[account] = flag;
    }

    function setMaxAmountPerAccount(uint256 _maxAmountPerAccount) external onlyOwner { 
        maxAmountPerAccount = _maxAmountPerAccount;
    }

    function setEnableTxLimit(bool _enableTxLimit) external onlyOwner { 
        enableTxLimit = _enableTxLimit;
    }
}