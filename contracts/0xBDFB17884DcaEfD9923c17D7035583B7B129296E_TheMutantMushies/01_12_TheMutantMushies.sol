/*
The Mutant Mushie Collection by the Phunky Fungi
Twitter: https://twitter.com/PhunkyFungi
Web: https://www.phunkyfungi.io

Launched with a little help from:
Fueled on Bacon - https://fueledonbacon.com
ZeroCode NFT - https://zerocodenft.com
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract TheMutantMushies is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint;
    enum SaleStatus{ PAUSED, PUBLIC }

    Counters.Counter private _tokenIds;

    uint public constant TOKENS_PER_PERSON_LIMIT = 2;
    uint public constant TOKENS_PER_TRAN_LIMIT = 2;
    uint public constant COLLECTION_SIZE = 420;
    uint public constant MINT_PRICE = 0.069 ether;
    SaleStatus public saleStatus = SaleStatus.PAUSED;

    bool public canReveal = false;
    
    string private _delayedRevealURI;
    string private _baseUri;
    address private immutable _revenueRecipient;
    mapping(address => uint) private _mintedCount;

    constructor(string memory delayedRevealURI, address revenueRecipient) 
    ERC721("TheMutantMushies", "TMM")
    {
        _delayedRevealURI = delayedRevealURI;
        _revenueRecipient = revenueRecipient;
    }

    function totalSupply() external view returns (uint) {
        return _tokenIds.current();
    }

    /// @dev override base uri. It will be combined with token ID
    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    /// @notice Set hidden metadata uri
    function setHiddenUri(string memory uri) onlyOwner external {
        _delayedRevealURI = uri;
    }

    /// @notice Set sales status
    function setSaleStatus(SaleStatus status) onlyOwner external {
        saleStatus = status;
    }

    /// @notice Reveal metadata for all the tokens
    function reveal(string memory baseUri) onlyOwner external {
        require(!canReveal,'Already Revealed.');
        _baseUri = baseUri;
        canReveal = true;
    }

    /// @notice Get token's URI. In case of delayed reveal we give user the json of the placeholer metadata.
    /// @param tokenId token ID
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return canReveal 
            ? string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"))
            : _delayedRevealURI;
    }

    /// @notice Withdraw's contract's balance to the minter's address
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance");

        payable(_revenueRecipient).transfer(balance);
    }

    function mint(uint count) external payable {
        require(saleStatus != SaleStatus.PAUSED, "Sales are off");
        require(msg.value >= count * MINT_PRICE, "Ether value sent is not sufficient");
        require(_tokenIds.current() + count <= COLLECTION_SIZE, "Number of requested tokens will exceed collection size");
        require(_mintedCount[msg.sender] + count <= TOKENS_PER_PERSON_LIMIT, "Max 2 tokens per wallet");

        _mintedCount[msg.sender] += count;
        _mintTokens(msg.sender, count);
    }

    /// @dev mint tokens
    function _mintTokens(address to, uint count) internal {
        for(uint index = 0; index < count; index++) {

            _tokenIds.increment();
            uint newItemId = _tokenIds.current();

            _safeMint(to, newItemId);
        }
    }
}