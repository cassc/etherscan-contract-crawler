//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Voltz is ERC721, ERC721URIStorage, IERC2981, Ownable {
    uint256 public constant MAX_SUPPLY = 9999;
    uint16[MAX_SUPPLY] public ids;
    uint16 private index;
    address vialAddress;
    string public _tokenUri = "https://assets.voltz.me/avatar/";
    address private royaltiesAddress = 0x3aC8d44a7A6579145f4B83accbfbbD6a497509a2;
    uint256 private royaltiesPercentage = 75;

    constructor(address payable owner) ERC721("VOLTZ Avatars", "VOLTZ") { }

    bool public contractLocked = false;

    function totalSupply() public pure returns (uint256) {
        return MAX_SUPPLY;
    }

    function mintTransfer(address to) public returns(uint256) {
        require(msg.sender == vialAddress, "Contract Not authorized");
        uint256 mintedId = 0;

        for (uint i = 0; i < 3; i++) {
            uint256 _random = uint256(keccak256(abi.encodePacked(index, to, block.timestamp, blockhash(block.number - 1))));
            mintedId = _pickRandomUniqueId(_random) + 1;

            _safeMint(to, mintedId);
        }
        return mintedId;
    }

    function secureBaseUri(string memory newUri) public onlyOwner {
        require(contractLocked == false, "Contract has been locked and URI can't be changed");
        _tokenUri = newUri;
    }

    function lockContract() public onlyOwner {
        contractLocked = true;
    }

    function setVialAddress(address newAddress) public onlyOwner {
        require(newAddress != address(0), 'Zero address not allowed');
        vialAddress = newAddress;
    }

    function _baseURI() internal view override returns (string memory) {
        return _tokenUri;
    }

	function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _pickRandomUniqueId(uint256 random) private returns (uint256 id) {
        uint256 len = ids.length - index++;
        require(len > 0, 'no ids left');
        uint256 randomIndex = random % len;
        id = ids[randomIndex] != 0 ? ids[randomIndex] : randomIndex;
        ids[randomIndex] = uint16(ids[len - 1] == 0 ? len - 1 : ids[len - 1]);
        ids[len - 1] = 0;
    }

    function _setRoyalties(address newRecipient) internal {
        require(newRecipient != address(0), "Royalties: new recipient is the zero address");
        royaltiesAddress = newRecipient;
    }

    function setRoyalties(address newRecipient) external onlyOwner {
        _setRoyalties(newRecipient);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        return (royaltiesAddress, (_salePrice * royaltiesPercentage) / 1000);
    }

}