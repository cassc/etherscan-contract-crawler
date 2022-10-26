// SPDX-License-Identifier: MIT

/**

    Coqui Collection
    Developed by dBloks.com

 */

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Coqui is ERC721, ERC721Enumerable, ERC721Burnable, ERC721Royalty, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string private BASE_URI;

    bool public isAllowListActive = false;
    bool public isSaleActive = false;
    bool public isBurnAllowed = false;

    uint256 public PRICE = 0.35 ether;
    uint256 public constant MAX_SUPPLY = 2222;
    uint256 public constant MAX_PUBLIC_MINT = 10;

    address public royaltyAddress;
    uint96 public royaltyBps;

    mapping(address => uint8) private _allowList;
    mapping(address => uint8) private _holders;

    constructor() ERC721("CQQUI", "COQ") {
        _tokenIds.increment();
    }

    /**
     *  Utils
     */

    function setPrice(uint256 _price) public onlyOwner {
        PRICE = _price;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        BASE_URI = baseURI_;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function reserve(uint256 numberOfTokens) public onlyOwner {
        require(_tokenIds.current() + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");

        for (uint256 i = 1; i <= numberOfTokens; i++) {
            _safeMint(msg.sender, _tokenIds.current());
            _tokenIds.increment();
        }
    }

    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) public onlyOwner {
        royaltyAddress = _receiver;
        royaltyBps = _feeNumerator;
        
        _setDefaultRoyalty(royaltyAddress, royaltyBps);
    }

    function setBurningIsActive(bool _isBurnAllowed) external onlyOwner {
        isBurnAllowed = _isBurnAllowed;
    }

    /**
     *  Whitelist
     */

    function setIsAllowListActive(bool _isAllowListActive) external onlyOwner {
        isAllowListActive = _isAllowListActive;
    }

    function setAllowList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = numAllowedToMint;
        }
    }

    function numAvailableToMint(address _address) external view returns (uint8) {
        return _allowList[_address];
    }

    function mintAllowList(uint8 numberOfTokens) external payable {
        require(isAllowListActive, "Allow list is not active");
        require(numberOfTokens <= _allowList[msg.sender], "Exceeded max available to purchase");
        require(numberOfTokens <= MAX_PUBLIC_MINT, "Exceeded max token purchase");
        require(_tokenIds.current() + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(PRICE * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for (uint256 i = 1; i <= numberOfTokens; i++) {            
            _safeMint(msg.sender, _tokenIds.current());
            _tokenIds.increment();
        }

        _allowList[msg.sender] -= numberOfTokens;
        _holders[msg.sender] += numberOfTokens;
    }
    
    /**
     *  Mint
     */

    function setSaleState(bool _newState) public onlyOwner {
        isSaleActive = _newState;
    }

    function mint(uint8 numberOfTokens) public payable {
        uint8 purchased = _holders[msg.sender];
        uint8 newPurchaseTotal = purchased + numberOfTokens;

        require(isSaleActive, "Sale is not active");
        require(numberOfTokens <= MAX_PUBLIC_MINT, "Exceeded max token purchase");
        require(newPurchaseTotal <= MAX_PUBLIC_MINT, "Purchase would exceed max tokens per wallet");
        require(_tokenIds.current() + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(PRICE * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for (uint256 i = 1; i <= numberOfTokens; i++) {            
            _safeMint(msg.sender, _tokenIds.current());
            _tokenIds.increment();
        }

        _holders[msg.sender] += numberOfTokens;
    }

    /**
     *  Overrides
     */

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {
        require(isBurnAllowed, "Burn is not active");
        super._burn(tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, ERC721Royalty) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}