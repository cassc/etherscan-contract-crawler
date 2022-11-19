// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "contracts/other/divestor_upgradeable.sol";
import "hardhat/console.sol";

contract LYMLiquidityPool is OwnableUpgradeable, DivestorUpgradeable {
    struct Meta {
        bool isOpen;
        uint256 interval;
        uint256 registerNumber;
        uint256 totalReward;
        uint256 allocatedReward;
        uint256 claimedReward;
        uint256 currentRound;
        IERC20 token;
        IERC20 pair;
    }

    struct User {
        bool register;
        uint256 registerAmount;
        uint256 rewarded;
    }

    struct UserRegister {
        uint256 registerAmount;
        uint256 rewarded;
    }

    struct Round {
        uint256 endTm;
        uint256 reward;
        uint256 rewarded;
        uint256 tvl;
    }

    Meta public meta;

    // round => user address => info
    mapping(uint256 => mapping(address => UserRegister)) public registerInfo;
    mapping(address => User) public userInfo;
    mapping(uint256 => Round) public roundInfo;

    mapping(address => bool) public admin;

    modifier onlyOpen() {
        require(meta.isOpen, "not open");
        _;
    }

    modifier onlyAdmin() {
        require(admin[_msgSender()], "not admin");
        _;
    }

    modifier onlyOrigin() {
        require(tx.origin == msg.sender, "not origin");
        _;
    }

    // function setInfo() external onlyOwner {
    //     roundInfo[3] = Round({ endTm: 1669384136, reward: 0, rewarded: 0, tvl: 0 });
    //     meta.currentRound = 3;
    // }

    function deleteRound(uint256[] calldata roundIds_) external onlyOwner {
        for (uint256 i = 0; i < roundIds_.length; ++i) {
            delete roundInfo[roundIds_[i]];
        }
    }

    function delRegisterInfo(address account_, uint256[] calldata roundIds_) external onlyOwner {
        for (uint256 i = 0; i < roundIds_.length; ++i) {
            registerInfo[roundIds_[i]][account_] = UserRegister({ registerAmount: 0, rewarded: 0 });
        }
    }

    modifier distributionReward() {
        _;

        uint256 endTm = roundInfo[meta.currentRound].endTm;
        if (endTm == 0) {
            roundInfo[meta.currentRound].endTm = block.timestamp + meta.interval;
        }
        if (block.timestamp >= endTm) {
            uint256 reward = ((meta.totalReward - meta.allocatedReward) * 8) / 10;
            if (reward > 0) {
                meta.allocatedReward += reward;
                // meta.lastDistributionTm = block.timestamp;

                roundInfo[meta.currentRound].reward = reward;

                ++meta.currentRound;
                roundInfo[meta.currentRound].endTm = block.timestamp + meta.interval;
            }
        }
    }

    function setTIme(uint256 tm_) public {
        meta.interval = tm_;
    }

    function totalInfo()
        public
        view
        returns (
            uint256 clamedReward,
            uint256 tvl,
            uint256 regNumber
        )
    {
        clamedReward = meta.claimedReward;
        tvl = roundInfo[meta.currentRound].tvl;
        regNumber = meta.registerNumber;
    }

    function initialize(
        address token_,
        address pair_,
        uint256 interval_
    ) public initializer {
        __Ownable_init_unchained();

        meta.token = IERC20(token_);
        meta.pair = IERC20(pair_);
        meta.interval = interval_;

        admin[msg.sender] = true;
        admin[token_] = true;

        meta.isOpen = true;
    }

    function setOpen(bool isOpen_) public onlyOwner {
        meta.isOpen = isOpen_;
    }

    function setAdmin(address addr_, bool com_) public onlyOwner {
        admin[addr_] = com_;
    }

    function addReward(uint256 amount) public onlyAdmin distributionReward {
        // meta.token.transferFrom(msg.sender, address(this), amount);
        meta.totalReward += amount;
    }

    function register(uint256 amount_) public onlyOpen distributionReward onlyOrigin {
        require(amount_ > 0, "amount must > 0");
        User storage uInfo = userInfo[msg.sender];
        uInfo.registerAmount += amount_;
        // uInfo.registerRound = meta.currentRound;

        if (!uInfo.register) {
            ++meta.registerNumber;
            uInfo.register = true;
        }

        uint256 round;
        if (block.timestamp > roundInfo[meta.currentRound].endTm && roundInfo[meta.currentRound].endTm != 0) {
            round = meta.currentRound + 1;
        } else {
            round = meta.currentRound;
        }

        meta.pair.transferFrom(msg.sender, address(this), amount_);

        if (registerInfo[round][msg.sender].registerAmount == 0) {
            amount_ = uInfo.registerAmount;
        }

        _register(round, msg.sender, amount_);
        // meta.tvl += amount_;
    }

    function _register(
        uint256 round,
        address account_,
        uint256 amount_
    ) internal {
        registerInfo[round][account_].registerAmount += amount_;
        roundInfo[round].tvl += amount_;
    }

    function _removeRegister(
        uint256 round,
        address account_,
        uint256 amount_
    ) internal {
        registerInfo[round][account_].registerAmount = 0;
        roundInfo[round].tvl -= amount_;
    }

    function getReward(address account_) public view returns (uint256 reward, uint256 roundId) {
        // User storage uInfo = userInfo[account_];

        if (meta.currentRound == 0 || !userInfo[account_].register) {
            return (reward, roundId);
        }

        UserRegister memory regInfo;
        for (uint256 i = meta.currentRound - 1; i > 0; --i) {
            regInfo = registerInfo[i][account_];
            if (regInfo.rewarded != 0) {
                break;
            }
            if (regInfo.registerAmount == 0) {
                continue;
            }
            reward = (regInfo.registerAmount * roundInfo[i].reward) / roundInfo[i].tvl;
            roundId = i;
            break;
        }
    }

    function claimReward() public onlyOpen distributionReward onlyOrigin {
        uint256 lastRound = meta.currentRound - 1;

        // User storage uInfo = userInfo[msg.sender];
        // require(uInfo.registerAmount > 0, "no stake");

        (uint256 reward, uint256 roundId) = getReward(msg.sender);
        require(reward > 0, "no reward");

        roundInfo[roundId].rewarded += reward;
        registerInfo[roundId][msg.sender].rewarded = reward;

        userInfo[msg.sender].rewarded += reward;
        meta.claimedReward += reward;

        meta.token.transfer(msg.sender, reward);

        if (lastRound != roundId && registerInfo[meta.currentRound][msg.sender].registerAmount != 0) {
            return;
        }
        _register(meta.currentRound, msg.sender, userInfo[msg.sender].registerAmount);
    }

    function unRegister() public distributionReward onlyOrigin {
        User storage uInfo = userInfo[msg.sender];
        require(uInfo.registerAmount > 0, "no stake");

        uint256 currRegister = registerInfo[meta.currentRound][msg.sender].registerAmount;
        if (currRegister > 0) {
            _removeRegister(meta.currentRound, msg.sender, currRegister);
        }
        // require(registerAmount == uInfo.registerAmount, "no stake");

        meta.pair.transfer(msg.sender, uInfo.registerAmount);
        uInfo.registerAmount = 0;
    }

    function info(address account_) external view returns (uint256[6] memory uInfo) {
        uInfo[0] = meta.totalReward - meta.allocatedReward;
        uInfo[1] = meta.totalReward;
        uInfo[2] = roundInfo[meta.currentRound].endTm;
        uInfo[3] = userInfo[account_].registerAmount;
        (uInfo[4], ) = getReward(account_);
        uInfo[5] = registerInfo[meta.currentRound][account_].registerAmount;
    }
}