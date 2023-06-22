// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

/**
 * Lazy Payable Claim interface
 */
interface ILazyPayableClaim {
    event ClaimInitialized(address indexed creatorContract, uint256 indexed instanceId, address initializer);
    event ClaimUpdated(address indexed creatorContract, uint256 indexed instanceId);
    event ClaimMint(address indexed creatorContract, uint256 indexed instanceId);
    event ClaimMintBatch(address indexed creatorContract, uint256 indexed instanceId, uint16 mintCount);
    event ClaimMintProxy(address indexed creatorContract, uint256 indexed instanceId, uint16 mintCount, address proxy, address mintFor);

    /**
     * @notice Withdraw funds
     */
    function withdraw(address payable receiver, uint256 amount) external;

    /**
     * @notice check if a mint index has been consumed or not (only for merkle claims)
     *
     * @param creatorContractAddress    the address of the creator contract for the claim
     * @param instanceId                the claim instanceId for the creator contract
     * @param mintIndex                 the mint claim instance
     * @return                          whether or not the mint index was consumed
     */
    //function checkMintIndex(address creatorContractAddress, uint256 instanceId, uint32 mintIndex) external view returns(bool);

    /**
     * @notice check if multiple mint indices has been consumed or not (only for merkle claims)
     *
     * @param creatorContractAddress    the address of the creator contract for the claim
     * @param instanceId                the claim instanceId for the creator contract
     * @param mintIndices               the mint claim instance
     * @return                          whether or not the mint index was consumed
     */
    //function checkMintIndices(address creatorContractAddress, uint256 instanceId, uint32[] calldata mintIndices) external view returns(bool[] memory);

    /**
     * @notice get mints made for a wallet (only for non-merkle claims with walletMax)
     *
     * @param minter                    the address of the minting address
     * @param creatorContractAddress    the address of the creator contract for the claim
     * @param instanceId                the claim instance for the creator contract
     * @return                          how many mints the minter has made
     */
    //function getTotalMints(address minter, address creatorContractAddress, uint256 instanceId) external view returns(uint32);

    /**
     * @notice allow a wallet to lazily claim a token according to parameters
     * @param creatorContractAddress    the creator contract address
     * @param instanceId                the claim instanceId for the creator contract
     */
    function mint(address creatorContractAddress, uint256 instanceId) external payable;

    /**
     * @notice allow a wallet to lazily claim a token according to parameters
     * @param creatorContractAddress    the creator contract address
     * @param instanceId                the claim instanceId for the creator contract
     * @param mintCount                 the number of claims to mint
     */
    function mintBatch(address creatorContractAddress, uint256 instanceId, uint16 mintCount) external payable;


    /**
     * @notice allow a proxy to mint a token for another address
     * @param creatorContractAddress    the creator contract address
     * @param instanceId                the claim instanceId for the creator contract
     * @param mintCount                 the number of claims to mint
     * @param mintFor                   the address to mint for
     */
    //function mintProxy(address creatorContractAddress, uint256 instanceId, uint16 mintCount, address mintFor) external payable;
}