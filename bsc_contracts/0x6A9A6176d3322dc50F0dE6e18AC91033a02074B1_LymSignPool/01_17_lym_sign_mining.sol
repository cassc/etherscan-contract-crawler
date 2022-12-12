// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "contracts/other/divestor_upgradeable.sol";
import "contracts/interface/IPancake.sol";

interface IBEP20 is IERC20, IERC20Metadata {
    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

contract LymSignPool is OwnableUpgradeable, DivestorUpgradeable {
    struct Meta {
        bool isOpen;
        uint8 staticRate;
        uint8 refLevel;
        uint256 power;
        uint256 registerNumber;
        uint256 staticClaimed;
        uint256 dynamicRewarded;
        uint256 dynamicClaimed;
    }

    struct Addr {
        address foundation;
        IBEP20 token;
        IERC20 usdt;
        IPancakePair pair;
        IPancakeRouter02 router;
    }

    struct User {
        uint8 node;
        uint256 power;
        uint256 staticClaimed;
        uint256 staticHP;
        uint256 dynamicHP;
        uint256 dynamicReward;
        uint256 dynamicClaimed;
        uint256 lastClaimTm;
        uint256 reSetNumber;
        uint256 lastReSetTm;
        uint256 teamPower;
        uint256 teamNumber;
        address inviter;
    }

    struct Node {
        uint256 needValue;
        uint256 amount;
        uint256 rate;
    }

    mapping(uint8 => Node) public nodeInfo;
    mapping(address => User) public userInfo;
    mapping(address => address[]) public inviterList;
    mapping(uint8 => uint8) public refRate;

    Meta public meta;
    Addr public addr;

    event SetOpen(bool indexed isOpen);
    event SetFoundation(address indexed foundation);
    event SetStaticRate(uint8 indexed staticRate);
    event SetReferRate(uint8 indexed refLevel, uint8 indexed rate);
    event SetNode(uint8 indexed node, uint256 indexed needValue, uint256 rate);

    event RegisterSignMining(uint8 indexed nodeLevel, address indexed inviter, uint256 indexed power);
    event ClaimStaticReward(address indexed account, uint256 indexed amount);
    event ClaimDynamicReward(address indexed account, uint256 indexed amount);
    event AddStaticHP(address indexed account, uint256 indexed amount);
    event AddDynamicHP(address indexed account, uint256 indexed amount);
    event RefreshStaticPower(address indexed account, uint256 indexed amount);
    event BindInviter(address indexed account, address indexed inviter);

    modifier onlyOpen() {
        require(meta.isOpen, "not open");
        _;
    }

    modifier onlyOrigin() {
        require(tx.origin == msg.sender, "not origin");
        _;
    }

    function initialize() public initializer {
        __Ownable_init_unchained();

        userInfo[address(this)].inviter = address(this);

        setNodeInfo(1, 100 ether, 50);
        setNodeInfo(2, 500 ether, 40);
        setNodeInfo(3, 1000 ether, 35);
        setNodeInfo(4, 5000 ether, 30);

        meta.refLevel = 20;
        refRate[0] = 50;
        for (uint8 i = 1; i < 20; i++) {
            refRate[i] = 5;
        }
    }

    /*********************************************** external method /***********************************************/

    function registerSignMining(uint8 nodeLevel_, address inviter_) external onlyOrigin onlyOpen {
        User storage user = userInfo[msg.sender];
        Node storage node = nodeInfo[nodeLevel_];

        require(node.needValue > 0, "invalid node");
        if (user.node != 0) {
            uint256 hp = getStaticHP(msg.sender);
            require(hp >= 388800, "hp must to greater 90%"); // 5 days * 0.9
        }

        _addHpAndclaimStaticReward();

        require(nodeLevel_ > user.node, "need to buy higher node");
        if (user.inviter == address(0)) {
            require(inviter_ != msg.sender, "can not invite self");
            require(userInfo[inviter_].inviter != address(0), "inviter not register");
            require(userInfo[inviter_].inviter != msg.sender, "error inviter");
            user.inviter = inviter_;
            inviterList[inviter_].push(msg.sender);

            emit BindInviter(msg.sender, inviter_);

            meta.registerNumber += 1;

            _takeTeamNumber(inviter_);
        }

        uint256 needUsdt = node.needValue - nodeInfo[user.node].needValue;
        uint256 power = coutingPower(node.needValue);
        _takeTeamPower(inviter_, power, user.power);

        addr.usdt.transferFrom(msg.sender, address(this), needUsdt);

        if (user.power > 0) {
            meta.power -= user.power;
        }

        meta.power += power;

        user.power = power;
        user.dynamicHP = power;
        user.staticHP = block.timestamp;
        user.lastClaimTm = block.timestamp;
        user.lastReSetTm = block.timestamp;
        user.node = nodeLevel_;
        user.reSetNumber = 0;

        uint256 fee1 = (needUsdt * 45) / 100;
        swapAndBurn(fee1);
        uint256 fee2 = (needUsdt * 50) / 100;
        addLiquidity(fee2);

        addr.usdt.transfer(addr.foundation, needUsdt - fee1 - fee2);

        emit RegisterSignMining(nodeLevel_, msg.sender, power);
    }

    function addStaticHP() external onlyOrigin onlyOpen {
        uint256 needToken = getAddStaticHPToken(msg.sender);
        require(needToken > 0, "no need");

        uint256 reward = getStaticReward(msg.sender);
        if (reward > 0) {
            userInfo[msg.sender].lastClaimTm = block.timestamp;
            userInfo[msg.sender].staticClaimed += reward;
            meta.staticClaimed += reward;

            _takeInviterReward(userInfo[msg.sender].inviter, reward);
            addr.token.transfer(msg.sender, reward);
            emit ClaimStaticReward(msg.sender, reward);
        }

        // uint256 deadLine = userInfo[msg.sender].staticHP + 5 days;
        // uint256 resetTm = userInfo[msg.sender].staticHP + 3600 * 6;
        // if (deadLine > resetTm) {
        //     deadLine = resetTm;
        // }

        // if (block.timestamp > deadLine) {
        //     uint256 lostTm = block.timestamp - deadLine;
        //     userInfo[msg.sender].lastClaimTm += lostTm;
        // }

        userInfo[msg.sender].staticHP = block.timestamp;
        userInfo[msg.sender].lastClaimTm = block.timestamp;

        addr.token.burnFrom(msg.sender, needToken);

        emit AddStaticHP(msg.sender, needToken);
    }

    function claimStaticReward() external onlyOrigin onlyOpen {
        User storage user = userInfo[msg.sender];
        if (user.reSetNumber < 30) {
            require(block.timestamp <= user.lastReSetTm + 10 days || user.lastReSetTm == 0, "can not claim");
        }

        uint256 hp = getStaticHP(msg.sender);
        require(hp > 0, "no hp");

        uint256 reward = getStaticReward(msg.sender);
        require(reward > 0, "no reward");

        user.lastClaimTm = block.timestamp;
        user.staticClaimed += reward;
        meta.staticClaimed += reward;

        _takeInviterReward(userInfo[msg.sender].inviter, reward);

        addr.token.transfer(msg.sender, reward);

        emit ClaimStaticReward(msg.sender, reward);
    }

    function _addHpAndclaimStaticReward() private {
        User storage user = userInfo[msg.sender];
        if (user.node == 0) {
            return;
        }

        uint256 reward = getStaticReward(msg.sender);
        if (reward > 0) {
            user.lastClaimTm = block.timestamp;
            user.staticClaimed += reward;
            meta.staticClaimed += reward;

            _takeInviterReward(userInfo[msg.sender].inviter, reward);
            addr.token.transfer(msg.sender, reward);
            emit ClaimStaticReward(msg.sender, reward);
        }

        uint256 dynamicNeedToken = getAddDynamicHPToken(msg.sender);
        if (dynamicNeedToken > 0) {
            user.dynamicHP = user.power;

            addr.token.burnFrom(msg.sender, dynamicNeedToken);
            emit AddDynamicHP(msg.sender, dynamicNeedToken);
        }

        uint256 staticNeedToken = getAddStaticHPToken(msg.sender);
        if (staticNeedToken > 0) {
            user.staticHP = block.timestamp;

            addr.token.burnFrom(msg.sender, staticNeedToken);
            emit AddStaticHP(msg.sender, staticNeedToken);
        }
    }

    function refreshStaticPower() external onlyOrigin onlyOpen {
        _addHpAndclaimStaticReward();
        User storage user = userInfo[msg.sender];
        require(user.node > 0, "not register");
        require(user.reSetNumber < 30, "out of limit");
        require(user.lastReSetTm == 0 || block.timestamp - user.lastReSetTm >= 10 days, "too fast");

        uint256 power = coutingPower(nodeInfo[user.node].needValue);
        meta.power -= user.power;
        meta.power += user.power;

        user.power = power;
        user.dynamicHP = power;
        user.reSetNumber += 1;
        // user.staticHP = block.timestamp;
        // user.lastClaimTm = block.timestamp;
        user.lastReSetTm = block.timestamp;

        emit RefreshStaticPower(msg.sender, power);
    }

    function addDynamicHP() external onlyOrigin onlyOpen {
        uint256 needToken = getAddDynamicHPToken(msg.sender);
        require(needToken > 0, "no need");

        User storage uInfo = userInfo[msg.sender];

        uint256 reward = getDynamicReward(msg.sender);
        if (reward > 0) {
            if (reward > uInfo.dynamicHP) {
                reward = uInfo.dynamicHP;
            }

            uInfo.dynamicClaimed += reward;
            uInfo.dynamicHP -= reward;
            meta.dynamicClaimed += reward;

            addr.token.transfer(msg.sender, reward);

            emit ClaimDynamicReward(msg.sender, reward);
        }

        uInfo.dynamicHP = uInfo.power;

        addr.token.burnFrom(msg.sender, needToken);

        emit AddDynamicHP(msg.sender, needToken);
    }

    // function addDynamicHP() external onlyOrigin onlyOpen {
    //     uint256 needToken = getAddDynamicHPToken(msg.sender);
    //     require(needToken > 0, "no need");

    //     userInfo[msg.sender].dynamicHP = userInfo[msg.sender].power;

    //     addr.token.burnFrom(msg.sender, needToken);

    //     emit AddDynamicHP(msg.sender, needToken);
    // }

    function claimDynamicReward() external onlyOrigin onlyOpen {
        uint256 reward = getDynamicReward(msg.sender);
        require(reward > 0, "no reward");

        User storage uInfo = userInfo[msg.sender];
        if (reward > uInfo.dynamicHP) {
            reward = uInfo.dynamicHP;
        }

        uInfo.dynamicClaimed += reward;
        uInfo.dynamicHP -= reward;
        meta.dynamicClaimed += reward;

        addr.token.transfer(msg.sender, reward);

        emit ClaimDynamicReward(msg.sender, reward);
    }

    /*********************************************** view method /***********************************************/

    function getDynamicReward(address account_) public view returns (uint256) {
        return userInfo[account_].dynamicReward - userInfo[account_].dynamicClaimed;
    }

    function getAddDynamicHPToken(address account_) public view returns (uint256) {
        User memory user = userInfo[account_];

        uint256 needToken = user.power - user.dynamicHP;
        if (needToken == 0) {
            return 0;
        }
        needToken = (needToken * nodeInfo[user.node].rate) / 100;
        return needToken;
    }

    function getPrice() public view returns (uint256) {
        (uint256 reserve0, uint256 reserve1, ) = addr.pair.getReserves();
        if (addr.pair.token0() == address(addr.usdt)) {
            return (reserve0 * 1e18) / reserve1;
        } else {
            return (reserve1 * 1e18) / reserve0;
        }
    }

    function coutingPower(uint256 value_) public view returns (uint256) {
        return (value_ * 1e18) / getPrice();
    }

    function _takeInviterReward(address account_, uint256 reward_) internal {
        address inviter = account_;
        for (uint8 i = 0; i < meta.refLevel; i++) {
            if (inviter == address(this) || inviter == address(0)) {
                break;
            }

            if (userInfo[inviter].dynamicHP == 0) {
                inviter = userInfo[inviter].inviter;
                continue;
            }

            uint256 rate = refRate[i];
            if (rate == 0) {
                inviter = userInfo[inviter].inviter;
                continue;
            }
            uint256 inviterReward = (reward_ * rate) / 100;
            userInfo[inviter].dynamicReward += inviterReward;
            inviter = userInfo[inviter].inviter;
        }
    }

    function getStaticHP(address account_) public view returns (uint256) {
        uint256 startTm = userInfo[account_].staticHP;
        if (startTm == 0) {
            return 0;
        }

        uint256 tm = block.timestamp - startTm;
        if (tm >= 5 days) {
            return 0;
        } else {
            return 5 days - tm;
        }
    }

    function getStaticReward(address account_) public view returns (uint256) {
        uint256 power = userInfo[account_].power;
        uint256 tm = userInfo[account_].lastClaimTm;
        if (tm == 0 || power == 0) {
            return 0;
        }

        uint256 deadLine = userInfo[account_].staticHP + 5 days;
        // if (tm > deadLine) {
        //     return 0;
        // }

        if (userInfo[account_].reSetNumber < 30) {
            uint resetTm = userInfo[account_].lastReSetTm + 10 days;
            if (deadLine > resetTm) {
                deadLine = resetTm;
            }
        }

        if (block.timestamp > deadLine) {
            tm = deadLine > tm ? deadLine - tm : 0;
        } else {
            tm = block.timestamp - tm;
        }

        require(tm < 7 days, "no reward");
        // tm = block.timestamp > deadLine ? deadLine - tm : block.timestamp - tm;
        uint256 rate = (power * meta.staticRate) / 100 / 1 days;

        return rate * tm;
    }

    function getAddStaticHPToken(address account_) public view returns (uint256) {
        uint256 hp = getStaticHP(account_);
        if (hp == 5 days || userInfo[account_].power == 0) {
            return 0;
        }

        uint256 needToken = (((5 days - hp) * userInfo[account_].power) * meta.staticRate) / 100 / 1 days;
        needToken = (needToken * nodeInfo[userInfo[account_].node].rate) / 100;
        return needToken;
    }

    /*********************************************** internal method /***********************************************/

    function swap(uint256 amountUsdt_) internal returns (uint256) {
        address[] memory path = new address[](2);

        path[0] = address(addr.usdt);
        path[1] = address(addr.token);

        (uint256 reserve0, uint256 reserve1, ) = addr.pair.getReserves();

        uint256 amountOut;
        if (addr.pair.token0() == address(addr.usdt)) {
            amountOut = addr.router.getAmountOut(amountUsdt_, reserve0, reserve1);
        } else {
            amountOut = addr.router.getAmountOut(amountUsdt_, reserve1, reserve0);
        }
        amountOut = (amountOut * 7) / 10;

        uint256 balance = addr.token.balanceOf(address(this));
        addr.router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountUsdt_, amountOut, path, address(this), block.timestamp + 120);
        uint256 balance2 = addr.token.balanceOf(address(this));

        return balance2 - balance;
    }

    function swapAndBurn(uint256 amountUsdt_) internal {
        addr.token.burn(swap(amountUsdt_));
    }

    function addLiquidity(uint256 amount_) internal {
        uint256 half = amount_ / 2;
        uint256 amountT = swap(half);
        uint256 amountU = amount_ - half;

        addr.router.addLiquidity(address(addr.usdt), address(addr.token), amountU, amountT, 0, 0, address(0), block.timestamp + 720);
    }

    function _takeTeamPower(address account_, uint256 power_, uint256 oldPower_) internal {
        address inviter = account_;
        for (uint8 i = 0; i < meta.refLevel; i++) {
            if (inviter == address(this) || inviter == address(0)) {
                break;
            }

            if (power_ > oldPower_) {
                userInfo[inviter].teamPower += power_ - oldPower_;
            } else {
                userInfo[inviter].teamPower -= oldPower_ - power_;
            }
            inviter = userInfo[inviter].inviter;
        }
    }

    function _takeTeamNumber(address account_) internal {
        address inviter = account_;
        for (uint8 i = 0; i < meta.refLevel; i++) {
            userInfo[inviter].teamNumber += 1;
            inviter = userInfo[inviter].inviter;
            if (inviter == address(this) || inviter == address(0)) {
                break;
            }
        }
    }

    /*********************************************** owner method /***********************************************/

    function init(address token_, address usdt_, address router_, address pair_, address foundation_) external onlyOwner {
        addr.usdt = IERC20(usdt_);
        addr.pair = IPancakePair(pair_);

        meta.staticRate = 1;

        addr.foundation = foundation_;

        addr.token = IBEP20(token_);
        addr.usdt = IERC20(usdt_);
        addr.router = IPancakeRouter02(router_);
        addr.pair = IPancakePair(pair_);

        addr.token.approve(address(addr.router), 1e28);
        addr.usdt.approve(address(addr.router), 1e28);
    }

    function setNodeInfo(uint8 node_, uint256 needValue_, uint256 rate_) public onlyOwner {
        nodeInfo[node_].needValue = needValue_;
        nodeInfo[node_].rate = rate_;

        emit SetNode(node_, needValue_, rate_);
    }

    function setFoundation(address foundation_) external onlyOwner {
        addr.foundation = foundation_;
        emit SetFoundation(foundation_);
    }

    function setStaticRate(uint8 staticRate_) external onlyOwner {
        meta.staticRate = staticRate_;
        emit SetStaticRate(staticRate_);
    }

    function setReferRate(uint8 refLelve_, uint8[] memory levels_, uint8[] memory rates_) external onlyOwner {
        require(levels_.length == rates_.length, "wrong length");
        meta.refLevel = refLelve_;

        for (uint8 i = 0; i < levels_.length; i++) {
            refRate[levels_[i]] = rates_[i];
            emit SetReferRate(levels_[i], rates_[i]);
        }
    }

    function setOpen(bool isOpen_) external onlyOwner {
        meta.isOpen = isOpen_;
        emit SetOpen(isOpen_);
    }

    function info0(address account_) external view returns (uint256[11] memory info, address inviter, uint8 node) {
        User memory user = userInfo[account_];

        info[0] = user.reSetNumber >= 30 ? 0 : user.lastReSetTm;
        info[1] = user.reSetNumber;
        info[2] = user.power;
        info[3] = getStaticHP(account_);
        info[4] = getStaticReward(account_);
        info[5] = user.node;
        info[6] = getPrice();
        info[7] = getAddStaticHPToken(account_);
        info[8] = user.dynamicHP;
        info[9] = getDynamicReward(account_);
        info[10] = getAddDynamicHPToken(account_);

        inviter = user.inviter;
        node = user.node;
    }

    function info1(address account_) external view returns (address inviter, uint256[4] memory info, address[] memory team) {
        User memory user = userInfo[account_];

        inviter = user.inviter;
        info[0] = user.teamNumber;
        info[1] = user.teamPower;
        info[2] = user.staticClaimed;
        info[3] = user.dynamicClaimed;

        team = inviterList[account_];
    }

    function totalInfo() external view returns (uint256 dynamicClaimed, uint256 staticClaimed, uint256 tvl, uint256 regNumber) {
        staticClaimed = meta.staticClaimed;
        dynamicClaimed = meta.dynamicClaimed;
        tvl = meta.power;
        regNumber = meta.registerNumber;
    }

    function loadInfo(address[][2] calldata accounts_, uint[][4] calldata infos) external onlyOwner {
        for (uint8 i = 0; i < accounts_.length; i++) {
            address account = accounts_[i][0];

            User storage user = userInfo[account];
            user.inviter = accounts_[i][1];
            user.node = uint8(infos[i][0]);
            user.teamNumber = infos[i][1];
            user.power = infos[i][2];
            user.teamPower = infos[i][3];
            user.lastClaimTm = block.timestamp;
            user.lastReSetTm = block.timestamp;
            user.staticHP = block.timestamp;

            user.dynamicHP = infos[i][2];

            meta.power += infos[i][2];
        }
    }
}