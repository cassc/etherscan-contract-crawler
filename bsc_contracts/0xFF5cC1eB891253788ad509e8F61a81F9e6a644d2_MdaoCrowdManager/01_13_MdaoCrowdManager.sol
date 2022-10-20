// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./MDaoCrowd.sol";

contract MdaoCrowdManager is AccessControl {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant CROWD_ROLE = keccak256("CROWD_ROLE");
    address public constant LP = 0x9b22403637F18020B78696766d2Be7De2F1a67e2;
    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address public constant CROWD_ACCOUNT = 0x91898e7c4e98249BfD22aA8Ed3698a2ea705e0AB;
    address public constant META_CROWD = 0xe28a60A43035824c575a78Ff83bCCA68a4506121;
    address public constant META_POINT = 0x0a29702D828C3bd9bA20C8d0cD46Dfb853422E98;
    address public vipFeeAddr = 0x15C06310C173eB31fC14CB0c453928e5B8b5CeBC;
    address public txFeeAddr = 0x0A1A6D2637AD0BE46BbD59E43B28640fCbb79650;
    address public defaultOperator = 0x5E2C9E05613d86C1C7BC5bC7532630F8229776ee;
    uint256 public defaultTxFee = 50e18;
    uint256 public txFee = 5e18 / 10;
    uint32[] public vipFee = [0, 1000, 1000, 5000, 10000, 100000, 200000];
    uint8 public leverageMinVip = 1;

    mapping(address => address) public crowdMap;
    mapping(address => uint256) public crowdTxFee;
    mapping(address => bool) public crowdStatus;

    EnumerableSet.AddressSet crowdSet;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);
    }

    function setParams(uint256 _txFee, uint8 _leverageMinVip) external onlyRole(OPERATOR_ROLE) {
        txFee = _txFee;
        leverageMinVip = _leverageMinVip;
    }

    function setAddresses(address _vipFeeAddr, address _txFeeAddr) external onlyRole(OPERATOR_ROLE) {
        vipFeeAddr = _vipFeeAddr;
        txFeeAddr = _txFeeAddr;
    }

    function setVipFee(uint32[] calldata _vipFee) external onlyRole(OPERATOR_ROLE) {
        vipFee = _vipFee;
    }

    function setDefaultOperator(address _defaultOperator) external onlyRole(OPERATOR_ROLE) {
        defaultOperator = _defaultOperator;
    }

    function chargeCrowdTxFee(address crowdAddr, uint256 amount) external {
        require(crowdSet.contains(crowdAddr), "crowd not exists");
        IERC20(USDT).safeTransferFrom(msg.sender, txFeeAddr, amount);
        crowdTxFee[crowdAddr] += amount;
    }

    function takeCrowdTxFee() external onlyRole(CROWD_ROLE) {
        require(crowdTxFee[msg.sender] >= txFee, "crowdTxFee not enough");
        crowdTxFee[msg.sender] -= txFee;
    }

    function buyVip(address crowdAddr, uint8 vip) external {
        require(crowdSet.contains(crowdAddr), "crowd not exists");
        require(crowdMap[msg.sender] == crowdAddr, "wrong crowdAddr");
        require(vip < vipFee.length, "wrong vip");
        IERC20(USDT).safeTransferFrom(msg.sender, vipFeeAddr, uint256(vipFee[vip]) * 1e18);
        ICrowdAccount(CROWD_ACCOUNT).upgrade(crowdAddr, vip);
    }

    function setCrowdStatus(bool status) external {
        address crowdAddr = crowdMap[msg.sender];
        require(crowdAddr != address(0), "crowd not exists");
        crowdStatus[crowdAddr] = status;
    }

    function newMdaoCrowd() external {
        require(crowdMap[msg.sender] == address(0), "crowd exists");
        require(ICrowdAccount(CROWD_ACCOUNT).registered(msg.sender), "not registered");
        MDaoCrowd crowd = new MDaoCrowd();
        address crowdAddr = address(crowd);
        crowdMap[msg.sender] = crowdAddr;
        crowdStatus[crowdAddr] = true;
        crowdSet.add(crowdAddr);
        _grantRole(CROWD_ROLE, crowdAddr);
        IERC20(USDT).safeTransferFrom(msg.sender, txFeeAddr, defaultTxFee);
        crowdTxFee[crowdAddr] = defaultTxFee;
        initCrowd(crowdAddr);
    }

    function initCrowd(address crowdAddr) internal {
        MDaoCrowd crowd = MDaoCrowd(crowdAddr);
        ICrowdAccount account = ICrowdAccount(CROWD_ACCOUNT);
        crowd.crowdRegister(msg.sender);
        uint8 vips = account.accountVips(msg.sender);
        account.upgrade(crowdAddr, leverageMinVip);
        crowd.setLeverage(true);
        crowd.setRecipient(msg.sender);
        crowd.grantRole(crowd.RESCUE_ROLE(), msg.sender);
        crowd.grantRole(crowd.OPERATOR_ROLE(), msg.sender);
        crowd.grantRole(crowd.OPERATOR_ROLE(), defaultOperator);
        account.upgrade(crowdAddr, vips);
    }

    function crowdGrantRole(
        address crowdAddr,
        bytes32 role,
        address account
    ) external onlyRole(OPERATOR_ROLE) {
        MDaoCrowd(crowdAddr).grantRole(role, account);
    }

    function transferFee(
        address token,
        address to,
        uint256 amount
    ) external onlyRole(OPERATOR_ROLE) {
        IERC20(token).safeTransfer(to, amount);
    }

    function crowdCount() external view returns (uint256) {
        return crowdSet.length();
    }

    function crowdList(uint256 offset, uint256 size) external view returns (address[] memory addrs, bool[] memory flags) {
        uint256 length = crowdSet.length();
        require(offset + size <= length, "out of bound");
        addrs = new address[](size);
        flags = new bool[](size);
        address[] memory values = crowdSet.values();
        for (uint256 i = 0; i < size; i++) {
            addrs[i] = values[offset + i];
            flags[i] = crowdStatus[addrs[i]];
        }
    }
}