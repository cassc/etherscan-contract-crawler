// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract MiniDigitalBaby is ERC721Enumerable, Ownable {

    string private baseTokenURI = "ipfs://";
    address private signerAddress;

    constructor() ERC721("Mini Digital Baby", "MiniBaby") {
        setSignerAddress(msg.sender);
    }

    function setSignerAddress(address signer) public onlyOwner {
        signerAddress = signer;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function mint(address to, uint256 tokenId) external {
        require(msg.sender == signerAddress);
        _safeMint(to, tokenId);
    }

    function burn(uint256 tokenId) public virtual {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "burn caller is not owner nor approved"
        );
        _burn(tokenId);
    }

}