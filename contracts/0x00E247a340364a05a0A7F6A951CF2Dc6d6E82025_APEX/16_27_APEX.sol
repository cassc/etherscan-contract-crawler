// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

import "./componets/IdentityManage.sol";
import "./componets/ERC721Membership.sol";
import "./componets/Stage.sol";

import {Errors} from "./libraries/Errors.sol";

contract APEX is
    ERC721Membership,
    IdentityManage,
    Stage,
    Ownable,
    DefaultOperatorFilterer
{
    using Strings for uint256;

    uint256 private constant MAX_SUPPLY = 5000;

    uint256 private constant MAX_NORMAL_MINT = 1;
    uint256 private constant MAX_WHITELIST_MINT = 1;
    uint256 private constant MAX_OG_MINT = 2;
    uint256 private constant MAX_TREASURYADMIN_MINT = 50;

    mapping(address => uint256) _mintedNumOf;

    constructor() ERC721("Lux3 APEX", "APEX") {}

    function mint() external {
        bytes32 currentStage = getCurrentStage();
        if (currentStage != FORMAL_MINT) {
            revert Errors.MintNotStarted();
        }

        _verifyMintNumber(1, MAX_NORMAL_MINT);

        _batchMint(msg.sender, MAX_NORMAL_MINT);
    }

    function whitelistMint(bytes32[] calldata merkleProof) external {
        bytes32 currentStage = getCurrentStage();
        if (currentStage == WARM_UP) {
            revert Errors.MintNotStarted();
        }

        if (!isWhitelist(msg.sender, merkleProof)) {
            revert Errors.NoCorrespondingIdentity();
        }

        _verifyMintNumber(1, MAX_NORMAL_MINT);

        _batchMint(msg.sender, MAX_WHITELIST_MINT);
    }

    function ogMint(
        uint256 mintNumber,
        bytes32[] calldata merkleProof
    ) external {
        bytes32 currentStage = getCurrentStage();
        if (currentStage == WARM_UP) {
            revert Errors.MintNotStarted();
        }

        if (!isOG(msg.sender, merkleProof)) {
            revert Errors.NoCorrespondingIdentity();
        }

        _verifyMintNumber(mintNumber, MAX_OG_MINT);

        _batchMint(msg.sender, mintNumber);
    }

    function treasuryAdminMint(uint256 mintNumber) external {
        bytes32 currentStage = getCurrentStage();
        if (currentStage == WARM_UP) {
            revert Errors.MintNotStarted();
        }

        if (!isTreasuryAdmin(msg.sender)) {
            revert Errors.NoCorrespondingIdentity();
        }

        _verifyMintNumber(mintNumber, MAX_TREASURYADMIN_MINT);

        _batchMint(msg.sender, mintNumber);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721Membership, AccessControl)
        returns (bool)
    {
        return
            AccessControl.supportsInterface(interfaceId) ||
            ERC721Membership.supportsInterface(interfaceId);
    }

    function _batchMint(address to, uint256 mintNumber) private {
        uint256 currentTokenId = totalSupply();
        uint256 afterTokenId = currentTokenId + mintNumber;
        if (afterTokenId > MAX_SUPPLY) {
            revert Errors.CannotMintMore(currentTokenId, MAX_SUPPLY);
        }

        while (currentTokenId < afterTokenId) {
            currentTokenId += 1;
            _mint(to, currentTokenId);
        }
        _mintedNumOf[to] += mintNumber;
    }

    function _verifyMintNumber(
        uint256 mintNumber,
        uint256 maxAllowedToMint
    ) private view {
        uint256 mintedNum = _mintedNumOf[msg.sender];
        if (mintedNum + mintNumber > maxAllowedToMint) {
            revert Errors.CannotMintMore(mintedNum, maxAllowedToMint);
        }
    }
}