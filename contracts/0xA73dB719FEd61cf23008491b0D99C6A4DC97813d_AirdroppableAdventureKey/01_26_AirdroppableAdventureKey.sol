// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "limit-break-contracts/contracts/adventures/AdventureNFT.sol";
import "limit-break-contracts/contracts/initializable/IMaxSupplyInitializer.sol";

error MaxSupplyAlreadyInitialized();
error MaxSupplyCannotBeSetToZero();
error MaxSupplyExceeded(uint256 supplyAfterMint, uint256 maxSupply);

/**
 * @title AirdroppableAdventureKey
 * @author Limit Break, Inc.
 * @notice An adventure key reference contract that can be airdropped and cloned using EIP-1167.
 * See https://eips.ethereum.org/EIPS/eip-1167 for details.
 */
contract AirdroppableAdventureKey is AdventureNFT, IMaxSupplyInitializer {

    uint256 private nextTokenId;

    /// @dev The maximum token supply
    uint256 public maxSupply;

    constructor() ERC721("", "") {}

    /// @dev Initializes parameters of tokens with maximum supplies.
    /// These cannot be set in the constructor because this contract is optionally compatible with EIP-1167.
    function initializeMaxSupply(uint256 maxSupply_) public override onlyOwner {
        if(maxSupply > 0) {
            revert MaxSupplyAlreadyInitialized();
        }

        if(maxSupply_ == 0) {
            revert MaxSupplyCannotBeSetToZero();
        }

        maxSupply = maxSupply_;
    }

    /// @dev ERC-165 interface support
    function supportsInterface(bytes4 interfaceId) public view virtual override(AdventureNFT, IERC165) returns (bool) {
        return
        interfaceId == type(IMaxSupplyInitializer).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    /// @notice Owner bulk mint to airdrop
    function airdropMint(address[] calldata to) external onlyOwner {
        if(nextTokenId == 0) {
            nextTokenId = 1;
        }

        uint256 batchSize = to.length;
        uint256 tokenIdToMint = nextTokenId;
        
        uint256 supplyAfterMint = tokenIdToMint + batchSize - 1;
        uint256 maxSupply_ = maxSupply;
        if(supplyAfterMint > maxSupply_) {
            revert MaxSupplyExceeded(supplyAfterMint, maxSupply_);
        }

        nextTokenId = nextTokenId + batchSize;

        unchecked {
            for(uint256 i = 0; i < batchSize; ++i) {
                _mint(to[i], tokenIdToMint + i);
            }
        }
    }
}