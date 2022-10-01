// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "./FrozenToken.sol";
import "./token/ERC20/utils/SafeERC20.sol";

contract StakingTheKey{

    using SafeERC20 for FrozenToken;

    FrozenToken public _depositToken;
    uint256 public _priceUSDT;
    address public _owner;
    mapping(address => bool) public _b2s;
    address public _marketingContract;
    StakingTheKey public _oldStakingContract;
    address priceSetter;

    uint256 immutable _days = 1 days;
    //uint256 immutable _days = 2 minutes;

    struct Staking{
        uint256 amount;
        uint8 staking;
        uint256 StakingMonths;
        uint256 StakingPeriod;
        uint256 stakingTimestamp;
        uint256 daysRemains;
        bool frozen;
    }

    mapping(uint8 => uint8[]) public StakingPeriods;

    mapping(address => Staking[]) public holders;
    mapping(address => uint256) public holderStakingCount;

    modifier onlyOwner() {
        require(msg.sender == _owner, "caller is not Owner");
        _;
    }

    modifier onlyPriceSetter() {
        require(msg.sender == priceSetter || msg.sender == _owner, "caller is not Owner");
        _;
    }

    modifier onlyB2S() {
        require(_b2s[msg.sender] || msg.sender == _owner, "caller is not b2s");
        _;
    }

    event AddedToStakingNotActivated(address indexed user, uint256 amount);
    event AddedToStaking(address indexed user, uint256 amount, uint8 token, uint256 period);
    event WithdrawalPercents(address indexed user, uint256 amount, uint8 token);
    event WithdrawalBodyDeposit(address indexed user, uint256 amount, uint8 token);
    event ReinvestedPercents(address indexed user, uint256 amount, uint8 token);
    event AddedToTokenStaking(address indexed user, uint256 amount, uint8 token);

    constructor(address owner, FrozenToken depositToken, address migrationCaller){
        _owner = owner;
        _depositToken = depositToken;
        StakingPeriods[6].push(17); //6 months - 5% (0,17 in day)
        StakingPeriods[9].push(23); //9 months - 7% (0,23 in day)
        StakingPeriods[12].push(30); //12 months - 9% (0,3 in day)
        StakingPeriods[24].push(40); //24 months - 12% (0,4 in day)
        StakingPeriods[24].push(50); //24 months - 15% (0,5 in day)
        StakingPeriods[24].push(57); //24 months - 17% (0,57 in day)
        StakingPeriods[24].push(60); //24 months - 18% (0,6 in day)
        StakingPeriods[24].push(67); //24 months - 20% (0,67 in day)
    }

    function newOwner(address _newOwner) public onlyOwner{
        _owner = _newOwner;
    }

    function setOldStakingContract(address oldStakingContract) public onlyOwner{
        _oldStakingContract = StakingTheKey(oldStakingContract);
    }

    function setMarketingContract(address marketingContract) public onlyOwner{
        _marketingContract = marketingContract;
    }

    function setB2S(address b2s) public onlyOwner{
        _b2s[b2s] = true;
    }

    function setPriceSetter(address _priceSetter) public onlyOwner{
        priceSetter = _priceSetter;
    }

    function setPriceUSDT(uint256 priceUSDT) public onlyPriceSetter{
        _priceUSDT = priceUSDT;
    }

    function getPriceUSDT() public view returns(uint256){
        return _priceUSDT;
    }

    function getPeriods(uint8 period) public view returns(uint8[] memory){
        return StakingPeriods[period];
    }

    function getStaking(address user) public view returns (Staking[] memory) {
        return holders[user];
    }

    function transferFromTheOld(address[] memory users) public onlyOwner{
        for(uint256 i; i < users.length; i++){
            Staking[] memory st = _oldStakingContract.getStaking(users[i]);
            for(uint256 s; s < st.length; s++){
                holders[users[i]].push(Staking(st[s].amount, st[s].staking, st[s].StakingMonths, st[s].StakingPeriod, st[s].stakingTimestamp, st[s].daysRemains, st[s].frozen));
                holderStakingCount[users[i]]++;
            }
        }
    }

    function transferFromTheOldOne(address user, uint256 num) public onlyOwner{
        Staking[] memory st = _oldStakingContract.getStaking(user);
        holders[user].push(Staking(st[num].amount, st[num].staking, st[num].StakingMonths, st[num].StakingPeriod, st[num].stakingTimestamp, st[num].daysRemains, st[num].frozen));
        holderStakingCount[user]++;
    }

    function transferTokenToStaking(uint256 amount, uint8 period, uint256 PV) public {
        require(amount > 0, "The amount cannot be zero");
        require(StakingPeriods[period][0] != 0, "There is no such staking period");

        uint8 per;
        if(PV < 1000){
            require(period != 24, "Insufficient Personal Volume for staking for this period");
            per = StakingPeriods[period][0];
        }else{
            if(period == 24){
                if(PV < 15000){
                    per = StakingPeriods[period][0];
                }else if(PV < 75000){
                    per = StakingPeriods[period][1];
                }else if(PV < 200000){
                    per = StakingPeriods[period][2];
                }else if(PV < 1000000){
                    per = StakingPeriods[period][3];
                }else{
                    per = StakingPeriods[period][4];
                }
            }else{
                per = StakingPeriods[period][0];
            }
        }

        uint256 periodDays = uint256(period) * 30;
        _depositToken.safeTransferFrom(msg.sender, address(this), amount);
        holders[msg.sender].push(Staking(amount, 1, period, per, block.timestamp, periodDays, false));
        holderStakingCount[msg.sender]++;
        emit AddedToStaking(msg.sender, amount, 1, period);
    }

    function transferFrozenToStaking(uint8 period, uint8 token, uint256 PV) public {
        require(StakingPeriods[period][0] != 0, "There is no such staking period");
        uint256 timestamp = block.timestamp;
        bool fr;
        for(uint i; i < holderStakingCount[msg.sender]; i++){
            if(holders[msg.sender][i].frozen && holders[msg.sender][i].staking == token){
                uint256 per;
                if(PV < 1000){
                    if(period == 24){
                        per = StakingPeriods[12][0];
                        period = 12;
                    }else{
                        per = StakingPeriods[period][0];
                    }
                }else{
                    if(period == 24){
                        if(PV < 15000){
                            per = StakingPeriods[period][0];
                        }else if(PV < 75000){
                            per = StakingPeriods[period][1];
                        }else if(PV < 200000){
                            per = StakingPeriods[period][2];
                        }else if(PV < 1000000){
                            per = StakingPeriods[period][3];
                        }else{
                            per = StakingPeriods[period][4];
                        }
                    }else{
                        per = StakingPeriods[period][0];
                    }
                }
                fr = true;
                uint256 periodDays = uint256(period) * 30;
                holders[msg.sender][i].StakingPeriod = per;
                holders[msg.sender][i].stakingTimestamp = timestamp;
                holders[msg.sender][i].StakingMonths = period;
                holders[msg.sender][i].daysRemains = periodDays;
                holders[msg.sender][i].frozen = false;
                emit AddedToStaking(msg.sender, holders[msg.sender][i].amount, token, period);
            }
        }
        require(fr, "No pending Tokens");
    }

    function transferAdminTokenToStaking(address user, uint8 token, uint256 amount, uint8 period, uint8 index) public onlyOwner{
        require(user != address(0), "User with zero address");
        require(amount > 0, "The amount cannot be zero");
        require(StakingPeriods[period][index] != 0, "There is no such staking period");
        uint256 periodDays = uint256(period) * 30;
        if(token == 1){
            _depositToken.safeTransferFrom(msg.sender, address(this), amount);
        }
        holders[user].push(Staking(amount, token, period, StakingPeriods[period][index], block.timestamp, periodDays, false));
        holderStakingCount[user]++;
        emit AddedToStaking(user, amount, token, period);
    }

    function delivery(
		address user,
		uint8 token,
		uint256 amount
	) external onlyB2S {
        holders[user].push(Staking(amount, token, 0, 0, 0, 0, true));
        holderStakingCount[user]++;
        emit AddedToStakingNotActivated(user, amount);
	}

    function withdrawPercents(uint8 token) public{
        for(uint i; i < holders[msg.sender].length; i++){
            if(holders[msg.sender][i].staking == token){
                withdrawOneStakingPercents(i);
            }
        }
    }

    function withdrawPercentsForPeriod(uint8 token, uint256 period) public{
        for(uint i; i < holders[msg.sender].length; i++){
            if(holders[msg.sender][i].staking == token && holders[msg.sender][i].StakingMonths == period){
                withdrawOneStakingPercents(i);
            }
        }
    }

    function withdrawOneStakingPercents(uint256 stakingNum) public{
        require(stakingNum < holders[msg.sender].length, "Staking does not exist");
        uint256 amount;
        uint256 amountUSDT;
        uint256 bAmount;
        uint256 bAmountUSDT;
        uint256 timestamp = block.timestamp;
        
        if(holders[msg.sender][stakingNum].stakingTimestamp != 0 || !holders[msg.sender][stakingNum].frozen){
            (uint256 days_, uint256 remains) = getDate(msg.sender, stakingNum);
            if(days_ > 0){
                holders[msg.sender][stakingNum].stakingTimestamp = timestamp - remains;
                if(holders[msg.sender][stakingNum].daysRemains > days_){
                    holders[msg.sender][stakingNum].daysRemains -= days_;
                    if(holders[msg.sender][stakingNum].staking == 1){
                        amount = (holders[msg.sender][stakingNum].amount * holders[msg.sender][stakingNum].StakingPeriod / 100) / 100 * days_;
                    }else if(holders[msg.sender][stakingNum].staking == 0){
                        amountUSDT = (holders[msg.sender][stakingNum].amount * holders[msg.sender][stakingNum].StakingPeriod / 100) / 100 * days_;
                    }
                }else{
                    if(holders[msg.sender][stakingNum].staking == 1){
                        amount = (holders[msg.sender][stakingNum].amount * holders[msg.sender][stakingNum].StakingPeriod / 100) / 100 * holders[msg.sender][stakingNum].daysRemains;
                        bAmount = holders[msg.sender][stakingNum].amount;
                    }else if(holders[msg.sender][stakingNum].staking == 0){
                        amountUSDT = (holders[msg.sender][stakingNum].amount * holders[msg.sender][stakingNum].StakingPeriod / 100) / 100 * holders[msg.sender][stakingNum].daysRemains;
                        bAmountUSDT = holders[msg.sender][stakingNum].amount;
                    }
                }
            }
        }

        uint256 allStakingAmount;
        uint256 nAmount;
        
        if(amount > 0){
            _depositToken.mint(msg.sender, amount * 75 / 100);
            _depositToken.mint(_marketingContract, amount * 25 / 100);
            if(holders[msg.sender][stakingNum].StakingPeriod >= 12){
                allStakingAmount = holders[msg.sender][stakingNum].amount;
            }
            nAmount += amount * 25 / 100;
            emit WithdrawalPercents(msg.sender, amount, 1);
        }
        if(bAmount > 0){
            _depositToken.safeTransfer(msg.sender, bAmount);
            if(holders[msg.sender].length > 1){
                holders[msg.sender][stakingNum] = holders[msg.sender][holders[msg.sender].length - 1];
            }
            holders[msg.sender].pop();
            holderStakingCount[msg.sender]--;
            emit WithdrawalBodyDeposit(msg.sender, bAmount, 1);
        }
        if(amountUSDT > 0){
            amountUSDT = 10 ** _depositToken.decimals() * amountUSDT / _priceUSDT;
            _depositToken.mint(msg.sender, amountUSDT * 75 / 100);
            _depositToken.mint(_marketingContract, amountUSDT * 25 / 100);
            if(holders[msg.sender][stakingNum].StakingPeriod == 12){
                allStakingAmount = holders[msg.sender][stakingNum].amount;
            }
            nAmount += amountUSDT * 25 / 100;
            emit WithdrawalPercents(msg.sender, amountUSDT, 0);
        }
        if(bAmountUSDT > 0){
            bAmountUSDT = 10 ** _depositToken.decimals() * bAmountUSDT / _priceUSDT;
            _depositToken.mint(msg.sender, bAmountUSDT);
            if(holders[msg.sender].length > 1){
                holders[msg.sender][stakingNum] = holders[msg.sender][holders[msg.sender].length - 1];
            }
            holders[msg.sender].pop();
            holderStakingCount[msg.sender]--;
            emit WithdrawalBodyDeposit(msg.sender, bAmountUSDT, 0);
        }
        
        (bool success,) = _marketingContract
        .call(abi.encodeWithSignature("depositPools(address,uint256,uint256)",
        msg.sender,nAmount,allStakingAmount));
        require(success,"depositPools call FAIL");
    }

    function addToStaking(uint256 amount, uint256 stakingNum) public{
        require(stakingNum < holders[msg.sender].length, "Staking does not exist");
        require(holders[msg.sender][stakingNum].staking == 1, "Staking is not in the project tokens!");
        require(amount > 0, "The amount cannot be zero");
        _depositToken.safeTransferFrom(msg.sender, address(this), amount);
        (uint256 m, ) = getDate(msg.sender, stakingNum);
        if(m > 0){
            reinvestOneStakingPercents(stakingNum);
        }
        holders[msg.sender][stakingNum].amount += amount;
        emit AddedToTokenStaking(msg.sender, amount, 1);
    }

    function reinvestStakingPercents(uint8 token) public{
        for(uint i; i < holders[msg.sender].length; i++){
            if(holders[msg.sender][i].staking == token){
                reinvestOneStakingPercents(i);
            }
        }
    }

    function reinvestStakingPercentsForPeriod(uint8 token, uint256 period) public{
        for(uint i; i < holders[msg.sender].length; i++){
            if(holders[msg.sender][i].staking == token && holders[msg.sender][i].StakingMonths == period){
                reinvestOneStakingPercents(i);
            }
        }
    }

    function reinvestOneStakingPercents(uint256 stakingNum) public{
        require(stakingNum < holders[msg.sender].length, "Staking does not exist");
        Staking memory st = holders[msg.sender][stakingNum];
        uint256 amount;
        uint256 amountUSDT;
        
        if(st.stakingTimestamp != 0 || !st.frozen){
            (uint256 days_, uint256 remains) = getDate(msg.sender, stakingNum);
            if(days_ > 0 || st.daysRemains > days_){
                st.stakingTimestamp = block.timestamp - remains;
                if(st.daysRemains > days_){
                    st.daysRemains -= days_;
                    if(st.staking == 1){
                        amount += (st.amount * st.StakingPeriod / 100) / 100 * days_;
                    }else if(st.staking == 0){
                        amountUSDT += (st.amount * st.StakingPeriod / 100) / 100 * days_;
                    }
                }
            }
        }

        uint256 allStakingAmount;
        uint256 nAmount;
        
        if(amount > 0){
            _depositToken.mint(_marketingContract, amount * 25 / 100);
            if(st.StakingPeriod >= 12){
                allStakingAmount += st.amount;
            }
            st.amount += amount * 75 / 100;
            _depositToken.mint(address(this), amount * 75 / 100);
            nAmount += amount * 25 / 100;
            (bool success,) = _marketingContract
            .call(abi.encodeWithSignature("depositPools(address,uint256,uint256)",
            msg.sender,nAmount,allStakingAmount));
            require(success,"depositPools call FAIL");
            emit ReinvestedPercents(msg.sender, amount, 1);
        }
        if(amountUSDT > 0){
            st.amount += amountUSDT;
            emit ReinvestedPercents(msg.sender, amountUSDT, 0);
        }

        holders[msg.sender][stakingNum] = st;
    }

    function getDate(address user, uint cell) public view returns(uint256 days_, uint256 remains){
        remains = block.timestamp - holders[user][cell].stakingTimestamp;
        while(remains >= _days){
            remains -= _days;
            days_++;
        }
    }

    function withdrawLostTokens(IERC20 tokenAddress) public {
        if (tokenAddress != IERC20(address(0))) {
            tokenAddress.transfer(msg.sender, tokenAddress.balanceOf(address(this)));
        }
    }
}