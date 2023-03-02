//SPDX-License-Identifier: MIT

/// @title 404
/// @author transientlabs.xyz

pragma solidity 0.8.17;

import { ERC721ATLMerkle, ERC721ATLCore, ERC721A, MerkleProof } from "ERC721ATLMerkle.sol";
import { BlockList } from "BlockList.sol";
import { StoryContract } from "StoryContract.sol";

contract MissivesFromAGenerativeRealm is ERC721ATLMerkle, BlockList, StoryContract {
    
    bool public burnOpen;

    constructor(
        address royaltyRecipient,
        uint256 royaltyPercentage,
        uint256 price,
        uint256 supply,
        bytes32 merkleRoot,
        address admin,
        address payout,
        address[] memory blockedMarketplaces
    ) 
    ERC721ATLMerkle("Missives from a Generative Realm", "MGR", royaltyRecipient, royaltyPercentage, price, supply, merkleRoot, admin, payout)
    BlockList()
    StoryContract(true)
    {
        // blocklist
        uint256 l = blockedMarketplaces.length;
        for (uint256 i = 0; i < l; i++) {
            _setBlockListStatus(blockedMarketplaces[i], true);
        }
    }

    //================= Burn Functions =================//
    /// @notice function to set burn status
    /// @dev requires admin or owner
    function setBurnStatus(bool status) external adminOrOwner {
        burnOpen = status;
    }

    /// @notice burn function
    /// @dev requires burn to be open
    function burn(uint256 tokenId) external {
        require(burnOpen, "Burn is not open");
        _burn(tokenId, true);
    }

    //================= BlockList =================//
    function setBlockListStatus(address operator, bool status) external onlyOwner {
        _setBlockListStatus(operator, status);
    }

    //================= Overrides =================//
    /// @dev see {ERC721A.setApprovalForAll}
    function setApprovalForAll(address operator, bool approved) public virtual override(ERC721A) notBlocked(operator) {
        ERC721A.setApprovalForAll(operator, approved);
    }

    /// @dev see {ERC165.supportsInterface}
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721ATLCore, StoryContract) returns (bool) {
        return StoryContract.supportsInterface(interfaceId) || ERC721ATLCore.supportsInterface(interfaceId);
    }

    //================= Story Contract =================//
    /// @notice function to check if a token exists on the token contract
    function _tokenExists(uint256 tokenId) internal view override returns (bool) {
        return _exists(tokenId) && owner() == msg.sender;
    }

    /// @notice function to check ownership of a token
    function _isTokenOwner(address potentialOwner, uint256 tokenId) internal view override returns (bool) {
        return _exists(tokenId) && ownerOf(tokenId) == potentialOwner;
    }

    //================= Mint =================//
    function mint(uint256 /*numToMint*/, bytes32[] calldata /*merkleProof*/) external override payable nonReentrant {
        revert("use mintToken");
    }

    /// @notice function to mint with delegate minting enabled
    function mintToken(address recipient, uint256 numToMint, bytes32[] calldata merkleProof) external payable nonReentrant {
        require(_totalMinted() + numToMint <= maxSupply, "ERC721ATLMerkle: No token supply left");
        require(msg.value >= mintPrice * numToMint, "ERC721ATLMerkle: Not enough ether attached to the transaction");
        require(_numberMinted(recipient) + numToMint <= mintAllowance, "ERC721ATLMerkle: Mint allowance reached");
        if (allowlistSaleOpen) {
            bytes32 leaf = keccak256(abi.encodePacked(recipient));
            require(MerkleProof.verify(merkleProof, allowlistMerkleRoot, leaf), "ERC721ATLMerkle: Not on allowlist");
        }
        else if (!publicSaleOpen) {
            revert("ERC721ATLMerkle: Mint not open");
        }

        _mint(recipient, numToMint); // no external call here

        (bool success, ) = payoutAddress.call{value: msg.value}("");
        require(success, "payment failed");
    }
}