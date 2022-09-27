// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./libraries/WhiteList.sol";

contract PrivateRound is WhiteList {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public token;

    uint256 public tokensPerBnb;

    uint256 public timeStart;
    uint256 public timeEnd;

    uint256 public timeLock = 60 * 60 * 24 * 180;

    // Contributions state
    mapping(address => uint256) public contributions;

    mapping(address => Data) public data;

    // Total wei raised (BNB)
    uint256 public weiRaised = 0;

    uint256 public maxWeiRaised = 200000000000000000000;
    
    uint256 public tokenRaised;

    uint256 public percentTokenFirst = 10;

    uint256 public timePeriod = 60 * 60 * 24 * 30;

    // 12 moth lock
    uint256 public countPeriodWithdraw = 12;

    uint256 public maxBuy = 50000000000000000000;
    uint256 public minBuy = 10000000000000000000;

    bool public isWhiteList;
    uint256 public timeBuyWhitelist;

    event Contribute(address indexed owner, uint256 tm, uint256 amount);

    event Withdraw(address indexed owner, uint256 tm ,uint256 amount);

    struct Data {
        uint256 timeContribute;
        uint256 amountWithdrawn;
        uint256 lastWithdrawn;
        uint256 countWithdrawn;
        bool isFirstWithdrawn;
    }

    //
    constructor(address _tokenEco, uint256 _tokensPerBnb) {
        token = IERC20(_tokenEco);
        tokensPerBnb = _tokensPerBnb;
    }

    function claim() public {
        // Validations.
        require(
            msg.sender != address(0),
            "Presle: beneficiary is the zero address"
        );
        require(contributions[msg.sender] > 0, "PRIVATEROUND:invalid");
        require(block.timestamp > timeEnd, "PRIVATEROUND:time_invalid");

        (
            uint256 _amountwithdrawNow,
            uint256 countWithdrawnSave,
            bool isFirstWithdrawSave
        ) = _caculateWithdraw(msg.sender);
        require(_amountwithdrawNow > 0, "PRIVATEROUND:AMOUNT_INVALID");
        token.safeTransfer(msg.sender, _amountwithdrawNow);

        data[msg.sender].amountWithdrawn = _amountwithdrawNow.add(
            data[msg.sender].amountWithdrawn
        );
        data[msg.sender].lastWithdrawn = block.timestamp;
        data[msg.sender].countWithdrawn = countWithdrawnSave;
        data[msg.sender].isFirstWithdrawn = isFirstWithdrawSave;
        emit Withdraw(msg.sender, block.timestamp, _amountwithdrawNow);
    }

    function contribute() public payable {
        // Validations.
        require(
            msg.sender != address(0),
            "Presle: beneficiary is the zero address"
        );

        require(isOpen() == true, "Crowdsale has not yet started");

        require(msg.value >= minBuy, "PRIVATEROUND:MINIMUM");

        require(maxWeiRaised >= weiRaised.add(msg.value), "PRIVATEROUND:maxWeiRaised");

        require(
            msg.value.add(contributions[msg.sender]) <= maxBuy,
            "PRIVATEROUND:MAXINUM"
        );

        if (isCheckWhiteList()) {
            require(
                isAddressInWhiteList(msg.sender) == true,
                "PRIVATEROUND: IS_NOT_WHITELISTED"
            );
        }

        _contribute(msg.sender, msg.value);
    }

    function getDataContribute(address _address)
        external
        view
        returns (uint256 weiRaisedContribute, uint256 amountTokens)
    {
        weiRaisedContribute = contributions[_address];
        amountTokens = _getTokenAmount(weiRaisedContribute);
    }

    // Calculate how many MANYs do they get given the amount of wei
    function _getTokenAmount(uint256 weiAmount) public view returns (uint256) {
        return weiAmount.mul(tokensPerBnb);
    }

    function withdrawToken() external {
       claim();
    }

    function getDataWithdraw(address _address)
        public
        view
        returns (uint256 amountWithdrawNow, Data memory _data)
    {
        (uint256 _amountwithdrawNow, , ) = _caculateWithdraw(_address);
        return (_amountwithdrawNow, data[_address]);
    }

    function _contribute(address beneficiary, uint256 weiAmount) internal {
        // Update how much wei we have raised
        weiRaised = weiRaised.add(weiAmount);
        // Update how much wei has this address contributed
        contributions[beneficiary] = contributions[beneficiary].add(weiAmount);
        
        Data memory _dataBuy = data[beneficiary];
        _dataBuy.timeContribute = block.timestamp;
        _dataBuy.amountWithdrawn = 0;
        _dataBuy.lastWithdrawn = 0;
        _dataBuy.countWithdrawn = 0;

        tokenRaised = tokenRaised.add(_getTokenAmount(weiAmount));

        data[beneficiary] = _dataBuy;

        emit Contribute(beneficiary, block.timestamp, weiAmount);
    }

    function setContribute(address _address, uint256 weiAmount) public onlyOwner{
        _contribute(_address, weiAmount);
    }

    function removeContribute(address _address) public onlyOwner {
        uint256 amountContributed = contributions[_address];
        tokenRaised = tokenRaised.sub(_getTokenAmount(amountContributed));
        weiRaised = weiRaised.sub(amountContributed);
        contributions[_address]=0;
    }

    function _caculateWithdraw(address _address)
        private
        view
        returns (
            uint256 amountTokenWithdraw,
            uint256 countWithdrawnSave,
            bool isFirstWithdrawSave
        )
    {
        if (block.timestamp < timeEnd) {
            return (0, 0, false);
        }


        Data memory _dataBuy = data[_address];
        uint256 amountFirst = _getTokenAmount(contributions[_address])
            .mul(percentTokenFirst)
            .div(100);

        uint256 _amountTokenWithdraw = _dataBuy.isFirstWithdrawn
            ? 0
            : amountFirst;

        if((timeEnd + timeLock) > block.timestamp) {
            return(_amountTokenWithdraw,0,true);
        }

        isFirstWithdrawSave = true;

        uint256 calCountTime = (block.timestamp - (timeEnd + timeLock)).div(timePeriod);
        calCountTime++;
        
        calCountTime = calCountTime > countPeriodWithdraw
            ? countPeriodWithdraw
            : calCountTime;
        uint256 countWithdraw = calCountTime > _dataBuy.countWithdrawn
            ? calCountTime - _dataBuy.countWithdrawn
            : 0;
        uint256 calTokenAmount = _getTokenAmount(contributions[_address]);
        _amountTokenWithdraw += (calTokenAmount.sub(amountFirst))
            .div(countPeriodWithdraw)
            .mul(countWithdraw);

        amountTokenWithdraw = _amountTokenWithdraw;
        countWithdrawnSave = _dataBuy.countWithdrawn.add(countWithdraw);
    }

    // funcitons isOpnen returns a bool by timeStart and timeEnd
    function isOpen() public view returns (bool) {
        return block.timestamp > timeStart && block.timestamp < timeEnd;
    }

    function isCheckWhiteList() public view returns (bool) {
        return isWhiteList && block.timestamp <= timeStart + timeBuyWhitelist;
    }

    function setMaxWeiRaised(uint256 max) public onlyOwner{
        maxWeiRaised = max; 
    }

    // funcitons setTime sets timeStart and timeEnd`
    function setTime(uint256 _timeStart, uint256 _timeEnd) public onlyOwner {
        require(_timeStart < _timeEnd);
        timeStart = _timeStart;
        timeEnd = _timeEnd;
    }

    function setWhiteList(bool _isWhiteList, uint256 _timeBuyWhitelist)
        public
        onlyOwner
    {
        isWhiteList = _isWhiteList;
        timeBuyWhitelist = _timeBuyWhitelist;
    }

    function takeAmountToken(address _address) public onlyOwner {
        require(msg.sender == address(0), "Presle: beneficiary is the zero address");

        uint256 balance = token.balanceOf(address(this));

        uint256 _amount = balance.sub(tokenRaised);

        require(_amount > 0, "PRIVATEROUND:AMOUNT_INVALID");
        
        token.safeTransfer(_address, _amount);
    }

    function takeOutFundingRaised()public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawAnyToken(address _token, address _to, uint256 _amount)
        public
        onlyOwner
    {
        require(_token != address(0), "Presle: beneficiary is the zero address");
        require(_to != address(0), "Presle: beneficiary is the zero address");
        require(_amount > 0, "PRIVATEROUND:AMOUNT_INVALID");

        IERC20(_token).safeTransfer(_to, _amount);
    }
    function setToken(address _token) public onlyOwner {
        token = IERC20(_token);
    }
    function setTokenPerBNB(uint256 _tokensPerBnb) public onlyOwner {
        tokensPerBnb = _tokensPerBnb;
    }
    function setMinMaxBuy(uint256 _min, uint256 _max) public onlyOwner {
        minBuy = _min;
        maxBuy = _max;
    }
}