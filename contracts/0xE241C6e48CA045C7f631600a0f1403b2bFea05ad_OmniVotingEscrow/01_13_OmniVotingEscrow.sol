// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./interfaces/IVotingEscrow.sol";
import "./interfaces/IOmniVotingEscrow.sol";
import "./interfaces/IVotingEscrowRemapper.sol";
import "@layerzerolabs/solidity-examples/contracts/lzApp/NonblockingLzApp.sol";

contract OmniVotingEscrow is NonblockingLzApp, IOmniVotingEscrow {
    IVotingEscrow public immutable votingEscrow;
    IVotingEscrowRemapper public immutable votingEscrowRemapper;

    // Packet types for child chains:
    uint16 PT_USER = 0; // user balance and total supply update
    uint16 PT_TS = 1; // total supply update

    event UserBalToChain(uint16 dstChainId, address localUser, address remoteUser, IVotingEscrow.Point userPoint, IVotingEscrow.Point totalSupplyPoint);
    event TotalSupplyToChain(uint16 dstChainId, IVotingEscrow.Point totalSupplyPoint);

    constructor(address _lzEndpoint, address _votingEscrowRemapper) NonblockingLzApp(_lzEndpoint) {
        require(_votingEscrowRemapper != address(0x0), "OmniVotingEscrow: remapper cannot be 0x0");

        votingEscrowRemapper = IVotingEscrowRemapper(_votingEscrowRemapper);
        votingEscrow = votingEscrowRemapper.getVotingEscrow();
    }

    function _nonblockingLzReceive(
        uint16, /*_srcChainId*/
        bytes memory, /*_srcAddress*/
        uint64, /*_nonce*/
        bytes memory /*_payload*/
    ) internal virtual override {
        revert("OmniVotingEscrow: cannot receive lzMsgs");
    }

    function estimateSendUserBalance(uint16 _dstChainId, bool _useZro, bytes calldata _adapterParams) public view returns (uint nativeFee, uint zroFee) {
        bytes memory lzPayload = abi.encode(PT_USER, address(0x0), 0, IVotingEscrow.Point(0, 0, 0, 0), IVotingEscrow.Point(0, 0, 0, 0));
        return lzEndpoint.estimateFees(_dstChainId, address(this), lzPayload, _useZro, _adapterParams);
    }

    function estimateSendTotalSupply(uint16 _dstChainId, bool _useZro, bytes calldata _adapterParams) public view returns (uint nativeFee, uint zroFee) {
        bytes memory lzPayload = abi.encode(PT_TS, IVotingEscrow.Point(0, 0, 0, 0));
        return lzEndpoint.estimateFees(_dstChainId, address(this), lzPayload, _useZro, _adapterParams);
    }

    function sendUserBalance(address _localUser, uint16 _dstChainId, address payable _refundAddress, address _zroPaymentAddress, bytes memory _adapterParams) public payable {
        uint userEpoch = votingEscrow.user_point_epoch(_localUser);
        IVotingEscrow.Point memory uPoint = votingEscrow.user_point_history(_localUser, userEpoch);

        uint lockedEnd = votingEscrow.locked__end(_localUser);

        // always send total supply along with a user update
        uint totalSupplyEpoch = votingEscrow.epoch();
        IVotingEscrow.Point memory tsPoint = votingEscrow.point_history(totalSupplyEpoch);

        address remappedAddress = votingEscrowRemapper.getRemoteUser(_localUser, _dstChainId);
        address remoteUser = remappedAddress != address(0x0) ? remappedAddress : _localUser;

        bytes memory lzPayload = abi.encode(PT_USER, remoteUser, lockedEnd, uPoint, tsPoint);
        _lzSend(_dstChainId, lzPayload, _refundAddress, _zroPaymentAddress, _adapterParams, msg.value);
        emit UserBalToChain(_dstChainId, _localUser, remoteUser, uPoint, tsPoint);
    }

    function sendTotalSupply(uint16 _dstChainId, address payable _refundAddress, address _zroPaymentAddress, bytes memory _adapterParams) public payable {
        uint totalSupplyEpoch = votingEscrow.epoch();
        IVotingEscrow.Point memory tsPoint = votingEscrow.point_history(totalSupplyEpoch);

        // Total supply point may only change if none has checkpointed after the current week has started.
        // If that's the case the checkpoint is performed at this point, before bridging the total supply.
        if (_hasLastCheckpointExpired(tsPoint.ts)) {
            votingEscrow.checkpoint();
            // Get updated point.
            totalSupplyEpoch = votingEscrow.epoch();
            tsPoint = votingEscrow.point_history(totalSupplyEpoch);
        }

        bytes memory lzPayload = abi.encode(PT_TS, tsPoint);
        _lzSend(_dstChainId, lzPayload, _refundAddress, _zroPaymentAddress, _adapterParams, msg.value);
        emit TotalSupplyToChain(_dstChainId, tsPoint);
    }

    function _hasLastCheckpointExpired(uint lastCheckpointTimestamp) internal view returns (bool) {
        // If last checkpoint rounded to weeks + one week is still behind the block timestamp, then it has expired.
        return (lastCheckpointTimestamp / 1 weeks) * 1 weeks + 1 weeks < block.timestamp;
    }
}