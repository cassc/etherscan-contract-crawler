// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {Data, HeyMintStorage} from "../libraries/HeyMintStorage.sol";
import {ERC721AUpgradeable, IERC721AUpgradeable, ERC721AStorage} from "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import {ERC4907AUpgradeable} from "erc721a-upgradeable/contracts/extensions/ERC4907AUpgradeable.sol";
import {ERC721AQueryableUpgradeable} from "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";
import {IERC2981Upgradeable, IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {RevokableOperatorFiltererUpgradeable} from "operator-filter-registry/src/upgradeable/RevokableOperatorFiltererUpgradeable.sol";

/**
 * @title HeyMintERC721AUpgradeable
 * @author HeyMint Launchpad (https://join.heymint.xyz)
 * @notice This contract contains shared logic to be inherited by all implementation contracts
 */
contract HeyMintERC721AUpgradeable is
    ERC4907AUpgradeable,
    ERC721AQueryableUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    RevokableOperatorFiltererUpgradeable
{
    using HeyMintStorage for HeyMintStorage.State;

    uint256 public constant defaultHeymintFeePerToken = 0.0007 ether;
    address public constant heymintPayoutAddress =
        0xE1FaC470dE8dE91c66778eaa155C64c7ceEFc851;

    // ============ BASE FUNCTIONALITY ============

    /**
     * @dev Overrides the default ERC721A _startTokenId() so tokens begin at 1 instead of 0
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @notice Wraps and exposes publicly _numberMinted() from ERC721A
     * @param _owner The address of the owner to check
     */
    function numberMinted(address _owner) public view returns (uint256) {
        return _numberMinted(_owner);
    }

    /**
     * @dev Used to directly approve a token for transfers by the current msg.sender,
     * bypassing the typical checks around msg.sender being the owner of a given token.
     * This approval will be automatically deleted once the token is transferred.
     * @param _tokenId The ID of the token to approve
     */
    function _directApproveMsgSenderFor(uint256 _tokenId) internal {
        ERC721AStorage.layout()._tokenApprovals[_tokenId].value = msg.sender;
    }

    /**
     * @notice Returns the owner of the contract
     */
    function owner()
        public
        view
        virtual
        override(OwnableUpgradeable, RevokableOperatorFiltererUpgradeable)
        returns (address)
    {
        return OwnableUpgradeable.owner();
    }

    // https://chiru-labs.github.io/ERC721A/#/migration?id=supportsinterface
    /**
     * @notice Returns true if the contract implements the interface defined by interfaceId
     * @param interfaceId The interface identifier, as specified in ERC-165
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721AUpgradeable, IERC721AUpgradeable, ERC4907AUpgradeable)
        returns (bool)
    {
        // Supports the following interfaceIds:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        // - IERC4907: 0xad092b5c
        return
            ERC721AUpgradeable.supportsInterface(interfaceId) ||
            type(IERC2981Upgradeable).interfaceId == interfaceId ||
            ERC4907AUpgradeable.supportsInterface(interfaceId);
    }

    // ============ HEYMINT FEE ============

    /**
     * @notice Returns the HeyMint fee per token. If the fee is 0, the default fee is returned
     */
    function heymintFeePerToken() public view returns (uint256) {
        uint256 fee = HeyMintStorage.state().data.heymintFeePerToken;
        return fee == 0 ? defaultHeymintFeePerToken : fee;
    }

    // ============ OPERATOR FILTER REGISTRY ============

    /**
     * @notice Override default ERC-721 setApprovalForAll to require that the operator is not from a blocklisted exchange
     * @dev See {IERC721-setApprovalForAll}.
     * @param operator Address to add to the set of authorized operators
     * @param approved True if the operator is approved, false to revoke approval
     */
    function setApprovalForAll(
        address operator,
        bool approved
    )
        public
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        require(
            !HeyMintStorage.state().cfg.soulbindingActive,
            "TOKEN_IS_SOULBOUND"
        );
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @notice Override default ERC721 approve to require that the operator is not from a blocklisted exchange
     * @dev See {IERC721-approve}.
     * @param to Address to receive the approval
     * @param tokenId ID of the token to be approved
     */
    function approve(
        address to,
        uint256 tokenId
    )
        public
        payable
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperatorApproval(to)
    {
        require(
            !HeyMintStorage.state().cfg.soulbindingActive,
            "TOKEN_IS_SOULBOUND"
        );
        super.approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     *      The added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        payable
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      The added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        payable
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      The added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        public
        payable
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // ============ RANDOM HASH ============

    /**
     * @notice Generate a suitably random hash from block data
     * Can be used later to determine any sort of arbitrary outcome
     * @param _tokenId The token ID to generate a random hash for
     */
    function _generateRandomHash(uint256 _tokenId) internal {
        Data storage data = HeyMintStorage.state().data;
        if (data.randomHashStore[_tokenId] == bytes32(0)) {
            data.randomHashStore[_tokenId] = keccak256(
                abi.encode(block.prevrandao, _tokenId)
            );
        }
    }

    // ============ TOKEN TRANSFER CHECKS ============

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 tokenId,
        uint256 quantity
    ) internal override whenNotPaused onlyAllowedOperator(from) {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        require(
            !state.advCfg.stakingActive ||
                state.data.stakingTransferActive ||
                state.data.currentTimeStaked[tokenId] == 0,
            "TOKEN_IS_STAKED"
        );
        require(
            state.data.tokenOwnersOnLoan[tokenId] == address(0),
            "CANNOT_TRANSFER_LOANED_TOKEN"
        );
        if (
            state.cfg.soulbindingActive &&
            !state.data.soulboundAdminTransferInProgress
        ) {
            require(from == address(0), "TOKEN_IS_SOULBOUND");
        }
        if (state.cfg.randomHashActive && from == address(0)) {
            _generateRandomHash(tokenId);
        }

        super._beforeTokenTransfers(from, to, tokenId, quantity);
    }
}