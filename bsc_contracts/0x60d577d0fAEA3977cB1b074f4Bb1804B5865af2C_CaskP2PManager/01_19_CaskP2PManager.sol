// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../job_queue/CaskJobQueue.sol";
import "../interfaces/ICaskP2PManager.sol";
import "../interfaces/ICaskP2P.sol";
import "../interfaces/ICaskVault.sol";

contract CaskP2PManager is
Initializable,
ReentrancyGuardUpgradeable,
CaskJobQueue,
ICaskP2PManager
{
    using SafeERC20 for IERC20Metadata;

    uint8 private constant QUEUE_ID_P2P = 1;


    /** @dev Pointer to CaskP2P contract */
    ICaskP2P public caskP2P;

    /** @dev vault to use for P2P funding. */
    ICaskVault public caskVault;
    

    /************************** PARAMETERS **************************/

    /** @dev max number of failed P2P purchases before P2P is permanently canceled. */
    uint256 public maxSkips;

    /** @dev P2P transaction fee. */
    uint256 public paymentFee;



    function initialize(
        address _caskP2P,
        address _caskVault
    ) public initializer {
        caskP2P = ICaskP2P(_caskP2P);
        caskVault = ICaskVault(_caskVault);

        maxSkips = 0;
        paymentFee = 0;

        __CaskJobQueue_init(3600);
    }
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function registerP2P(
        bytes32 _p2pId
    ) override external nonReentrant whenNotPaused {
        processWorkUnit(QUEUE_ID_P2P, _p2pId);
    }

    function processWorkUnit(
        uint8 _queueId,
        bytes32 _p2pId
    ) override internal {

        ICaskP2P.P2P memory p2p = caskP2P.getP2P(_p2pId);

        if (p2p.status != ICaskP2P.P2PStatus.Active){
            return;
        }

        uint32 timestamp = uint32(block.timestamp);

        // not time to process yet, re-queue for processAt time
        if (p2p.processAt > timestamp) {
            scheduleWorkUnit(_queueId, _p2pId, bucketAt(p2p.processAt));
            return;
        }

        uint256 amount = p2p.amount;
        if (p2p.totalAmount > 0 && amount > p2p.totalAmount - p2p.currentAmount) {
            amount = p2p.totalAmount - p2p.currentAmount;
        }
        // did a transfer happen successfully?
        if (_processP2PTransfer(p2p, amount)) {

            if (p2p.totalAmount == 0 || p2p.currentAmount + amount < p2p.totalAmount) {
                scheduleWorkUnit(_queueId, _p2pId, bucketAt(p2p.processAt + p2p.period));
            }

            caskP2P.managerProcessed(_p2pId, amount, paymentFee);

        } else {
            if (maxSkips > 0 && p2p.numSkips >= maxSkips) {
                caskP2P.managerCommand(_p2pId, ICaskP2P.ManagerCommand.Pause);
            } else {
                scheduleWorkUnit(_queueId, _p2pId, bucketAt(p2p.processAt + p2p.period));

                caskP2P.managerCommand(_p2pId, ICaskP2P.ManagerCommand.Skip);
            }
        }

    }

    function _processP2PTransfer(
        ICaskP2P.P2P memory _p2p,
        uint256 _amount
    ) internal returns(bool) {
        try caskVault.protocolPayment(_p2p.user, _p2p.to, _amount, paymentFee) {
            return true;
        } catch (bytes memory) {
            return false;
        }
    }


    function setParameters(
        uint256 _maxSkips,
        uint256 _paymentFee,
        uint32 _queueBucketSize,
        uint32 _maxQueueAge
    ) external onlyOwner {
        maxSkips = _maxSkips;
        paymentFee = _paymentFee;
        queueBucketSize = _queueBucketSize;
        maxQueueAge = _maxQueueAge;

        emit SetParameters();
    }

    function recoverFunds(
        address _asset,
        address _dest
    ) external onlyOwner {
        IERC20Metadata(_asset).transfer(_dest, IERC20Metadata(_asset).balanceOf(address(this)));
    }
}