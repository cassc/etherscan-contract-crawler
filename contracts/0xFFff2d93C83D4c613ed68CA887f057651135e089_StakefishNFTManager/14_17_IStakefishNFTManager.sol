// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "IERC721Metadata.sol";
import "IERC721Enumerable.sol";

interface IStakefishNFTManager is IERC721Metadata, IERC721Enumerable {

    event StakefishMintedWithContract(uint256 tokenId, address validatorContract, address to);
    event StakefishBurnedWithContract(uint256 tokenId, address validatorContract, address from);

    /// @dev implements immutable types
    function factory() external view returns (address);

    /// @notice Mints a new NFT Validator for each 32 ETH
    /// @param validators The number of validators requested
    function mint(uint256 validators) external payable;

    /// @notice Withdraw from NFT - only allowed for ownerOf(tokenId)
    /// @param tokenId of the NFT
    function withdraw(uint256 tokenId) external;

    /// @notice computes address based on token
    /// @param tokenId of the NFT
    /// @return address of the validator contract
    function computeAddress(uint256 tokenId) external view returns (address);

    /// @notice lookups the NFT Owner by address => tokenId => owner
    /// @param validator address created by mint
    /// @return address of the owner
    function validatorOwner(address validator) external view returns (address);

    /// @notice lookups the tokenId based on validator address
    /// @param validator address created by mint
    /// @return tokenId of the NFT
    function tokenForValidatorAddr(address validator) external view returns (uint256);

    /// @notice lookups the validator address based on tokenId
    /// @param tokenId of the NFT
    /// @return address of the validator contract
    function validatorForTokenId(uint256 tokenId) external view returns (address);

    /// @notice Burn NFT
    /// @notice Burns the token if the new nft manager implements the validatorOwner correctly
    /// function does not destroy validator contract, which freely allow
    /// them to associate to a new NFT Issuer contract for migration
    function verifyAndBurn(address newManager, uint256 tokenId) external;

    /// @notice claim NFT from another NFT Manager, used for migration
    /// @param oldManager old nft manager
    /// @param tokenId of the NFT on the old manager
    function claim(address oldManager, uint256 tokenId) external;

    /// @notice multicall static
    function multicallStatic(uint256[] calldata tokenIds, bytes[] calldata data) external view returns (bytes[] memory results);

    /// @notice multicall across multiple tokenIds
    function multicall(uint256[] calldata tokenIds, bytes[] calldata data) external returns (bytes[] memory results);
}