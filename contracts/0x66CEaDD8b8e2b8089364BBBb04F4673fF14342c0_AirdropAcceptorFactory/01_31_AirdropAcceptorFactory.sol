// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/proxy/Clones.sol";

import "../interfaces/IDispatcher.sol";
import "../utils/KeysMapping.sol";
import "../utils/Ownable.sol";

import "./AirdropAcceptor.sol";
import "./IAirdropAcceptorFactory.sol";

contract AirdropAcceptorFactory is IAirdropAcceptorFactory, Ownable {
    IDispatcher public immutable hub;

    event AirdropAcceptorCreated(
        address indexed instance,
        uint256 indexed receiverId,
        address indexed owner,
        address creator
    );

    constructor(address _admin, address _dispatcher) Ownable(_admin) {
        hub = IDispatcher(_dispatcher);
    }

    function createAirdropAcceptor(address _to) external override returns (address, uint256) {
        address receiverImpl = hub.getContract(KeysMapping.AIRDROP_RECEIVER);

        address instance = Clones.clone(receiverImpl);

        uint256 wrapperId = AirdropAcceptor(instance).initialize(_to);

        IAllowedNFTs(hub.getContract(KeysMapping.PERMITTED_NFTS)).setNFTPermit(
            instance,
            KeysMapping.AIRDROP_WRAPPER_STRING
        );

        emit AirdropAcceptorCreated(instance, wrapperId, _to, msg.sender);

        return (instance, wrapperId);
    }
}