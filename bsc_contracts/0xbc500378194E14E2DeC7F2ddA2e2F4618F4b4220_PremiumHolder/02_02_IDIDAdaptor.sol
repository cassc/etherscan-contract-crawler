// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface for DID adaptor.
 * DAO users can sign up with 3rd party DID protocols, eg Binance BABT, ENS, etc.
 */
interface IDIDAdaptor {
    function connect(
        uint256 tokenId,
        address claimer,
        bytes32 accountType,
        bytes memory sign_info
    ) external virtual returns (bool);

    function verifyAccount(uint256 tokenId)
        external
        view
        virtual
        returns (bool);

    function disconnect(uint256 tokenId) external virtual returns (bool);

    function totalBinding() external returns (uint256);
}