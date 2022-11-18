// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../access/InitializableOwnable.sol";
import "../../initializable/IMaxSupplyInitializer.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

error AirdropBatchSizeMustBeGreaterThanZero();
error MaxSupplyAlreadyInitialized();
error MaxSupplyCannotBeSetToMaxUint256();
error MaxSupplyCannotBeSetToZero();
error MaxSupplyExceeded(uint256 supplyAfterMint, uint256 maxSupply);

/**
 * @title SequentialAirdropMint
 * @author Limit Break, Inc.
 * @notice A contract mix-in that may optionally be used with extend ERC-721 tokens with sequential airdrop minting capabilities.
 * @dev Inheriting contracts must implement `_mintToken` and implement EIP-165 support as shown:
 *
 * function supportsInterface(bytes4 interfaceId) public view virtual override(AdventureNFT, IERC165) returns (bool) {
 *     return
 *     interfaceId == type(IMaxSupplyInitializer).interfaceId ||
 *     super.supportsInterface(interfaceId);
 *  }
 *
 */
abstract contract SequentialAirdropMint is InitializableOwnable, IMaxSupplyInitializer {

    /// @dev The next token id that will be minted - if zero, the next minted token id will be 1
    uint256 public nextTokenId;

    /// @dev The maximum token supply
    uint256 private _maxSupply;

    /// @dev Initializes parameters of tokens with maximum supplies.
    /// This cannot be set in the constructor because this contract is optionally compatible with EIP-1167.
    /// Throws if maxSupply has already been set to a non-zero value.
    /// Throws if specified maxSupply_ is zero.
    /// Throws if specified maxSupply_ is set to max uint256.
    function initializeMaxSupply(uint256 maxSupply_) public override onlyOwner {
        if(_maxSupply > 0) {
            revert MaxSupplyAlreadyInitialized();
        }

        if(maxSupply_ == 0) {
            revert MaxSupplyCannotBeSetToZero();
        }

        if(maxSupply_ == type(uint256).max) {
            revert MaxSupplyCannotBeSetToMaxUint256();
        }

        _maxSupply = maxSupply_;
    }

    /// @notice Owner bulk mint to airdrop.
    /// Throws if length of `to` array is zero.
    /// Throws if minting batch would exceed the max supply.
    function airdropMint(address[] calldata to) external onlyOwner {
        uint256 batchSize = to.length;
        if(batchSize == 0) {
            revert AirdropBatchSizeMustBeGreaterThanZero();
        }

        uint256 tokenIdToMint = nextTokenId;
        if(tokenIdToMint == 0) {
            tokenIdToMint = 1;
        }
        
        uint256 supplyAfterMint = tokenIdToMint + batchSize - 1;
        uint256 maxSupply_ = _maxSupply;
        if(supplyAfterMint > maxSupply_) {
            revert MaxSupplyExceeded(supplyAfterMint, maxSupply_);
        }

        unchecked {
            nextTokenId = tokenIdToMint + batchSize;

            for(uint256 i = 0; i < batchSize; ++i) {
                address recipient = to[i];
                if(recipient != address(0)) {
                    _mintToken(to[i], tokenIdToMint + i);
                }
            }
        }
    }

    /// @notice Returns the maximum mintable supply
    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    /// @dev Inheriting contracts must implement the token minting logic
    function _mintToken(address to, uint256 tokenId) internal virtual;
}