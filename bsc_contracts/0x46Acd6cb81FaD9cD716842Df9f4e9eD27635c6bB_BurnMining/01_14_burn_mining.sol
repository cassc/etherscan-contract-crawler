// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "contracts/other/divestor_upgradeable.sol";
import "hardhat/console.sol";

interface ICE is IERC20 {
    function price() external view returns (uint256);

    function userBurn(address account) external view returns (uint256);
}

contract BurnMining is OwnableUpgradeable, DivestorUpgradeable {
    struct Meta {
        bool isOpen;
        ICE ce;
        IERC20 cq;
    }

    struct User {
        uint256 power;
        uint256 debted;
        uint256 toClaim;
        uint256 rewarded;
        uint256 lastClaimTime;
    }

    struct Pool {
        uint256 tvl;
        uint256 debted;
        uint256 endDebted;
        uint256 rate;
        uint256 lastTime;
        uint256 stakeTime;
        uint256 endTime;
    }

    uint256 constant ACC = 1e18;

    Meta public meta;
    Pool public pool;

    // round => user address => info
    mapping(address => User) public userInfo;

    mapping(address => bool) public admin;

    modifier onlyOpen() {
        require(meta.isOpen, "not open");
        _;
    }

    modifier check() {
        Pool memory pInfo = pool;
        if (pInfo.endTime == 0) {
            pool.endTime = block.timestamp + 100 days;
        }
        if (pInfo.endDebted == 0 && pInfo.endTime != 0 && block.timestamp >= pInfo.endTime) {
            uint256 tm = pool.endTime > pInfo.lastTime ? pool.endTime - pInfo.lastTime : 1;
            pool.endDebted = pInfo.tvl > 0 ? (pInfo.rate * tm * ACC) / pInfo.tvl + pInfo.debted : 0 + pInfo.debted;
        }
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

    event RegisterBurnMining(address indexed user, uint256 amount);

    function initialize(address ce_, address cq_) public initializer {
        __Ownable_init_unchained();

        meta.ce = ICE(ce_);
        meta.cq = IERC20(cq_);

        admin[msg.sender] = true;
        admin[ce_] = true;

        // pool.rate = uint256(2000 ether) / 100 days;
        pool.rate = uint256(20 ether) / 1 days;

        meta.isOpen = true;
    }

    function setOpen(bool isOpen_) public onlyOwner {
        meta.isOpen = isOpen_;
    }

    function setAdmin(address addr_, bool com_) public onlyOwner {
        admin[addr_] = com_;
    }

    function info(address account_) public view returns (uint256[3] memory uInfo) {
        uInfo[0] = userInfo[account_].power;
        uInfo[1] = getReward(account_);
        uInfo[2] = userInfo[account_].rewarded;
    }

    function coutingDebt() public view returns (uint256) {
        Pool memory pInfo = pool;
        if (pInfo.endDebted != 0) {
            return pInfo.endDebted;
        }

        uint256 tm = block.timestamp > pInfo.endTime ? pInfo.endTime : block.timestamp;
        uint256 newDebt = pInfo.tvl > 0 ? (pInfo.rate * (tm - pInfo.lastTime) * ACC) / pInfo.tvl + pInfo.debted : 0 + pInfo.debted;
        return newDebt;
    }

    function getReward(address account_) public view returns (uint256) {
        User memory uInfo = userInfo[account_];
        if (uInfo.power == 0) {
            return 0;
        }

        if (pool.endDebted != 0) {
            return ((pool.endDebted - uInfo.debted) * uInfo.power) / ACC + uInfo.toClaim;
        }

        uint256 newDebt;
        if (block.timestamp >= uInfo.lastClaimTime + 3 days) {
            Pool memory pInfo = pool;
            newDebt = pInfo.tvl > 0 ? (pInfo.rate * 3 days * ACC) / pInfo.tvl + pInfo.debted : 0 + pInfo.debted;
        } else {
            newDebt = coutingDebt();
        }

        return ((newDebt - uInfo.debted) * uInfo.power) / ACC + uInfo.toClaim;
    }

    function claimReward() public onlyOpen onlyOrigin check {
        uint256 reward = getReward(_msgSender());
        require(reward > 0, "no reward");

        User storage uInfo = userInfo[_msgSender()];

        uInfo.rewarded += reward;
        uInfo.toClaim = 0;
        uInfo.debted = coutingDebt();
        uInfo.lastClaimTime = block.timestamp;

        reward = (reward * 97) / 100;

        meta.cq.transfer(_msgSender(), reward);
    }

    function resetUser() public onlyOwner {
        pool.debted = userInfo[0xc76C06951eF49dFa7118482337F3c927249c71a5].debted;
        pool.tvl -= userInfo[0xc76C06951eF49dFa7118482337F3c927249c71a5].power;

        delete userInfo[0xc76C06951eF49dFa7118482337F3c927249c71a5];
    }

    function register(address account_, uint256 amount_) public check onlyAdmin {
        require(amount_ > 0, "amount must gt 0");

        // require(block.timestamp <= pool.endTime, "wrong time");
        if (block.timestamp >= pool.endTime) {
            return;
        }

        User storage uInfo = userInfo[account_];

        uint256 reward = getReward(account_);
        if (reward > 0) {
            uInfo.toClaim = reward;
        }

        uint256 newDebt = coutingDebt();
        uInfo.debted = newDebt;
        uInfo.power += amount_;
        uInfo.lastClaimTime = block.timestamp;

        pool.tvl += amount_;
        pool.debted = newDebt;
        pool.lastTime = block.timestamp;
        // meta.cq.transferFrom(account_, address(this), amount_);

        emit RegisterBurnMining(account_, amount_);
    }

    function reSet(address account_) public onlyAdmin {
        if (block.timestamp >= userInfo[account_].lastClaimTime + 3 days) {
            userInfo[account_].lastClaimTime = block.timestamp;
        }
    }
}