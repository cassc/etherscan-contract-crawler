//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Pirla is ERC721, ERC721URIStorage, IERC2981, Ownable {
    uint256 public constant MAX_SUPPLY = 9801;
    uint16[MAX_SUPPLY] public ids;
    uint16 private index;
    string public _tokenUri = "ipfs://bafybeia2amlespjtuu6dmztdhvag266dqxj3suiox5bz2b3gty6hmjm2ju/";
    address private creatorAddress = 0x1BF341B75A5a346B1A91895C4EC50352cB00108B;
    address private royaltiesAddress = 0x0aC355818193324F43a5a496A16C021aC2e7e22B;
    uint256 private royaltiesPercentage = 99;

    uint256 public totalMints = 0;
    uint256 public maxPerWallet = 3;

    mapping(address => uint256) public walletMints;

    constructor(address payable owner) ERC721("PIRLA 99x99", "PIRLA") { }

    function totalSupply() public pure returns (uint256) {
        return MAX_SUPPLY;
    }

    function safeMint(address to, uint256 quantity) internal {
        uint256 tokenId = 0;
        for (uint i = 0; i < quantity; i++) {
            uint256 _random = uint256(keccak256(abi.encodePacked(index, to, block.timestamp, blockhash(block.number - 1))));
            tokenId = _pickRandomUniqueId(_random) + 1;
            totalMints++;
            _safeMint(to, tokenId);
        }
    }

    function mintToken(uint256 quantity_) public {
        if (msg.sender != creatorAddress) {
            require(walletMints[msg.sender] + quantity_ <= maxPerWallet, "mints per wallet exceeded");
        }
        walletMints[msg.sender] += quantity_;
        safeMint(msg.sender, quantity_);
    }

    function getMyWalletMints() public view returns (uint256) {
        return walletMints[msg.sender];
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