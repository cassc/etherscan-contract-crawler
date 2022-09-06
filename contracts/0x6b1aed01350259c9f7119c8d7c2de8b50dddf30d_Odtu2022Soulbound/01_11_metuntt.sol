// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Odtu2022Soulbound is ERC721, Ownable {

    error Soulbound();

    using Strings for uint256;

    string private URIPrefix;
    string private URISuffix = ".json";

    constructor (string memory _URIprefix) ERC721("2021-2022 Highest CGPA METU Graduates", "HIGHMETUGRAD") {
        URIPrefix = _URIprefix;
    }

    function mint() external onlyOwner {
        _safeMint(address(0x349e0bbb5B5cCD306861D4eD020Fa0aE044426FC), 1);
        _safeMint(address(0x0492112b755EEa45CF92533276edb7147e8f5B62), 2);
        _safeMint(address(0xf2CFf2346E5a7402e123EFf10743C7dF147A4065), 3);
        _safeMint(address(0xc7C89024A10d65a34871FA954dd4694b2Aaaccf9), 4);
        _safeMint(address(0x3c000c1F862757176622357C5aA843e7dA4E3203), 5);
        _safeMint(address(0x1B36707A5598C7b15739a17D6E74fBec2fa80736), 6);
        _safeMint(address(0xd63E05F239d85D3383673089D554b8dEEAfe80B2), 7);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return URIPrefix;
    }

    function changeURI(string memory newPrefix) external onlyOwner {
        URIPrefix = newPrefix;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "Non-existent token given!");

        string memory currentURIPrefix = _baseURI();
        return bytes(currentURIPrefix).length > 0
            ? string(abi.encodePacked(currentURIPrefix, _tokenId.toString(), URISuffix))
        : "";
    }
    
    /***** SOULBOUND *****/

    // Not allowed to prevent gas waste
    function _approve(address to, uint256 tokenId) internal override {
        revert Soulbound();
    }

    // Not allowed to prevent gas waste
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal override {
        revert Soulbound();
    }

    // Transfers are not allowed except minting
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        if(from != address(0)) revert Soulbound();
    }
}