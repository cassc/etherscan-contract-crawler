// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../OZ/OZERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./ERC721Creator.sol";
import "./ERC721Metadata.sol";
import "./ERC721ProxyCall.sol";
import "./ERC721Royalty.sol";
import "../interfaces/ILazyMintable.sol";
import "../users/AddressManagerNode.sol";

import "../interfaces/IAdminRole.sol";
import "../interfaces/INodeRole.sol";
import "../interfaces/IModuleRole.sol";
import "../interfaces/ICHIZUCore.sol";

error ERC721Mint_Policy_Is_Not_0();
error ERC721Mint_Time_Expired();

/**
 * @title Allows creators to mint NFTs.
 */
abstract contract ERC721Mint is
    Initializable,
    AddressManagerNode,
    OZERC721Upgradeable,
    ERC721ProxyCall,
    ERC721Creator,
    ERC721Royalty,
    ERC721Metadata
{
    using ECDSA for bytes32;

    /// @notice A sequence ID to use for the last minted NFT.
    uint256 internal lastTokenId;
    /// @notice address of orderFulfiller contract
    address private orderFulfiller;

    mapping(bytes32 => bool) public mintHashHistory;

    /**
     * @notice Emitted when a new NFT is minted.
     * @param creator The address of the creator & owner at this time this NFT was minted.
     * @param tokenId The tokenId of the newly minted NFT.
     * @param indexedTokenIPFSPath The CID of the newly minted NFT, indexed to enable watching
     * for mint events by the tokenCID.
     * @param tokenIPFSPath The actual CID of the newly minted NFT.
     */
    event Minted(
        address indexed creator,
        uint256 indexed tokenId,
        uint256 policy,
        string indexed indexedTokenIPFSPath,
        string tokenIPFSPath,
        bytes32 mintHash
    );

    /**
     * @dev Called once after the initial deployment to set the initial tokenId.
     * @param _core The address of the contract defining roles for collections to use.
     */
    function _initializeERC721Mint(address _core)
        internal
        view
        onlyInitializing
    {
        AddressManagerNode(payable(_core));
    }

    /**
     * @notice It allows you to mint with hash and signature
     * @notice Used when you want to mint with policy
     * @dev Used hash value is not available
     * @dev Erc721 does not use validateinfo
     * @param signerAddress This is the address of the person who signed about mint
     * @param mintSignature Mint signature signed with minthash
     * @param mintHash It's a hash of the transaction information about mint
     * @param creatorAddress This is the address of the creator
     * @param receiverAddress This is the address of the recipient
     * @param ipfsHash ipfshash used for mint
     * @param policy To register policy id.
     * @return tokenId newly minted tokenId of nft
     */
    function mint(
        address signerAddress,
        bytes memory mintSignature,
        bytes32 mintHash,
        address creatorAddress,
        address receiverAddress,
        uint256 policy,
        string memory ipfsHash,
        uint256 expiredAt
    ) public returns (uint256 tokenId) {
        require(!mintHashHistory[mintHash], "ERC721Mint_Hash_Is_Duplicated");

        if (expiredAt < block.timestamp) {
            revert ERC721Mint_Time_Expired();
        }

        if (policy == 0) {
            revert ERC721Mint_Policy_Is_Not_0();
        }

        bool success = _validateMintSignature(
            signerAddress,
            mintSignature,
            mintHash,
            creatorAddress,
            ipfsHash,
            expiredAt
        );
        require(success, "ERC721Mint : Signature is wrong");

        unchecked {
            // Number of tokens cannot overflow 256 bits.
            tokenId = ++lastTokenId;
        }
        _mint(receiverAddress, tokenId);
        _updateTokenCreator(tokenId, payable(creatorAddress));
        _setTokenIPFSHash(tokenId, ipfsHash);
        _setTokenPolicy(tokenId, policy);

        mintHashHistory[mintHash] = true;

        // setApprovalForAll(orderFulfiller, true);
        emit Minted(
            receiverAddress,
            tokenId,
            policy,
            ipfsHash,
            ipfsHash,
            mintHash
        );
    }

    /**
     * @notice Function used in the fulfillorder
     * @dev Only chizu module is available
     * @param creatorAddress This is the address of the creator
     * @param receiverAddress This is the address of the recipient
     * @param ipfsHash ipfshash used for mint
     * @param mintHash It's a hash of the transaction information
     * @return tokenId newly minted tokenId of nft
     */
    function chizuMintFor(
        address creatorAddress,
        address receiverAddress,
        uint256 policy,
        string memory ipfsHash,
        bytes32 mintHash,
        uint256 expiredAt
    ) public onlyCHIZUModule returns (uint256 tokenId) {
        require(!mintHashHistory[mintHash], "ERC721Mint_Hash_Is_Duplicated");

        if (expiredAt < block.timestamp) {
            revert ERC721Mint_Time_Expired();
        }

        if (policy == 0) {
            revert ERC721Mint_Policy_Is_Not_0();
        }

        unchecked {
            // Number of tokens cannot overflow 256 bits.
            tokenId = ++lastTokenId;
        }
        _mint(receiverAddress, tokenId);
        _updateTokenCreator(tokenId, payable(creatorAddress));
        _setTokenIPFSHash(tokenId, ipfsHash);
        _setTokenPolicy(tokenId, policy);

        mintHashHistory[mintHash] = true;

        emit Minted(
            receiverAddress,
            tokenId,
            policy,
            ipfsHash,
            ipfsHash,
            mintHash
        );
    }

    /**
     * @notice Gets the tokenId of the next NFT minted.
     * @return tokenId The ID that the next NFT minted will use.
     */
    function getLastTokenId() external view returns (uint256 tokenId) {
        tokenId = lastTokenId;
    }

    /**
     * @dev Functions that validate mintsignature
     */
    function _validateMintSignature(
        address signerAddress,
        bytes memory mintSignature,
        bytes32 mintHash,
        address creatorAddress,
        string memory ipfsHash,
        uint256 expiredAt
    ) internal view returns (bool success) {
        if (!INodeRole(core).isNode(signerAddress)) {
            return false;
        }

        bytes32 calculatedHash = keccak256(
            abi.encodePacked(
                uint256(uint160(address(this))),
                uint256(uint160(creatorAddress)),
                ipfsHash,
                uint256(expiredAt)
            )
        );
        bytes32 calculatedSignature = keccak256(
            abi.encodePacked(
                //ethereum signature prefix
                "\x19Ethereum Signed Message:\n32",
                //Orderer
                uint256(calculatedHash)
            )
        );
        address recoveredSigner = calculatedSignature.recover(mintSignature);

        if (calculatedHash != mintHash) {
            return false;
        }

        if (recoveredSigner != signerAddress) {
            return false;
        }
        return true;
    }

    /**
     * @dev Explicit override to address compile errors.
     */
    function _burn(uint256 tokenId)
        internal
        virtual
        override(OZERC721Upgradeable, ERC721Creator, ERC721Metadata)
    {
        super._burn(tokenId);
    }

    /**
     * @inheritdoc ERC165
     * @dev This is required to avoid compile errors.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(OZERC721Upgradeable, ERC721Royalty, ERC721Creator)
        returns (bool)
    {
        if (interfaceId == type(ILazyMintable).interfaceId) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[1000] private __gap;
}