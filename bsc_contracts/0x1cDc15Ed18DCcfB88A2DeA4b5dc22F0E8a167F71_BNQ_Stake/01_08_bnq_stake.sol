// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "../router.sol";

interface Rew {
    function rewardToNFTDividend(uint256 amount) external;
}

contract BNQ_Stake is OwnableUpgradeable {
    using AddressUpgradeable for address;
    IERC20Upgradeable public BNQ;
    IERC20Upgradeable public U;
    IPancakeRouter02 public router;
    address constant burnAddress = 0x000000000000000000000000000000000000dEaD;
    address public nftRew;
    address public node;
    IPair public pair;
    uint[] miningRate;
    uint[] outRate;
    uint[] referRate;
    uint public totalStake;

    struct UserInfo {
        uint stakeAmount;
        uint totalQuota;
        uint claimedQuota;
        address invitor;
        uint referAmount;
        uint refer_n;
        uint rate;
        mapping(uint => uint) dayReferReward;
        uint referReward;
        uint claimed;
        uint claimTime;
        uint totalStake;
    }

    mapping(address => UserInfo) public userInfo;
    mapping(address => address[]) public userReferList;
    bool public status;

    event Stake(address indexed player, uint indexed amount);
    event Claim(address indexed player, uint indexed amount);

    function initialize() public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        miningRate = [100 ether, 1000 ether, 5000 ether, 10000 ether];
        outRate = [25, 26, 28, 30];
        referRate = [30, 10, 10, 10, 10, 10, 20];
        U = IERC20Upgradeable(0x55d398326f99059fF775485246999027B3197955);
        BNQ = IERC20Upgradeable(0x5c530131700B8dd88e4FAEFEa616D04f6f13Fc96);
        setRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        nftRew = 0x36D34719da77b0904e19740153BE2aDa941F66ac;
        node = 0x2F53005F309d0C5884C127B24efaf197f546bb52;
    }

    modifier onlyEOA(){
        require(msg.sender == tx.origin, 'not allowed');
        require(!msg.sender.isContract(), 'not allowed');
        _;
    }

    function setRouter(address addr) public onlyOwner {
        router = IPancakeRouter02(addr);
        pair = IPair(IPancakeFactory(router.factory()).getPair(address(U), address(BNQ)));
    }

    function setStatus(bool b) external onlyOwner {
        status = b;
    }

    function setToken(address addr) external onlyOwner {
        BNQ = IERC20Upgradeable(addr);
    }

    function setU(address addr) external onlyOwner {
        U = IERC20Upgradeable(addr);
    }

    function setPair(address addr) external onlyOwner {
        pair = IPair(addr);
    }

    function setAddress(address node_, address nft_) external onlyOwner {
        node = node_;
        nftRew = nft_;
    }

    function getBNQPrice() public view returns (uint){
        (uint token0,uint token1,) = pair.getReserves();
        uint price;
        if (pair.token0() == address(U)) {
            price = token0 * 1e18 / token1;
        } else {
            price = token1 * 1e18 / token0;
        }
        return price;
    }

    function countingUserRate(uint amount) public view returns (uint quota){
        require(amount >= miningRate[0], 'must more than 100');
        quota = 0;
        if (amount > miningRate[3]) {
            quota = amount * outRate[3] / 10;
        }
        for (uint i = 1; i < 4; i++) {
            if (amount <= miningRate[i]) {
                quota = amount * outRate[i - 1] / 10;
                return quota;
            }
        }
    }

    function countingBNQ(uint amount, uint price) public pure returns (uint out){
        out = amount * 1e18 / price;
    }

    function calculateReward(address addr) public view returns (uint, uint){
        UserInfo storage info = userInfo[addr];
        (uint rew,bool isOut) = _calculateRew(addr);
        uint out = 0;
        uint referRew = 0;
        if (isOut) {
            return (rew, countingBNQ(rew, getBNQPrice()));
        } else {
            if (rew + info.referReward > info.totalQuota - info.claimedQuota) {
                referRew = info.totalQuota - info.claimedQuota - rew;
            } else {
                referRew = info.referReward;
            }
        }
        out = countingBNQ(rew + referRew, getBNQPrice());
        return (rew + referRew, out);
    }

    function _calculateRew(address addr) public view returns (uint rew, bool isOut){
        UserInfo storage info = userInfo[addr];
        isOut = false;
        if (info.stakeAmount == 0) {
            rew = 0;
        }
        rew = (block.timestamp - info.claimTime) * info.rate;
        if (rew > info.totalQuota - info.claimedQuota) {
            rew = info.totalQuota - info.claimedQuota;
            isOut = true;
        }
    }

    function getCurrentDay() public view returns (uint){
        return (block.timestamp - (block.timestamp % 86400));
    }

    function _processRefer(address addr, uint amount) internal {
        address temp = userInfo[addr].invitor;
        uint tempRew;
        uint time = getCurrentDay();
        UserInfo storage info;
        for (uint i = 0; i < 7; i++) {
            info = userInfo[temp];
            while (info.stakeAmount == 0) {
                temp = info.invitor;
                info = userInfo[temp];
                if (temp == address(this) || temp == address(0)) {
                    break;
                }
            }
            if (temp == address(this) || temp == address(0)) {
                break;
            }
            if (i > 0 && info.refer_n < 5) {
                temp = info.invitor;
                continue;
            }
            tempRew = amount * referRate[i] / 100;
            if (tempRew + info.dayReferReward[time] > info.stakeAmount / 2) {
                if(info.stakeAmount / 2 >= info.dayReferReward[time]){
                    tempRew = info.stakeAmount / 2 - info.dayReferReward[time];
                }else{
                    tempRew = 0;
                }

            }
            info.referReward += tempRew;
            info.dayReferReward[time] += tempRew;
            temp = info.invitor;
        }
    }

    function getUserDailyReferReward(address addr) public view returns (uint){
        return (userInfo[addr].dayReferReward[getCurrentDay()]);
    }

    function reBuy(uint amount) internal {
        U.approve(address(router), amount);
        address[] memory path = new address[](2);
        path[0] = address(U);
        path[1] = address(BNQ);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amount, 0, path, burnAddress, block.timestamp + 720);
    }

    function _processReferAmount(address addr, uint amount, bool isAdd) internal {
        address temp = userInfo[addr].invitor;
        if (isAdd) {
            for (uint i = 0; i < 7; i++) {
                if (temp == address(this) || temp == address(0)) {
                    break;
                }
                userInfo[temp].referAmount += amount;
                temp = userInfo[temp].invitor;
            }
        } else {
            for (uint i = 0; i < 7; i++) {
                if (temp == address(this) || temp == address(0)) {
                    break;
                }
                if (userInfo[temp].referAmount >= amount) {
                    userInfo[temp].referAmount -= amount;
                }

                temp = userInfo[temp].invitor;
            }
        }

    }

    function stake(uint amount, address invitor) external onlyEOA {
        require(status, 'not open yet');
        UserInfo storage info = userInfo[msg.sender];
        require(info.stakeAmount == 0, 'been staked');
        U.transferFrom(msg.sender, address(this), amount);
        reBuy(amount);
        if (info.invitor == address(0)) {
            require((userInfo[invitor].stakeAmount > 0 && invitor != msg.sender) || invitor == address(this), 'wrong invitor');
            info.invitor = invitor;
        }
        invitor = info.invitor;
        userInfo[invitor].refer_n ++;
        userReferList[invitor].push(msg.sender);
        _processReferAmount(msg.sender, amount, true);
        info.stakeAmount = amount;
        info.totalQuota = countingUserRate(amount);
        info.claimTime = block.timestamp;
        info.claimedQuota = 0;
        info.rate = amount / 100 / 86400;
        totalStake += amount;
        info.totalStake += amount;
        emit Stake(msg.sender, amount);
    }

    function checkUserReferList(address addr) external view returns (address[] memory){
        return userReferList[addr];
    }

    function _processOut(address addr) internal {
        UserInfo storage info = userInfo[addr];
        totalStake -= info.stakeAmount;
        info.stakeAmount = 0;
        info.rate = 0;
        info.totalQuota = 0;
        info.claimedQuota = 0;
//        address invitor = info.invitor;
//        userInfo[invitor].refer_n --;
//        uint length = userReferList[invitor].length;
//        for (uint i = 0; i < length; i++) {
//            if (userReferList[invitor][i] == addr) {
//                userReferList[invitor][i] = userReferList[invitor][length - 1];
//                userReferList[invitor].pop();
//            }
//        }

    }

    function safePull(address token, address wallet, uint amount) external onlyOwner {
        IERC20Upgradeable(token).transfer(wallet, amount);
    }

    function claimReward() external onlyEOA {
        UserInfo storage info = userInfo[msg.sender];
        require(info.stakeAmount > 0, 'no amount');
        (uint rew,bool isOut) = _calculateRew(msg.sender);
        uint referRew = 0;
        {
            if (isOut) {
                _processRefer(msg.sender, rew);
                _processReferAmount(msg.sender, info.stakeAmount, false);
                _processOut(msg.sender);
            } else {
                if (rew + info.referReward > info.totalQuota - info.claimedQuota) {
                    _processRefer(msg.sender, rew);
                    if(info.totalQuota >= info.claimedQuota + rew){
                        referRew = info.totalQuota - info.claimedQuota - rew;
                    }
                    _processReferAmount(msg.sender, info.stakeAmount, false);
                    _processOut(msg.sender);

                } else {
                    _processRefer(msg.sender, rew);
                    referRew = info.referReward;
                    info.claimedQuota += rew + referRew;
                }
            }
        }
        uint price = getBNQPrice();
        uint tokenRew = countingBNQ((rew + referRew) * 92 / 100, price);
        info.claimed += tokenRew;

        BNQ.transfer(msg.sender, tokenRew);
        uint nodeRew = countingBNQ(rew * 2 / 100, price);
        uint nftRews = countingBNQ(rew * 5 / 100, price);
        BNQ.transfer(node, nodeRew);
        BNQ.transfer(nftRew, nftRews);
        //        Rew(node).rewardToNFTDividend(nodeRew);
        //        Rew(nftRew).rewardToNFTDividend(nftRews);
        if (info.referReward >= referRew) {
            info.referReward -= referRew;
        }
        info.claimTime = block.timestamp;
        emit Claim(msg.sender, rew);
    }

    function helpClaimed(address addr) external onlyOwner {
        UserInfo storage info = userInfo[addr];
        require(info.stakeAmount > 0, 'no amount');
        (uint rew,bool isOut) = _calculateRew(addr);
        uint referRew = 0;
        {
            if (isOut) {
//                _processRefer(addr, rew);
//                _processReferAmount(addr, info.stakeAmount, false);
                _processOut(addr);
            } else {
                if (rew + info.referReward > info.totalQuota - info.claimedQuota) {
                    _processRefer(addr, rew);
                    referRew = info.totalQuota - info.claimedQuota - rew;
                    _processReferAmount(addr, info.stakeAmount, false);
                    _processOut(addr);

                } else {
                    _processRefer(addr, rew);
                    referRew = info.referReward;
                    info.claimedQuota += rew + referRew;
                }
            }
        }
        uint price = getBNQPrice();
        uint tokenRew = countingBNQ((rew + referRew) * 92 / 100, price);
        info.claimed += tokenRew;
        BNQ.transfer(addr, tokenRew);
        uint nodeRew = countingBNQ(rew * 2 / 100, price);
        uint nftRews = countingBNQ(rew * 5 / 100, price);
        BNQ.transfer(node, nodeRew);
        BNQ.transfer(nftRew, nftRews);
//        Rew(node).rewardToNFTDividend(nodeRew);
//        Rew(nftRew).rewardToNFTDividend(nftRews);
        info.referReward -= referRew;
        info.claimTime = block.timestamp;
        emit Claim(addr, rew);
    }


}