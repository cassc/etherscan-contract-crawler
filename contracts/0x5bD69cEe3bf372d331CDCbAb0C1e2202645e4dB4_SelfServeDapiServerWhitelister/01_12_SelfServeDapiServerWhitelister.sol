// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@api3/airnode-protocol-v1/contracts/dapis/DapiReader.sol";
import "./interfaces/ISelfServeDapiServerWhitelister.sol";
import "@api3/airnode-protocol-v1/contracts/dapis/interfaces/IDapiServer.sol";
import "@api3/airnode-protocol-v1/contracts/whitelist/interfaces/IWhitelistWithManager.sol";

contract SelfServeDapiServerWhitelister is
    DapiReader,
    ISelfServeDapiServerWhitelister
{
    constructor(address _dapiServer) DapiReader(_dapiServer) {}

    function allowToReadDataFeedWithIdFor30Days(
        bytes32 dataFeedId,
        address reader
    ) public override {
        (uint64 expirationTimestamp, ) = IDapiServer(dapiServer)
            .dataFeedIdToReaderToWhitelistStatus(dataFeedId, reader);
        uint64 targetedExpirationTimestamp = uint64(block.timestamp + 30 days);
        if (targetedExpirationTimestamp > expirationTimestamp) {
            IWhitelistWithManager(dapiServer).extendWhitelistExpiration(
                dataFeedId,
                reader,
                targetedExpirationTimestamp
            );
        }
    }

    function allowToReadDataFeedWithDapiNameFor30Days(
        bytes32 dapiName,
        address reader
    ) external override {
        allowToReadDataFeedWithIdFor30Days(
            keccak256(abi.encodePacked(dapiName)),
            reader
        );
    }
}