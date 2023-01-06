// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "ERC721A/ERC721A.sol";
import "openzeppelin/access/Ownable.sol";
import "openzeppelin/utils/Strings.sol";

contract ShowReceipt is ERC721A, Ownable {
    string public baseURI;
    address public royaltyDestination;
    uint256 public royaltyDivisor = 20; // 5% royalty

    constructor(string memory _baseURI) ERC721A("Show This Receipt At Exit", "RCPT") {
        baseURI = _baseURI;
        royaltyDestination = msg.sender;
        _mint(msg.sender, 14);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    // Admin functions
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function mint(address to, uint256 qty) external onlyOwner {
        _mint(to, qty);
    }

    function setRoyaltyInfo(address _royaltyDestination, uint256 _royaltyDivisor) external onlyOwner {
        royaltyDestination = _royaltyDestination;
        royaltyDivisor = _royaltyDivisor;
    }

    // View functions
    function tokenURI(uint256 tokenID) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(tokenID)));
    }

    function royaltyInfo(uint256, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        if (royaltyDivisor < 1) {
            return (address(0), 0);
        }
        receiver = royaltyDestination;
        royaltyAmount = _salePrice / royaltyDivisor;
    }

    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return interfaceId == 0x7f5828d0 // ERC165 Interface ID for ERC173
            || interfaceId == 0x80ac58cd // ERC165 Interface ID for ERC721
            || interfaceId == 0x5b5e139f // ERC165 Interface ID for ERC165
            || interfaceId == 0x01ffc9a7 // ERC165 Interface ID for ERC721Metadata
            || interfaceId == 0x2a55205a; // ERC165 Interface ID for https://eips.ethereum.org/EIPS/eip-2981
    }
}