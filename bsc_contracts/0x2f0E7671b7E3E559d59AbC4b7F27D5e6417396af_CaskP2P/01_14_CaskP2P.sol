// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@opengsn/contracts/src/BaseRelayRecipient.sol";

import "../interfaces/ICaskP2P.sol";
import "../interfaces/ICaskP2PManager.sol";

contract CaskP2P is
ICaskP2P,
Initializable,
OwnableUpgradeable,
PausableUpgradeable,
BaseRelayRecipient
{
    using SafeERC20 for IERC20Metadata;

    /** @dev contract to manage P2P executions. */
    ICaskP2PManager public p2pManager;

    /** @dev map of P2P ID to P2P info. */
    mapping(bytes32 => P2P) private p2pMap; // p2pId => P2P
    mapping(address => bytes32[]) private userP2Ps; // user => p2pId[]


    /** @dev minimum amount of vault base asset for a P2P. */
    uint256 public minAmount;

    /** @dev minimum period for a P2P. */
    uint32 public minPeriod;

    function initialize() public initializer {
        __Ownable_init();
        __Pausable_init();

        minAmount = 1;
        minPeriod = 86400;
    }
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function versionRecipient() public pure override returns(string memory) { return "2.2.0"; }

    function _msgSender() internal view override(ContextUpgradeable, BaseRelayRecipient)
    returns (address sender) {
        sender = BaseRelayRecipient._msgSender();
    }

    function _msgData() internal view override(ContextUpgradeable, BaseRelayRecipient)
    returns (bytes calldata) {
        return BaseRelayRecipient._msgData();
    }

    modifier onlyUser(bytes32 _p2pId) {
        require(_msgSender() == p2pMap[_p2pId].user, "!AUTH");
        _;
    }

    modifier onlyManager() {
        require(_msgSender() == address(p2pManager), "!AUTH");
        _;
    }


    function createP2P(
        address _to,
        uint256 _amount,
        uint256 _totalAmount,
        uint32 _period
    ) external override whenNotPaused returns(bytes32) {
        require(_amount >= minAmount, "!INVALID(amount)");
        require(_period >= minPeriod, "!INVALID(period)");

        bytes32 p2pId = keccak256(abi.encodePacked(_msgSender(), _amount, _period, block.number, block.timestamp));

        uint32 timestamp = uint32(block.timestamp);

        P2P storage p2p = p2pMap[p2pId];
        p2p.user = _msgSender();
        p2p.to = _to;
        p2p.amount = _amount;
        p2p.totalAmount = _totalAmount;
        p2p.period = _period;
        p2p.createdAt = timestamp;
        p2p.processAt = timestamp;
        p2p.status = P2PStatus.Active;

        userP2Ps[_msgSender()].push(p2pId);

        p2pManager.registerP2P(p2pId);

        require(p2p.status == P2PStatus.Active, "!UNPROCESSABLE");
        require(p2p.numPayments == 1, "!UNPROCESSABLE"); // make sure first P2P payment succeeded

        emit P2PCreated(p2pId, p2p.user, p2p.to, _amount, _totalAmount, _period);

        return p2pId;
    }

    function pauseP2P(
        bytes32 _p2pId
    ) external override onlyUser(_p2pId) whenNotPaused {
        P2P storage p2p = p2pMap[_p2pId];
        require(p2p.status == P2PStatus.Active, "!NOT_ACTIVE");

        p2p.status = P2PStatus.Paused;

        emit P2PPaused(_p2pId, p2p.user);
    }

    function resumeP2P(
        bytes32 _p2pId
    ) external override onlyUser(_p2pId) whenNotPaused {
        P2P storage p2p = p2pMap[_p2pId];
        require(p2p.status == P2PStatus.Paused, "!NOT_PAUSED");

        p2p.status = P2PStatus.Active;

        if (p2p.processAt < uint32(block.timestamp)) {
            p2p.processAt = uint32(block.timestamp);
        }

        p2pManager.registerP2P(_p2pId);

        emit P2PResumed(_p2pId, p2p.user);
    }

    function cancelP2P(
        bytes32 _p2pId
    ) external override onlyUser(_p2pId) whenNotPaused {
        P2P storage p2p = p2pMap[_p2pId];
        require(p2p.status == P2PStatus.Active ||
            p2p.status == P2PStatus.Paused, "!INVALID(status)");

        p2p.status = P2PStatus.Canceled;

        emit P2PCanceled(_p2pId, p2p.user);
    }

    function getP2P(
        bytes32 _p2pId
    ) external override view returns (P2P memory) {
        return p2pMap[_p2pId];
    }

    function getUserP2P(
        address _user,
        uint256 _idx
    ) external override view returns (bytes32) {
        return userP2Ps[_user][_idx];
    }

    function getUserP2PCount(
        address _user
    ) external override view returns (uint256) {
        return userP2Ps[_user].length;
    }


    /************************** MANAGER FUNCTIONS **************************/

    function managerCommand(
        bytes32 _p2pId,
        ManagerCommand _command
    ) external override onlyManager {

        P2P storage p2p = p2pMap[_p2pId];

        if (_command == ManagerCommand.Skip) {

            p2p.processAt = p2p.processAt + p2p.period;
            p2p.numSkips += 1;

            emit P2PSkipped(_p2pId, p2p.user);

        } else if (_command == ManagerCommand.Pause) {

            p2p.status = P2PStatus.Paused;

            emit P2PPaused(_p2pId, p2p.user);

        } else if (_command == ManagerCommand.Cancel) {

            p2p.status = P2PStatus.Canceled;

            emit P2PCanceled(_p2pId, p2p.user);

        }
    }

    function managerProcessed(
        bytes32 _p2pId,
        uint256 _amount,
        uint256 _fee
    ) external override onlyManager {
        P2P storage p2p = p2pMap[_p2pId];

        p2p.processAt = p2p.processAt + p2p.period;
        p2p.currentAmount += _amount;
        p2p.numPayments += 1;

        emit P2PProcessed(_p2pId, p2p.user, _amount, _fee);

        if (p2p.totalAmount > 0 && p2p.currentAmount >= p2p.totalAmount) {
            p2p.status = P2PStatus.Complete;
            emit P2PCompleted(_p2pId, p2p.user);
        }

    }

    /************************** ADMIN FUNCTIONS **************************/

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setManager(
        address _p2pManager
    ) external onlyOwner {
        p2pManager = ICaskP2PManager(_p2pManager);
    }

    function setTrustedForwarder(
        address _forwarder
    ) external onlyOwner {
        _setTrustedForwarder(_forwarder);
    }

    function setMinAmount(
        uint256 _minAmount
    ) external onlyOwner {
        minAmount = _minAmount;
    }

    function setMinPeriod(
        uint32 _minPeriod
    ) external onlyOwner {
        minPeriod = _minPeriod;
    }
}