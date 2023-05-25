// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

contract Dooplicator is ERC721A, ERC2981, ReentrancyGuard, AccessControl, Ownable {
    bytes32 public constant SUPPORT_ROLE = keccak256('SUPPORT');

    IERC721Enumerable public immutable doodles;
    IERC721Enumerable public immutable spaceDoodles;

    uint256[40] claimedBitMap;

    string public provenance;
    string private _baseURIExtended;

    bool public claimActive;

    constructor(address doodles_, address spaceDoodles_) ERC721A("Dooplicator", "DOOPL") {
        require(
            IERC721Enumerable(doodles_).supportsInterface(0x780e9d63),
            "Doodles address does not support ERC721Enumerable"
        );

        require(
            IERC721Enumerable(spaceDoodles_).supportsInterface(0x780e9d63),
            "Space Doodles address does not support ERC721Enumerable"
        );

        doodles = IERC721Enumerable(doodles_);
        spaceDoodles = IERC721Enumerable(spaceDoodles_);

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(SUPPORT_ROLE, msg.sender);
    }

    function setClaimActive(bool claimActive_) external onlyRole(SUPPORT_ROLE) {
        claimActive = claimActive_;
    }

    function isClaimed(uint256 tokenId) public view returns (bool) {
        uint256 claimedWordIndex = tokenId / 256;
        uint256 claimedBitIndex = tokenId % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 tokenId) internal {
        uint256 claimedWordIndex = tokenId / 256;
        uint256 claimedBitIndex = tokenId % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function claim() external nonReentrant {
        require(claimActive, "Claim is not active.");

        uint256 numTokensClaimed;

        for (uint256 i; i < doodles.balanceOf(msg.sender); i++) {
            uint256 tokenId = doodles.tokenOfOwnerByIndex(msg.sender, i);
            if (!isClaimed(tokenId)) {
                _setClaimed(tokenId);
                numTokensClaimed++;
            }
        }

        for (uint256 i; i < spaceDoodles.balanceOf(msg.sender); i++) {
            uint256 tokenId = spaceDoodles.tokenOfOwnerByIndex(msg.sender, i);
            if (!isClaimed(tokenId)) {
                _setClaimed(tokenId);
                numTokensClaimed++;
            }
        }

        _safeMint(msg.sender, numTokensClaimed);
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId, true);
        _resetTokenRoyalty(tokenId);
    }

    ////////////////
    // tokens
    ////////////////
    /**
     * @dev sets the base uri for {_baseURI}
     */
    function setBaseURI(string memory baseURI_) external onlyRole(SUPPORT_ROLE) {
        _baseURIExtended = baseURI_;
    }

    /**
     * @dev See {ERC721-_baseURI}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }

    /**
     * @dev sets the provenance hash
     */
    function setProvenance(string memory provenance_) external onlyRole(SUPPORT_ROLE) {
        provenance = provenance_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721A, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    ////////////////
    // royalty
    ////////////////
    /**
     * @dev See {ERC2981-_setDefaultRoyalty}.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyRole(SUPPORT_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @dev See {ERC2981-_deleteDefaultRoyalty}.
     */
    function deleteDefaultRoyalty() external onlyRole(SUPPORT_ROLE) {
        _deleteDefaultRoyalty();
    }

    /**
     * @dev See {ERC2981-_setTokenRoyalty}.
     */
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyRole(SUPPORT_ROLE) {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * @dev See {ERC2981-_resetTokenRoyalty}.
     */
    function resetTokenRoyalty(uint256 tokenId) external onlyRole(SUPPORT_ROLE) {
        _resetTokenRoyalty(tokenId);
    }
}