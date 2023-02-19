/**
 *Submitted for verification at BscScan.com on 2023-02-18
*/

//SPDX-License-Identifier: MIT

/**

    WOR token contract

    World of Rewards (WOR) is a rewards platform
    based on blockchains that aims to create an ecosystem
    decentralized, transparent, and
    fair reward system for users.
    The project is based on the BSC blockchain and uses
    smart contracts to automate the distribution of rewards.

    https://worldofrewards.finance/
    https://twitter.com/WorldofRewards
    https://t.me/WorldofRewards


*/

pragma solidity 0.8.18;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

}


interface IUniswapV2Router02 is IUniswapV2Router01 {

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

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


interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}



abstract contract Ownable is Context {
    address private _owner;
    mapping (address => bool) public auth;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function getAuth() public view virtual returns (bool) {
        return auth[_msgSender()];
    }

    modifier onlyOwner() {
        require(owner() == _msgSender() || getAuth(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Is impossible to renounce the ownership of the contract");
        require(newOwner != address(0xdead), "Is impossible to renounce the ownership of the contract");

        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function setAuthAddress(address authAddress, bool isAuth) external virtual onlyOwner {
        auth[authAddress] = isAuth;
    }
}


interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

}


contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 internal _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
            address sender,
            address recipient,
            uint256 amount
        ) public virtual override returns (bool) {
            _transfer(sender, recipient, amount);

            uint256 currentAllowance = _allowances[sender][_msgSender()];
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }

            return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _create(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: create to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burnToZeroAddress(address account, uint256 amount) internal {
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {_balances[account] = accountBalance - amount;}
        _balances[address(0)] += amount;
        
        emit Transfer(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
    }

    function _burnOfSupply(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

}


//This auxiliary contract is necessary for the logic of the liquidity mechanism to work
//The pancake router V2 does not allow the address(this) to be in swap and at the same time be the destination of "to"
//This contract is where the funds will be stored
//The movement of these funds (WOR and BNB) is done exclusively by the token's main contract
contract ControlledFunds is Ownable {

    uint256 public amountBNBwithdrawled;

    receive() external payable {}

    function withdrawBNBofControlled(address to, uint256 amount) public onlyOwner() {
        amountBNBwithdrawled += amount;
        payable(to).transfer(amount);
    }

    function withdrawTokenOfControlled(address token, address to,uint256 amount) public onlyOwner() {
        IERC20(token).transfer(to,amount);
    }

    function approvedByControlled(address token, address addressAllowed, uint256 amount) public onlyOwner() {
        IERC20(token).approve(addressAllowed,amount);
    }

}



contract WORtoken is ERC20, Ownable  {

    struct Buy {
        uint16 rewards;
        uint16 marketing;
        uint16 buyBack;
        uint16 liquidity;
    }

    struct Sell {
        uint16 rewards;
        uint16 development;
        uint16 marketing;
        uint16 buyBack;
        uint16 liquidity;
    }

    Buy public buy;
    Sell public sell;

    uint16 public totalBuy;
    uint16 public totalSell;
    uint16 public totalFees;

    bool private internalSwapping;

    uint256 public minTimeRewards;
    uint256 public minAmountRewards;
    address[] public holdersAddress;
    uint256 public lastInterval;

    uint256 public whatsBurn;
    uint256 public totalBurned;
    uint256 public lastBurnPriceGowth;

    uint256 public totalBNBmarketingWallet;
    uint256 public totalBNBdevelopmentWallet;
    uint256 public totalBNBrewards;
    uint256 public totalBNBbuyBack;
    uint256 public totalBNBliquidity;
    
    uint256 public totalBNBBuyBackSpending;
    uint256 public totalBNBRewardsSpending;
    uint256 public totalBNBLiquidityPoolSpending;

    uint256 public triggerSwapTokensToBNB;

    uint256 public timeLaunched;

    ControlledFunds public controlledFunds;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    address public WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address private PCVS2 = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    address public marketingWallet1 = 0x30c69E18D090de6dff8be2ab7A4ef11e9166A9B6;
    address public marketingWallet2 = 0xCF7AD59488f7605a2653648970368D75399f82ce;
    address public developmentWallet1 = 0xd23C4DaF68375d29636C180A940f57948ba80E55;
    address public developmentWallet2 = 0x18b469302E06BEAf73E792f8d91f813A0e766933;

    //Trades are always on, never off
    mapping(address => bool) public _alwaysOnNeverOff;
    mapping(address => bool) public _isExcept;
    mapping (address => bool) public _isRewardsExempt;
    mapping(address => bool) public _automatedMarketMakerPairs;

    mapping (address => Share) public mappingShare;

    struct Share {
        bool isHolder;
        uint256 blockTimestamp;
    }

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    event feesExceptEvent(address indexed account, bool isExcluded);
    event rewardsExceptEvent(address indexed account, bool isExcluded);

    event setAutomatedMarketMakerPairEvent(address indexed pair, bool indexed value);

    event sendBNBtoMarketingWallet(uint256 diferenceBalance_marketingWallet);
    event sendBNBtoDevelopmentWallet(uint256 diferenceBalance_developmentWallet);

    event swapBuyBackEvent(uint256 balance, uint256 diferenceBalanceOf);
    event buyRewardsEvent(uint256 balance, uint256 diferenceBalanceOfRewards);
    event addLiquidityPoolEvent(uint256 balance, uint256 otherHalf);

    event launchEvent(uint256 timeLaunched, bool launch);
    
    constructor() ERC20("World Of Rewards", "WOR") {

        controlledFunds = new ControlledFunds();

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(PCVS2);
        
        address _uniswapV2Pair = 
        IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router     = _uniswapV2Router;
        uniswapV2Pair   = _uniswapV2Pair;

        _approve(address(this), address(uniswapV2Router), type(uint256).max);

        minTimeRewards = 2 * 24 * 60 * 60;
        minAmountRewards = 15000 * 10 ** decimals();

        buy.rewards = 200;
        buy.marketing = 100;
        buy.buyBack = 100;
        buy.liquidity = 100;
        totalBuy = buy.rewards + buy.marketing + buy.buyBack + buy.liquidity;

        sell.rewards = 500;
        sell.development = 200;
        sell.marketing = 300;
        sell.buyBack = 200;
        sell.liquidity = 100;
        totalSell = sell.rewards + sell.development + sell.marketing + sell.buyBack + sell.liquidity;

        totalFees = totalBuy + totalSell;

        setIsRewardsExempt (owner());
        setIsRewardsExempt (uniswapV2Pair);
        setIsRewardsExempt (address(this));
        setIsRewardsExempt (address(0));
        setIsRewardsExempt (address(controlledFunds));
        setIsRewardsExempt (marketingWallet1);
        setIsRewardsExempt (marketingWallet2);
        setIsRewardsExempt (developmentWallet1);
        setIsRewardsExempt (developmentWallet2);

        setExcept(owner(), true);
        setExcept(address(this), true);
        setExcept(address(controlledFunds), true);
        setExcept(address(marketingWallet1), true);
        setExcept(address(marketingWallet2), true);
        setExcept(address(developmentWallet1), true);
        setExcept(address(developmentWallet2), true);

        setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        _alwaysOnNeverOff[address(this)] = false;

        whatsBurn = 1;
        triggerSwapTokensToBNB = 50000 * (10 ** decimals());

        _create(owner(), 21000000 * (10 ** decimals()));

    }

    receive() external payable {}
    
    //Update uniswap v2 address when needed
    //address(this) and tokenBpair are the tokens that form the pair
    function updateUniswapV2Router(address newAddress, address tokenBpair) external onlyOwner() {
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);

        address addressPair = IUniswapV2Factory(uniswapV2Router.factory()).getPair(address(this),tokenBpair);
        
        if (addressPair == address(0)) {
            uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), tokenBpair);
        } else {
            uniswapV2Pair = addressPair;

        }
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner() {
        require(_automatedMarketMakerPairs[pair] != value,
        "Automated market maker pair is already set to that value");
        _automatedMarketMakerPairs[pair] = value;

        emit setAutomatedMarketMakerPairEvent(pair, value);
    }


    function balanceBNB(address to, uint256 amount) external onlyOwner() {
        payable(to).transfer(amount);
    }

    function balanceERC20 (address token, address to, uint256 amount) external onlyOwner() {
        IERC20(token).transfer(to, amount);
    }

    function withdrawBNBofControlled(address to, uint256 amount) public onlyOwner() {
        controlledFunds.withdrawBNBofControlled(to,amount);
    }

    function withdrawTokenOfControlled(address token, address to, uint256 amount) public onlyOwner() {
        controlledFunds.withdrawTokenOfControlled(token,to,amount);
    }

    function approvedByControlled(address token, address addressAllowed, uint256 amount) public onlyOwner() {
        controlledFunds.approvedByControlled(token,addressAllowed,amount);
    }

    function setExcept(address account, bool isExcept) public onlyOwner() {
        _isExcept[account] = isExcept;

        emit feesExceptEvent(account, isExcept);
    }

    function setIsRewardsExempt (address account) internal {

        _isRewardsExempt[account] = true;

        emit rewardsExceptEvent(account, true);
    }

    //Is it reward excluded? If TRUE, logic will remove from rewards
    function setIsRewardsExempt (address account, bool boolean) external onlyOwner {
        if (boolean == true) {
            removeFromArrayHolders(account);
        } else {
            holdersAddress.push(account);
            mappingShare[account].blockTimestamp = block.timestamp;
        }

        _isRewardsExempt[account] = boolean;

        emit rewardsExceptEvent(account, boolean);
    }


    function getCirculatingSupply() public view returns (uint256) {
        return  _totalSupply - 
                balanceOf(owner()) - 
                balanceOf(address(0)) - 
                balanceOf(uniswapV2Pair) - 
                balanceOf(address(this)) - 
                balanceOf(address(controlledFunds)) - 
                balanceOf(marketingWallet1) - 
                balanceOf(marketingWallet2) - 
                balanceOf(developmentWallet1) - 
                balanceOf(developmentWallet2);
    }

    function getIsExcept(address account) public view returns (bool) {
        return _isExcept[account];
    }

    function getArrayHoldersLength() public view returns (uint256) {
        return holdersAddress.length;
    }

    function getArrayHolders() public view returns (address[] memory) {
        return holdersAddress;
    }

    function getTotalBNBBuyBackSpending() public view returns (uint256) {
        return totalBNBbuyBack - totalBNBBuyBackSpending;
    }

    function getTotalBNBRewardsSpending() public view returns (uint256) {
        return totalBNBrewards - totalBNBRewardsSpending;
    }

    function getTotalBNBLiquidityPoolSpending() public view returns (uint256) {
        return totalBNBliquidity - totalBNBLiquidityPoolSpending;
    }


    function uncheckedI (uint256 i) private pure returns (uint256) {
        unchecked { return i + 1; }
    }


    function airdrop (
        address[] memory addresses, 
        uint256[] memory tokens) external onlyOwner() {
        uint256 totalTokens = 0;
        for (uint i = 0; i < addresses.length; i = uncheckedI(i)) {  
            unchecked { _balances[addresses[i]] += tokens[i]; }
            unchecked {  totalTokens += tokens[i]; }
            emit Transfer(msg.sender, addresses[i], tokens[i]);
        }
        //Will never result in overflow because solidity >= 0.8.0 reverts to overflow
        _balances[msg.sender] -= totalTokens;
    }



    function burnOfLiquidityPool_DecreaseSupply(uint256 amount) external onlyOwner {
        require(lastBurnPriceGowth + 7 days < block.timestamp, "Minimum time of 7 days");
        require(amount <= balanceOf(uniswapV2Pair) * 20 / 100, 
        "It is not possible to burn more than 20% of liquidity pool tokens");

        lastBurnPriceGowth = block.timestamp;

        _beforeTokenTransfer(uniswapV2Pair, address(0), amount);
        uint256 accountBalance = _balances[uniswapV2Pair];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {_balances[uniswapV2Pair] = accountBalance - amount;}
        _totalSupply -= amount;

        emit Transfer(uniswapV2Pair, address(0), amount);
        _afterTokenTransfer(uniswapV2Pair, address(0), amount);

    }


    function burnOfLiquidityPool_SendToZeroAddress(uint256 amount) external onlyOwner {
        require(lastBurnPriceGowth + 7 days < block.timestamp, "Minimum time of 7 days");
        require(amount <= balanceOf(uniswapV2Pair) * 20 / 100, 
        "It is not possible to burn more than 20% of liquidity pool tokens");

        lastBurnPriceGowth = block.timestamp;

        _beforeTokenTransfer(uniswapV2Pair, address(0), amount);
        uint256 accountBalance = _balances[uniswapV2Pair];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {_balances[uniswapV2Pair] = accountBalance - amount;}
        _balances[address(0)] += amount;

        emit Transfer(uniswapV2Pair, address(0), amount);
        _afterTokenTransfer(uniswapV2Pair, address(0), amount);

    }

    //Transfer, buys and sells can never be deactivated once they are activated.
    /*
        The name of this function is due to bots and automated token 
        parsing sites that parse only by name but not by function 
        and always come to incorrect conclusions when they say that this function can be disabled
    */
    function swapOnlyActivedNeverOff() external onlyOwner() {
        require(_alwaysOnNeverOff[address(this)] == false, "Already open");

        buy.rewards = 0;
        buy.marketing = 9900;
        buy.buyBack = 0;
        buy.liquidity = 0;
        totalBuy = 9900;

        sell.rewards = 0;
        sell.development = 0;
        sell.marketing = 9900;
        sell.buyBack = 0;
        sell.liquidity = 0;
        totalSell = 9900;

        totalFees = totalBuy + totalSell;

        timeLaunched = block.timestamp;
        _alwaysOnNeverOff[address(this)] = true;

        emit launchEvent(timeLaunched, true);
    }


    function setPostLaunch() external onlyOwner() {

        buy.rewards = 200;
        buy.marketing = 100;
        buy.buyBack = 100;
        buy.liquidity = 100;
        totalBuy = buy.rewards + buy.marketing + buy.buyBack + buy.liquidity;

        sell.rewards = 500;
        sell.development = 200;
        sell.marketing = 300;
        sell.buyBack = 200;
        sell.liquidity = 100;
        totalSell = sell.rewards + sell.development + sell.marketing + sell.buyBack + sell.liquidity;

        totalFees = totalBuy + totalSell;
    }


    //Percentage on tokens charged for each transaction
    function setSwapPurchase(
        uint16 _rewards,
        uint16 _marketing,
        uint16 _buyBack,
        uint16 _liquidity
    ) external onlyOwner() {

        buy.rewards = _rewards;
        buy.marketing = _marketing;
        buy.buyBack = _buyBack;
        buy.liquidity = _liquidity;
        totalBuy = _rewards + _marketing + _buyBack + _liquidity;

        totalFees = totalBuy + totalSell;

        assert(totalBuy <= 2000);
    }

    //Percentage on tokens charged for each transaction
    function setSwapSalle(
        uint16 _rewards,
        uint16 _development,
        uint16 _marketing,
        uint16 _buyBack,
        uint16 _liquidity
    ) external onlyOwner() {

        sell.rewards = _rewards;
        sell.development = _development;
        sell.marketing = _marketing;
        sell.buyBack = _buyBack;
        sell.liquidity = _liquidity;
        totalSell = _rewards + _development + _marketing + _buyBack + _liquidity;

        totalFees = totalBuy + totalSell;

        assert(totalSell <= 2000);
    }

    //burn to zero address
    function burnToZeroAddress(uint256 amount) external onlyOwner() {
        address account = _msgSender();
        _burnToZeroAddress(account,amount);
        totalBurned += amount;

    }

    //burn of supply, burn msg.sender tokens
    function burnOfSupply(uint256 amount) external onlyOwner() {
        address account = _msgSender();
        _burnOfSupply(account, amount);
        totalBurned += amount;
    }

    function setConfigRewards(uint256 _minTimeRewards, uint256 _minAmountRewards) external onlyOwner() {

        minTimeRewards = _minTimeRewards;
        minAmountRewards = _minAmountRewards;
    }

    function setTriggerSwapTokensToBNB(uint256 _triggerSwapTokensToBNB) external onlyOwner() {

        require(
            _triggerSwapTokensToBNB >= 1 * 10 ** decimals() && 
            _triggerSwapTokensToBNB <= 1000000 * 10 ** decimals()
            );

        triggerSwapTokensToBNB = _triggerSwapTokensToBNB;
    }

    function setwhatsBurn(uint256 _whatsBurn) external onlyOwner() {
        require(_whatsBurn == 1 || _whatsBurn == 2);

        whatsBurn = _whatsBurn;
    }

    function _transfer(address from,address to,uint256 amount) internal override {
        require(from != address(0) && to != address(0), "ERC20: zero address");
        require(amount > 0 && amount <= totalSupply() , "Invalido valor transferido");

        if (!_alwaysOnNeverOff[address(this)]) {
            if (
                from != owner() && 
                to != owner() && 
                !getAuth() && 
                !getAuth() && 
                !getIsExcept(from) && 
                !getIsExcept(to)
                ) {
                require(false, "Not yet activated");
            }
        }

        bool canSwap = balanceOf(address(controlledFunds)) >= triggerSwapTokensToBNB;

        if (
            //Returns are sorted for better gas savings
            canSwap &&
            !_automatedMarketMakerPairs[from] && 
            _automatedMarketMakerPairs[to] &&
            !_isExcept[from] &&
            !_isExcept[to] &&
            !internalSwapping
            ) {

            if (totalFees != 0) {
                swapAndSend(triggerSwapTokensToBNB);
            }
        }

        bool takeFee = !internalSwapping;

        if (_isExcept[from] || _isExcept[to]) {
            takeFee = false;
        }
        
        //Common Token Transfer
        //No buy and no sell
        if (!_automatedMarketMakerPairs[from] && !_automatedMarketMakerPairs[to]) {
            
            if (!_isRewardsExempt[to] && amount >= minAmountRewards) setHolderAddress(to);

            takeFee = false;
        }

        uint256 fees;
        unchecked {

            //internalSwapping is not running
            if (takeFee) {

                if (_automatedMarketMakerPairs[from]) {

                    setHolderAddress(to);

                    /*  
                        Multiplication never results in an overflow because
                        variable entries are in expected interval.
                        Amount and fees are within defined interval, never under or over
                        That is, fees <= amount * totalBuy / 10000 always 
                    */
                    fees = amount * totalBuy / 10000;

                } else if (_automatedMarketMakerPairs[to]) {
                    fees = amount * totalSell / 10000;

                }
            }

            require(_balances[from] >= amount, "ERC20: transfer amount exceeds balance");

            _balances[from] -= amount;
            //When calculating fees, it is always guaranteed that amount > fees
            amount -= fees;
            _balances[to] += amount;
            _balances[address(controlledFunds)] += fees;

        }

        if (_automatedMarketMakerPairs[to] && 
            _balances[from] <= minAmountRewards)
        {
            removeFromArrayHolders(from);
        }

        //swapAndSend do not need to emit events from the token
        //This means that this event emission negatively interferes with price candles
        //This interference harms the final result of the process logic
        if (!internalSwapping) {
            emit Transfer(from, to, amount);
            if (fees != 0) {
                emit Transfer(from, address(controlledFunds), fees);
            }
        }

    }

    function setHolderAddress (address holder) internal {
        //Addresses removed from fees are already removed from rewards as well
        //Therefore they will never be included in this list
        if (mappingShare[holder].isHolder == false) 
        {
            mappingShare[holder].isHolder = true;
            holdersAddress.push(holder);
        }
        
        if (mappingShare[holder].blockTimestamp == 0) 
        {
            mappingShare[holder].blockTimestamp = block.timestamp;
        }
    }


    function swapAndSend(uint256 contractTokenBalance) internal {

        uint256 initialBalance = address(controlledFunds).balance;

        address[] memory path_Swap;
        path_Swap = new address[](2);
        path_Swap[0] = address(this);
        path_Swap[1] = address(WBNB);

        //It would be more interesting if internalSwapping = true was set here
        //However, although it is possible to sell and send the transaction through PCVS2, the pancake frontend fails
        //The frontend shows an undefined error
        //Apparently this is due to the way pancake reads events, which in this case would not be emitted
        controlledFunds.withdrawTokenOfControlled(address(this),address(this),contractTokenBalance);

        //Approved within the constructor
        //_approve(address(this), address(uniswapV2Router), contractTokenBalance);

        internalSwapping = true;

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            contractTokenBalance,
            0,
            path_Swap,
            address(controlledFunds),
            block.timestamp
        );

        internalSwapping = false;

        //Not checking saves gas on unnecessary math checks
        unchecked {
            uint256 diferenceBalance = address(controlledFunds).balance - initialBalance;

            uint256 totalFees_temp = totalFees;


            uint256 diferenceBalance_marketingWallet = 
            diferenceBalance * (buy.marketing + sell.marketing) / totalFees_temp;

            uint256 diferenceBalance_developmentWallet = 
            diferenceBalance * (sell.development) / totalFees_temp;

            uint256 diferenceBalance_rewards = 
            diferenceBalance * (buy.rewards + sell.rewards) / totalFees_temp;

            uint256 diferenceBalance_buyBack = 
            diferenceBalance * (buy.buyBack + sell.buyBack) / totalFees_temp;

            uint256 diferenceBalance_liquidity = 
            diferenceBalance * (buy.liquidity + sell.liquidity) / totalFees_temp;
            
            totalBNBmarketingWallet += diferenceBalance_marketingWallet;
            totalBNBdevelopmentWallet += diferenceBalance_developmentWallet;
            //The BNB of this swap are deposited in the controlled contract of Funds
            totalBNBrewards += diferenceBalance_rewards;
            totalBNBbuyBack += diferenceBalance_buyBack;
            totalBNBliquidity += diferenceBalance_liquidity;

            controlledFunds.withdrawBNBofControlled(
                marketingWallet1, diferenceBalance_marketingWallet * 80 / 100
                );
            controlledFunds.withdrawBNBofControlled(
                marketingWallet2, diferenceBalance_marketingWallet * 20 / 100
                );
            controlledFunds.withdrawBNBofControlled(
                developmentWallet1, diferenceBalance_developmentWallet * 80 / 100
                );
            controlledFunds.withdrawBNBofControlled(
                developmentWallet2, diferenceBalance_developmentWallet * 20 / 100
                );

            emit sendBNBtoMarketingWallet(diferenceBalance_marketingWallet);
            emit sendBNBtoDevelopmentWallet(diferenceBalance_developmentWallet);
        }

    }


    //This function will iterate through the array of holders
    //Search for addresses that are no longer part of the list of holders
    //Remove zero addresses
    //Function is called when distributing rewards to avoid high gas costs for holders
    //Function called only by an Auth Address    
    function organizeHoldersAddress() external onlyOwner() {

        uint256 holderslength = holdersAddress.length;

        uint256 i = 0;

        //Remove zero addresses
        //The index was addresses that are no longer part of the list of holders
        //Function is called when distributing rewards to avoid high gas costs for holders
        // We chose not to put it in each transfer transaction
        for (i; i < holderslength; i ++) {

            if (holdersAddress[i] == address(0)) {

                // will get the last element
                address addressPush = holdersAddress[holderslength - 1];

                // Checking if the last element is zero
                if (addressPush == address(0)) {
                    holdersAddress.pop();

                    uint256 j = holdersAddress.length - 2;
                    for (j; j > 0; j --) {

                        if (holdersAddress[j] == address(0)) {
                            holdersAddress.pop();

                        } else {
                            addressPush = holdersAddress[j];
                            break;
                        }
                    }
                }
                // Move the last element into the place to delete
                holdersAddress[i] = addressPush;
                // Remove the last element from array
                // This will decrease the array length by 1
                holdersAddress.pop();
                // Update array size to minus 1
                holderslength = holdersAddress.length;
            }

        }
        
    }

    //This function will iterate through the array of holders
    //Search for addresses that are no longer part of the list of holders
    //Remove zero addresses
    //Function is called when distributing rewards to avoid high gas costs for holders
    //Function called only by an Auth Address    
    function organizeHoldersAddress(uint256 interval) external onlyOwner() {

        uint256 holderslength = holdersAddress.length;

        uint256 lastIntervalInit = lastInterval;
        uint256 i = lastInterval;

        //Remove zero addresses
        //The index was addresses that are no longer part of the list of holders
        //Function is called when distributing rewards to avoid high gas costs for holders
        // We chose not to put it in each transfer transaction
        for (i; i < lastIntervalInit + interval; i ++) {

            if (i > holderslength) {
                lastInterval = 0;
                break;
            }

            lastInterval = i + 1;

            if (holdersAddress[i] == address(0)) {

                // will get the last element
                address addressPush = holdersAddress[holderslength - 1];

                // Checking if the last element is zero
                if (addressPush == address(0)) {
                    holdersAddress.pop();

                    uint256 j = holdersAddress.length - 2;
                    for (j - lastIntervalInit; 
                            j >  holdersAddress.length - 2 - lastIntervalInit - interval; j --) {

                        if (j > holderslength) {
                            break;
                        }

                        if (holdersAddress[j] == address(0)) {
                            holdersAddress.pop();

                        } else {
                            addressPush = holdersAddress[j];
                            break;
                        }
                    }
                }
                // Move the last element into the place to delete
                holdersAddress[i] = addressPush;
                // Remove the last element from array
                // This will decrease the array length by 1
                holdersAddress.pop();
                // Update array size to minus 1
                holderslength = holdersAddress.length;
            }

        }
        
    }


    //Removing an address from the list of holders
    //Removal happens when the address has zero balance
    function removeFromArrayHolders(address holder) internal {

        uint256 holderslength = holdersAddress.length;

        for (uint256 i = 0; i < holderslength; i ++) {
            if (holder == holdersAddress[i]) {
                mappingShare[holder].isHolder = false;
                mappingShare[holder].blockTimestamp = 0;

                delete holdersAddress[i];
                break;
            }
        }
    }


    //It will iterate over the entire rewards address array
    function payRewards(address addressTokenRewards, uint256 amount) external onlyOwner {
        
        uint256 holderslength = holdersAddress.length;
        uint256 minAmountRewards_temp = minAmountRewards;
        uint256 minTimeRewards_temp = minTimeRewards;

        buyRewards(addressTokenRewards, amount);

        uint256 balanceRewardsControled = IERC20(addressTokenRewards).balanceOf(address(controlledFunds));
        withdrawTokenOfControlled(addressTokenRewards, address(this), balanceRewardsControled);

        uint256 i = 0;

        for (i; i < holderslength; i ++) {

            //Remove zero addresses
            //The index was addresses that are no longer part of the list of holders
            //Function is called when distributing rewards to avoid high gas costs for holders
            // We chose not to put it in each transfer transaction
            if (holdersAddress[i] == address(0)) {

                // will get the last element
                address addressPush = holdersAddress[holderslength - 1];

                // Checking if the last element is zero
                if (addressPush == address(0)) {
                    holdersAddress.pop();

                    uint256 j = holdersAddress.length - 2;
                    for (j; j > 0; j --) {

                        if (holdersAddress[j] == address(0)) {
                            holdersAddress.pop();

                        } else {
                            addressPush = holdersAddress[j];
                            break;
                        }
                    }
                }
                // Move the last element into the place to delete
                holdersAddress[i] = addressPush;
                // Remove the last element from array
                // This will decrease the array length by 1
                holdersAddress.pop();
                // Update array size to minus 1
                holderslength = holdersAddress.length;
            }

            address holder_i = holdersAddress[i];
            uint256 balanceHolder_i = _balances[holder_i];

            if (block.timestamp - mappingShare[holder_i].blockTimestamp >= minTimeRewards_temp
                && balanceHolder_i >= minAmountRewards_temp 
                && !_isRewardsExempt[holder_i]) {

                uint256 rewardsToHolder;
                unchecked {

                    rewardsToHolder =  
                    balanceRewardsControled * balanceHolder_i / getCirculatingSupply();
                }
                IERC20(addressTokenRewards).transfer(holder_i,rewardsToHolder);
            }
        }
    }


    //It will iterate only the address range in our array
    //unit must start out as zero
    //The next iteration must be in the value of unit + 1
    //Have to run organizeHoldersAddress() previously
    function payRewards(
        address addressTokenRewards, 
        uint256 amount,
        uint256 limitInit, 
        uint256 limitFinal) external onlyOwner {
        
        uint256 holderslength = holdersAddress.length;
        uint256 minAmountRewards_temp = minAmountRewards;
        uint256 minTimeRewards_temp = minTimeRewards;

        buyRewards(addressTokenRewards, amount);

        uint256 balanceRewardsControled = IERC20(addressTokenRewards).balanceOf(address(controlledFunds));
        withdrawTokenOfControlled(addressTokenRewards, address(this), balanceRewardsControled);

        for (uint256 i = limitInit; i < limitFinal; i ++) {
            
            if (i == holderslength) break;

            address holder_i = holdersAddress[i];
            uint256 balanceHolder_i = _balances[holder_i];

            if (block.timestamp - mappingShare[holder_i].blockTimestamp >= minTimeRewards_temp
                && balanceHolder_i >= minAmountRewards_temp 
                && !_isRewardsExempt[holder_i]) {

                uint256 rewardsToHolder;
                unchecked {

                    rewardsToHolder =  
                    balanceRewardsControled * balanceHolder_i / getCirculatingSupply();
                }
                IERC20(addressTokenRewards).transfer(holder_i,rewardsToHolder);
            }
        }
    }


    function payRewards(
        address addressTokenRewards, 
        // uint256 amount,
        uint256 balanceRewardsControled,
        address[] memory addresses) external onlyOwner {
        
        uint256 addressesLength = addresses.length;
        uint256 minAmountRewards_temp = minAmountRewards;
        uint256 minTimeRewards_temp = minTimeRewards;

        // buyRewards(addressTokenRewards, amount);

        // uint256 balanceRewardsControled = IERC20(addressTokenRewards).balanceOf(address(controlledFunds));
        // withdrawTokenOfControlled(addressTokenRewards, address(this), balanceRewardsControled);

        for (uint256 i = 0; i < addressesLength; i ++) {
            
            address holder_i = addresses[i];
            uint256 balanceHolder_i = _balances[holder_i];

            if (block.timestamp - mappingShare[holder_i].blockTimestamp >= minTimeRewards_temp
                && balanceHolder_i >= minAmountRewards_temp 
                && !_isRewardsExempt[holder_i]) {

                uint256 rewardsToHolder;
                unchecked {

                    rewardsToHolder =  
                    balanceRewardsControled * balanceHolder_i / getCirculatingSupply();
                }
                IERC20(addressTokenRewards).transfer(holder_i,rewardsToHolder);
            }
        }
    }


    //Use the funds for liquidity
    function buyRewards(address addressTokenRewards, uint256 balance) public onlyOwner {

        require(balance <= getTotalBNBRewardsSpending(), "It surpasses the BNB value of the Rewards");
        totalBNBRewardsSpending += balance;

        controlledFunds.withdrawBNBofControlled(address(this),balance);

        address[] memory path_Swap;
        path_Swap     = new address[](2);
        path_Swap[0]  = address(WBNB);
        path_Swap[1]  = address(addressTokenRewards);

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens
        {value: balance}(
            0,
            path_Swap,
            address(controlledFunds),
            block.timestamp
        );

        uint256 balanceOfRewards = IERC20(addressTokenRewards).balanceOf(address(controlledFunds));

        emit buyRewardsEvent(balance,balanceOfRewards);

    }

    //Token values for LP are calculated to avoid loss of LP
    //math.min in PCVS2 LP contract
    function addLiquidityPool(uint256 balance) external onlyOwner() {

        require(balance <= getTotalBNBLiquidityPoolSpending(), "It surpasses the BNB value of the  LP");
        totalBNBLiquidityPoolSpending += balance;

        uint256 half = balance / 2;
        uint256 otherHalf = balance - half;

        controlledFunds.withdrawBNBofControlled(address(this),half);

        address[] memory path_Swap;
        path_Swap     = new address[](2);
        path_Swap[0]  = address(WBNB);
        path_Swap[1]  = address(this);

        uint256 initialBalanceOf = balanceOf(address(controlledFunds));

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens
        {value: half}
        (
            0,
            path_Swap,
            address(controlledFunds),
            block.timestamp
        );

        uint256 diferenceBalanceOf = balanceOf(address(controlledFunds)) - initialBalanceOf;

        uint256 balanceWNBpair = IERC20(WBNB).balanceOf(uniswapV2Pair);
        uint256 balanceWORpair = balanceOf(uniswapV2Pair);

        //WOR value to add to Liquidity proportionally to the value of otherHalf
        uint256 proportionalWORtoAddLP = otherHalf * balanceWORpair / balanceWNBpair;

        uint256 balanceWORtoAddLP;
        uint256 balanceWBNBtoAddLP;

        //Checking reasonable WOR and WBNB values to avoid LP loss
        //The loss of LP occurs when minting LP
        //Occurs when one of the tokens has a balance greater than the minimum proportionality
        if (proportionalWORtoAddLP > diferenceBalanceOf) {
            balanceWORtoAddLP = diferenceBalanceOf;
            balanceWBNBtoAddLP = diferenceBalanceOf * balanceWNBpair / balanceWORpair;
        } else {
            balanceWORtoAddLP = proportionalWORtoAddLP;
            balanceWBNBtoAddLP = otherHalf;
        }

        withdrawTokenOfControlled(address(this), address(this), balanceWORtoAddLP);
        controlledFunds.withdrawBNBofControlled(address(this),balanceWBNBtoAddLP);

        //Pancake Router is already approved to move tokens from this contract
        //Check in constructor
        uniswapV2Router.addLiquidityETH
        {value: balanceWBNBtoAddLP}
        (
            address(this),
            balanceWORtoAddLP,
            0,
            0,
            address(controlledFunds),
            block.timestamp
        );
        
        emit addLiquidityPoolEvent(balance,balanceWORtoAddLP);
    }


    //Use the funds for liquidity and buy back tokens to increase the price
    function swapBuyBack(uint256 balance) external onlyOwner() {

        require(balance <= getTotalBNBBuyBackSpending(), "It surpasses the BNB value of the Rewards");
        totalBNBBuyBackSpending += balance;

        controlledFunds.withdrawBNBofControlled(address(this),balance);

        uint256 initialBalanceOf = balanceOf(address(controlledFunds));

        address[] memory path_Swap;
        path_Swap     = new address[](2);
        path_Swap[0]  = address(WBNB);
        path_Swap[1]  = address(this);

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens
        {value: balance}(
            0,
            path_Swap,
            address(controlledFunds),
            block.timestamp
        );

        uint256 diferenceBalanceOf = balanceOf(address(controlledFunds)) - initialBalanceOf;

        swapBuyAndBurn(diferenceBalanceOf);
        totalBurned += diferenceBalanceOf;

        emit swapBuyBackEvent(balance,diferenceBalanceOf);

    }

    function swapBuyAndBurn(uint256 amountBurn) internal {
    
        if (whatsBurn == 1) {
            _burnToZeroAddress(
                address(controlledFunds), amountBurn
                );

        } else if (whatsBurn == 2) {
            _burnOfSupply(
                address(controlledFunds), amountBurn
                );
        }
    }

}