/**
 *Submitted for verification at Etherscan.io on 2023-07-17
*/

/**
Telegram: https://t.me/mayhemportal
Twitter: https://twitter.com/Mayhem_ERC
Website: https://projectmayhem.agency/


Introducing "Project Mayhem" - a captivating crypto endeavor that lets you step into the shoes of a corrupt politician, wielding unparalleled power and influence. 
In a world where politicians have long exploited their positions to manipulate tax systems and wreak havoc on economies, it's time for you to embrace the dark side.

Project Mayhem unveils a collection of NFTs like no other. These exclusive tokens represent notorious politicians, embodying their unscrupulous tactics, 
manipulative strategies, and their ability to control the financial realm.

But here's where the allure intensifies. As the owner of a politician NFT, you gain the exhilarating privilege of molding the tax landscape. 
However, there's a twist – to exercise your authority and alter the state of ERC20 taxes, you must burn your NFT, symbolizing the sacrifice of your corrupt alter ego.

Picture yourself at the epicenter of a clandestine network, where you can bend the rules and shape tax policies to your advantage. By willingly relinquishing your NFT, 
you unleash a profound transformation, exerting your influence over the ERC20 native currency that fuels Project Mayhem.

Gone are the days of being at the mercy of politicians. Project Mayhem empowers you to embrace your inner manipulator and mold the financial destiny of the ecosystem. 
Through the act of burning your NFT, you transcend conventional boundaries and cement your role as the ultimate corrupt politician, 
leaving an indelible mark on the tax landscape.

Seize the opportunity to indulge in the allure of power, to manipulate and subvert the system to your advantage. 
Project Mayhem beckons you to embrace the darkness within and exploit the very mechanisms that have long plagued society. 
Are you prepared to embrace your alter ego and embark on a journey where corruption knows no bounds? The path to power and manipulation awaits your command.
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IEnactMayhem {
    function setBuyFeeAndCollectionAddress(uint256 _marketingFee, address collectionAddress) external;
    function setSellFeeAndCollectionAddress(uint256 newFee, address collectionAddress) external;
    function setBuyFee(uint256 newFee) external;
    function setSellFee(uint256 newFee) external;
    function setCollectionAddress(address collectionAddress) external;
    function setLiqBuyFee(uint256 newFee) external;
    function setLiqSellFee(uint256 newFee) external;
    function setBuyBuyBackFee(uint256 newFee) external;
    function setSellBuyBackFee(uint256 newFee) external;
    function killdozer(uint256 buyMarketing, uint256 sellMarketing, uint256 buyLiquidity, uint256 sellLiquidity, uint256 buyBuyBack, uint256 sellBuyBack) external;
}

abstract contract Ownable {
    address internal owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function Ownershiplock(uint256 time) public virtual onlyOwner {
        _previousOwner = owner;
        owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(owner, address(0));
    }

    function Ownershipunlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked");
        emit OwnershipTransferred(owner, _previousOwner);
        owner = _previousOwner;
    }
}

/**
 * Router Interfaces
 */

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

/**
 * Contract Code
 */

contract Mayhem is IERC20, Ownable, IEnactMayhem {

    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "Project Mayhem"; // 
    string constant _symbol = "Mayhem"; // 
    uint8 constant _decimals = 9;
    uint256 _totalSupply = 1 * 10**9 * 10**_decimals;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isTxLimitExempt;
    
    // Detailed Fees
    uint256 public liqFee;
    uint256 public marketingFee;
    uint256 public buybackFee;
    uint256 public totalFee;
    address public erc1155Contract;

    uint256 public BuyliquidityFee    = 10;
    uint256 public BuymarketingFee    = 10;
    uint256 public BuybuybackFee      = 10;
    uint256 public BuytotalFee        = BuyliquidityFee + BuymarketingFee + BuybuybackFee;

    uint256 public SellliquidityFee    = 10;
    uint256 public SellmarketingFee    = 10;
    uint256 public SellbuybackFee      = 10;
    uint256 public SelltotalFee        = SellliquidityFee + SellmarketingFee + SellbuybackFee;

    // Max wallet & Transaction
    uint256 public _maxBuyTxAmount = _totalSupply / (100) * (2); // 2%
    uint256 public _maxSellTxAmount = _totalSupply / (100) * (2); // 2%
    uint256 public _maxWalletToken = _totalSupply / (100) * (2); // 2%

    // Fees receivers
    address public autoLiquidityReceiver = 0x000000000000000000000000000000000000dEaD;
    address public feeCollectionAddress = 0xBF70750c72559D641eBAe083F69E54e8603a2d9a;
    address public buybackFeeReceiver = 0xBF70750c72559D641eBAe083F69E54e8603a2d9a;
	address public stucketh = 0xBF70750c72559D641eBAe083F69E54e8603a2d9a;

    IDEXRouter public router;
    address public pair;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 1000 * 1; // 0.1%
    uint256 public maxSwapSize = _totalSupply / 100 * 1; //1%
    uint256 public tokensToSell;

    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    modifier onlyOwnerOrAuthorized() {
        require(msg.sender == owner || msg.sender == address(erc1155Contract), "Unauthorized");
        _;
    }
  
    constructor () Ownable(msg.sender) {
        owner = msg.sender;
        erc1155Contract = address(0x0);

        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;


        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;
        feeCollectionAddress = address(0x0);

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable { }
      
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        if(sender == pair){
            buyFees();
        }

        if(recipient == pair){
            sellFees();
        }

        if (sender != owner && recipient != address(this) && recipient != address(DEAD) && recipient != pair || isTxLimitExempt[recipient]){
            uint256 heldTokens = balanceOf(recipient);
            require((heldTokens + amount) <= _maxWalletToken,"Total Holding is currently limited, you can not buy that much.");}

        // Checks max transaction limit
        if(sender == pair){
            require(amount <= _maxBuyTxAmount || isTxLimitExempt[recipient], "TX Limit Exceeded");
        }
        
        if(recipient == pair){
            require(amount <= _maxSellTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
        }
        //Exchange tokens
        if(shouldSwapBack()){ swapBack(); }

        _balances[sender] = _balances[sender] - amount;

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(recipient, amount) : amount;
        _balances[recipient] = _balances[recipient] + amountReceived;

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + (amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    // Internal Functions
    function buyFees() internal{
        liqFee    = BuyliquidityFee;
        marketingFee    = BuymarketingFee;
        buybackFee      = BuybuybackFee;
        totalFee        = BuytotalFee;
    }

    function sellFees() internal{
        liqFee    = SellliquidityFee;
        marketingFee    = SellmarketingFee;
        buybackFee      = SellbuybackFee;
        totalFee        = SelltotalFee;
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function takeFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount / 100 * (totalFee);

        _balances[address(this)] = _balances[address(this)] + (feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount - (feeAmount);
    }
  
    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 contractTokenBalance = balanceOf(address(this));
        if(contractTokenBalance >= maxSwapSize){
            tokensToSell = maxSwapSize;            
        }
        else{
            tokensToSell = contractTokenBalance;
        }

        uint256 amountToLiquify = tokensToSell / (totalFee) * (liqFee) / (2);
        uint256 amountToSwap = tokensToSell - (amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance - (balanceBefore);

        uint256 totalETHFee = totalFee - (liqFee / (2));
        
        uint256 amountETHLiquidity = amountETH * (liqFee) / (totalETHFee) / (2);
        uint256 amountETHbuyback = amountETH * (buybackFee) / (totalETHFee);
        uint256 amountETHMarketing = amountETH * (marketingFee) / (totalETHFee);

        (bool MarketingSuccess,) = payable(feeCollectionAddress).call{value: amountETHMarketing, gas: 30000}("");
        require(MarketingSuccess, "receiver rejected ETH transfer");
        (bool buybackSuccess,) = payable(buybackFeeReceiver).call{value: amountETHbuyback, gas: 30000}("");
        require(buybackSuccess, "receiver rejected ETH transfer");

        addLiquidity(amountToLiquify, amountETHLiquidity);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
    if(tokenAmount > 0){
            router.addLiquidityETH{value: ethAmount}(
                address(this),
                tokenAmount,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(ethAmount, tokenAmount);
        }
    }

    // External Functions
    function checkSwapThreshold() external view returns (uint256) {
        return swapThreshold;
    }
    
    function checkMaxWalletToken() external view returns (uint256) {
        return _maxWalletToken;
    }
    
    function checkMaxBuyTxAmount() external view returns (uint256) {
        return _maxBuyTxAmount;
    }
    
    function checkMaxSellTxAmount() external view returns (uint256) {
        return _maxSellTxAmount;
    }

    function isNotInSwap() external view returns (bool) {
        return !inSwap;
    }

    // Only Owner allowed
    function setBuyFees(uint256 _liquidityFee, uint256 _buybackFee, uint256 _marketingFee) external onlyOwner {
		require (_liquidityFee <= 5, "Fee can't exceed 5%");
		require (_buybackFee <= 5, "Fee can't exceed 5%");
		require (_marketingFee <= 5, "Fee can't exceed 5%");
        BuyliquidityFee = _liquidityFee;
        BuybuybackFee = _buybackFee;
        BuymarketingFee = _marketingFee;
        BuytotalFee = _liquidityFee + (_buybackFee) + (_marketingFee);
    }


    // Set functions on receivers and taxes only callable by owner or NFT


    function setBuyFeeAndCollectionAddress(uint256 _marketingFee, address collectionAddress) external onlyOwnerOrAuthorized {
		require (_marketingFee <= 5, "Fee can't exceed 5%");
        BuymarketingFee = _marketingFee;
        feeCollectionAddress = collectionAddress;
        BuytotalFee = BuyliquidityFee + BuymarketingFee + BuybuybackFee;
    }

    function setBuyFee(uint256 _marketingFee) external onlyOwnerOrAuthorized {
		require (_marketingFee <= 5, "Fee can't exceed 5%");
        BuymarketingFee = _marketingFee;
        BuytotalFee = BuyliquidityFee + BuymarketingFee + BuybuybackFee;
    }

    function setSellFee(uint256 _marketingFee) external onlyOwnerOrAuthorized {
		require (_marketingFee <= 5, "Fee can't exceed 5%");
        SellmarketingFee = _marketingFee;
        SelltotalFee = SellliquidityFee + SellmarketingFee + SellbuybackFee;
    }

    function setSellFeeAndCollectionAddress(uint256 _marketingFee, address collectionAddress) external onlyOwnerOrAuthorized {
		require (_marketingFee <= 5, "Fee can't exceed 5%");
        SellmarketingFee = _marketingFee;
        feeCollectionAddress = collectionAddress;
        SelltotalFee = SellliquidityFee + SellmarketingFee + SellbuybackFee;
    }

    function setLiqBuyFee(uint256 newFee) external onlyOwnerOrAuthorized {
		require (newFee <= 5, "Fee can't exceed 5%");
        BuyliquidityFee = newFee;
        BuytotalFee = BuyliquidityFee + BuymarketingFee + BuybuybackFee;
    }

    function setLiqSellFee(uint256 newFee) external onlyOwnerOrAuthorized {
		require (newFee <= 5, "Fee can't exceed 5%");
        SellliquidityFee = newFee;
        SelltotalFee = SellliquidityFee + SellmarketingFee + SellbuybackFee;
    }

    function setBuyBuyBackFee(uint256 newFee) external onlyOwnerOrAuthorized {
		require (newFee <= 5, "Fee can't exceed 5%");
        BuybuybackFee = newFee;
        BuytotalFee = BuyliquidityFee + BuymarketingFee + BuybuybackFee;
    }

    function setSellBuyBackFee(uint256 newFee) external onlyOwnerOrAuthorized {
		require (newFee <= 5, "Fee can't exceed 5%");
        SellbuybackFee = newFee;
        SelltotalFee = SellliquidityFee + SellmarketingFee + SellbuybackFee;
    }

    function setCollectionAddress(address collectionAddress) external onlyOwnerOrAuthorized {
        feeCollectionAddress = collectionAddress;
    }

    function setERC1155Contract(address _erc1155Contract) external onlyOwnerOrAuthorized {
        erc1155Contract = _erc1155Contract;
    }

    function killdozer(uint256 buyMarketing, uint256 sellMarketing, uint256 buyLiquidity, uint256 sellLiquidity, uint256 buyBuyBack, uint256 sellBuyBack) external onlyOwnerOrAuthorized {
		require (buyMarketing <= 5, "Fee can't exceed 5%");
		require (sellMarketing <= 5, "Fee can't exceed 5%");
		require (buyLiquidity <= 5, "Fee can't exceed 5%");
		require (sellLiquidity <= 5, "Fee can't exceed 5%");
		require (buyBuyBack <= 5, "Fee can't exceed 5%");
		require (sellBuyBack <= 5, "Fee can't exceed 5%");
        BuymarketingFee = buyMarketing;
        SellmarketingFee = sellMarketing;
        BuyliquidityFee = buyLiquidity;
        SellliquidityFee = sellLiquidity;
        BuybuybackFee = buyBuyBack;
        SellbuybackFee = sellBuyBack;
        BuytotalFee = BuyliquidityFee + BuymarketingFee + BuybuybackFee;
        SelltotalFee = SellliquidityFee + SellmarketingFee + SellbuybackFee;
    }

    function setSellFees(uint256 _liquidityFee, uint256 _buybackFee, uint256 _marketingFee) external onlyOwner {
		require (_liquidityFee <= 5, "Fee can't exceed 5%");
		require (_buybackFee <= 5, "Fee can't exceed 5%");
		require (_marketingFee <= 5, "Fee can't exceed 5%");
        SellliquidityFee = _liquidityFee;
        SellbuybackFee = _buybackFee;
        SellmarketingFee = _marketingFee;
        SelltotalFee = _liquidityFee + (_buybackFee) + (_marketingFee);
    }
    
    function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver, address _buybackFeeReceiver) external onlyOwner {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        feeCollectionAddress = _marketingFeeReceiver;
        buybackFeeReceiver = _buybackFeeReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint256 _percentage_min_base10000, uint256 _percentage_max_base10000) external onlyOwner {
        swapEnabled = _enabled;
        swapThreshold = _totalSupply / (10000) * (_percentage_min_base10000);
        maxSwapSize = _totalSupply / (10000) * (_percentage_max_base10000);
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }
    
    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }
	
    function ownerSetLimits(uint256 maxBuyTXPercentage_base1000, uint256 maxSellTXPercentage_base1000, uint256 maxWallPercent_base1000) external onlyOwner {
        require(maxBuyTXPercentage_base1000 >=5, "Cannot set Max Transaction below 0.5%");
		require(maxSellTXPercentage_base1000 >=5, "Cannot set Max Transaction below 0.5%");
        require(maxWallPercent_base1000 >=10, "Cannot set Max Wallet below 1%");
        _maxWalletToken = _totalSupply / (1000) * (maxWallPercent_base1000);
		_maxSellTxAmount = _totalSupply / (1000) * (maxSellTXPercentage_base1000);
		_maxBuyTxAmount = _totalSupply / (1000) * (maxBuyTXPercentage_base1000);
    }
	
    function setMaxWalletPercent_base1000(uint256 maxWallPercent_base1000) external onlyOwner {
        require(maxWallPercent_base1000 >=10, "Cannot set Max Wallet below 1%");
        _maxWalletToken = _totalSupply / (1000) * (maxWallPercent_base1000);
    }

    function setMaxBuyTxPercent_base1000(uint256 maxBuyTXPercentage_base1000) external onlyOwner {
		require(maxBuyTXPercentage_base1000 >=5, "Cannot set Max Transaction below 0.5%");
        _maxBuyTxAmount = _totalSupply / (1000) * (maxBuyTXPercentage_base1000);
    }

    function setMaxSellTxPercent_base1000(uint256 maxSellTXPercentage_base1000) external onlyOwner {
		require(maxSellTXPercentage_base1000 >=5, "Cannot set Max Transaction below 0.5%");
        _maxSellTxAmount = _totalSupply / (1000) * (maxSellTXPercentage_base1000);
    }

    // Stuck Balances Functions
    function rescueToken(address tokenAddress, uint256 tokens) public returns (bool success) {
        return IERC20(tokenAddress).transfer(stucketh, tokens);
    }

    function clearStuckBalance(uint256 amountPercentage) external {
        uint256 amountETH = address(this).balance;
        payable(stucketh).transfer(amountETH * amountPercentage / 100);
    }

    event AutoLiquify(uint256 amountETH, uint256 amountTokens);

}