// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

/*         __                __      __
     _____/ /_____  _____   / /___ _/ /_
    / ___/ __/ __ \/ ___/  / / __ `/ __ \
   / /__/ /_/ /_/ / /     / / /_/ / /_/ /
   \___/\__/\____/_/     /_/\__,_/_.___/

                               ctor.xyz   */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PF2T is ERC721, ERC721Royalty, Ownable {
    string private _baseTokenURI;

    event PermanentURI(string uri, uint256 indexed tokenId);

    constructor() ERC721("Post Futurism II - TAMASHII", "PF2T") {
        _baseTokenURI = "ipfs://QmehHavKkubdQDtF1DVEcy1iWiVWEP85jD96wV1ZDGUZXY/";

        _mint(0xeb899C3432CB1Fde26D2f8a84A644bE1099a956c, 1);
        _mint(0xeb899C3432CB1Fde26D2f8a84A644bE1099a956c, 2);
        _mint(0xA288E8502d71F478DbA9F98595Eb753aB39c298D, 3);
        _mint(0xA288E8502d71F478DbA9F98595Eb753aB39c298D, 4);
        _mint(0x570DC2127F98ce3cF841f3e0038a6257E31F6A4d, 5);
        _mint(0x570DC2127F98ce3cF841f3e0038a6257E31F6A4d, 6);
        _mint(0xb68E6d2238c99F3Fb346093a1e76961d4a30829c, 7);
        _mint(0xb68E6d2238c99F3Fb346093a1e76961d4a30829c, 8);
        _mint(0xb5E1Fc4aF4dd6aB3282D16499420954b192e1849, 9);
        _mint(0xb5E1Fc4aF4dd6aB3282D16499420954b192e1849, 10);
        _mint(0xb5E1Fc4aF4dd6aB3282D16499420954b192e1849, 11);
        _mint(0x2D09d880CB50C09313C8DCcA6B209413D31CC372, 12);
        _mint(0x2D09d880CB50C09313C8DCcA6B209413D31CC372, 13);
        _mint(0x2D09d880CB50C09313C8DCcA6B209413D31CC372, 14);
        _mint(0x5B0c276E9Dc16B113b1EE36bfA4f1113750A35a3, 15);
        _mint(0x5B0c276E9Dc16B113b1EE36bfA4f1113750A35a3, 16);
        _mint(0x5B0c276E9Dc16B113b1EE36bfA4f1113750A35a3, 17);
        _mint(0x5B0c276E9Dc16B113b1EE36bfA4f1113750A35a3, 18);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseTokenURI(string calldata baseTokenURI) external onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function mint(address to, uint256 tokenId) external onlyOwner {
        _mint(to, tokenId);
    }

    function freezeMetadata(uint256 tokenId) external onlyOwner {
        emit PermanentURI(tokenURI(tokenId), tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
    }
}