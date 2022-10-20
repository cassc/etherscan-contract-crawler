// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface IMetaPointV2 {
    function register(address head) external;

    function up() external;

    function upBatch(uint256 times) external;

    function withdraw(uint256 amount) external;

    function arping(address addr) external view returns (uint256 total_, uint256 withdraw_);

    function levelUp(uint8 target) external;
}

interface IMetaCrowdV2 {
    function fund(uint256 regionIndex, uint256 amount) external;

    function withdrawBrokerReward(uint256 regionIndex, uint256[] memory roundIds) external;

    function harvestAll(uint256 regionIndex, uint256[] memory roundIds) external;

    function setLeverage(bool flag) external;

    function pending(
        address account,
        uint256 regionIndex,
        uint256 round
    )
        external
        view
        returns (
            uint256[] memory amounts,
            uint16 state,
            uint16 version,
            bool restart
        );

    function pendingForBrokerReward(
        address account,
        uint256 regionIndex,
        uint256[] calldata roundIds
    ) external view returns (uint256 amount, uint16[] memory states);

    function getHarvestableIds(address account, uint256 regionIndex) external view returns (uint256[] memory);

    function getBrokerRewardIds(address account, uint256 regionIndex) external view returns (uint256[] memory);
}

interface ICrowdAccount {
    function register(address head) external;

    function upgrade(address addr, uint8 vips) external;

    function accountVips(address addr) external returns (uint8 vips);

    function registered(address addr) external view returns (bool);

    function transferPriorityAmount(address addr, uint256 amount) external;
}

interface ICrowdFundAlloc {
    function withdrawPeerReward() external;

    function unlockWithdraw() external;
}

interface ICrowdManager {
    function takeCrowdTxFee() external;
}

contract MDaoCrowd is AccessControl {
    using SafeERC20 for IERC20;
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant RESCUE_ROLE = keccak256("RESCUE_ROLE");
    address public constant LP = 0x9b22403637F18020B78696766d2Be7De2F1a67e2;
    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address public constant CROWD_ACCOUNT = 0x91898e7c4e98249BfD22aA8Ed3698a2ea705e0AB;
    address public constant META_CROWD = 0xe28a60A43035824c575a78Ff83bCCA68a4506121;
    address public constant META_POINT = 0x0a29702D828C3bd9bA20C8d0cD46Dfb853422E98;
    address public constant FUND_ALLOC = 0x0556Be00a3DD855f3C287f1240A32044b5627C8a;
    address public recipient;
    address public mamager;

    constructor() {
        mamager = msg.sender;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);
        IERC20(USDT).safeApprove(msg.sender, 2**256 - 1);
        IERC20(USDT).safeApprove(META_CROWD, 2**256 - 1);
        IERC20(LP).safeApprove(META_POINT, 2**256 - 1);
    }

    function setRecipient(address _recipient) external onlyRole(OPERATOR_ROLE) {
        require(_recipient != address(0), "recipient error");
        recipient = _recipient;
    }

    function crowdRegister(address head) external onlyRole(OPERATOR_ROLE) {
        ICrowdAccount(CROWD_ACCOUNT).register(head);
    }

    function fund(uint256 regionIdx, uint256 amount) external onlyRole(OPERATOR_ROLE) {
        ICrowdManager(mamager).takeCrowdTxFee();
        IMetaCrowdV2(META_CROWD).fund(regionIdx, amount);
    }

    function harvestAll(uint256 regionIndex) external {
        ICrowdManager(mamager).takeCrowdTxFee();
        uint256[] memory roundIds = IMetaCrowdV2(META_CROWD).getHarvestableIds(address(this), regionIndex);
        IMetaCrowdV2(META_CROWD).harvestAll(regionIndex, roundIds);
    }

    function withdrawBrokerReward(uint256 regionIndex) external {
        ICrowdManager(mamager).takeCrowdTxFee();
        uint256[] memory roundIds = IMetaCrowdV2(META_CROWD).getBrokerRewardIds(address(this), regionIndex);
        IMetaCrowdV2(META_CROWD).withdrawBrokerReward(regionIndex, roundIds);
    }

    function setLeverage(bool flag) external onlyRole(OPERATOR_ROLE) {
        IMetaCrowdV2(META_CROWD).setLeverage(flag);
    }

    function register(address head) external onlyRole(OPERATOR_ROLE) {
        IMetaPointV2(META_POINT).register(head);
    }

    function up() external onlyRole(OPERATOR_ROLE) {
        ICrowdManager(mamager).takeCrowdTxFee();
        IMetaPointV2(META_POINT).up();
    }

    function levelUp(uint8 target) external onlyRole(OPERATOR_ROLE) {
        ICrowdManager(mamager).takeCrowdTxFee();
        IMetaPointV2(META_POINT).levelUp(target);
    }

    function upBatch(uint256 times) external onlyRole(OPERATOR_ROLE) {
        ICrowdManager(mamager).takeCrowdTxFee();
        IMetaPointV2(META_POINT).upBatch(times);
    }

    function withdraw(uint256 amount) external {
        ICrowdManager(mamager).takeCrowdTxFee();
        IMetaPointV2(META_POINT).withdraw(amount);
    }

    function arping() external view returns (uint256 total_, uint256 withdraw_) {
        return IMetaPointV2(META_POINT).arping(address(this));
    }

    function rescue(address token, uint256 amount) external onlyRole(RESCUE_ROLE) {
        IERC20(token).safeTransfer(recipient, amount);
    }

    function withdrawPeerReward() external {
        ICrowdManager(mamager).takeCrowdTxFee();
        ICrowdFundAlloc(FUND_ALLOC).withdrawPeerReward();
    }

    function unlockWithdraw() external {
        ICrowdManager(mamager).takeCrowdTxFee();
        ICrowdFundAlloc(FUND_ALLOC).unlockWithdraw();
    }

    function transferPriorityAmount(address addr, uint256 amount) external onlyRole(OPERATOR_ROLE) {
        ICrowdAccount(CROWD_ACCOUNT).transferPriorityAmount(addr, amount);
    }
}