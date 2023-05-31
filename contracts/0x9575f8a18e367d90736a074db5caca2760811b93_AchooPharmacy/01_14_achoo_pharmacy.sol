// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

contract AchooPharmacy is ERC721Enumerable, ERC721Burnable, Ownable {
    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public constant MAX_PUBLIC_MINT = 3;
    uint256 public constant PRICE_PER_TOKEN = 0.02 ether; // price for the public mint, AL is free

    bool public allowListSaleActive = false;
    mapping(address => bool) private _allowList;

    bool public primarySaleActive = false;

    string private _baseURIExtended;
    bool public _metadataLocked = false;

    constructor() ERC721("Achoo Pharmacy", "AVTK") Ownable() {}
    
    // baseURI control
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        require(_metadataLocked == false, "Metadata is locked! no updates possible");
        _baseURIExtended = _newBaseURI;
    }

    function lockMetadata() external onlyOwner {
        _metadataLocked = true;
    }

    function setAllowListSaleActive(bool _allowListSaleActive) external onlyOwner {
        allowListSaleActive = _allowListSaleActive;
    }

    function setAllowList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = true;
        }
    }

    // AL mint is free
    function mintAllowList() external {
        uint256 ts = totalSupply();

        require(allowListSaleActive, "Allow list sale is not active");
        require(ts + 1 <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(_allowList[msg.sender] == true, "Sender not on allow list");

        _safeMint(msg.sender, ts);

        // only 1 allowed per AL slot
        _allowList[msg.sender] = false;
    }

    function setPrimarySaleActive(bool _primarySaleActive) external onlyOwner {
        primarySaleActive = _primarySaleActive;
    }

    // Public mint is 0.02eth
    function mintPrimary(uint256 numberOfTokens) external payable {
        uint256 ts = totalSupply();

        require(primarySaleActive, "Primary sale must be active to mint tokens");
        require(numberOfTokens <= MAX_PUBLIC_MINT, "Exceeded max token purchase");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }

    // allow us to reserve a few tests for the giveaways
    function reserve(uint256 numberOfTokens) external onlyOwner {
        uint256 ts = totalSupply();
        
        require(ts + numberOfTokens <= MAX_SUPPLY, "Reserve would exceed max tokens");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // in case we need to feed the contract with eth
    receive() external payable { }

    // required overrides since we inherit from both ERC721Enumerable & ERC721Burnable
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}