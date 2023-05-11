/**
 *Submitted for verification at BscScan.com on 2023-05-10
*/

// SPDX-License-Identifier: MIT

// Tg: https://t.me/PopeyeBSC

pragma solidity 0.8.19;

interface IBEP20 {
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

interface IPancakeFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IPancakeRouter {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

}

abstract contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Popeye is IBEP20, Ownable {

    mapping (address => uint) private _balances;
    mapping (address => mapping (address => uint)) private _allowances;
    mapping(address => bool) private excludedFromLimits;
    mapping(address => bool) public excludedFromFees;
    mapping(address=>bool) public isAMM;
    
    string private constant _name = 'Popeye';
    string private constant _symbol = 'Popeye';

    uint8 private constant _decimals = 18;

    uint public constant InitialSupply= 1 * 1e6 * 10**_decimals;
    uint private _circulatingSupply=InitialSupply;
    uint public buyTax = 100;
    uint public sellTax = 100;
    uint public transferTax = 0;
    uint public projectTax=700;
    uint public swapTreshold=8;
    uint public LaunchTimestamp;
    uint public devShare=50;
    uint public marketingShare=50;
    uint constant TAX_DENOMINATOR=1000;
    uint constant MAXTAXDENOMINATOR=10;

    uint256 public maxWalletBalance;
    uint256 public maxTransactionAmount;

    bool private _isSwappingContractModifier;

    IPancakeRouter private  _pancakeRouter;

    address private _pancakePairAddress;
    address public marketingWallet;
    address public devWallet;
    address public constant burnWallet = 0x000000000000000000000000000000000000dEaD;
    address private constant PancakeRouter=0x10ED43C718714eb63d5aA57B78B54704E256024E;

    modifier lockTheSwap {
        _isSwappingContractModifier = true;
        _;
        _isSwappingContractModifier = false;
    }

    constructor () {
        marketingWallet=0x143f0Eb3DbB823856c31E14dB34CCBC442B71bDa;
        devWallet=0x50f0dDb79A040c33f82062c58e8EbC0856081eD0;
        uint devwalletBalance=_circulatingSupply;
        _balances[devWallet] = devwalletBalance;
        emit Transfer(address(0), devWallet, devwalletBalance);

        _pancakeRouter = IPancakeRouter(PancakeRouter);
        _pancakePairAddress = IPancakeFactory(_pancakeRouter.factory()).createPair(address(this), _pancakeRouter.WETH());
        isAMM[_pancakePairAddress]=true;
    
        excludedFromFees[devWallet]=true;
        excludedFromFees[marketingWallet]=true;
        excludedFromFees[PancakeRouter]=true;
        excludedFromFees[address(this)]=true;
        excludedFromLimits[devWallet] = true;
        excludedFromLimits[marketingWallet] = true;
        excludedFromLimits[burnWallet] = true;
        excludedFromLimits[address(this)] = true;
        transferOwnership(devWallet);
    }

    function ChangeMarketingWallet(address newWallet) external onlyOwner{
        marketingWallet=newWallet;
    }
    function ChangeDevWallet(address newWallet) public onlyOwner{
        devWallet=newWallet;
    }
    function SetMarketingAndDevShare(uint _devShare, uint _marketingShare) public onlyOwner{
        require(_devShare+_marketingShare<=100);
        devShare=_devShare;
        marketingShare=_marketingShare;
    }
    function setMaxWalletBalancePercent(uint256 percent) external onlyOwner {
        require(percent >= 10, "min 1%");
        require(percent <= 1000, "max 100%");
        maxWalletBalance = InitialSupply * percent / 1000;
    }
    function setMaxTransactionAmount(uint256 percent) public onlyOwner {
        require(percent >= 25, "min 0.25%");
        require(percent <= 10000, "max 100%");
        maxTransactionAmount = InitialSupply * percent / 10000;
    }
    function _transfer(address sender, address recipient, uint amount) private{
        require(sender != address(0), "Transfer from zero");
        require(recipient != address(0), "Transfer to zero");
        if(excludedFromFees[sender] || excludedFromFees[recipient])
            _feelessTransfer(sender, recipient, amount);
        else { 
            require(LaunchTimestamp>0,"trading not yet enabled");
            _taxedTransfer(sender,recipient,amount);                  
        }
    }
    function _taxedTransfer(address sender, address recipient, uint amount) private{
        uint senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");
        bool excludedAccount = excludedFromLimits[sender] || excludedFromLimits[recipient];
        if (
            isAMM[sender] &&
            !excludedAccount
        ) {
            require(
                amount <= maxTransactionAmount,
                "Transfer amount exceeds the maxTxAmount."
            );
            uint256 contractBalanceRecepient = balanceOf(recipient);
            require(
                contractBalanceRecepient + amount <= maxWalletBalance,
                "Exceeds maximum wallet token amount."
            );
        } else if (
            isAMM[recipient] &&
            !excludedAccount
        ) {
            require(amount <= maxTransactionAmount, "Sell transfer amount exceeds the maxSellTransactionAmount.");
        }

        bool isBuy=isAMM[sender];
        bool isSell=isAMM[recipient];
        uint tax;
        if(isSell){
            tax=sellTax;
        } else if(isBuy){
            tax=buyTax;
        } else tax=transferTax;

        if((sender!=_pancakePairAddress)&&(!_isSwappingContractModifier))
            _swapContractToken(false);

        uint contractToken=_calculateFee(amount, tax, projectTax);
        uint taxedAmount=amount-contractToken;
        _balances[sender]-=amount;
        _balances[address(this)] += contractToken;
        _balances[recipient]+=taxedAmount;
        emit Transfer(sender,recipient,taxedAmount);
    }
    function _calculateFee(uint amount, uint tax, uint taxPercent) private pure returns (uint) {
        return (amount*tax*taxPercent) / (TAX_DENOMINATOR*TAX_DENOMINATOR);
    }
    function _feelessTransfer(address sender, address recipient, uint amount) private{
        uint senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");
        _balances[sender]-=amount;
        _balances[recipient]+=amount;      
        emit Transfer(sender,recipient,amount);
    }
    function setSwapTreshold(uint newSwapTresholdPermille) public onlyOwner{
        require(newSwapTresholdPermille<=10);
        swapTreshold=newSwapTresholdPermille;
    }
    function SetTaxes(uint buy, uint sell, uint transfer_, uint project) public onlyOwner{
        uint maxTax=TAX_DENOMINATOR/MAXTAXDENOMINATOR;
        require(buy<=maxTax&&sell<=maxTax&&transfer_<=maxTax,"Tax exceeds maxTax");
        require(project==TAX_DENOMINATOR,"Taxes don't add up to denominator");
        buyTax=buy;
        sellTax=sell;
        transferTax=transfer_;
        projectTax=project;
    }
    function _swapContractToken(bool ignoreLimits) private lockTheSwap{
        uint contractBalance=_balances[address(this)];
        uint totalTax=projectTax;
        uint tokenToSwap=_balances[_pancakePairAddress]*swapTreshold/1000;
        if(totalTax==0)return;
        if(ignoreLimits)
            tokenToSwap=_balances[address(this)];
        else if(contractBalance<tokenToSwap)
            return;

        uint tokenForProject= tokenToSwap;
        uint swapToken=tokenForProject;
        _swapTokenForBNB(swapToken);

        uint marketbalance=address(this).balance * marketingShare/100;
        uint devbalance=address(this).balance * devShare/100;
        (bool marketing,)=marketingWallet.call{value:marketbalance}("");
        marketing=true;
        (bool dev,)=devWallet.call{value:devbalance}("");
        dev=true;
    }
    function _swapTokenForBNB(uint amount) private {
        _approve(address(this), address(_pancakeRouter), amount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _pancakeRouter.WETH();

        try _pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        ){}
        catch{}
    }
    function getBurnedTokens() external view returns(uint){
        return (InitialSupply-_circulatingSupply)+_balances[address(0xdead)];
    }
    function getCirculatingSupply() external view returns(uint){
        return (InitialSupply-_balances[address(0xdead)]);
    }
    function SetAMM(address AMM, bool Add) external onlyOwner{
        require(AMM!=_pancakePairAddress,"can't change pancake");
        isAMM[AMM]=Add;
    }
    function ExcludeAccountFromFees(address account, bool exclude) public onlyOwner{
        require(account!=address(this),"can't Include the contract");
        excludedFromFees[account]=exclude;
    }
    function setExcludedAccountFromLimits(address account, bool exclude) public onlyOwner{
        excludedFromLimits[account]=exclude;
    }
    function isExcludedFromLimits(address account) public view returns(bool) {
        return excludedFromLimits[account];
    }
    function SetupEnableTrading() external onlyOwner{
        require(LaunchTimestamp==0,"AlreadyLaunched");
        LaunchTimestamp=block.timestamp;
        maxWalletBalance = InitialSupply * 2 / 100;
        maxTransactionAmount = InitialSupply * 2 / 100;
    }

    receive() external payable {}

    function getOwner() external view override returns (address) {return owner();}
    function name() external pure override returns (string memory) {return _name;}
    function symbol() external pure override returns (string memory) {return _symbol;}
    function decimals() external pure override returns (uint8) {return _decimals;}
    function totalSupply() external view override returns (uint) {return _circulatingSupply;}
    function balanceOf(address account) public view override returns (uint) {return _balances[account];}
    function allowance(address _owner, address spender) external view override returns (uint) {return _allowances[_owner][spender];}
    function transfer(address recipient, uint amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function approve(address spender, uint amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function _approve(address owner, address spender, uint amount) private {
        require(owner != address(0), "Approve from zero");
        require(spender != address(0), "Approve to zero");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function transferFrom(address sender, address recipient, uint amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        uint currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "Transfer > allowance");
        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }
    function increaseAllowance(address spender, uint addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint subtractedValue) external returns (bool) {
        uint currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "<0 allowance");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

}