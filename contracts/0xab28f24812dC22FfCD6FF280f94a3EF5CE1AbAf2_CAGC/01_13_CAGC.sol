// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract CAGC is ERC721, Ownable, PaymentSplitter {

    uint256 public constant MAX_TOKENS = 6969;
    uint256 public constant TOKENS_PER_MINT = 20;
    uint256 public mintPrice = 0.03 ether;
    uint256 private totalMinted = 0;
    uint256 private reservedTokens = 0;

    string private _baseTokenURI;
    bool public saleIsOpen = false;

    mapping (address => bool) private _reserved;
    address public proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;

    event MintChadApe (address indexed buyer, uint256 startWith, uint256 batch);

    constructor(
        address[] memory payees,
        uint256[] memory shares,
        string memory baseURI
    ) ERC721("Chad Ape Gym Club", "CAGC") PaymentSplitter(payees, shares) {
        _baseTokenURI = baseURI;
    }

    function mintChadApe(uint256 numberOfTokens) external payable {
        require(saleIsOpen, "Sale is not active");
        require(numberOfTokens <= TOKENS_PER_MINT, "Max apes per mint exceeded");
        require(totalMinted + numberOfTokens <= MAX_TOKENS - reservedTokens, "Purchase would exceed max available apes");
        require(mintPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");

        emit MintChadApe(msg.sender, totalMinted+1, numberOfTokens);

        for(uint256 i = 1;  i <= numberOfTokens; i++) {
            _safeMint(msg.sender, totalMinted + i);
        }

        totalMinted += numberOfTokens;
    }

    function reservedMint() external payable {
        require(saleIsOpen, "Sale is not active");
        require(_reserved[msg.sender], "You don't have any reserved tokens left");
        require(mintPrice <= msg.value, "Ether value sent is not correct");

        emit MintChadApe(msg.sender, totalMinted + 1, 1);

        _safeMint(msg.sender, totalMinted + 1);
        totalMinted += 1;
        reservedTokens -=1 ;
        _reserved[msg.sender] = false;
    }

    function giveaway(uint256 numberOfTokens, address mintAddress) external onlyOwner {
        require(totalMinted + numberOfTokens <= MAX_TOKENS - reservedTokens, "Purchase would exceed max available apes");

        for(uint256 i = 1;  i <= numberOfTokens; i++) {
            _mint(mintAddress, totalMinted + i);
        }

        totalMinted += numberOfTokens;
    }

    function totalSupply() public view returns (uint256) {
        return totalMinted;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function addToWhitelist(address _addr) external onlyOwner {
        _reserved[_addr] = true;
        reservedTokens += 1;
    }

    function batchWhitelist(address[] memory _addrs) external onlyOwner {
        uint size = _addrs.length;

        for(uint256 i = 0; i < size; i++){
            _reserved[_addrs[i]] = true;
        }

        reservedTokens += size;
    }

    function removeFromWhitelist(address _addr) external onlyOwner {
         _reserved[_addr] = false;
         reservedTokens -=1;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function changePrice(uint256 _newPrice) external onlyOwner {
        mintPrice = _newPrice;
    }

    function flipSaleState() external onlyOwner {
        saleIsOpen = !saleIsOpen;
    }

    function getReservedCount() external onlyOwner view returns (uint256) {
        return reservedTokens;
    }

    /**
    * Override isApprovedForAll to auto-approve opensea proxy contract
    */
    function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
        if (operator == proxyRegistryAddress) {
            return true;
        }
        return super.isApprovedForAll(_owner, operator);
    }

    /**
    * Change the OS proxy if ever needed.
    */
    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }
}