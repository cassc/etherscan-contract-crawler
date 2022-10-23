// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "../router.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract CK_Stake is OwnableUpgradeable {
    IERC20 public U;
    IERC20 public ck;
    IPancakeRouter02 public router;
    address public pair;
    uint public TVL;
    uint constant acc = 1e10;
    uint[] scale;
    uint[] public rate;
    bool public status;
    address public wallet;
    uint public stakeLimit;
    uint public referRewardAmount;
    address public ckPair;
    address constant burnAddress = 0x000000000000000000000000000000000000dEaD;
    uint public outRate;

    struct UserInfo {
        address invitor;
        uint totalPower;
        uint stakeAmount;
        uint refer;
        uint refer_n;
        uint referAmount;
        uint claimed;
        uint referReward;
        uint claimedQuota;
        uint claimTime;
    }

    mapping(address => UserInfo) public userInfo;
    uint public reBuyAmount;
    uint public totalClaimed;
    uint public priceSet;
    mapping(address => bool) public stakeW;

    struct TokenInfo {
        IERC20 addr;
        address pair;
        bool status;
    }

    mapping(uint => TokenInfo) public tokenInfo;
    uint[] tokenList;
    mapping(address => bool) public tokenStatus;
    uint[] referLevel;
    uint[] rewardList;
    mapping(address => uint) public userLevelReward;
    mapping(address => uint) public userLevelSet;
    uint public rateChangeTime;

    event Bond(address indexed addr, address indexed invitor_);
    event Stake(address indexed addr, uint indexed amount);
    using AddressUpgradeable for address;
    function initialize() initializer public {
        __Ownable_init_unchained();
        status = true;
        router = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        stakeLimit = 500 ether;
        U = IERC20(0x55d398326f99059fF775485246999027B3197955);
        ck = IERC20(0x89B575938a84B05dF228268e64524640B7aF00c3);
        pair = 0x8d927CaEb3482FcC052F3884535a6e20F1058f88;
        ckPair = 0x8d927CaEb3482FcC052F3884535a6e20F1058f88;
        referLevel = [0, 20000 ether, 100000 ether, 300000 ether];
        rewardList = [0, 16 ether, 24 ether, 40 ether];
        wallet = 0xca01F83CF51b12Ac62FB058E6e8e351bFf95e609;
        outRate = 180;
        rate = [10, 13];
        swapApprove();
    }

    modifier onlyEOA {
        require(!msg.sender.isContract(), 'not allowed');
        require(msg.sender == tx.origin, 'not allowed');
        _;
    }

    modifier rateChange{
        if (U.balanceOf(pair) > 2000000 ether) {
            rateChangeTime = block.timestamp;
        }
        _;
    }


    function setStakeLimit(uint limit) external onlyOwner {
        stakeLimit = limit;
    }

    function setU(address u_) external onlyOwner {
        U = IERC20(u_);
    }

    function setCkPair(address pair_) external onlyOwner {
        ckPair = pair_;
    }

    function setWallet(address addr) external onlyOwner {
        wallet = addr;
    }

    function setReferLevel(uint[] memory referL) external onlyOwner {
        referLevel = referL;
    }

    function setRewardL(uint[] memory rewL) external onlyOwner {
        rewardList = rewL;
    }

    function setToken(address token_) external onlyOwner {
        ck = IERC20(token_);
    }

    function setRouter(address addr) external onlyOwner {
        router = IPancakeRouter02(addr);
    }

    function getTokenPrice(uint tokenIndex) public view returns (uint){
        TokenInfo memory info = tokenInfo[tokenIndex];
        if (!info.status) {
            return 0;
        }
        uint balance1 = U.balanceOf(info.pair);
        uint balance2 = info.addr.balanceOf(info.pair);
        uint price = balance1 * (10 ** (info.addr.decimals())) / balance2;
        return price;
    }

    function addTokenInfo(address token_) external onlyOwner {
        require(!tokenStatus[token_], 'already add');
        tokenStatus[token_] = true;
        tokenList.push(tokenList.length + 1);
        address pairs = IPancakeFactory(router.factory()).getPair(token_, address(U));
        require(pairs != address(0), 'wrong token pair');
        tokenInfo[tokenList.length].pair = pairs;
        tokenInfo[tokenList.length].addr = IERC20(token_);
        tokenInfo[tokenList.length].status = true;
    }

    function editStatus(uint tokenIndex, bool b) external onlyOwner {
        tokenInfo[tokenIndex].status = b;
    }


    function setStatus(bool b) external onlyOwner {
        status = b;
    }


    function setStakeList(address addr, bool b) external onlyOwner {
        stakeW[addr] = b;
    }

    function setPair(address pair_) external onlyOwner {
        pair = pair_;
    }

    function setPrice(uint price_) external onlyOwner {
        priceSet = price_;
    }

    function getCkPrice() public view returns (uint){

        if (priceSet > 0) {
            return priceSet;
        }
        if (pair == address(0)) {
            return 1e19;
        }
        uint balance1 = U.balanceOf(pair);
        uint balance2 = ck.balanceOf(pair);
        uint price = balance1 * 1e18 / balance2;
        return price;
    }

    function countingQuota(uint amount, uint price) public pure returns (uint){
        uint out = amount * price / 1e18;
        return out;
    }

    function countingToken(uint amount, uint price, uint tokenIndex) public view returns (uint){
        uint out = amount * 10 ** (tokenInfo[tokenIndex].addr.decimals()) / price;
        return out;
    }

    function countingCk(uint amount, uint price) public pure returns (uint){
        uint out = amount * 1e18 / price;
        return out;
    }

    function countingPower(uint uAmount) public view returns (uint){
        return uAmount * outRate / 100;
    }

    function calculateReward(address addr) public view returns (uint){
        UserInfo storage user = userInfo[addr];
        uint rew;
        uint quota = user.totalPower - user.claimedQuota;
        if (rateChangeTime == 0) {
            uint tempRate = quota * rate[0] / 1000 / 86400;
            rew = (block.timestamp - user.claimTime) * tempRate;
        } else {
            if (user.claimTime >= rateChangeTime) {
                uint tempRate = quota * rate[1] / 1000 / 86400;
                rew = (block.timestamp - user.claimTime) * tempRate;
            } else {
                uint tempRate = quota * rate[1] / 1000 / 86400;
                rew = (block.timestamp - rateChangeTime) * tempRate;
                tempRate = quota * rate[0] / 1000 / 86400;
                rew += (rateChangeTime - user.claimTime) * tempRate;
            }
        }
        if (rew > user.totalPower - user.claimedQuota) {
            rew = user.totalPower - user.claimedQuota;
        }
        uint out = countingCk(rew, getCkPrice());
        return out;


    }

    function _calculateReward(address addr) public view returns (uint, bool){
        UserInfo storage user = userInfo[addr];
        uint rew;
        bool out = false;
        uint quota = user.totalPower - user.claimedQuota;
        if (rateChangeTime == 0) {
            uint tempRate = quota * rate[0] / 1000 / 86400;
            rew = (block.timestamp - user.claimTime) * tempRate;
        } else {
            if (user.claimTime >= rateChangeTime) {
                uint tempRate = quota * rate[1] / 1000 / 86400;
                rew = (block.timestamp - user.claimTime) * tempRate;
            } else {
                uint tempRate = quota * rate[1] / 1000 / 86400;
                rew = (block.timestamp - rateChangeTime) * tempRate;
                tempRate = quota * rate[0] / 1000 / 86400;
                rew += (rateChangeTime - user.claimTime) * tempRate;
            }
        }

        if (rew >= user.totalPower - user.claimedQuota) {
            rew = user.totalPower - user.claimedQuota;
            out = true;
        }
        return (rew, out);


    }

    function checkAllToken() public view returns (uint[] memory index, string[] memory names, uint[] memory decimals, address[] memory addrs, uint[] memory price_){
        uint temp;
        for (uint i = 0; i < tokenList.length; i++) {
            if (tokenInfo[tokenList[i]].status) {
                temp++;
            }
        }
        index = new uint[](temp);
        names = new string[](temp);
        decimals = new uint[](temp);
        addrs = new address[](temp);
        price_ = new uint[](temp);
        for (uint i = 0; i < tokenList.length; i++) {
            if (tokenInfo[tokenList[i]].status) {
                index[temp - 1] = tokenList[i];
                names[temp - 1] = tokenInfo[tokenList[i]].addr.symbol();
                decimals[temp - 1] = tokenInfo[tokenList[i]].addr.decimals();
                addrs[temp - 1] = address(tokenInfo[tokenList[i]].addr);
                price_[temp - 1] = getTokenPrice(tokenList[i]);
                temp--;
            }
        }
    }

    function _processOut(address addr) internal {
        UserInfo storage user = userInfo[addr];
        TVL -= user.totalPower;
        _processReferAmount(addr, user.stakeAmount);
        user.totalPower = 0;
        user.stakeAmount = 0;
        user.claimedQuota = 0;
        user.claimTime = block.timestamp;

    }

    function _processReferAmount(address addr, uint amount) internal {
        address temp = userInfo[addr].invitor;
        for (uint i = 0; i < 10; i++) {
            if (temp == address(0) || temp == address(this)) {
                break;
            }
            if (userInfo[temp].referAmount < amount) {
                userInfo[temp].referAmount = 0;
            }
            if (userInfo[temp].referAmount >= amount) {
                userInfo[temp].referAmount -= amount;
            }

            temp = userInfo[temp].invitor;
        }
    }

    //    function _processReferLevelReward(address addr, uint price, uint tokenIndex) internal {
    //        uint totalU = 80 ether;
    //        uint left = totalU;
    //        address temp = userInfo[addr].invitor;
    //        uint tempLevel;
    //        uint lastLevel;
    //        for (uint i = 0; i < 10; i++) {
    //            if (temp == address(0) || temp == address(this)) {
    //                break;
    //            }
    //            tempLevel = getUserLevel(temp);
    //            if (tempLevel <= lastLevel || userInfo[temp].totalPower < rewardList[tempLevel]) {
    //                temp = userInfo[temp].invitor;
    //                continue;
    //            }
    //            lastLevel = tempLevel;
    //            uint rew = rewardList[tempLevel];
    //            left -= rew;
    //            uint tokenRew = countingToken(rew, price, tokenIndex);
    //            userLevelReward[temp] += tokenRew;
    //            tokenInfo[tokenIndex].addr.transfer(temp, tokenRew);
    //            if (lastLevel == 3) {
    //                break;
    //            }
    //        }
    //        if (left >= 1 ether) {
    //            tokenInfo[tokenIndex].addr.transfer(referTokenAddress, countingToken(left, price, tokenIndex));
    //        }
    //    }

    function _processRefer(address addr, uint price) internal {
        uint amount = 50 ether;
        uint _tempRew = amount / 10;
        address temp = userInfo[addr].invitor;
        uint ckPrice = price;
        uint totalOut;
        bool isOut;
        uint rew;
        uint tempLevel;
        uint lastLevel = getUserLevel(addr);
        bool[] memory isReward = new bool[](4);
        for (uint i = 0; i < 40; i++) {
            uint tempRew;
            if (i < 10) {
                tempRew = _tempRew;
            } else {
                tempRew = 0;
            }


            if (temp == address(0) || temp == address(this)) {
                break;
            }

            UserInfo storage info = userInfo[temp];
            if (
                info.totalPower == 0) {
                temp = info.invitor;
                continue;
            }
            tempLevel = getUserLevel(temp);
            if (tempLevel > lastLevel) {
                tempRew += rewardList[tempLevel];
                lastLevel = tempLevel;
            } else if (tempLevel == lastLevel && !isReward[tempLevel] && tempLevel != 0) {
                tempRew += rewardList[tempLevel] / 10;
                isReward[tempLevel] = true;
            }
            if (tempRew == 0) {
                temp = info.invitor;
                continue;
            }


            (rew, isOut) = _calculateReward(temp);
            uint leftQuota = info.totalPower - info.claimedQuota;
            if (leftQuota < tempRew) {
                _processTransfer(temp, leftQuota, ckPrice);
                userInfo[temp].claimed += countingCk(leftQuota, ckPrice);
                userInfo[temp].referReward += leftQuota;
                _processOut(temp);
                temp = info.invitor;
                continue;
            }

            if (isOut) {
                uint power = info.totalPower;
                uint finalRew = countingCk(rew, ckPrice);
                info.totalPower = 0;
                info.stakeAmount = 0;
                info.claimedQuota = 0;
                totalOut += power;
                info.claimed += finalRew;
                totalClaimed += finalRew * 98 / 100;
                ck.transfer(temp, finalRew * 98 / 100);
                ck.transfer(wallet, finalRew / 50);
            } else {
                info.referReward += tempRew;
                info.claimedQuota += tempRew;
                _processTransfer(temp, tempRew, ckPrice);
            }
            temp = info.invitor;

        }
        TVL -= totalOut;
    }

    function swapApprove() public onlyOwner {
        U.approve(address(router), 1000000e28);
    }

    function reBuyCK(uint amount) internal {
        address[] memory path = new address[](2);
        path[0] = address(U);
        path[1] = address(ck);
        U.approve(address(router), amount * 2);
        // make the swap
        router.swapExactTokensForTokens(
            amount,
            0,
            path,
            wallet,
            block.timestamp + 720
        );
        reBuyAmount = 0;
    }

    function setUserLevel(address addr, uint level) external onlyOwner {
        userLevelSet[addr] = level;
    }


    function getUserLevel(address addr) public view returns (uint){
        uint amount = userInfo[addr].referAmount;
        if (userLevelSet[addr] != 0) {
            return userLevelSet[addr];
        }
        if (amount == 0 || userInfo[addr].totalPower == 0) {
            return 0;
        }

        uint level = 3;
        for (uint i = 0; i < referLevel.length; i++) {
            if (amount < referLevel[i]) {
                level = i - 1;
                break;
            }
        }
        return level;
    }

    function _processTransfer(address addr, uint uAmount, uint ckPrice) internal {
        uint rew = countingCk(uAmount / 2, ckPrice);
        ck.transfer(addr, rew);
        userInfo[addr].claimed += rew;
        U.transfer(addr, uAmount / 2);
    }


    function stake(uint amount, uint tokenIndex, address invitor) external onlyEOA rateChange {
        require(status, 'not start yet');
        require(amount >= stakeLimit, 'lower than min');
        require(amount <= 510 ether, 'out of limit');
        require(userInfo[msg.sender].totalPower == 0, 'staked');
        IERC20 tokens = tokenInfo[tokenIndex].addr;
        if (userInfo[msg.sender].invitor == address(0)) {
            require(userInfo[invitor].invitor != address(0) || invitor == address(this), 'wrong invitor');
            userInfo[msg.sender].invitor = invitor;
            userInfo[invitor].refer_n++;
            address temps = userInfo[msg.sender].invitor;
            for (uint i = 0; i < 20; i++) {
                if (temps == address(0) || temps == address(this)) {
                    break;
                }
                userInfo[temps].refer ++;
                userInfo[temps].referAmount += amount;
                temps = userInfo[temps].invitor;
            }
        }
        uint power = countingPower(amount);
        uint price = getTokenPrice(tokenIndex);
        uint tokenNeed = countingToken(amount / 2, price, tokenIndex);
        uint uAmount = amount / 2;
        if (!stakeW[msg.sender]) {
            U.transferFrom(msg.sender, address(this), uAmount);
            tokens.transferFrom(msg.sender, address(this), tokenNeed);
            address temp = userInfo[msg.sender].invitor;
            uint leftQuota = userInfo[temp].totalPower - userInfo[temp].claimedQuota;
            if (leftQuota < 200 ether) {
                _processTransfer(temp, leftQuota, price);
                userInfo[temp].referReward += leftQuota;
                _processOut(temp);
            } else {
                _processTransfer(temp, 200 ether, price);
                userInfo[temp].referReward += 200 ether;
                userInfo[temp].claimedQuota += 200 ether;
            }
        }
        if (!stakeW[msg.sender]) {
            _processRefer(msg.sender, price);
            ck.transfer(0x4Ba1421168D9e75D6918E965bE45F8B9fbab447f, countingCk(81 ether, price));
            //            reBuyCK(81 ether);
            U.transfer(0x62A22c93A07aBE23960857551363A75588977Cfe, U.balanceOf(address(this)));
        }
        TVL += power;
        userInfo[msg.sender].totalPower = power;
        userInfo[msg.sender].stakeAmount = amount;
        userInfo[msg.sender].claimTime = block.timestamp;
        emit Stake(msg.sender, amount);
    }

    function claimReward() external onlyEOA rateChange {
//        require(false,'market port is repairing');
        UserInfo storage user = userInfo[msg.sender];
        (uint rew,bool out) = _calculateReward(msg.sender);
        uint price = getCkPrice();
        uint finalsRew = countingCk(rew, price);
        require(finalsRew > 0, 'no reward');
        if (out) {
            _processOut(msg.sender);
            ck.transfer(msg.sender, finalsRew * 98 / 100);
            ck.transfer(wallet, finalsRew / 50);
            user.claimed += finalsRew;
        } else {
            user.claimed += finalsRew;
            user.claimedQuota += rew;
            ck.transfer(msg.sender, finalsRew * 98 / 100);
            ck.transfer(wallet, finalsRew / 50);

        }
        totalClaimed += finalsRew;
        user.claimTime = block.timestamp;
    }

    function helpClaimed(address addr) external onlyOwner{
        UserInfo storage user = userInfo[addr];
        (uint rew,bool out) = _calculateReward(addr);
        uint price = getCkPrice();
        uint finalsRew = countingCk(rew, price);
//        require(finalsRew > 0, 'no reward');
        if (out) {
            _processOut(addr);
            ck.transfer(addr, finalsRew * 98 / 100);
            ck.transfer(wallet, finalsRew / 50);
            user.claimed += finalsRew;
        } else {
            user.claimed += finalsRew;
            user.claimedQuota += rew;
            ck.transfer(addr, finalsRew * 98 / 100);
            ck.transfer(wallet, finalsRew / 50);

        }
        totalClaimed += finalsRew;
        user.claimTime = block.timestamp;
    }



    function safePull(address token, address wallet_, uint amount) external onlyOwner {
        IERC20(token).transfer(wallet_, amount);
    }

    function checkPrice() external view returns (uint, uint){
        return (getCkPrice(), countingQuota(ck.balanceOf(0x000000000000000000000000000000000000dEaD), getCkPrice()));
    }

}