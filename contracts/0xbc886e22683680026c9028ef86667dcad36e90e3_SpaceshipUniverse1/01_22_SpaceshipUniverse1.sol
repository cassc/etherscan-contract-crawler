// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./interfaces/ISpaceshipUniverse1.sol";
import "./interfaces/IERC4906.sol";
import "./helper/Error.sol";

/*
...........................................//............................................
.........................................//...//.........................................
......................................./@//...@/@#.......................................
......................................//(//...@////......................................
..................................../@/@@//...@/@@/@.....................................
...................................@//@/@//...@/@@@@//...................................
................................../(@@/@@//...@/@@/@@/@%.................................
................................./@(@@/@@//...@/@@/@@/@%.................................
...............................&@(@@@@@/@//...@/@/@@@@@//................................
............................../@@@@@@/@/@@/...@/@/@@@@@@@@/..............................
.............................@/////////////////////////////@.............................
.........................../(///////////////////////////////@/...........................
.........................(@@////........................./////@&.........................
........................//@@////.......,,...,.....,......///(/@@/........................
....................../@/@@@////....................@....///(/@@@@&......................
.....................//@@@@@////..,..... .../.,..........///(/@@@@//.....................
.................../@(@@@@@@////..@,,......@./..@........///(/@@@@@/@%...................
..................@/@@@@@@@@/@//....,... @.,.....,.......///(/@@@@@@@//..................
...............@/@@@@@/@@@@@/@//.........,...............///(/@@@@@@@@@@/................
..............&@/@@@@@/@@@@@/@//.........,...............///(/@@@@@@@@@@//...............
............./@(@@@@@(@@@@@@////.............,...........///(/@@@@@/@@@@@/@/.............
...........%@/@@@@@@/@@@@@@@////.........................///(/@@@@@@@@@@@@@/@............
..........///@@@@@/@@@@@@@@/@//////////////////////////////(((@@@@@@@@/@@@@@/@/..........
......../@//@@@@@/@@@@@@@@@@@@/((((((((((#(...(#(((((((((((/@@@@@@@@@@@/@@@@@//@.........
.......///@@@////(/@//(....//@@@@@/@@@@@@//...@/@@@@@@(@@@@@(/....///@/(////@@@/@/.......
.......///@@@////(/@//(....//@@@@@/@@@@@@//...@/@@@@@@(@@@@@(/....///@/(////@@@/@/.......
...../@(@@///................/@/@@/@@@@@@//...@/@@@@@@/@@(@%................///@@(@%.....
................................/@/@@@@@@//...@/@@@@@@/@/................................
..................................%@//@@@//...@/@@@/(/...................................
...................................../@////...@///@%.....................................
......................................../@/...@//........................................
.........................................@/...@/.........................................
..........................................@...@..........................................
 ::::::::  :::::::::      :::      ::::::::  :::::::::: :::::::::      :::     :::::::::  
:+:    :+: :+:    :+:   :+: :+:   :+:    :+: :+:        :+:    :+:   :+: :+:   :+:    :+:
+:+        +:+    +:+  +:+   +:+  +:+        +:+        +:+    +:+  +:+   +:+  +:+    +:+
+#++:++#++ +#++:++#+  +#++:++#++: +#+        +#++:++#   +#++:++#+  +#++:++#++: +#++:++#: 
       +#+ +#+        +#+     +#+ +#+        +#+        +#+    +#+ +#+     +#+ +#+    +#+
#+#    #+# #+#        #+#     #+# #+#    #+# #+#        #+#    #+# #+#     #+# #+#    #+#
 ########  ###        ###     ###  ########  ########## #########  ###     ### ###    ###
*/

/// @title SpaceshipUniverse1
/// @notice Spaceship NFT for Spacebar Universe 1
/// This contract introduces the concept of "Active Ownership", wherein the user must fulfill
/// certain conditions to gain full ownership of a spaceship NFT.
/// Until these conditions are met, the spaceship is locked and cannot be transferred.
/// For the above purpose, this contract implements ERC5192.
/// Additionally, the Space Factory reserves the right to burn the spaceship under specific conditions (to be defined later).
/// The total circulating supply (minted minus burned) is limited.
contract SpaceshipUniverse1 is
    DefaultOperatorFilterer,
    ERC2981,
    ISpaceshipUniverse1,
    ERC721,
    IERC4906,
    Ownable,
    Error
{
    /* ============ Variables ============ */

    /// @dev Circulalting supply of Spaceship Universe1 is fixed
    uint16 public immutable MAX_SPACESHIP_UNIVERSE1_CIRCULATING_SUPPLY;
    uint16 public currentSupply;
    uint256 public nextTokenId;
    address public spaceFactory;

    // @dev mapping from token ID to whether it is fully owned Ownership
    mapping(uint256 => bool) public unlocked;

    // Optional token URIs for decentralized storage
    mapping(uint256 => string) private _decentralizedTokenURIs;
    string decentralizedTokenURIBase = "ipfs://";

    /* ============ Modifiers ============ */

    modifier onlySpaceFactory() {
        if (msg.sender != spaceFactory) {
            revert OnlySpaceFactory();
        }
        _;
    }

    /* ============ Constructor ============ */

    constructor(
        address _spaceFactory,
        uint16 maxSpaceshipUniverse1CirculatingSupply,
        address defaultAdmin,
        address royaltyReceiver
    ) ERC721("Songhwa - Universe 1", "SPACEBAR") {
        //@TODO change back to Spacebar
        spaceFactory = _spaceFactory;
        transferOwnership(defaultAdmin); // this is for OpenSea's collection admin
        _setDefaultRoyalty(royaltyReceiver, 500); // set default royalty to 5%
        MAX_SPACESHIP_UNIVERSE1_CIRCULATING_SUPPLY = maxSpaceshipUniverse1CirculatingSupply;
    }

    /* ============ External Functions ============ */

    /// @inheritdoc ISpaceshipUniverse1
    function mint(address to) external onlySpaceFactory returns (uint256) {
        if (currentSupply == MAX_SPACESHIP_UNIVERSE1_CIRCULATING_SUPPLY)
            revert ReachedMaxSupply();
        unchecked {
            ++currentSupply;
        }

        _mint(to, nextTokenId);
        emit Locked(nextTokenId); // Protoship is locked by default

        unchecked {
            ++nextTokenId;
        }
        return nextTokenId - 1; //returns current tokenId
    }

    /// @inheritdoc ISpaceshipUniverse1
    function unlock(uint256 tokenId) external onlySpaceFactory {
        if (unlocked[tokenId]) revert OnlyLockedToken();
        unlocked[tokenId] = true;
        emit Unlocked(tokenId);
    }

    /// @inheritdoc ISpaceshipUniverse1
    function burn(uint256 tokenId) external onlySpaceFactory {
        if (unlocked[tokenId]) revert OnlyLockedToken();
        _burn(tokenId);
        unchecked {
            --currentSupply;
        }
    }

    /// @inheritdoc ISpaceshipUniverse1
    function updateMetadata(uint256 tokenId) external onlySpaceFactory {
        emit MetadataUpdate(tokenId);
    }

    /// @dev override the ERC721 transfer and approval methods for Operator Filterer
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(IERC721, ERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public override(IERC721, ERC721) onlyAllowedOperatorApproval(operator) {
        if (!unlocked[tokenId]) revert TokenLocked(); // prevent locked tokens from being approved
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(IERC721, ERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(IERC721, ERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(IERC721, ERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /// @dev In the future, Spaceship's token URI will be stored on decentralized storage
    function setDecentralizedTokenURIBase(
        string memory _decentralizedTokenURIBase_
    ) external onlySpaceFactory {
        decentralizedTokenURIBase = _decentralizedTokenURIBase_;
    }

    function setDecentralizedTokenURI(
        uint256 tokenId,
        string memory decentralizedTokenURI
    ) external onlySpaceFactory {
        _decentralizedTokenURIs[tokenId] = decentralizedTokenURI;
        emit MetadataUpdate(tokenId);
    }

    /* ============ Internal Functions ============ */

    /// @dev override approve to prevent locked tokens from being transferred to other addresses
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override {
        if (to != address(0) && from != address(0) && !unlocked[tokenId]) {
            revert TokenLocked();
        }
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // @TODO URI may change in the future
    function _baseURI() internal pure override returns (string memory) {
        return
            "https://cdn.stage.internal-spacebar.xyz/metadata/spacebar_universe1/";
    }

    /* ============ View Functions ============ */
    function locked(uint256 tokenId) external view override returns (bool) {
        return !unlocked[tokenId];
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _decentralizedTokenURI = _decentralizedTokenURIs[tokenId];

        // If the token has decentralized token URI, return it
        if (bytes(_decentralizedTokenURI).length > 0) {
            return
                string(
                    abi.encodePacked(
                        decentralizedTokenURIBase,
                        _decentralizedTokenURI
                    )
                );
        }

        // Otherwise, return the default token URI
        return super.tokenURI(tokenId);
    }

    /* ============ ERC-165 ============ */

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC2981, ERC721, IERC165) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}