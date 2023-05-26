/**
 *Submitted for verification at Etherscan.io on 2023-05-19
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/**
 * Standard SafeMath, stripped down to just add/sub/mul/div
 */
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    mapping(address => bool) internal _isOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        _isOwner[msgSender] = true;
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * ERC20 standard interface.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IDEXRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}

contract SafeToken is Ownable {
    address payable safeManager;

    constructor() {
        safeManager = payable(msg.sender);
    }

    function getSafeManager() public view returns (address) {
        return safeManager;
    }

    function setSafeManager(address payable _safeManager) public onlyOwner {
        safeManager = _safeManager;
    }

    function withdrawEth(uint256 _amount) external {
        require(msg.sender == safeManager);
        safeManager.transfer(_amount);
    }
}

contract BaseToken is Ownable, IERC20 {
    using SafeMath for uint256;

    address Eth = 0x2170Ed0880ac9A755fd29B2688956BD959F933F8;
    address WEth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    string _name;
    string _symbol;
    uint8 _decimals;
    uint256 _totalSupply;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint8 decimals_
    ) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = totalSupply_;
        _decimals = decimals_;
    }

    receive() external payable {}

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveFrom(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "approve from the zero address");
        require(spender != address(0), "approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != ~uint256(0)) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
                .sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual returns (bool) {
        return _basicTransfer(sender, recipient, amount);
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function burn(uint256 amount) internal virtual {
        _burn(_msgSender(), amount);
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address holder, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[holder][spender];
    }
}

contract MainToken is
    BaseToken("ASS", "ASS", 1000000000000 * 10**18, 18),
    SafeToken
{
    using SafeMath for uint256;

    address public lpAddress = 0x8eF618475e4E198B6763412943A2B17725555555;
    address public cexAddress =
        0x5e4728608FEd3E7ddb31e26f65940624c6666666;
    address public marketingAddress = 0x95EbD7e86ed18727ED1651CdC90a16E0d7777777;
    address public buybackAddress = 0x1D87789d61ADacd83a3913b431d63D5038888888;

    IDEXRouter uniswapRouter;
	
	uint256 public swapbackThreshold = 10;
    uint256 public mainTokenTotalBuy = 0;
    uint256 public mainTokenTotalSell = 0;
	uint8 constant SELL_THRESHOLD = 70;

    uint256 public undistributedBuyTax = 0;
    uint256 public undistributedSellTax = 0;
    uint256 public firstAddliquid = 0;

    uint8 public BUY_IN_TAX_PERCENTAGE = 4;
    uint8 public SELL_OUT_TAX_PERCENTAGE = 4;

    uint8 constant TX_NORMAL = 0;
    uint8 constant TX_BUY = 1;
    uint8 constant TX_SELL = 2;
	
	uint256 private maxEthUserCanBuy = 2000000 * 10**18; // 2 million Eth

    bool inSwap;

    event BurnSupply(address indexed _user, uint256 _amount);
    constructor() {
        uniswapRouter = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        approveFrom(address(this), address(uniswapRouter), ~uint256(0));

        address contractOwner = owner();
        _balances[contractOwner] = _totalSupply;
    }

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    /**
     *  Set address
     */
    function initSpecialAddresses(
        address _lpAddress,
        address _cexAddress,
        address _marketingAddress,
        address _buybackAddress
    ) public onlyOwner {
        // Set new address
        lpAddress = _lpAddress;
        marketingAddress = _marketingAddress;
        cexAddress = _cexAddress;
        buybackAddress = _buybackAddress;
    }

    function setLPAddress(address newLPAddress) public onlyOwner {
        lpAddress = newLPAddress;
    }

    function setMarketingAddress(address newMarketingAddress) public onlyOwner {
        marketingAddress = newMarketingAddress;
    }

    function setCexAddress(address newCexAddress) public onlyOwner {
        cexAddress = newCexAddress;
    }
    function setBuybackAddress(address newBuybackAddress) public onlyOwner {
        buybackAddress = newBuybackAddress;
    }
	
	/**
        Get total sell value / total buy value
        In percentage
     */
    function sellPressure(uint256 amount) private view returns (uint256) {
        // No buy no sell
        if (mainTokenTotalBuy == 0) {
            return 100;
        }

        // Calculate sell value percentage
        uint256 estimatedMainToken = getMainTokenEstimatedPrice(amount);
        return
            mainTokenTotalSell.add(estimatedMainToken).mul(100).div(
                mainTokenTotalBuy
            );
    }
	
	/**
        Check if the address can sell token
     */
    function canSellToken(
        /*address sender, */
        uint256 amount
    ) private view {
        require(
            /* excludeMaxTxn[sender] || */
            sellPressure(amount) < SELL_THRESHOLD,
            "Sell Limit Exceeded"
        );
    }

    /**
        Check if a buyer can buy token:
        * Buying value in Eth < max Eth limit
     */
    function canBuyToken(
        /*address buyer, */
        uint256 amount
    ) private view {
        require(
            getMainTokenEstimatedPrice(amount) < maxEthUserCanBuy,
            "Buy limit exceeded"
        );
    }
	

    /**
     *  Withdraw all Eth accidentally sent to this address
     */
    function withdrawAllEth() external {
        require(msg.sender == safeManager);
        safeManager.transfer(address(this).balance);
    }

    /**
        Undistributed sell tax in project token
    */
    function getSellTaxBalance() public view returns (uint256) {
        return undistributedSellTax.div(10**_decimals);
    }

    /**
        Undistributed buy tax in project token
    */
    function getBuyTaxBalance() public view returns (uint256) {
        return undistributedBuyTax.div(10**_decimals);
    }

    /**
     *  Set Buy in tax percentage
     */
    function setBuyInTaxPercentage(uint8 percent) external onlyOwner {
        require(percent <= 15, "Tax percentage must be less than 15");
        BUY_IN_TAX_PERCENTAGE = percent;
    }

    /**
     *  Set  Sell out tax percentage
     */
    function setSellOutTaxPercentage(uint8 percent) external onlyOwner {
        require(percent <= 15, "Tax percentage must be less than 15");
        SELL_OUT_TAX_PERCENTAGE = percent;
    }

    /* Burn Total Supply Function */
    function burnDead(uint256 _value) external onlyOwner {
        transfer(DEAD, _value);
        emit Transfer(msg.sender, DEAD, _value);
    }

    function burnSupply(uint256 _value) external onlyOwner {
        burn(_value);
        emit BurnSupply(msg.sender, _value);
    }

    // Swap THIS token into Eth (eth).
    function swapTokenToEth(uint256 amount) private {
        require(amount > 0);
        IERC20 tokenContract = IERC20(address(this));
        tokenContract.approve(address(uniswapRouter), amount);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function distributeAutoBuyBack(uint256 amount, address receiverAddress) private {
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = address(this);

        uniswapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amount
        }(0, path, receiverAddress, block.timestamp.add(300));
    }

    /**
        Force swapping all undistributed buy tax
        and distribute
     */
    function swapBackAndDistributeBuyTax() private swapping {
        uint256 EthBefore = address(this).balance;
        swapTokenToEth(undistributedBuyTax);
        uint256 EthAfter = address(this).balance;
        uint256 EthToDistribute = EthAfter.sub(EthBefore);

        uint256 marketingEth = EthToDistribute.mul(25).div(100);
        distributeAutoBuyBack(marketingEth, marketingAddress);

        uint256 lpEth = EthToDistribute.mul(25).div(100);
        distributeAutoBuyBack(lpEth, lpAddress);

        uint256 cexEth = EthToDistribute.mul(25).div(100);
        distributeAutoBuyBack(cexEth, cexAddress);

        distributeAutoBuyBack(EthToDistribute.sub(marketingEth).sub(lpEth).sub(cexEth), buybackAddress);

        undistributedBuyTax = 0;
    }

    /**
        Force swapping all undistributed sell tax
        and distribute
     */
    function swapBackAndDistributeSellTax() private swapping {
        uint256 EthBefore = address(this).balance;

        swapTokenToEth(undistributedSellTax);
        uint256 EthAfter = address(this).balance;
        uint256 EthToDistribute = EthAfter.sub(EthBefore);

        uint256 marketingEth = EthToDistribute.mul(25).div(100);
        distributeAutoBuyBack(marketingEth, marketingAddress);

        uint256 lpEth = EthToDistribute.mul(25).div(100);
        distributeAutoBuyBack(lpEth, lpAddress);

        uint256 cexEth = EthToDistribute.mul(25).div(100);
        distributeAutoBuyBack(cexEth, cexAddress);

        distributeAutoBuyBack(EthToDistribute.sub(marketingEth).sub(lpEth).sub(cexEth), buybackAddress);

        undistributedSellTax = 0;
    }

    function canSwapBack() private view returns (bool) {
        return !inSwap;
    }

    /**
     * Returns the transfer type.
     * 1 if user is buying (swap main token for sc token)
     * 2 if user is selling (swap sc token for main token)
     * 0 if user do the simple transfer between two wallets.
     */
    function checkTransferType(address sender, address recipient)
        private
        view
        returns (uint8)
    {
        if (sender.code.length > 0) {
            // in case of the wallet, there's no code => length == 0.
            return TX_BUY; // buy
        } else if (recipient.code.length > 0) {
            return TX_SELL; // sell
        }

        return TX_NORMAL; // normal transfer
    }
	/**
     * Returns the total sell/total buy ratio of the main token in percentage
     * E.g. 200 = 200%
     */
    function totalMainTokenSellBuyRatio() public view returns (uint256) {
        if (mainTokenTotalBuy == 0) {
            return 0;
        }
        uint256 upper = mainTokenTotalBuy.sub(mainTokenTotalSell);
        uint256 lower = mainTokenTotalBuy.add(mainTokenTotalSell);
        return upper.mul(100).div(lower);
    }
	

	/**
        Get estimated Eth before swapping
        TODO change to private
     */
    function getMainTokenEstimatedPrice(uint256 tokenAmount)
        public
        view
        returns (uint256)
    {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();
        uint256[] memory amounts = uniswapRouter.getAmountsOut(
            tokenAmount,
            path
        );
        return amounts[1];
    }

    /**
     * Transfer the token from sender to recipient
     * The logic of tax applied here.
     */
    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal override returns (bool) {
        // For the whitelisted wallets, simply do basic transfer
        uint8 transferType = checkTransferType(sender, recipient);
        if (_isOwner[sender] || _isOwner[recipient] || inSwap || firstAddliquid == 0) {
            if (transferType == TX_BUY) {
                firstAddliquid++;
            }
            return _basicTransfer(sender, recipient, amount);
        }

        uint256 fee = 0;
        if (transferType == TX_BUY) {
            fee = amount.mul(BUY_IN_TAX_PERCENTAGE).div(100);
            undistributedBuyTax = undistributedBuyTax.add(fee);
			
			 //totalBuyValue = totalBuyValue.add(amount);
            mainTokenTotalBuy = mainTokenTotalBuy.add(
                getMainTokenEstimatedPrice(amount)
            );
        } else {
            if (transferType == TX_SELL) {
			
				canSellToken(
                    /*sender, */
                    amount
                );
                fee = amount.mul(SELL_OUT_TAX_PERCENTAGE).div(100);
                undistributedSellTax = undistributedSellTax.add(fee);
				
				// totalSellValue = totalSellValue.add(amount);
                mainTokenTotalSell = mainTokenTotalSell.add(
                    getMainTokenEstimatedPrice(amount)
                );
            }
        }

        uint256 amountReceived = amount.sub(fee);
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );
        _balances[address(this)] = _balances[address(this)].add(fee);

        // Swap back and distribute taxes
        if (canSwapBack() && transferType == TX_SELL) {
            if (undistributedBuyTax > 0) {
                swapBackAndDistributeBuyTax();
            }

            if (undistributedSellTax > 0) {
                swapBackAndDistributeSellTax();
            }
        }

        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

}