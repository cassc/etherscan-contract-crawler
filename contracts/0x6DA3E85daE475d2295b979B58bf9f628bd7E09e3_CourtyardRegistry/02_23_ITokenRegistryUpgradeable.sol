// SPDX-FileCopyrightText: © Courtyard Inc. (https://courtyard.io)
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

/**
 * @title {@openzeppelin/contracts-upgradeable} version of {ITokenRegistry}.
 */
interface ITokenRegistryUpgradeable is IERC165Upgradeable {

    /**
     * @dev mint a new token to {to}, and return the token id of the newly minted token. Upon minting a token, it is
     * required to provide the {proofOfIntegrity} of integrity of the token. 
     * 
     * The proof of integrity uniquely identifies the token and is used to guarantee the integrity of the token at all times.
     * 
     * Use-case: for a token representing a physical asset, {proofOfIntegrity} is a hash of the information that uniquely
     * identifies the physical asset in the physical world. 
     */
    function mintToken(address to, bytes32 proofOfIntegrity) external returns (uint256);

    /**
     * @dev burn a token. The calling burner account or contract should be approved to manipulate the token.
     * 
     * To prevent mistakes from happening, an implementation of {burnToken} should add a safeguard so that only an
     * account that is allowed to burn tokens AND is approved to maniputate the token should be able to call this
     * function.
     */
    function burnToken(bytes32 proofOfIntegrity) external returns (bool);

}