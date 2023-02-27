// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {TypeAndVersion} from "../interfaces/TypeAndVersion.sol";
import {ICollectooorFactory} from "../interfaces/ICollectooorFactory.sol";
import {IDistributooorFactory} from "../interfaces/IDistributooorFactory.sol";
import {CrossChainHub} from "../vendor/CrossChainHub.sol";
import {Sets} from "../vendor/Sets.sol";
import {Withdrawable} from "../vendor/Withdrawable.sol";
import {Collectooor} from "./Collectooor.sol";

/// @title CollectooorFactory
/// @author kevincharm
/// @notice This contract keeps an up-to-date record of participants of a long-
///     running raffle. The list of participants is additionally recorded as
///     a sparse merkle tree, which gets submitted to the RaffleChef in the
///     canonical chain.
/// @dev This contract is intended to be deployed on Arbitrum Nova.
contract CollectooorFactory is
    ICollectooorFactory,
    TypeAndVersion,
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    CrossChainHub,
    Withdrawable
{
    using Sets for Sets.Set;
    /// @notice Unique identifier for this Collectooors
    uint256 public nextId;
    /// @notice Set of collectooor contracts
    Sets.Set private collectooors;
    /// @notice Master copy of collectooors to deploy
    address public collectooorMasterCopy;

    uint256[47] private __CollectooorFactory_gap;

    error UnknownCollectooor(address collectooor);
    error UnknownCrossChainAction(uint8 action);
    error CollectooorNotFinalised(address collectooor);

    constructor() CrossChainHub(bytes("")) {
        _disableInitializers();
    }

    function init(
        address celerMessageBus_,
        uint256 maxCrossChainFee_,
        address collectooorMasterCopy_
    ) public initializer {
        __Ownable_init();
        __CrossChainHub_init(celerMessageBus_, maxCrossChainFee_);
        collectooors.init();
        collectooorMasterCopy = collectooorMasterCopy_;
    }

    function typeAndVersion()
        external
        pure
        virtual
        override(TypeAndVersion, CrossChainHub)
        returns (string memory)
    {
        return "CollectooorFactory 1.0.0";
    }

    fallback() external payable {}

    receive() external payable {}

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function _authoriseWithdrawal() internal override onlyOwner {}

    function setCollectooorMasterCopy(
        address collectooorMasterCopy_
    ) external onlyOwner {
        address oldMasterCopy = collectooorMasterCopy;
        collectooorMasterCopy = collectooorMasterCopy_;
        emit CollectooorMasterCopyUpdated(
            oldMasterCopy,
            collectooorMasterCopy_
        );
    }

    function createCollectooor(
        uint32 maxDepth,
        uint256 collectionDeadlineTimestamp
    ) external returns (address) {
        address collectooorProxy = Clones.clone(collectooorMasterCopy);
        // Record as known consumer
        collectooors.add(collectooorProxy);
        Collectooor(collectooorProxy).init(
            msg.sender,
            maxDepth,
            collectionDeadlineTimestamp
        );
        emit CollectooorDeployed(collectooorProxy);
        return collectooorProxy;
    }

    function _executeValidatedMessage(
        address sender,
        uint64 srcChainId,
        bytes calldata message,
        address /** executor */
    ) internal virtual override {
        (uint8 rawAction, bytes memory data) = abi.decode(
            message,
            (uint8, bytes)
        );
        CrossChainAction action = CrossChainAction(rawAction);
        if (action == CrossChainAction.RequestMerkleRoot) {
            (address requester, address collectooor) = abi.decode(
                data,
                (address, address)
            );
            if (!collectooors.has(collectooor)) {
                revert UnknownCollectooor(collectooor);
            }
            if (!Collectooor(collectooor).isFinalised()) {
                revert CollectooorNotFinalised(collectooor);
            }
            bytes32 merkleRoot = Collectooor(collectooor).getLastRoot();
            uint256 nodeCount = Collectooor(collectooor).getParticipantsCount();
            // Send merkleRoot back to sender
            _sendCrossChainMessage(
                srcChainId,
                sender,
                uint8(IDistributooorFactory.CrossChainAction.ReceiveMerkleRoot),
                abi.encode(
                    requester,
                    collectooor,
                    block.number,
                    merkleRoot,
                    nodeCount
                )
            );
            emit MerkleRootSent(requester, merkleRoot, nodeCount);
        } else {
            revert UnknownCrossChainAction(rawAction);
        }

        // else if (action == CrossChainAction.RequestMerkleRootAtBlock) {
        //     (address requester, address collectooor, uint256 blockNumber) = abi
        //         .decode(data, (address, address, uint256));
        //     if (!collectooors.has(collectooor)) {
        //         revert UnknownCollectooor(collectooor);
        //     }
        //     bytes32 merkleRoot = Collectooor(collectooor).getRootAtBlock(
        //         blockNumber
        //     );
        //     uint256 nodeCount = Collectooor(collectooor).getParticipantsCount();
        //     // Send merkleRoot back to sender
        //     _sendCrossChainMessage(
        //         srcChainId,
        //         sender,
        //         uint8(IDistributooorFactory.CrossChainAction.ReceiveMerkleRoot),
        //         abi.encode(
        //             requester,
        //             collectooor,
        //             block.number,
        //             merkleRoot,
        //             nodeCount
        //         )
        //     );
        // }
    }

    function setMessageBus(address messageBus) external onlyOwner {
        _setMessageBus(messageBus);
    }

    function setMaxCrossChainFee(uint256 maxFee) external onlyOwner {
        _setMaxCrossChainFee(maxFee);
    }

    function setKnownCrossChainHub(
        uint256 chainId,
        address crossChainHub,
        bool isKnown
    ) external onlyOwner {
        _setKnownCrossChainHub(chainId, crossChainHub, isKnown);
    }
}