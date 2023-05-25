// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/// @title: Murakami.Flowers
/// @author: niftykit.com

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IMurakamiFlowersSeed.sol";

contract MurakamiFlowers is
    ERC721,
    ERC721Enumerable,
    ERC2981,
    ReentrancyGuard,
    AccessControl,
    Ownable
{
    IMurakamiFlowersSeed private _seed;

    string private _tokenBaseURI;

    bool private _active;

    constructor(
        address seed_,
        address royalty_,
        uint96 royaltyFee_,
        string memory tokenBaseURI_
    ) ERC721("Murakami.Flowers", "M.F") {
        _active = false;
        _tokenBaseURI = tokenBaseURI_;
        _seed = IMurakamiFlowersSeed(seed_);
        _setDefaultRoyalty(royalty_, royaltyFee_);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function setActive(bool newActive) external onlyOwner {
        _active = newActive;
    }

    function setBaseURI(string memory newBaseURI)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _tokenBaseURI = newBaseURI;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function mint(address to) external onlyOwner {
        _mint(to);
    }

    function reveal() external nonReentrant {
        require(_active, "Not active");
        require(_seed.balanceOf(_msgSender(), 0) > 0, "Not enough Seeds");

        _seed.burn(_msgSender(), 1);
        _mint(_msgSender());
    }

    function active() external view returns (bool) {
        return _active;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _tokenBaseURI;
    }

    function _mint(address to) internal {
        uint256 mintIndex = totalSupply() + 1;
        _safeMint(to, mintIndex);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC2981, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}