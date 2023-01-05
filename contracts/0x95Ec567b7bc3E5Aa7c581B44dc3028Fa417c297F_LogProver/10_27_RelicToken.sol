/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./interfaces/IContractURI.sol";
import "./interfaces/IERC5192.sol";
import "./interfaces/ITokenURI.sol";

/**
 * @title RelicToken
 * @author Theori, Inc.
 * @notice RelicToken is the base contract for all Relic SBTs. It implements
 *         ERC721 (with transfers disables) and ERC5192.
 */
abstract contract RelicToken is Ownable, ERC165, IERC721, IERC721Metadata, IERC5192 {
    mapping(address => bool) public provers;

    /// @notice contract metadata URI provider
    IContractURI contractURIProvider;

    /**
     * @notice determind if the given owner is entitiled to a token with the specific data
     * @param owner the address in question
     * @param data the opaque data in question
     * @return the existence of the given data
     */
    function hasToken(address owner, uint96 data) internal view virtual returns (bool);

    /**
     * @notice updates the set of contracts trusted to create new tokens and
     *         possibly resolve entitlement questions
     * @param prover the address of the prover
     * @param valid whether the prover is trusted
     */
    function setProver(address prover, bool valid) external onlyOwner {
        provers[prover] = valid;
    }

    /**
     * @notice helper function to break a tokenId into its constituent data
     * @param tokenId the tokenId in question
     * @return who the address bound to this token
     * @return data any additional data bound to this token
     */
    function parseTokenId(uint256 tokenId) internal pure returns (address who, uint96 data) {
        who = address(bytes20(bytes32(tokenId << 96)));
        data = uint96(tokenId >> 160);
    }

    /**
     * @notice issue a new Relic
     * @param who the address to which this token should be bound
     * @param data any data to be associated with this token
     * @dev emits ERC-721 Transfer event and ERC-5192 Locked event. Note
     *      that storage is not generally updated by this function.
     */
    function mint(address who, uint96 data) public virtual {
        require(provers[msg.sender], "only a prover can mint");
        require(hasToken(who, data), "cannot mint for invalid token");

        uint256 id = uint256(uint160(who)) | (uint256(data) << 160);
        emit Transfer(address(0), who, id);
        emit Locked(id);
    }

    /* begin ERC-721 spec functions */
    /**
     * @inheritdoc IERC721
     * @dev If the token has not been issued (no transfer event) this function
     *      may still return an owner if there is an account entitled to this
     *      token.
     */
    function ownerOf(uint256 id) public view virtual returns (address who) {
        uint96 data;
        (who, data) = parseTokenId(id);
        if (!hasToken(who, data)) {
            who = address(0);
        }
    }

    /**
     * @inheritdoc IERC721
     * @dev Balance will always be 0 if the address is not entitled to any
     *      tokens, and 1 if they are entitled to a token. If multiple tokens
     *      are minted, this will still return 1.
     */
    function balanceOf(address who) external view override returns (uint256 balance) {
        require(who != address(0), "ERC721: address zero is not a valid owner");
        if (hasToken(who, 0)) {
            balance = 1;
        }
    }

    /**
     * @inheritdoc IERC721
     * @dev Immediately reverts: Relics are soul-bound/non-transferrable
     */
    function safeTransferFrom(
        address, /* from */
        address, /* _to */
        uint256, /* _tokenId */
        bytes calldata /* data */
    ) external pure {
        revert("RelicToken is soulbound");
    }

    /**
     * @inheritdoc IERC721
     * @dev Immediately reverts: Relics are soul-bound/non-transferrable
     */
    function safeTransferFrom(
        address, /* from */
        address, /* to */
        uint256 /* tokenId */
    ) external pure {
        revert("RelicToken is soulbound");
    }

    /**
     * @inheritdoc IERC721
     * @dev Immediately reverts: Relics are soul-bound/non-transferrable
     */
    function transferFrom(
        address, /* from */
        address, /* to */
        uint256 /* id */
    ) external pure {
        revert("RelicToken is soulbound");
    }

    /**
     * @inheritdoc IERC721
     * @dev Immediately reverts: Relics are soul-bound/non-transferrable
     */
    function approve(
        address, /* to */
        uint256 /* tokenId */
    ) external pure {
        revert("RelicToken is soulbound");
    }

    /**
     * @inheritdoc IERC721
     * @dev Immediately reverts: Relics are soul-bound/non-transferrable
     */
    function setApprovalForAll(
        address, /* operator */
        bool /* _approved */
    ) external pure {
        revert("RelicToken is soulbound");
    }

    /**
     * @inheritdoc IERC721
     * @dev Always returns the null address: Relics are soul-bound/non-transferrable
     */
    function getApproved(
        uint256 /* tokenId */
    ) external pure returns (address operator) {
        operator = address(0);
    }

    /**
     * @inheritdoc IERC721
     * @dev Always returns false: Relics are soul-bound/non-transferrable
     */
    function isApprovedForAll(
        address, /* owner */
        address /* operator */
    ) external pure returns (bool) {
        return false;
    }

    /**
     * @inheritdoc IERC165
     * @dev Supported interfaces: IERC721, IERC721Metadata, IERC5192
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return (interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC5192).interfaceId ||
            super.supportsInterface(interfaceId));
    }

    /// @inheritdoc IERC721Metadata
    function name() external pure virtual returns (string memory);

    /// @inheritdoc IERC721Metadata
    function symbol() external pure virtual returns (string memory);

    /// @inheritdoc IERC721Metadata
    function tokenURI(uint256 tokenID) external view virtual returns (string memory);

    /* end ERC-721 spec functions */

    /* begin ERC-5192 spec functions */
    /**
     * @inheritdoc IERC5192
     * @dev All valid tokens are locked: Relics are soul-bound/non-transferrable
     */
    function locked(uint256 id) external view returns (bool) {
        return ownerOf(id) != address(0);
    }

    /* end ERC-5192 spec functions */

    /* begin OpenSea metadata functions */
    /**
     * @notice contract metadata URI as defined by OpenSea
     */
    function contractURI() external view returns (string memory) {
        return contractURIProvider.contractURI();
    }

    /**
     * @notice set contract-level metadata URI provider
     * @param provider new metadata URI provider
     */
    function setContractURIProvider(IContractURI provider) external onlyOwner {
        contractURIProvider = provider;
    }
    /* end OpenSea metadata functions */
}