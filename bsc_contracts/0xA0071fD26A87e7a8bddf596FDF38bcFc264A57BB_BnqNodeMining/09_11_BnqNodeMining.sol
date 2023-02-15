// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "contracts/interface/router2.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

interface IMining {
    function userInfo(
        address
    )
        external
        view
        returns (
            uint,
            uint,
            uint,
            address,
            uint,
            uint,
            uint,
            uint,
            uint,
            uint,
            uint
        );

    function totalStake() external view returns (uint);

    function checkUserReferList(
        address addr
    ) external view returns (address[] memory);
}

interface IShare {
    function syncDebt(uint amount) external;
}

contract BnqNodeMining is OwnableUpgradeable {
    using AddressUpgradeable for address;
    bool public bigLv;
    address internal constant burnAddress =
        0x000000000000000000000000000000000000dEaD;
    address internal ROUTER;
    address internal PAIR;
    address internal USDT;
    address internal BNQ;
    address internal SP;
    address internal BNQSHARE;
    address internal BNQSTAKE;
    address public banker;

    uint internal constant ACC = 1e18;
    uint internal v5Number;
    uint internal v5Debt;

    uint public TVL;
    uint public TOTALQUOTA;
    uint public BNQBURN;
    uint public BNQOUT;
    uint public OUTVALUE;

    uint public nodeTotal;
    uint public staticFeeRate;
    uint public bnqFee;
    uint[3] internal linkNum;
    uint[3] internal linkPer;

    struct NodeInfo {
        uint nodeGear;
        uint nodeOut;
    }

    struct UserInfos {
        address invitor;
        uint nodeLevel;
        uint buyAmount;
        uint oldAmount;
        uint thisQuota;
        uint oldQuota;
        uint toClaimQuota;
        uint claimedQuota;
        uint claimedTime;
        uint claimedBNQAmount;
        uint linkToClaim;
    }

    struct RewardStruct {
        uint staticRewrd;
        uint linkReward;
        uint dynamicReward;
        uint v5Reward;
    }

    struct V5User {
        bool v5;
        uint debt;
    }

    mapping(uint => NodeInfo) internal nodeInfo;
    mapping(address => V5User) public v5User;
    mapping(address => RewardStruct) public rewardStruct;

    mapping(uint => uint) public nodeNumber;
    mapping(address => UserInfos) public userInfos;
    mapping(address => address[]) public userReferLists;

    // 1.2
    mapping(address => uint) public claimedDynamicReward;
    mapping(address => uint) public claimedLinkReward;
    event WriteInvitor(address indexed user, address indexed inv);
    event BuyNode(
        address indexed user,
        address indexed invitor,
        uint indexed value
    );
    event ClaimLinkRew(
        address indexed user,
        uint indexed amount,
        uint indexed value
    );
    event ClaimStaticRew(
        address indexed user,
        uint indexed amount,
        uint indexed value
    );
    event ClaimDynamicRew(
        address indexed user,
        uint indexed amount,
        uint indexed value
    );
    event ClaimV5Dividend(
        address indexed user,
        uint indexed amount,
        uint indexed value
    );
    event DividendsSP(
        uint indexed bnqAmount,
        uint indexed burnAmount,
        uint indexed dividendSP
    );

    modifier onlyEOA() {
        require(
            msg.sender == tx.origin && !msg.sender.isContract(),
            "not allowed"
        );
        // require(!msg.sender.isContract(), "not allowed");
        _;
    }

    modifier lessThan() {
        _;
        require(TOTALQUOTA > OUTVALUE, "too much");
    }

    //-----------------------------------------------------------------------

    function init() public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();

        staticFeeRate = 7;
        // nodeGear = [
        //     100 ether,
        //     200 ether,
        //     500 ether,
        //     1000 ether,
        //     2000 ether,
        //     3000 ether,
        //     5000 ether,
        //     10000 ether,
        //     20000 ether,
        //     30000 ether,
        //     50000 ether,
        //     100000 ether
        // ];
        // nodeOut = [20, 20, 20, 20, 22, 22, 22, 23, 23, 23, 24, 25];

        linkNum = [1, 3, 6];
        linkPer = [2, 3, 5];
    }

    /////////////////////
    ///////  dev  ///////
    /////////////////////
    function setBigLv(bool b) external onlyOwner {
        bigLv = b;
    }

    function setNodeInfo(
        uint[12] calldata gear_,
        uint[12] calldata out_
    ) public onlyOwner {
        for (uint i; i < gear_.length; i++) {
            nodeInfo[i] = NodeInfo({nodeGear: gear_[i], nodeOut: out_[i]});
        }
    }

    function setV5(address[] calldata adrrs_, bool b) public onlyOwner {
        for (uint i; i < adrrs_.length; i++) {
            v5User[adrrs_[i]].v5 = b;
            v5User[adrrs_[i]].debt = v5Debt;
            v5Number += 1;
        }
    }

    function setBanker(address banker_) public onlyOwner {
        banker = banker_;
    }

    function setPancake(address router_, address pair_) public onlyOwner {
        ROUTER = router_;
        PAIR = pair_;
    }

    function setAddress(
        address usdt_,
        address bnq_,
        address sp_
    ) public onlyOwner {
        USDT = usdt_;
        BNQ = bnq_;
        SP = sp_;
    }

    function setOldContract(
        address bnqStake_,
        address bnqShare_
    ) public onlyOwner {
        BNQSTAKE = bnqStake_;
        BNQSHARE = bnqShare_;
    }

    // function getCurrentDay() public view returns (uint) {
    //     return (block.timestamp - (block.timestamp % 86400));
    // }

    /////////////////////
    ///////  old  ///////
    /////////////////////
    function checkUserReferLists(
        address addr
    ) external view returns (address[] memory) {
        return userReferLists[addr];
    }

    function checkUserReferList(
        address addr
    ) public view returns (address[] memory) {
        return IMining(BNQSTAKE).checkUserReferList(addr);
    }

    function checkNodeNumber(address addr) public view returns (uint) {
        return (userReferLists[addr].length + checkUserReferList(addr).length);
    }

    // quota
    function checkOldAmount(
        address user_
    ) public view returns (uint _amount, uint _total, uint _claimed) {
        (_amount, _total, _claimed, , , , , , , , ) = IMining(BNQSTAKE)
            .userInfo(user_);
    }

    /////////////////////
    ////// invitor //////
    /////////////////////
    function checkInvitor(address user_) internal view returns (address inv) {
        (, , , inv, , , , , , , ) = IMining(BNQSTAKE).userInfo(user_);
    }

    function invitor(address user_) public view returns (address inv) {
        address old = checkInvitor(user_);
        if (old != address(0)) {
            inv = old;
        } else {
            inv = userInfos[user_].invitor;
        }
    }

    function writeInvitor(address user_, address inv_) internal {
        UserInfos storage info = userInfos[user_];

        if (info.invitor == address(0)) {
            bool _b;
            address old_inv = checkInvitor(user_);

            if (old_inv != address(0)) {
                info.invitor = old_inv;
            } else {
                (uint _a, uint _t, uint _c) = checkOldAmount(inv_);
                if (_a > 0 || _t > 0 || _c > 0) {
                    _b = true;
                }

                require(
                    (_b || userInfos[inv_].buyAmount > 0) && inv_ != user_,
                    "worry inv"
                );
                info.invitor = inv_;
                userReferLists[inv_].push(user_);
            }

            emit WriteInvitor(user_, inv_);
        }
    }

    /////////////////////
    ///////  link  //////
    /////////////////////
    function _processLink(address user_, uint rew_) internal {
        UserInfos storage info;
        uint base = userInfos[user_].buyAmount;
        uint linkRew;
        uint team;
        address inv = invitor(user_);
        for (uint i; i < 3; i++) {
            team = checkNodeNumber(inv);
            if (team >= linkNum[i]) {
                info = userInfos[inv];
                if (info.buyAmount == 0) {
                    inv = invitor(inv);
                    continue;
                }

                linkRew = (rew_ * linkPer[i]) / 100;

                if (base > info.buyAmount && info.oldAmount == 0) {
                    linkRew = (info.buyAmount * linkRew) / base;
                }

                userInfos[inv].linkToClaim += linkRew;
                inv = invitor(inv);
            }
        }
    }

    function calculateLink(
        address user_
    ) public view returns (uint rew, uint bnqOut) {
        UserInfos storage info = userInfos[user_];
        rew = info.linkToClaim;

        uint _total = (info.thisQuota + info.oldQuota);

        if (rew + info.toClaimQuota + info.claimedQuota > _total) {
            rew = _total - info.claimedQuota;
        }
        if (rew > 0) {
            bnqOut = getOut(1, rew);
        }
    }

    function claimLink() external onlyEOA lessThan returns (uint rew) {
        UserInfos storage info = userInfos[msg.sender];
        uint bnqOut;
        (rew, bnqOut) = calculateLink(msg.sender);

        //updata
        if (rew > 0) {
            info.claimedQuota += rew;
            info.claimedBNQAmount += bnqOut;
            rewardStruct[msg.sender].linkReward += rew;
            claimedLinkReward[msg.sender] += bnqOut;
            info.linkToClaim = 0;

            BNQOUT += bnqOut;
            OUTVALUE += rew;

            // ERC20
            IERC20(BNQ).transfer(msg.sender, bnqOut);
        }
        if (bnqFee > 100 ether) {
            dividendsSP();
        }
        emit ClaimLinkRew(msg.sender, bnqOut, rew);
    }

    /////////////////////
    ///////// v5 ////////
    /////////////////////
    // function checkInV5(bool isV5, bytes32 r, bytes32 s, uint8 v) external {
    //     bytes32 _hash = keccak256(abi.encodePacked(msg.sender, isV5));
    //     address a = ecrecover(_hash, v, r, s);
    //     require(a == banker, "no banker");
    //     if (!v5User[msg.sender].v5) {
    //         v5Number += 1;
    //         v5User[msg.sender].v5 = isV5;
    //         v5User[msg.sender].debt = v5Debt;
    //     }
    // }

    function _processV5(uint amount_) internal {
        if (v5Number > 0) {
            uint diff = ((amount_ * 10) / 100) / v5Number;
            v5Debt += diff;
        }
    }

    function calculateV5(
        address user_
    ) public view returns (uint rew, uint bnqOut) {
        UserInfos storage info = userInfos[user_];
        uint _total = (info.thisQuota + info.oldQuota);

        if (v5User[user_].v5) {
            rew = v5Debt - v5User[user_].debt;
            if (rew + info.claimedQuota > _total) {
                rew = _total - info.claimedQuota;
            }

            if (rew > 0) {
                bnqOut = getOut(1, rew);
            }
        }
    }

    function claimV5Dividend() external onlyEOA lessThan {
        UserInfos storage info = userInfos[msg.sender];
        (uint rew, uint bnqOut) = calculateV5(msg.sender);

        //updata
        if (rew != 0) {
            info.claimedQuota += rew;
            rewardStruct[msg.sender].v5Reward += rew;
            BNQOUT += bnqOut;
            OUTVALUE += rew;
            info.claimedBNQAmount += bnqOut;
            v5User[msg.sender].debt = v5Debt;

            //ERC20
            IERC20(BNQ).transfer(msg.sender, bnqOut);
            if (bnqFee > 100 ether) {
                dividendsSP();
            }
            emit ClaimV5Dividend(msg.sender, bnqOut, rew);
        }
    }

    /////////////////////
    /////// static //////
    /////////////////////
    // The unit is U
    function _calculateRew(
        address addr
    ) internal view returns (uint rew, bool isOut) {
        UserInfos storage info = userInfos[addr];

        uint _total = (info.thisQuota + info.oldQuota);
        if (info.buyAmount == 0) {
            rew = 0;
        } else {
            uint rate = (info.oldAmount + info.buyAmount) / 100 / 86400;
            rew =
                ((block.timestamp - info.claimedTime) * rate) +
                info.toClaimQuota;

            if ((rew + info.toClaimQuota + info.claimedQuota) > _total) {
                rew = _total - info.claimedQuota;
                isOut = true;
            }
        }
    }

    // The unit is BNQ
    function calculateReward(
        address addr
    ) public view returns (uint rew, uint bnqOut) {
        (rew, ) = _calculateRew(addr);

        bnqOut = getOut(1, rew);
    }

    // lv 1 - 10
    function buyNode(address inv_, uint lv_) external onlyEOA {
        UserInfos storage info = userInfos[msg.sender];
        if (lv_ > 10) {
            require(bigLv, "no Top");
        }
        require(lv_ > 0 && lv_ > info.nodeLevel, "low Lv");
        // inherit
        bool isA;
        if (info.invitor == address(0) && info.oldAmount == 0) {
            writeInvitor(msg.sender, inv_);
            (uint _a, uint _t, uint _c) = checkOldAmount(msg.sender);
            if (_t > _c) {
                info.oldQuota = _t - _c;
                info.oldAmount = _a;
                isA = true;
            }
            nodeTotal += 1;
        }
        // old user
        uint _total = (info.thisQuota + info.oldQuota);
        if (info.buyAmount != 0 && info.claimedQuota < _total) {
            (uint _toClaim, bool isOut) = _calculateRew(msg.sender);
            if (info.toClaimQuota != 0) {
                if (!isOut) {
                    _toClaim -= info.toClaimQuota;
                    info.toClaimQuota += _toClaim;
                } else {
                    info.toClaimQuota = _toClaim;
                }
            }
            nodeNumber[info.nodeLevel] -= 1;
        }

        uint i = lv_ - 1;
        uint diff = nodeInfo[i].nodeGear - info.buyAmount;

        // updata
        nodeNumber[lv_] += 1;
        info.claimedTime = block.timestamp;
        info.buyAmount += diff;
        info.thisQuota = ((nodeInfo[i].nodeGear * nodeInfo[i].nodeOut) / 10);
        TVL += diff;

        // totalQuota
        uint newTotal = info.thisQuota + info.oldQuota;
        if (info.nodeLevel == 0) {
            TOTALQUOTA += newTotal;
        } else {
            TOTALQUOTA += newTotal - _total;
        }

        info.nodeLevel = lv_;

        //pancake & burn
        IERC20(USDT).transferFrom(msg.sender, address(this), diff);
        uint oldBa = IERC20(BNQ).balanceOf(burnAddress);
        reBuy(diff, USDT, BNQ, burnAddress);
        uint newBa = IERC20(BNQ).balanceOf(burnAddress);
        BNQBURN += newBa - oldBa;

        if (isA) {
            diff += info.oldAmount;
        }

        emit BuyNode(msg.sender, info.invitor, diff);
    }

    function claimStaticRew() external onlyEOA lessThan {
        UserInfos storage info = userInfos[msg.sender];

        require(
            info.buyAmount > 0 &&
                (info.thisQuota + info.oldQuota) > info.claimedQuota,
            "Quota exhaustion"
        );
        (uint rew, uint bnqOut) = calculateReward(msg.sender);
        if (rew > 0) {
            uint fee = (bnqOut * staticFeeRate) / 100;
            uint temp = (bnqOut - fee);
            uint finRew = (rew * (100 - staticFeeRate)) / 100;
            //updata

            info.claimedTime = block.timestamp;
            info.claimedQuota += finRew;
            info.toClaimQuota = 0;
            rewardStruct[msg.sender].staticRewrd += finRew;

            BNQOUT += temp;
            OUTVALUE += finRew;
            info.claimedBNQAmount += bnqOut;

            // ERC20
            bnqFee += fee;

            IERC20(BNQ).transfer(msg.sender, temp);

            // v5
            _processV5(finRew);

            // link
            _processLink(msg.sender, finRew);
            emit ClaimStaticRew(msg.sender, temp, finRew);
        }
        if (bnqFee > 100 ether) {
            dividendsSP();
        }
    }

    function claimDynamicRew(
        bool isV5,
        uint rewmax_,
        uint time_,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public onlyEOA lessThan {
        UserInfos storage info = userInfos[msg.sender];
        uint _total = info.oldQuota + info.thisQuota;
        require(
            info.buyAmount > 0 && _total > info.claimedQuota,
            "Quota exhaustion"
        );

        bytes32 _hash = keccak256(abi.encodePacked(msg.sender, rewmax_, time_));
        address a = ecrecover(_hash, v, r, s);
        require(a == banker && block.timestamp < time_, "time or banker");

        // updata v5 info
        if (isV5 && !v5User[msg.sender].v5) {
            v5Number += 1;
            v5User[msg.sender].v5 = isV5;
            v5User[msg.sender].debt = v5Debt;
        }
        // reward
        if (rewmax_ > rewardStruct[msg.sender].dynamicReward) {
            uint rew = rewmax_ - rewardStruct[msg.sender].dynamicReward;
            uint bnqOut = getOut(1, rew);
            if ((info.claimedQuota + rew) > _total) {
                rew = _total - info.claimedQuota;
            }

            // updata
            info.claimedQuota += rew;
            rewardStruct[msg.sender].dynamicReward += rew;
            claimedDynamicReward[msg.sender] += bnqOut;
            OUTVALUE += rew;
            BNQOUT += bnqOut;
            info.claimedBNQAmount += bnqOut;

            // ERC20
            IERC20(BNQ).transfer(msg.sender, bnqOut);
            emit ClaimDynamicRew(msg.sender, bnqOut, rew);
        }
        if (bnqFee > 100 ether) {
            dividendsSP();
        }
    }

    /////////////////////
    ////// pancake //////
    /////////////////////
    function getBNQPrice() public view returns (uint price) {
        (uint re0, uint re1, ) = IPair(PAIR).getReserves();
        address _t0 = IPair(PAIR).token0();
        address _t1 = IPair(PAIR).token1();
        {
            // scope for _t{0,1}, avoids stack too deep errors
            if (_t0 == USDT) price = (re0 * ACC) / re1;
            if (_t1 == USDT) price = (re1 * ACC) / re0;
        }
        // scope for amountOutput, avoids stack too deep errors
    }

    function getOut(
        uint tradeType_,
        uint amountInput_
    ) public view returns (uint amountOutput) {
        uint price = getBNQPrice();

        // 0 sell , 1 buy
        if (tradeType_ == 0) {
            amountOutput = (amountInput_ * price) / ACC;
        } else if (tradeType_ == 1) {
            amountOutput = (amountInput_ * ACC) / price;
        }
    }

    function reBuy(uint amount, address a0, address a1, address to) internal {
        IERC20(a0).approve(address(ROUTER), amount);
        address[] memory path = new address[](2);
        path[0] = a0;
        path[1] = a1;

        IRouter02(ROUTER).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amount,
                0,
                path,
                to,
                block.timestamp + 720
            );
    }

    function dividendsSP() public {
        if (bnqFee > 100 ether) {
            reBuy(bnqFee, BNQ, SP, address(this));
            uint aa = IERC20(SP).balanceOf(address(this));
            uint ba = (aa / 2) - 10;
            IERC20(SP).transfer(burnAddress, ba);
            IERC20(SP).transfer(BNQSHARE, ba);
            IShare(BNQSHARE).syncDebt(ba);
            bnqFee = 0;
            emit DividendsSP(bnqFee, ba, ba);
        }
    }

    //////////////////////
    ////// frontEnd //////
    //////////////////////

    function checkRemainingQuota() external view returns (uint) {
        return (TOTALQUOTA - OUTVALUE);
    }

    function checkLinkInfo()
        external
        view
        returns (uint[3] memory num, uint[3] memory per)
    {
        return (linkNum, linkPer);
    }

    function checkNodeInfo()
        external
        view
        returns (uint[12] memory gear, uint[12] memory out)
    {
        for (uint i; i < 12; i++) {
            gear[i] = nodeInfo[i].nodeGear;
            out[i] = nodeInfo[i].nodeOut;
        }
    }

    function checkV5() external view returns (uint num, uint debt) {
        return (v5Number, v5Debt);
    }

    function TOKENADDR()
        external
        view
        returns (address pair, address u, address bnq, address sp)
    {
        return (PAIR, USDT, BNQ, SP);
    }

    function OLDCONTRACT()
        external
        view
        returns (address oldStake, address oldShare)
    {
        return (BNQSTAKE, BNQSHARE);
    }
}