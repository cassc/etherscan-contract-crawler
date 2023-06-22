// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract XRayDeebies is AccessControl, ERC721Enumerable {
    using Strings for uint256;

	string private baseTokenURI;
	bool public paused;
    address private ownerAddress;
    address private constant deebiesContract = 0x400E2073B4Ac13D6f11c15697DF7Fc609dB93809;
    

    constructor(address owner_) ERC721("X-Ray Deebies", "XRay_DEEBIES")  {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, ownerAddress);
        setOwner(owner_);
        paused = false;
    }

    function claimed(uint256 tokenId) public view virtual returns (bool) {
        return _exists(tokenId);
    }

    function baseClaim(uint256 tokenId) private {
        require(IERC721(deebiesContract).ownerOf(tokenId) == _msgSender(), string(abi.encodePacked('Not owner of DB ', tokenId.toString())));
        require(!claimed(tokenId), 'Already claimed!');

        _safeMint(_msgSender(), tokenId);
    }

    function claimXRayDeebies(uint256[] memory tokenIds) public {
        require(!paused, "Pause");
        
        for (uint256 i = 0; i < tokenIds.length; i++) {
            baseClaim(tokenIds[i]);
        }
    }

    function owner() public view virtual returns (address) {
        return ownerAddress;
    }

    function setOwner(address owner_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        ownerAddress = owner_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        baseTokenURI = baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Nonexistent token");

        string memory baseURI = _baseURI();
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function tokensOfOwner(address _owner) external view returns(uint256[] memory) {
        uint tokenCount = balanceOf(_owner);

        uint256[] memory result = new uint256[](tokenCount);
        for(uint i = 0; i < tokenCount; i++){
            result[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return result;
    }

    function pause(bool isPaused) public onlyRole(DEFAULT_ADMIN_ROLE) {
        paused = isPaused;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, AccessControl) returns (bool) {
        return ERC721Enumerable.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
    }
}