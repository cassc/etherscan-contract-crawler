// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

struct Account {
    uint256 srd;
    uint256 srw;
    address head;
    uint8 vip;
    uint40 point;
    uint40 effect;
    uint256 wdm;
    uint256 wd;
    uint256 wda;
    uint256 grd;
    uint40 rootSn;
}

interface IMeta {
    function accounts(address addr) external view returns (Account memory);
}

contract MetaAirdrop is AccessControlEnumerableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    function initialize() external initializer {
        __ReentrancyGuard_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);

        srcRate = 8e17;
        newRate = 2e17;

        srcTotal = 134966;

        mai = 0x35803e77c3163FEd8A942536C1c8e0d5bF90f906;
        meta = address(this);
    }

    address public mai;
    address public meta;

    uint40 public srcTotal;
    uint128 public srcRate;
    uint256 public srcAcc;
    mapping(address => uint40) public srcMetas;
    mapping(address => uint256) public srcDebets;

    bool public newWithdrawSwitch;
    uint128 public newRate;
    uint256 public newBack;
    mapping(address => uint40) public nowPoints;
    mapping(address => bool) public claims;

    function recharge(uint256 amount) external nonReentrant {
        IERC20Upgradeable(mai).safeTransferFrom(msg.sender, address(this), amount);
        srcAcc += (amount * srcRate) / 1e18 / srcTotal;
    }

    function setBaseParam(
        address mai_,
        address meta_,
        uint128 srcRate_,
        uint128 newRate_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        mai = mai_;
        meta = meta_;
        srcRate = srcRate_;
        newRate = newRate_;
    }

    function setNewParam(bool switch_, uint256 newBack_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        newWithdrawSwitch = switch_;
        newBack = newBack_;
    }

    function settle(IERC20Upgradeable token, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        token.safeTransfer(msg.sender, amount);
    }

    function newClaim() external nonReentrant {
        require(!claims[msg.sender], "Already claim.");
        uint40 nowMetaCount = IMeta(meta).accounts(msg.sender).point;
        claims[msg.sender] = true;
        nowPoints[msg.sender] = nowMetaCount;
    }

    function newWithdraw() external nonReentrant {
        require(newWithdrawSwitch, "Withdraw switch is close.");
        require(claims[msg.sender], "You have not claim.");
        uint40 nowMetaCount = IMeta(meta).accounts(msg.sender).point;
        if (nowMetaCount > nowPoints[msg.sender]) {
            uint256 backAmount = (nowMetaCount - nowPoints[msg.sender]) * newBack;
            nowPoints[msg.sender] = nowMetaCount;
            IERC20Upgradeable(mai).safeTransfer(msg.sender, backAmount);
        }
    }

    function newPending(address addr) external view returns (uint40 count, uint256 amount) {
        if (claims[addr]) {
            uint40 nowMetaCount = IMeta(meta).accounts(addr).point;
            if (nowMetaCount > nowPoints[addr]) {
                count = nowMetaCount - nowPoints[addr];
                amount = count * newBack;
            }
        }
    }

    function metasImport(address[] calldata addrs, uint40[] calldata metas) external onlyRole(OPERATOR_ROLE) {
        require(addrs.length == metas.length, "Length error.");
        for (uint40 i = 0; i < addrs.length; i++) {
            srcMetas[addrs[i]] = metas[i];
        }
    }

    function srcWithdraw(uint256 amount) external nonReentrant {
        require(amount <= srcPending(msg.sender), "Insufficient of Balance");
        srcDebets[msg.sender] += amount;
        IERC20Upgradeable(mai).safeTransfer(msg.sender, amount);
    }

    function srcPending(address addr) public view returns (uint256) {
        return srcAcc * srcMetas[addr] - srcDebets[addr];
    }
}