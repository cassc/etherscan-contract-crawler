// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
// by three they come
// by three they go
// and in between in fiery row
// burn the white-robed ranks of woe
// o/
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

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
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }
    modifier onlyOwner() {
        _checkOwner();
        _;
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
interface IFactory{
        function createPair(address tokenA, address tokenB) external returns (address pair);
        function getPair(address tokenA, address tokenB) external view returns (address pair);
}
interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;   
}
contract RewardsTracker is Ownable {

    mapping(address => uint256) public userShares;
    mapping(address => int256) internal magnifiedDividendCorrections;
    mapping(address => uint256) internal withdrawnDividends;
    mapping(address => bool) public excludedFromDividends;
    mapping(address => uint256) public lastClaimTime;
    mapping(address => uint256) public elegibleUsersIndex;
    mapping(address => bool ) public isElegible;

    address[] elegibleUsers;

    IRouter public rewardRouter;
    address public rewardToken;

    uint256 constant internal magnitude = 2**128;

    uint256 internal magnifiedDividendPerShare;
    uint256 public totalDividends;
    uint256 public totalDividendsWithdrawn;
    uint256 public totalShares;
    uint256 public minBalanceForRewards;
    uint256 public claimDelay;
    uint256 public currentIndex;

    event ExcludeFromDividends(address indexed account, bool value);
    event Claim(address indexed account, uint256 amount);
    event DividendWithdrawn(address indexed to, uint256 weiAmount);

    constructor(address _router, address _rewardToken) {
      rewardRouter = IRouter(_router);
      rewardToken = _rewardToken;
    }

    function excludeFromDividends(address account, bool value) external onlyOwner {
        require(excludedFromDividends[account] != value);
        excludedFromDividends[account] = value;
        if(value == true){
          _setBalance(account, 0);
        }
        else{
          _setBalance(account, userShares[account]);
        }
        emit ExcludeFromDividends(account, value);

    }
    
    function _setRewardToken(address newToken) internal{
      rewardToken = newToken;
    }

    function getAccount(address account) public view returns (uint256 withdrawableUserDividends, uint256 totalUserDividends, uint256 lastUserClaimTime, uint256 withdrawnUserDividends) {
        withdrawableUserDividends = withdrawableDividendOf(account);
        totalUserDividends = accumulativeDividendOf(account);
        lastUserClaimTime = lastClaimTime[account];
        withdrawnUserDividends = withdrawnDividends[account]; 
    }

    function setBalance(address account, uint256 newBalance) internal {
        if(excludedFromDividends[account]) {
            return;
        }   
        _setBalance(account, newBalance);
    }

    function _setMinBalanceForRewards(uint256 newMinBalance) internal {
        minBalanceForRewards = newMinBalance;
    }

    function autoDistribute(uint256 gasAvailable) public {
      uint256 size = elegibleUsers.length;
      if(size == 0) return;

      uint256 gasSpent = 0;
      uint256 gasLeft = gasleft();
      uint256 lastIndex = currentIndex;
      uint256 iterations = 0;

      while(gasSpent < gasAvailable && iterations < size){
        if(lastIndex >= size){
          lastIndex = 0;
        }
        address account = elegibleUsers[lastIndex];
        if(lastClaimTime[account] + claimDelay < block.timestamp){
          _processAccount(account);
        }
        lastIndex++;
        iterations++;
        gasSpent += gasLeft - gasleft();
        gasLeft = gasleft();
      }

      currentIndex = lastIndex;

    }

    function _processAccount(address account) internal returns(bool){
        uint256 amount = _withdrawDividendOfUser(account);

          if(amount > 0) {
              lastClaimTime[account] = block.timestamp;
              emit Claim(account, amount);
              return true;
          }
          return false;
    }

    /* function distributeDividends() external payable {
      if (msg.value > 0) {
      _distributeDividends(msg.value);
      }
    } no need for erc20 tokens */

    function _distributeDividends(uint256 amount) internal {
      require(totalShares > 0,"there are no shares");
      magnifiedDividendPerShare = magnifiedDividendPerShare + (amount * magnitude / totalShares);
      totalDividends= totalDividends + amount;
    }
    
    function _withdrawDividendOfUser(address user) internal returns (uint256) {
      uint256 _withdrawableDividend = withdrawableDividendOf(user);
      if (_withdrawableDividend > 0) {
        withdrawnDividends[user] += _withdrawableDividend;
        totalDividendsWithdrawn += _withdrawableDividend;
        emit DividendWithdrawn(user, _withdrawableDividend);
        (bool success) = swapEthForCustomToken(user, _withdrawableDividend);
        if(!success) {
          (bool secondSuccess,) = payable(user).call{value: _withdrawableDividend, gas: 3000}("");
          if(!secondSuccess) {
            withdrawnDividends[user] -= _withdrawableDividend;
            totalDividendsWithdrawn -= _withdrawableDividend;
            return 0;
          }       
        }
        return _withdrawableDividend;
      }
      return 0;
    }

    function swapEthForCustomToken(address user, uint256 amt) internal returns (bool) {
      address[] memory path = new address[](2);
      path[0] = rewardRouter.WETH();
      path[1] = rewardToken;
      
      try rewardRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amt}(0, path, user, block.timestamp) {
        return true;
      } catch {
        return false;
      }
    }

    function dividendOf(address _owner) public view returns(uint256) {
      return withdrawableDividendOf(_owner);
    }

    function withdrawableDividendOf(address _owner) public view returns(uint256) {
      return accumulativeDividendOf(_owner) - withdrawnDividends[_owner];
    }

    function withdrawnDividendOf(address _owner) public view returns(uint256) {
      return withdrawnDividends[_owner];
    }

    function accumulativeDividendOf(address _owner) public view returns(uint256) {
      return uint256(int256(magnifiedDividendPerShare * userShares[_owner]) + magnifiedDividendCorrections[_owner]) / magnitude;
    }

    function addShares(address account, uint256 value) internal {
      userShares[account] += value;
      totalShares += value;

      magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account] - int256(magnifiedDividendPerShare * value);
    }

    function removeShares(address account, uint256 value) internal {
      userShares[account] -= value;
      totalShares -= value;

      magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account] + int256(magnifiedDividendPerShare * value);
    }

    function _setBalance(address account, uint256 newBalance) internal {
      uint256 currentBalance = userShares[account];
      if(currentBalance > 0) {
        _processAccount(account);
      }
      if(newBalance < minBalanceForRewards && isElegible[account]){
        isElegible[account] = false;
        elegibleUsers[elegibleUsersIndex[account]] = elegibleUsers[elegibleUsers.length - 1];
        elegibleUsersIndex[elegibleUsers[elegibleUsers.length - 1]] = elegibleUsersIndex[account];
        elegibleUsers.pop();
        removeShares(account, currentBalance);
      }
      else{
        if(userShares[account] == 0){
          isElegible[account] = true;
          elegibleUsersIndex[account] = elegibleUsers.length;
          elegibleUsers.push(account);
        }
        if(newBalance > currentBalance) {
          uint256 mintAmount = newBalance - currentBalance;
          addShares(account, mintAmount);
        } else if(newBalance < currentBalance) {
          uint256 burnAmount = currentBalance - newBalance;
          removeShares(account, burnAmount);
        }
      }
    }
}

library Address {
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, 'Address: insufficient balance');

        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
    }
}

contract Lunatics is ERC20, Ownable, RewardsTracker {
    using Address for address payable;
    //custom
    IRouter public router;
    //address
    address public pair;
    //bool
    bool public swapAndLiquifyEnabled = true;
    bool public limitSells = true;
    bool public limitBuys = true;
    bool public feeStatus = true;
    bool public buyFeeStatus = true;
    bool public sellFeeStatus = true;
    bool public blockMultiBuys = true;
    bool public marketActive;
    bool private isInternalTransaction;
    //uint
    uint public gasLimit = 300_000;
    uint public minimumTokensBeforeSwap;
    uint public tokensToSwap;
    uint public intervalSecondsForSwap = 30;
    uint public minimumWeiForTokenomics = 1 * 10**17; // 0.1 ETH
    uint public maxBuyTxAmount;
    uint public maxSellTxAmount;
    uint private startTimeForSwap;
    uint private marketActiveAt;

    //struct
    struct userData {
        uint lastBuyTime;
    }
    struct Fees {
        uint64 rewards;
        uint64 marketing;
        uint64 buyback;
    }
    struct FeesAddress {
        address marketing;
        address buyback;
    }
    FeesAddress public feesAddress = FeesAddress(
        0x2d00FB5E5890EBF1B270fa4009E19052305F8074,
        0x8A52164f5612f0Cd075b8d5eA4a6b22d67335734
    );
    Fees public buyFees = Fees(3, 3, 2);
    Fees public sellFees = Fees(3, 3, 2);

    uint256 public totalBuyFee = 8;
    uint256 public totalSellFee = 8;

    //mapping
    mapping (address => bool) public premarketUser;
    mapping (address => bool) public excludedFromFees;
    mapping (address => userData) public userLastTradeData;
    mapping(address => bool) public isPair;
    event ContractSwap(uint256 date, uint256 amount);

    event PremarketUserChanged(bool status, address indexed user);
    event ExcludeFromFeesChanged(bool status, address indexed user);
    event MarketingFeeCollected(uint amount);
    event BuybackFeeCollected(uint amount);

    event FeesStatusChanged(bool feesActive, bool buy, bool sell);
    event SwapSystemChanged(bool status, uint256 intervalSecondsToWait, uint256 minimumToSwap, uint256 tokensToSwap);

    event MaxSellChanged(uint256 amount);
    event MaxBuyChanged(uint256 amount);
    event BlockMultiBuysChange(bool status);
    event LimitSellChanged(bool status);
    event LimitBuyChanged(bool status);
    event MarketStatusChanged(bool status, uint256 date);
    event TokenRemovedFromContract(address indexed tokenAddress, uint256 amount);
    event PairUpdated(address indexed pair);
    event RouterUpdated(address indexed router);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event SendDividends(uint256 tokensSwapped, uint256 amount);
    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );

    constructor(address _router, address _rewardToken) ERC20('Lunatics', 'LunaT') RewardsTracker(_router, _rewardToken) {
        router = IRouter(_router);
        pair = IFactory(router.factory()).createPair(address(this), router.WETH());
        uint _totalSupply = 100_000_000_000 * (10**9);

        maxSellTxAmount = _totalSupply / 100; // 1% supply
        maxBuyTxAmount = _totalSupply / 100; // 1% supply
        minimumTokensBeforeSwap = _totalSupply / 10000; //0.01% supply
        tokensToSwap = _totalSupply / 10000; //0.01% supply
        minBalanceForRewards = 500_000 * 10 ** 9; // 500k
        claimDelay = 60*60; // 1 hour

        // exclude from receiving dividends
        excludedFromDividends[address(this)] = true;
        excludedFromDividends[owner()] = true;
        excludedFromDividends[address(0xdead)] = true;
        excludedFromDividends[address(_router)] = true;
        excludedFromDividends[address(pair)] = true;

        // exclude from paying fees or having max transaction amount
        excludedFromFees[owner()] = true;
        excludedFromFees[address(this)] = true;
        excludedFromFees[feesAddress.marketing] = true;
        excludedFromFees[feesAddress.buyback] = true;

        premarketUser[owner()] = true;
        isPair[pair] = true;

        // _mint is an internal function in ERC20.sol that is only called here,
        // and CANNOT be called ever again
        _mint(owner(), _totalSupply);
    }

    receive() external payable {}

    function decimals() public pure override returns(uint8) {
        return 9;
    }

    /// @notice Manual claim the dividends
    function claim() external {
        super._processAccount(payable(msg.sender));
    }

    // to take leftover(tokens) from contract
    function transferToken(address _token, address _to, uint _value) external onlyOwner returns(bool _sent){
        if(_value == 0) {
            _value = IERC20(_token).balanceOf(address(this));
        } 
        _sent = IERC20(_token).transfer(_to, _value);
        emit TokenRemovedFromContract(_token, _value);
    }

    function transferETH() external onlyOwner {
        uint256 ETHbalance = address(this).balance;
        payable(owner()).sendValue(ETHbalance);
    }
    //switch functions
    function switchMarketActive(bool _state) external onlyOwner {
        //once marketActive is set to true, cannot be set back to false
        require(marketActive == false, "Cannot stop trade once is open");
        marketActive = _state;
        if(_state) {
            marketActiveAt = block.timestamp;
        }
        emit MarketStatusChanged(_state, block.timestamp);
    }
    function switchLimitSells(bool _state) external onlyOwner {
        limitSells = _state;
        emit LimitSellChanged(_state);
    }
    function updateRouter(address newRouter, bool _createPair) external onlyOwner {
        router = IRouter(newRouter);
        if(_createPair) {
            address _pair = IFactory(router.factory())
                .createPair(address(this), router.WETH());
            pair = _pair;
            emit PairUpdated(pair);
        } else {
            router = IRouter(newRouter);
        }
        emit RouterUpdated(newRouter);
    }

    function setBlockMultiBuys(bool _status) external onlyOwner {
        blockMultiBuys = _status;
        emit BlockMultiBuysChange(_status);
    }

    function switchLimitBuys(bool _state) external onlyOwner {
        limitBuys = _state;
        emit LimitBuyChanged(_state);
    }

    function setMaxSellTxAmount(uint _value) external onlyOwner {
        maxSellTxAmount = _value*10**decimals();
        require(maxSellTxAmount >= totalSupply() / 1000,"maxSellTxAmount should be at least 0.1% of total supply.");
        emit MaxSellChanged(_value);
    }

    function setMaxBuyTxAmount(uint _value) external onlyOwner {
        maxBuyTxAmount = _value*10**decimals();
        require(maxBuyTxAmount >= totalSupply() / 1000,"maxBuyTxAmount should be at least 0.1% of total supply.");
        emit MaxBuyChanged(maxBuyTxAmount);
    }
    
    function setFeeStatus(bool buy, bool sell, bool _state) external onlyOwner {
        feeStatus = _state;
        buyFeeStatus = buy;
        sellFeeStatus = sell;
        emit FeesStatusChanged(_state,buy,sell);
    }
    
    function setSwapAndLiquify(bool _state, uint _intervalSecondsForSwap, uint _minimumTokensBeforeSwap, uint _tokensToSwap) external onlyOwner {
        swapAndLiquifyEnabled = _state;
        intervalSecondsForSwap = _intervalSecondsForSwap;
        minimumTokensBeforeSwap = _minimumTokensBeforeSwap*10**decimals();
        tokensToSwap = _tokensToSwap*10**decimals();
        require(minimumTokensBeforeSwap > 1000000000, "More than one token required"); 
        require(tokensToSwap > 1000000000, "More than one token required");
        require(tokensToSwap <= minimumTokensBeforeSwap,"You cannot swap more then the minimum amount");
        require(tokensToSwap <= totalSupply() / 1000,"token to swap limited to 0.1% supply");
        emit SwapSystemChanged(_state,_intervalSecondsForSwap,_minimumTokensBeforeSwap,_tokensToSwap);
    }
    // mappings functions
    function setPremarketUser(address _target, bool _status) external onlyOwner {
        premarketUser[_target] = _status;
        emit PremarketUserChanged(_status,_target);
    }
    function KKMigration(address[] memory _address, uint256[] memory _amount) external onlyOwner {
        for(uint i=0; i< _amount.length; i++){
            address adr = _address[i];
            uint amnt = _amount[i] *10**decimals();
            super._transfer(owner(), adr, amnt);
        }
        // events from ERC20
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        excludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            excludedFromFees[accounts[i]] = excluded;
        }
        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setRewardToken(address newToken) external onlyOwner {
        super._setRewardToken(newToken);
    }

    function setMarketingWallet(address newWallet) external onlyOwner {
        feesAddress.marketing = newWallet;
    }

    function setBuybackWallet(address newWallet) external onlyOwner {
        feesAddress.buyback = newWallet;
    }

    function setClaimDelay(uint256 amountInSeconds) external onlyOwner {
        claimDelay = amountInSeconds;
    }

    function setBuyTaxes(
        uint64 _rewards,
        uint64 _marketing,
        uint64 _buyback
    ) external onlyOwner {
        totalBuyFee = _rewards + _marketing + _buyback;
        require(totalBuyFee <= 15, "Total buy fees cannot be more than 15%");
        buyFees = Fees(_rewards, _marketing, _buyback);
    }

    function setSellTaxes(
        uint64 _rewards,
        uint64 _marketing,
        uint64 _buyback
    ) external onlyOwner {
        totalSellFee = _rewards + _marketing + _buyback;
        require(totalSellFee <= 15, "Total sell fees cannot be more than 15%");
        sellFees = Fees(_rewards, _marketing, _buyback);
    }

    function setGasLimit(uint256 newGasLimit) external onlyOwner {
        gasLimit = newGasLimit;
    }

    function setMinBalanceForRewards(uint256 minBalance) external onlyOwner {
        minBalanceForRewards = minBalance;
    }

    function setPair(address newPair, bool value) external onlyOwner {
        isPair[newPair] = value;

        if (value) {
            excludedFromDividends[newPair] = true;
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
        emit ContractSwap(block.timestamp, tokenAmount);
    }
    function swapTokens(uint256 contractTokenBalance) private {
        isInternalTransaction = true;
        swapTokensForEth(contractTokenBalance);
        isInternalTransaction = false;
    }
    ////////////////////////
    // Transfer Functions //
    ////////////////////////

    function _transfer(address from, address to, uint256 amount) internal override {
        uint trade_type = 0;
    // market status flag
        if(!marketActive) {
            require(premarketUser[from],"cannot trade before the market opening");
        }
    // normal transaction
        if(!isInternalTransaction) {
        // tx limits
            //buy
            if(isPair[from]) {
                trade_type = 1;
                // limits
                if(!excludedFromFees[to]) {
                    // tx limit
                    if(limitBuys) {
                        require(amount <= maxBuyTxAmount, "maxBuyTxAmount Limit Exceeded");
                        // multi-buy limit
                        if(blockMultiBuys) {
                            require(marketActiveAt + 7 < block.timestamp,"You cannot buy at launch.");
                            require(userLastTradeData[tx.origin].lastBuyTime + 3 <= block.timestamp,"You cannot do multi-buy orders.");
                            userLastTradeData[tx.origin].lastBuyTime = block.timestamp;
                        }
                    }
                }
            }
            //sell
            else if(isPair[to]) {
                trade_type = 2;
                bool overMinimumTokenBalance = balanceOf(address(this)) >= minimumTokensBeforeSwap;
                // marketing auto-eth // if the swap is enabled and there are tokens in pool
                if (swapAndLiquifyEnabled && balanceOf(pair) > 0 && overMinimumTokenBalance &&
                    startTimeForSwap + intervalSecondsForSwap <= block.timestamp) {
                    // if contract has X tokens, not sold since Y time, sell Z tokens
                    startTimeForSwap = block.timestamp;
                    // sell to eth
                    swapTokens(tokensToSwap);
                }
                
                // limits
                if(!excludedFromFees[from]) {
                    // tx limit
                    if(limitSells) {
                    require(amount <= maxSellTxAmount, "maxSellTxAmount Limit Exceeded");
                    }
                }
            }
            // fees redistribution
            if(address(this).balance > minimumWeiForTokenomics) {
                //marketing
                uint256 caBalance = address(this).balance;
                uint256 marketingTokens = caBalance * sellFees.marketing / totalSellFee;
                (bool success,) = address(feesAddress.marketing).call{value: marketingTokens}("");
                if(success) {
                    emit MarketingFeeCollected(marketingTokens);
                }
                
                //buyback
                uint256 buybackTokens = caBalance * sellFees.buyback / totalSellFee;
                (bool success1,) = address(feesAddress.buyback).call{value: buybackTokens}("");
                if(success1) {
                    emit BuybackFeeCollected(buybackTokens);
                }
                //rewards
                uint256 dividends = caBalance * sellFees.rewards / totalSellFee;
                super._distributeDividends(dividends);
                super.autoDistribute(gasLimit);
            }
        // fees management
            if(feeStatus) {
                // buy
                if(trade_type == 1 && buyFeeStatus && !excludedFromFees[to]) {
                	uint txFees = amount * totalBuyFee / 100;
                	amount -= txFees;
                    super._transfer(from, address(this), txFees);
                }
                //sell
                if(trade_type == 2 && sellFeeStatus && !excludedFromFees[from]) {
                	uint txFees = amount * totalSellFee / 100;
                	amount -= txFees;
                    super._transfer(from, address(this), txFees);
                }
                // no wallet to wallet tax
            }
        }
        // transfer tokens
        super._transfer(from, to, amount);
        super.setBalance(from, balanceOf(from));
        super.setBalance(to, balanceOf(to));
        
    }
}