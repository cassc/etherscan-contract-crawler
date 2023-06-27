// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721Psi.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MetaDollsNFT is ERC721Psi, Ownable {
    constructor()
        ERC721Psi ("MetaDolls NFT", "METADOLLS") {
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://bafybeigt44of3nq6ycdzaurs3gqn3b6x7y7gnz6z5elmykfddjaanln3ke/";
    }

    function _startTokenId() internal view override returns (uint256) {
        return 1;
    }

    function mint(uint256 quantity, address wallet) external onlyOwner {
        // _safeMint's second argument now takes in a quantity, not a tokenId. (same as ERC721A)
        _safeMint(wallet, quantity);
    }

    /**********************************************************
    *
    *  ROYALTY
    *
    **********************************************************/
    function royaltyInfo(uint, uint _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        return (0x6E9cc0Ac20a79501A8d9950cebc160fF6840E026, (_salePrice * 777) / 10000);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Psi) returns (bool) {
        return (interfaceId == 0x2a55205a ||
        super.supportsInterface(interfaceId));
    }
}