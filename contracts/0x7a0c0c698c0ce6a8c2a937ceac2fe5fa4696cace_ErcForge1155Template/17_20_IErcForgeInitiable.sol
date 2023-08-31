//SPDX-License-Identifier: CC-BY-NC-ND

pragma solidity ^0.8.0;

interface IErcForgeInitiable {
    function init(
        address newOwner,
        string memory newName,
        string memory newSymbol,
        string memory newBaseTokenURI,
        string memory newContractUri,
        address royaltyReceiver,
        uint96 royaltyFee
    ) external;
}