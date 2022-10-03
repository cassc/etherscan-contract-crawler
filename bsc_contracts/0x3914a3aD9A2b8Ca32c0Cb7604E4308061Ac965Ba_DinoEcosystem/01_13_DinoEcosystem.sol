// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./interfaces/IERC20.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IEarn.sol";
import "./libraries/SafeMath.sol";
import "./libraries/SafeERC20.sol";
import "./libraries/Context.sol";
import "./libraries/Auth.sol";
import "hardhat/console.sol";
contract DinoEcosystem is Context, Auth, IERC20 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    //ERC20
    uint8 private _decimals = 18;
    uint256 private _totalSupply = 1_000_000_000 * (10 ** _decimals);
    string private _name = "Dino Ecosystem";
    string private _symbol = "DINO";
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    //Tokenomic Buy
    uint256 public percentBuyEarn = 100;
    uint256 public percentBuyReferral = 100;
    uint256 public percentBuyMarketing = 100;
    uint256 public percentBuyTreasury = 100;
    //Tokenomic Sell
    uint256 public percentSellEarn = 250;
    uint256 public percentSellMarketing = 250;
    uint256 public percentSellReferral = 200;
    uint256 public percentSellTreasury = 200;


    uint256 percentTaxAdditional = 0; 
    uint256 public percentTaxDenominator = 10000;
    uint256 public minimumSwapForWeth = 1;
    uint256 public minimumTokenLeft = 1;
    uint256 public minimumTimeBuy = 1 minutes;
    uint256 public minimumTimeSell = 1 minutes;
    uint256 public maximumAmountPerWallet = _totalSupply;

    bool public isAutoSwapForWeth = true;
    bool public isTaxBuyEnable = true;
    bool public isTaxSellEnable = true;
    bool public isHasMinimumTokenLeft = true;
    bool public isLastTimeBuyEnable = false;
    bool public isLastTimeSellEnable = false;
    bool public isMaxAmountPerWalletEnable = true;
    bool public isEarnEnable = false;
    bool public isSetAutoStakingEnable = true;

    // uint256
    mapping(address => bool) public isExcludeFromFee;
    mapping(address => bool) public isRecipientExcludeFromFee;
    mapping(address => bool) public isExcludeFromTimeBuyLimit;
    mapping(address => bool) public isExcludeFromMaxAmountPerWallet;
    mapping(address => bool) public isExcludeFromReward;
    mapping(address => bool) public isExcludeFromMinimumTokenLeft;
    mapping(address => bool) public isBot;
    mapping(address => address) public referralAddress;
    mapping(address => uint256) public lastTimeBuy;
    mapping(address => uint256) public lastTimeSell;
    
    //address
    address public factoryAddress;
    address public wethAddress;
    address public routerAddress;
    address public earnAddress;
    address public routerEarnAddress = 0x7B52bdE0D53D8Dc78E65e518d30De883400B3e01;
    address public treasuryAddress = 0x06523C7ae9e41b69CD6889973Fc600Fb3513FD07;
    address public marketingAddress = 0x2Ce7369d0Bf30A8FCA0a77376da0de196CB0C7EE;

    address ZERO = 0x0000000000000000000000000000000000000000;
    address DEAD = 0x000000000000000000000000000000000000dEaD;

    mapping(address => bool) public isPair;

    bool inSwap;
    bool inSetShare;

    event ErrorSetShare(string reason);

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier setshare() {
        inSetShare = true;
        _;
        inSetShare = false;
    }

    constructor() Auth(msg.sender) {

        if(block.chainid == 97) routerAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
        else if(block.chainid == 56) routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        else routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        
        wethAddress = IUniswapV2Router02(routerAddress).WETH();
        factoryAddress = IUniswapV2Router02(routerAddress).factory();
        IUniswapV2Factory(factoryAddress).createPair(address(this), wethAddress);
        address pairWETH = IUniswapV2Factory(factoryAddress).getPair(address(this), wethAddress);
        isPair[pairWETH] = true;

        isExcludeFromFee[msg.sender] = true;
        isExcludeFromFee[routerAddress] = true;
        isExcludeFromTimeBuyLimit[msg.sender] = true;
        isExcludeFromMaxAmountPerWallet[msg.sender] = true;
        isExcludeFromMaxAmountPerWallet[routerAddress] = true;
        isExcludeFromMaxAmountPerWallet[pairWETH] = true;
        isExcludeFromTimeBuyLimit[routerAddress] = true;
        isExcludeFromTimeBuyLimit[pairWETH] = true;
        isExcludeFromReward[pairWETH] = true;

        _approve(address(this), routerAddress, _totalSupply);

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }


    receive() external payable {}

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function getOwner() public view virtual override returns (address) {
        return _getOwner();
    }

    function balanceOf(address account)
    public
    view
    virtual
    override
    returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
    public
    virtual
    override
    returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
    public
    view
    virtual
    override
    returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
    public
    virtual
    override
    returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        if (_allowances[sender][msg.sender] != _totalSupply) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
            .sub(amount, "DinoV2: Insufficient Allowance");
        }
        _transfer(sender, recipient, amount);
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue)
    public
    virtual
    returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "DinoV2: decreased allowance below zero"
        );
    unchecked {
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
    }

        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "DinoV2: approve from the zero address");
        require(spender != address(0), "DinoV2: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        
        _beforeTransferToken(sender, recipient, amount);
        
        if (shouldTakeFee(sender, recipient)) {
            _complexTransfer(sender, recipient, amount);
        } else {
            _basicTransfer(sender, recipient, amount);
        }
        
        _afterTransferToken(sender, recipient, amount);
    }

    function _setShareReward(address account) internal setshare{
        IEarn(earnAddress).setShare(account, balanceOf(account));
        
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal {
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        
        emit Transfer(sender, recipient, amount);
    }

    function _complexTransfer(address sender, address recipient, uint256 amount) internal {
        
        uint256 amountTransfer = getAmountTransfer(sender, recipient, amount);

        if (shouldSwapForWeth(sender)) {
            _swapForWeth(_balances[address(this)],amount);
        }

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amountTransfer);
        
        emit Transfer(sender, recipient, amount);
    }

    function shouldSetShare(address _address) internal returns(bool) {
        if(inSwap) return false;
        if(inSetShare) return false;
        if(!isEarnEnable) return false;
        if(_address == earnAddress) return false;
        if(isPair[_address]) return false;
        if(isExcludeFromReward[_address]) return false;
        if(_address == routerAddress) return false;
        return true;
    }

    function getAmountTransfer(address sender, address recipient, uint256 amount) internal returns (uint256){
        uint256 percentTotalTax;
        uint256 amountTax = 0;
        uint256 amountReferral;
        if(isBot[sender] || isBot[recipient]) {
            percentTotalTax = 2500;
        }
        if(percentTotalTax == 0){
            if (!isPair[sender]) {
                if (isLastTimeSellEnable) {
                    if(block.timestamp.sub(lastTimeSell[sender]) < minimumTimeSell) {
                        percentTotalTax = 2500;
                    }
                }
            }
        }
        if(percentTotalTax == 0){
            if (isPair[sender]) {
                if (percentBuyReferral > 0 && referralAddress[recipient] != address(0)) {
                    percentTotalTax = percentBuyTreasury.add(percentBuyMarketing).add(percentBuyEarn);
                    amountReferral = amount.mul(percentBuyReferral).div(percentTaxDenominator);
                } else {
                    percentTotalTax = percentBuyReferral.add(percentBuyTreasury).add(percentBuyMarketing).add(percentBuyEarn);
                }
            } else {
                percentTotalTax = percentSellMarketing.add(percentSellTreasury).add(percentSellReferral).add(percentSellEarn);
            }
        }
        if(percentTotalTax == 0) return amount;

        amountTax = amount.mul(percentTotalTax).div(percentTaxDenominator);

        if (amountReferral > 0) {
            _balances[referralAddress[recipient]] = _balances[referralAddress[recipient]].add(amountReferral);
        }
        _balances[address(this)] = _balances[address(this)].add(amountTax.sub(amountReferral));

        emit Transfer(sender, address(this), amount);
        if(sender != earnAddress && recipient != earnAddress){
            if(isExcludeFromMinimumTokenLeft[sender]) return amount.sub(amountTax).sub(amountReferral);

            if (isHasMinimumTokenLeft && !isPair[sender] && _balances[sender].sub(amount) < minimumTokenLeft) {
                _balances[sender] = _balances[sender].add(minimumTokenLeft);
                return amount.sub(amountTax).sub(amountReferral).sub(minimumTokenLeft);
            } else {
                return amount.sub(amountTax).sub(amountReferral);
            }
        }
    }

    function _beforeTransferToken(address sender, address recipient, uint256 amount) internal {
        

    }

    function _afterTransferToken(address sender, address recipient, uint256 amount) internal {
        lastTimeBuy[recipient] = block.timestamp;
        lastTimeSell[sender] = block.timestamp;

        if (!inSwap && isMaxAmountPerWalletEnable && !isExcludeFromMaxAmountPerWallet[recipient] && sender != earnAddress && recipient != earnAddress) {
            require(_balances[recipient] <= maximumAmountPerWallet, "DinoV2: Maximum Amount Per Wallet is exceed");
        }

        if(shouldSetShare(sender)) _setShareReward(sender);
        if(shouldSetShare(recipient)) _setShareReward(recipient);
    }

    function burn(uint256 amount) external {
        require(_balances[_msgSender()] >= amount, "DinoV2: Insufficient Amount");
        _burn(_msgSender(), amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        _balances[account] = _balances[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, DEAD, amount);
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool){
        if (inSwap) return false;
        if (inSetShare) return false;
        if (sender == earnAddress || recipient == earnAddress) return false;
        if (isExcludeFromFee[sender]) return false;
        if (isRecipientExcludeFromFee[recipient]) return false;
        if (isPair[sender] && !isTaxBuyEnable) return false;
        if (isPair[recipient] && !isTaxSellEnable) return false;
        if (isPair[sender] && recipient == earnAddress) {
            return false;
        }
        return true;
    }

    function shouldSwapForWeth(address sender) internal view returns (bool){
        return (isAutoSwapForWeth && sender != earnAddress && !isPair[sender] && !inSwap && _balances[address(this)] >= minimumSwapForWeth);
    }

    function setIsPair(address pairAddress, bool state) external onlyOwner {
        isPair[pairAddress] = state;
    }

    function setIsBot(address _address, bool state) external onlyOwner {
        isBot[_address] = state;
    }

    function setMinimumTokenLeft(bool state, uint256 _minimumTokenLeft) external onlyOwner {
        require(_minimumTokenLeft <= (25000 * (10 ** _decimals)), "DinoV2: Max Amount Exceed");
        isHasMinimumTokenLeft = state;
        minimumTokenLeft = _minimumTokenLeft;
    }

    function setTaxReceiver(address _marketingAddress, address _treasuryAddress) external onlyOwner {
        marketingAddress = _marketingAddress;
        treasuryAddress = _treasuryAddress;
    }

    function setReferral(address parent, address child) external authorized {
        referralAddress[child] = parent;
    }

    function setrouterEarnAddress(address _routerEarnAddress) external onlyOwner {
        routerEarnAddress = _routerEarnAddress;
        isRecipientExcludeFromFee[_routerEarnAddress] = true;
        isExcludeFromFee[_routerEarnAddress] = true;
        isExcludeFromMaxAmountPerWallet[_routerEarnAddress] = true;
        isExcludeFromTimeBuyLimit[_routerEarnAddress] = true;
        isExcludeFromReward[_routerEarnAddress] = true;
    }

    function setIsTaxEnable(bool taxBuy, bool taxSell) external onlyOwner {
        isTaxBuyEnable = taxBuy;
        isTaxSellEnable = taxSell;
    }

    function setIsExcludeFromFee(address account, bool state) external authorized {
        isExcludeFromFee[account] = state;
    }

    function setIsRecipientExcludeFromFee(address account, bool state) external authorized {
        isRecipientExcludeFromFee[account] = state;
    }

    function setAutoSwapForWeth(bool state, uint256 amount) external onlyOwner {
        require(amount <= _totalSupply, "DinoV2: Amount Swap For Weth max total supply");
        isAutoSwapForWeth = state;
        minimumSwapForWeth = amount;
    }

    function setTimeBuy(bool state, uint256 time) external onlyOwner {
        require(time <= 1 hours, "DinoV2: Maximum Time Buy is 1 hours");
        isLastTimeBuyEnable = state;
        minimumTimeBuy = time;
    }

    function setTimeSell(bool state, uint256 time) external onlyOwner {
        require(time <= 24 hours, "DinoV2: Maximum Time Sell is 1 hours");
        isLastTimeSellEnable = state;
        minimumTimeSell = time;
    }

    function setMaxAmountPerWallet(bool state, uint256 amount) external onlyOwner {
        isMaxAmountPerWalletEnable = state;
        maximumAmountPerWallet = amount;
    }

    function setIsExcludeFromMaxAmountPerWallet(bool state, address account) external onlyOwner {
        isExcludeFromMaxAmountPerWallet[account] = state;
    }

    function setIsExcludeTimeBuy(bool state, address _account) external onlyOwner {
        isExcludeFromTimeBuyLimit[_account] = state;
    }

    function setEarnEnable(bool state) external onlyOwner {
        isEarnEnable = state;
    }

    function setPercentBuy(uint256 _percentEarn, uint256 _percentReferral, uint256 _percentMarketing, uint256 _percentTreasury) external onlyOwner {
        percentBuyEarn = _percentEarn;
        percentBuyReferral = _percentReferral;
        percentBuyMarketing = _percentMarketing;
        percentBuyTreasury = _percentTreasury;
        require(percentBuyEarn + percentBuyReferral + percentBuyMarketing + percentBuyTreasury <= 2500, "DinoV2: Maximum 25%");
    }

    function setPercentSell(uint256 _percentEarn, uint256 _percentMarketing, uint256 _percentReferral, uint256 _percentTreasury) external onlyOwner {
        percentSellEarn = _percentEarn;
        percentSellMarketing = _percentMarketing;
        percentSellReferral = _percentReferral;
        percentSellTreasury = _percentTreasury;
        require(percentSellEarn + percentSellMarketing + percentSellReferral + percentSellTreasury <= 2500, "DinoV2: Maximum 25%");
    }

    function _swapForWeth(uint256 amount,uint256 txAmount) internal swapping {
        if (amount > 0) {
            uint256 totalTax = percentSellMarketing.add(percentSellTreasury).add(percentSellMarketing).add(percentSellEarn);
            //total amount token for liquify

            IUniswapV2Router02 router = IUniswapV2Router02(routerAddress);

            uint256 balanceETHBefore = address(this).balance;

            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = wethAddress;

            uint256[] memory estimate = router.getAmountsOut(amount, path);

            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                amount,
                estimate[1],
                path,
                address(this),
                block.timestamp
            );

            uint256 balanceETHAfter = address(this).balance.sub(balanceETHBefore);

            // //distribute
            uint256 amountMarketing = getAmountPercent(balanceETHAfter, percentSellMarketing, totalTax);
            uint256 amountEarn = getAmountPercent(balanceETHAfter, percentSellEarn, totalTax);
            uint256 amountTreasury = getAmountPercent(balanceETHAfter, percentSellTreasury, totalTax);
            
            if (isEarnEnable) {
                payable(marketingAddress).transfer(amountMarketing);
                payable(treasuryAddress).transfer(amountTreasury);
                if(isEarnEnable) IEarn(routerEarnAddress).deposit{value : amountEarn}(txAmount);
            } else {
                payable(marketingAddress).transfer(amountMarketing.add(amountEarn));
                payable(treasuryAddress).transfer(amountTreasury);
            }
        }
    }

    function getAmountPercent(uint256 baseAmount, uint256 taxAmount, uint256 divider) internal view returns (uint256){
        return baseAmount.mul(taxAmount.mul(percentTaxDenominator).div(divider)).div(percentTaxDenominator);
    }

    function swapForWeth(uint256 txAmount) external onlyOwner {
        _swapForWeth(_balances[address(this)],txAmount);
    }

    function setIsExcludeFromMinimumTokenLeft(address _account, bool state) external onlyOwner{
        isExcludeFromMinimumTokenLeft[_account] = state;
    }

    function claimWeth(address to, uint256 amount) external onlyOwner {
        payable(to).transfer(amount);
    }

    function claimFromContract(address _tokenAddress, address to, uint256 amount) external onlyOwner {
        IERC20(_tokenAddress).safeTransfer(to, amount);
    }

    function setEarnAddress(address _address) external onlyOwner {
        earnAddress = _address;
        isExcludeFromFee[_address] = true;
        isRecipientExcludeFromFee[_address] = true;
        isExcludeFromMaxAmountPerWallet[_address] = true;
        isExcludeFromTimeBuyLimit[_address] = true;
        isExcludeFromReward[_address] = true;
    }

    function setIsExcludeFromReward(address _address, bool state) external onlyOwner {
        isExcludeFromReward[_address] = state;
    }
}