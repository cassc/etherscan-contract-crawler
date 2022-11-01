// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PosersCustom is ERC721, ReentrancyGuard, Ownable {

    address public POSERS_NFT = 0x02BeeD1404c69e62b76Af6DbdaE41Bd98bcA2Eab;
    string public baseURI = "https://storage.googleapis.com/posersnft/custom/meta/";

    constructor() ERC721("posers customised", "posc") {
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function lock(uint tokenId) external nonReentrant {
        if (IERC721(POSERS_NFT).ownerOf(tokenId) != address(this)) {
            IERC721(POSERS_NFT).transferFrom(msg.sender, address(this), tokenId);
        }
        mintOrTransfer(msg.sender, tokenId);
    }

    function unlock(uint tokenId) external nonReentrant {
        if (ownerOf(tokenId) != address(this)) {
            _transfer(msg.sender, address(this), tokenId);
        }
        IERC721(POSERS_NFT).transferFrom(address(this), msg.sender, tokenId);
    }

    function mintOrTransfer(address to, uint tokenId) internal {
        if (_exists(tokenId)) {
            _transfer(address(this), to, tokenId);
        } else {
            _mint(to, tokenId);
        }
    }

    function setBaseURI(string memory _baseURIArg) external onlyOwner {
        baseURI = _baseURIArg;
    }
}