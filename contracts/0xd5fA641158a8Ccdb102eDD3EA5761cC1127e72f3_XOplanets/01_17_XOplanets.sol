// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

/**
                                                                                 
 ##  ##    ####    #####    ##        ####    ##  ##   ######   ######    #####  
  ####    ##  ##   ##  ##   ##       ##  ##   ### ##   ##         ##     ##      
   ##     ##  ##   #####    ##       ######   ######   #####      ##      ####   
  ####    ##  ##   ##       ##       ##  ##   ## ###   ##         ##         ##  
 ##  ##    ####    ##       ######   ##  ##   ##  ##   ######     ##     #####  
                                                                                 
 */
contract XOplanets is ERC721, ERC721Enumerable, Ownable, ERC721Royalty {
    using SafeMath for uint256;

    string private _baseURIextended;
    string public PROVENANCE;
    string public contractURI;

    bool public isSaleActive = false;
    bool public isAllowlistSaleActive = false;

    uint256 public MAX_SUPPLY = 5069;
    uint256 public MAX_PUBLIC_MINT = 10;
    uint256 public PRICE_PER_TOKEN = 0.44 ether;
    uint256 public PRICE_PER_TOKEN_ALLOWLIST = 0.34 ether;

    mapping(address => uint8) private _allowlist;

    constructor() ERC721('XOplanets', 'XOP') {}

    // allowlist mint
    function setIsAllowlistSaleActive(bool isActive) external onlyOwner {
        isAllowlistSaleActive = isActive;
    }

    function setAllowlistAddresses(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint8 i = 0; i < addresses.length; i++) {
            _allowlist[addresses[i]] = numAllowedToMint;
        }
    }

    function allowlistMintAmount(address addr) external view returns (uint8) {
        return _allowlist[addr];
    }

    function mintAllowlisted(uint8 numberOfTokens) external payable {
        uint256 ts = totalSupply();
        require(isAllowlistSaleActive, 'Allowlist sale is not active');
        require(numberOfTokens <= _allowlist[msg.sender], 'Exceeded max available to purchase');
        require(ts + numberOfTokens <= MAX_SUPPLY, 'Purchase would exceed max tokens');
        require(PRICE_PER_TOKEN_ALLOWLIST * numberOfTokens <= msg.value, 'Ether value sent is not correct');

        _allowlist[msg.sender] -= numberOfTokens;
        for (uint8 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }

    // override base functions
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // setters
    function setMaxSupply(uint256 maxSupply_) external onlyOwner {
        MAX_SUPPLY = maxSupply_;
    }

    function setMaxPublicMint(uint256 maxPublicMint_) external onlyOwner {
        MAX_PUBLIC_MINT = maxPublicMint_;
    }

    function setPricePerToken(uint256 pricePerToken_) external onlyOwner {
        PRICE_PER_TOKEN = pricePerToken_;
    }

    function setPricePerTokenAllowlist(uint256 pricePerTokenAllowlist_) external onlyOwner {
        PRICE_PER_TOKEN_ALLOWLIST = pricePerTokenAllowlist_;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }

    function setContractURI(string memory contractUri_) external onlyOwner {
        contractURI = contractUri_;
    }

    // royalties
    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }

    function setDefaultRoyalty(address recipient, uint96 fraction) public {
        _setDefaultRoyalty(recipient, fraction);
    }

    // public mint
    function setIsSaleActive(bool isActive) public onlyOwner {
        isSaleActive = isActive;
    }

    function mint(uint256 numberOfTokens, address to) public payable {
        uint256 ts = totalSupply();
        require(isSaleActive, 'Sale must be active to mint tokens');
        require(numberOfTokens <= MAX_PUBLIC_MINT, 'Exceeded max token purchase');
        require(ts + numberOfTokens <= MAX_SUPPLY, 'Purchase would exceed max tokens');
        require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, 'Ether value sent is not correct');

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(to, ts + i);
        }
    }

    // free mint
    function freeMint(uint256 numberOfTokens, address to) public onlyOwner {
        uint256 ts = totalSupply();
        require(ts + numberOfTokens <= MAX_SUPPLY, 'Purchase would exceed max tokens');

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(to, ts + i);
        }
    }

    // withdraw functions
    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, 'Contract balance must be > 0');
        _widthdraw(owner(), address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        require(address(this).balance >= _amount, 'Contract balance must be >= _amount');
        (bool success, ) = _address.call{value: _amount}('');
        require(success, 'Transfer failed.');
    }
}