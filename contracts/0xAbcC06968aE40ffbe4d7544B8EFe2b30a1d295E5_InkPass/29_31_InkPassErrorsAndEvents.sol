// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

contract InkPassErrorsAndEvents {
    error EditionSoldOut();
    error InvalidEditionId();
    error NotOwnerOrRedeemer();
    error TokenNotTransferable();

    event EditionMaxSupply(uint256 editionId, uint128 maxSupply);
    event EditionURI(uint256 editionId, string uri);
}