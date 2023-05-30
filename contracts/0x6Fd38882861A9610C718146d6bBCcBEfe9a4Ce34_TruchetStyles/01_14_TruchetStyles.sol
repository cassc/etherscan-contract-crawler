// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract TruchetStyles is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    uint256 public constant MAX_TOKENS = 2048;
    string public constant DESCRIPTION = "2048 algorithmically generated, unique new stylizations on the humble truchet tile";

    string public baseURI;
    uint256 public price = 0.1 ether;
    bool public isActive = false;

    Counters.Counter private _tokenIdCounter;
    mapping(uint256 => uint256) public tokenSeed;

    constructor(string memory name, string memory symbol, string memory initialBaseURI, address payable[16] memory _specialMintRecipients, uint256[16] memory _specialMintSeeds) ERC721(name, symbol) {
        baseURI = initialBaseURI;
        specialMint(_specialMintRecipients[0], _specialMintSeeds[0]);
        specialMint(_specialMintRecipients[1], _specialMintSeeds[1]);
        specialMint(_specialMintRecipients[2], _specialMintSeeds[2]);
        specialMint(_specialMintRecipients[3], _specialMintSeeds[3]);
        specialMint(_specialMintRecipients[4], _specialMintSeeds[4]);
        specialMint(_specialMintRecipients[5], _specialMintSeeds[5]);
        specialMint(_specialMintRecipients[6], _specialMintSeeds[6]);
        specialMint(_specialMintRecipients[7], _specialMintSeeds[7]);
        specialMint(_specialMintRecipients[8], _specialMintSeeds[8]);
        specialMint(_specialMintRecipients[9], _specialMintSeeds[9]);
        specialMint(_specialMintRecipients[10], _specialMintSeeds[10]);
        specialMint(_specialMintRecipients[11], _specialMintSeeds[11]);
        specialMint(_specialMintRecipients[12], _specialMintSeeds[12]);
        specialMint(_specialMintRecipients[13], _specialMintSeeds[13]);
        specialMint(_specialMintRecipients[14], _specialMintSeeds[14]);
        specialMint(_specialMintRecipients[15], _specialMintSeeds[15]);
    }

    // STARTIN'

    function openTheGates() public onlyOwner {
      isActive = !isActive;
    }

    // MINTIN'

    function _mintTruchet(address walletAddress, uint256 seed) private {
        // ensure the max supply has not been reached
        require(_tokenIdCounter.current() < MAX_TOKENS, "NO_SUPPLY");

        // no zero-indexed tokens in this house
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();

        // JS timestamp
        tokenSeed[tokenId] = seed;

        _safeMint(walletAddress, tokenId);        
    }

    function specialMint(address walletAddress, uint256 seed) public payable onlyOwner {
        _mintTruchet(walletAddress, seed);
    }

    function createTruchet(uint256 seed) public payable virtual {
        require(isActive, "NOT_OPEN_YET");
        require(msg.value >= price, "PRICE_NOT_MET");

        // get you some
        _mintTruchet(msg.sender, seed);
    }

    function createTruchetForFriend(address walletAddress, uint256 seed) public payable virtual {
        require(isActive, "NOT_OPEN_YET");
        require(msg.value >= price, "PRICE_NOT_MET");

        // sharing is caring
        _mintTruchet(walletAddress, seed);
    }

    // HOUSEKEEPIN'

    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function updateBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for unminted token id");
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    // HOT POTETO!

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    // TOKENIN'

    function getTokensOfOwner(address _owner) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // No token, sad
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function remainingAmount() external view returns (uint256) {
        return MAX_TOKENS - totalSupply();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}