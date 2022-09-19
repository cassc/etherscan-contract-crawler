// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./interfaces/IReferral.sol";

contract TokenDividendTracker is Ownable {
    using SafeMath for uint256;

    address[] public shareholders;
    uint256 public currentIndex;
    mapping(address => bool) private _updated;
    mapping(address => uint256) public shareholderIndexes;

    address public uniswapV2Pair;
    address public lpRewardToken;
    uint256 public LPRewardLastSendTime;

    constructor(address uniswapV2Pair_, address lpRewardToken_) {
        uniswapV2Pair = uniswapV2Pair_;
        lpRewardToken = lpRewardToken_;
    }

    function resetLPRewardLastSendTime() public onlyOwner {
        LPRewardLastSendTime = 0;
    }

    function process(uint256 gas) external onlyOwner {
        uint256 shareholderCount = shareholders.length;

        if (shareholderCount == 0) return;
        uint256 nowbanance = IERC20(lpRewardToken).balanceOf(address(this));

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
                LPRewardLastSendTime = block.timestamp;
                return;
            }
            uint256 amount = nowbanance
                .mul(
                    IERC20(uniswapV2Pair).balanceOf(shareholders[currentIndex])
                )
                .div(IERC20(uniswapV2Pair).totalSupply());
            if (amount == 0) {
                currentIndex++;
                iterations++;
                return;
            }
            if (IERC20(lpRewardToken).balanceOf(address(this)) < amount) return;
            IERC20(lpRewardToken).transfer(shareholders[currentIndex], amount);
            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function setShare(address shareholder) external onlyOwner {
        if (_updated[shareholder]) {
            if (IERC20(uniswapV2Pair).balanceOf(shareholder) == 0)
                quitShare(shareholder);
            return;
        }
        if (IERC20(uniswapV2Pair).balanceOf(shareholder) == 0) return;
        addShareholder(shareholder);
        _updated[shareholder] = true;
    }

    function quitShare(address shareholder) internal {
        removeShareholder(shareholder);
        _updated[shareholder] = false;
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[
            shareholders.length - 1
        ];
        shareholderIndexes[
            shareholders[shareholders.length - 1]
        ] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}

contract Wrap {
    IERC20 public ft;
    IERC20 public usdt;

    constructor(IERC20 ft_, IERC20 usdt_) {
        ft = ft_;
        usdt = usdt_;
    }

    function withdraw() external {
        uint256 usdtBalance = usdt.balanceOf(address(this));
        if (usdtBalance > 0) {
            usdt.transfer(address(ft), usdtBalance);
        }
    }
}

contract WZDAO is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    IERC20 public immutable usdt;
    TokenDividendTracker public immutable dividendTracker;
    Wrap public immutable wrap;
    IReferral public immutable referral;

    bool private _swapping;
    uint256 private _lastSwapTime;

    uint256 private TAmountLpFee;

    uint256 public immutable lpRewardFee = 20;
    uint256 public immutable lpFee = 10;
    uint256[2] public referralFees = [12,8];
    uint256 public immutable defiWzLpFee = 10;
    uint256 public immutable wzDaoNftFee = 10;
    uint256 public immutable marketingFee = 10;

    address public marketingAddress;
    address public wzDaoNftAddress;
    address public defiWzLpAddress;
    address public lpReceiveAddress;

    address public immutable burnAddress = 0x000000000000000000000000000000000000dEaD;

    address private _fromAddress;
    address private _toAddress;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isDividendExempt;
    mapping(address => bool) private _blacklist;
    mapping(address=>address) private _wReferrals;
    mapping(address=>bool) private _isHold;

    uint256 public minPeriod = 1 days;
    uint256 public distributorGas = 200000;

    uint256 public swapStartTime;
    uint256 public swapInterval = 30 minutes;
    uint256 public holds;
    uint256 public takeFeeCondition = 200000;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetBlacklist(address indexed account, bool isExcluded);
    event BatchSetBlacklist(address[] accounts, bool isExcluded);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 usdtReceived,
        uint256 tokensIntoLiqudity
    );

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        IUniswapV2Router02 uniswapV2Router_,
        IERC20 usdt_,
        IReferral referral_,
        address marketingAddress_,
        address lpReceiveAddress_,
        address defiWzLpAddress_,
        address wzDaoNftAddress_,
        uint256 swapStartTime_
    ) payable ERC20(name_, symbol_) {
        uint256 totalSupply = totalSupply_ * 10 ** decimals();
        uniswapV2Router = uniswapV2Router_;
        usdt = usdt_;
        swapStartTime = swapStartTime_;
        marketingAddress = marketingAddress_;
        lpReceiveAddress = lpReceiveAddress_;
        defiWzLpAddress = defiWzLpAddress_;
        wzDaoNftAddress = wzDaoNftAddress_;
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                address(usdt)
            );
        dividendTracker = new TokenDividendTracker(
            uniswapV2Pair,
            uniswapV2Pair
        );
        wrap = new Wrap(IERC20(this), usdt);
        referral = referral_;
        excludeFromFees(owner(), true);
        excludeFromFees(marketingAddress, true);
        excludeFromFees(lpReceiveAddress, true);
        excludeFromFees(defiWzLpAddress, true);
        excludeFromFees(wzDaoNftAddress, true);

        excludeFromFees(burnAddress, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(dividendTracker), true);
        _isDividendExempt[address(this)] = true;
        _isDividendExempt[address(0)] = true;
        _isDividendExempt[burnAddress] = true;
        _isDividendExempt[address(dividendTracker)] = true;
        _mint(owner(), totalSupply);
    }

    receive() external payable {}

    function isExcludedFromFees(address account) external view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function isBlacklist(address _address) public view returns (bool) {
        return _blacklist[_address];
    }

    function isHold(address _address) public view returns(bool){
        return _isHold[_address];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        require(!isBlacklist(from) && !isBlacklist(to), "Is blacklist");//黑名单
        require(_canSwap(from, to), "Can't swap");//是否开启交易

        if (_shouldBan(from, to)) {//开盘ban机器人
            _setBlacklist(to, true);
        }
        
        if (_isSwapFee(from, to)) {//回流分红
            _swapFee();
        }
        //绑定关系
        if(!_isSwap(from,to)){
            _ref(from,to);
            _acceptRef(from,to);
        }
        if (_isTakeFee(from, to)) {
            if (from != uniswapV2Pair) {
                uint256 minHolderAmount = balanceOf(from).mul(99).div(100);
                if (amount > minHolderAmount) {
                    amount = minHolderAmount;
                }
            }
            amount = _takeFee(from,to, amount);
        }
        super._transfer(from, to, amount);
        setHold(from);
        setHold(to);
        if (_fromAddress == address(0)) _fromAddress = from;
        if (_toAddress == address(0)) _toAddress = to;
        if (!_isDividendExempt[_fromAddress] && _fromAddress != uniswapV2Pair)
            try dividendTracker.setShare(_fromAddress) {} catch {}
        if (!_isDividendExempt[_toAddress] && _toAddress != uniswapV2Pair)
            try dividendTracker.setShare(_toAddress) {} catch {}
        _fromAddress = from;
        _toAddress = to;
        if (
            !_swapping &&
            from != owner() &&
            to != owner() &&
            from != address(this) &&
            dividendTracker.LPRewardLastSendTime().add(minPeriod) <=
            block.timestamp
        ) {
            try dividendTracker.process(distributorGas) {} catch {}
        }
    }

    function _canSwap(address _from, address _to) private view returns (bool) {
        return
            swapStartTime < block.timestamp ||
            !_isSwap(_from,_to) ||
            (_isExcludedFromFees[_to] || _isExcludedFromFees[_from]);
    }

    function _isSwap(address _from,address _to)private view returns(bool){
        return uniswapV2Pair == _from || uniswapV2Pair == _to;
    }

    function _ref(address _parent,address _user) private  {
        if(referral.isBindReferral(_user) || !referral.isBindReferral(_parent)){
            return;
        }
        _wReferrals[_user] = _parent;
    }

    function _acceptRef(address _user,address _parent)  private {
        if(referral.isBindReferral(_user)){
            return;
        }
        address parent = _wReferrals[_user];
        if(parent != _parent){
            return;
        }
        _wReferrals[_user] = address(0);
        referral.bindReferral(parent,_user);
    }

    function _shouldBan(address _from, address _to)
        private
        view
        returns (bool)
    {
        uint256 current = block.timestamp;
        return
            _from == uniswapV2Pair &&
            !_isExcludedFromFees[_to] &&
            current >= swapStartTime &&
            current < swapStartTime.add(10 minutes);
    }

    function _isTakeFee(address _from, address _to)
        private
        view
        returns (bool)
    {
        if (
            _isExcludedFromFees[_from] ||
            _isExcludedFromFees[_to] ||
            _swapping ||
            holds >= takeFeeCondition
        ) {
            return false;
        }
        return true;
    }

    function _isSwapFee(address _from, address _to)
        private
        view
        returns (bool)
    {
        return
            !_swapping &&
            _from != uniswapV2Pair &&
            _from != owner() &&
            _to != owner() &&
            block.timestamp >= (_lastSwapTime + swapInterval);
    }

    function _swapFee() private {
        _swapping = true;
        if (TAmountLpFee > 0) {
            uint256 tLpAmount = _swapAndLiquify(TAmountLpFee);
            TAmountLpFee = 0;
            uint256 lpRewardAmount = tLpAmount.div(lpFee.add(lpRewardFee)).mul(lpRewardFee);
            uint256 lpAmount = tLpAmount.sub(lpRewardAmount);
            IERC20(uniswapV2Pair).transfer(address(dividendTracker),lpRewardAmount);
            IERC20(uniswapV2Pair).transfer(lpReceiveAddress,lpAmount);
        }
        _lastSwapTime = block.timestamp;
        _swapping = false;
    }

    function _takeFee(address _from,address _to, uint256 _amount)
        private
        returns (uint256 amountAfter)
    {
        amountAfter = _amount;
        //分享奖励
        address[] memory referrals = referral.getReferrals(
            _from == uniswapV2Pair?_to:_from,
            referralFees.length
        );
        for (uint256 i = 0; i < referrals.length; i++) {
            address to = referrals[i];
            uint256 reward = _amount.mul(referralFees[i]).div(1000);
            super._transfer(_from, to==address(0)?marketingAddress:to, reward);
            amountAfter = amountAfter.sub(reward);
        }

        //母币lp
        uint256 WFee = _amount.mul(defiWzLpFee).div(1000);
        if (WFee > 0) super._transfer(_from, defiWzLpAddress, WFee);
        amountAfter = amountAfter.sub(WFee);
        
        //nft
        uint256 NFee = _amount.mul(wzDaoNftFee).div(1000);
        if (NFee > 0) super._transfer(_from, wzDaoNftAddress, NFee);
        amountAfter = amountAfter.sub(NFee);
        
        //营销
        uint256 MFee = _amount.mul(marketingFee).div(1000);
        if (MFee > 0) super._transfer(_from, marketingAddress, MFee);
        amountAfter = amountAfter.sub(MFee);

        //lp
        uint256 LPFee = _amount.mul(lpRewardFee.add(lpFee)).div(1000);
        TAmountLpFee = TAmountLpFee.add(LPFee);
        if (LPFee > 0) super._transfer(_from, address(this), LPFee);
        amountAfter = amountAfter.sub(LPFee);
    }

    function _swapAndLiquify(uint256 tokenAmount) private returns(uint256 result){
        uint256 half = tokenAmount.div(2);
        uint256 otherHalf = tokenAmount.sub(half);
        uint256 newBalance = _swapTokensForUsdt(half);
        result = _addLiquidity(otherHalf, newBalance);
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function _swapTokensForUsdt(uint256 tokenAmount)
        private
        returns (uint256 amount)
    {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(usdt);
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uint256 before = usdt.balanceOf(address(this));
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(wrap),
            block.timestamp
        );
        wrap.withdraw();
        return usdt.balanceOf(address(this)).sub(before);
    }

    function _addLiquidity(uint256 tokenAmount, uint256 usdtAmount) private returns(uint256 result){
        usdt.approve(address(uniswapV2Router), usdtAmount);
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        (,,result) = uniswapV2Router.addLiquidity(
            address(this),
            address(usdt),
            tokenAmount,
            usdtAmount,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    function _setBlacklist(address _address, bool _v) private {
        if (_blacklist[_address] != _v) {
            _blacklist[_address] = _v;
            emit SetBlacklist(_address, _v);
        }
    }

    function withdraw(address _token, address payable _to) external onlyOwner {
        if (_token == address(0x0)) {
            payable(_to).transfer(address(this).balance);
        } else {
            IERC20(_token).transfer(
                _to,
                IERC20(_token).balanceOf(address(this))
            );
        }
    }

    function excludeFromFees(address account, bool _v) public onlyOwner {
        if (_isExcludedFromFees[account] != _v) {
            _isExcludedFromFees[account] = _v;
            emit ExcludeFromFees(account, _v);
        }
    }

    function setBlacklist(address _address, bool _v) external onlyOwner {
        _setBlacklist(_address, _v);
    }

    function excludeMultipleAccountsFromFees(
        address[] calldata accounts,
        bool _v
    ) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = _v;
        }
        emit ExcludeMultipleAccountsFromFees(accounts, _v);
    }

    function batchSetBlacklist(address[] calldata accounts, bool _v)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < accounts.length; i++) {
            _blacklist[accounts[i]] = _v;
        }
        emit BatchSetBlacklist(accounts, _v);
    }

    function setMinPeriod(uint256 number) external onlyOwner {
        minPeriod = number;
    }

    function resetLPRewardLastSendTime() external onlyOwner {
        dividendTracker.resetLPRewardLastSendTime();
    }

    function setSwapStartTime(uint256 _time) external onlyOwner {
        swapStartTime = _time;
    }

    function setSwapInterval(uint256 _interval) external onlyOwner {
        swapInterval = _interval;
    }

    function setMarketingAddress(address _address) external onlyOwner {
        marketingAddress = _address;
    }

    function setWzDaoNftAddress(address _address) external onlyOwner {
        wzDaoNftAddress = _address;
    }

    function setDefiWzLpAddress(address _address) external onlyOwner {
        defiWzLpAddress = _address;
    }

    function setTakeFeeCondition(uint256 _c) external onlyOwner{
        takeFeeCondition = _c;
    }

    function setLpReceiveAddress(address _address) external onlyOwner {
        lpReceiveAddress = _address;
    }

    function updateDistributorGas(uint256 newValue) external onlyOwner {
        require(
            newValue >= 100000 && newValue <= 500000,
            "distributorGas must be between 200,000 and 500,000"
        );
        require(
            newValue != distributorGas,
            "Cannot update distributorGas to same value"
        );
        distributorGas = newValue;
    }

    function setHold(address _address) public {
        uint256 balance = balanceOf(_address);
        bool isHol = isHold(_address);
        if(isHol && balance <= 0){
            _isHold[_address] = false;
            holds -= 1;
        }
        if(!isHol && balance>0){
            _isHold[_address] = true;
            holds += 1;
        }
    }
}