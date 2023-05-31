// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PolyPixos is ERC721, ERC721Enumerable, ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    string public PROVENANCE = "a70f3c526e578ec1e04477622311dd076169f22cde00aad48994b7f418922ad1";

    uint256 public constant MAX_SUPPLY = 4444;

    uint256 public constant MAX_PURCHASE = 3;

    uint256 public constant PRICE = 0.1111 ether;

    uint256 public constant MINTS_PER_POLYVERSE_PASS = 3;

    IERC721 public polyversePass;

    mapping(uint256 => bool) public usedPolyversePasses;

    enum SalePhase { NOT_OPEN, POLYVERSE_PASS, PRESALE, PUBLIC }

    SalePhase public salePhase;

    mapping(address => uint256) public whitelist;

    mapping(address => uint256) public reserved;

    uint256 private nextTokenId;

    string private tokenBaseURI;    

    event WhitelistAdded(address indexed addr, uint256 indexed tokenAmount);

    constructor(IERC721 _polyversePass) ERC721("PolyPixos", "POLYPIXOS")
    {
        polyversePass = _polyversePass;
        nextTokenId = nextTokenId.add(1);
    }

    function mintWithPolyversePass(uint256 polyversePassTokenId) external nonReentrant {
        require(salePhase >= SalePhase.POLYVERSE_PASS, "Sale phase did not start");
        require(msg.sender == polyversePass.ownerOf(polyversePassTokenId), "Must own specified Polyverse Pass Token ID");
        require(!usedPolyversePasses[polyversePassTokenId], "Already used");
        require(totalSupply().add(MINTS_PER_POLYVERSE_PASS) <= MAX_SUPPLY, "Exceeds max supply");

        usedPolyversePasses[polyversePassTokenId] = true;

        _mint(MINTS_PER_POLYVERSE_PASS);
    }

    function mintReserved(uint256 numberOfNfts) external nonReentrant {
        require(salePhase >= SalePhase.POLYVERSE_PASS, "Sale phase did not start");
        require(totalSupply().add(numberOfNfts) <= MAX_SUPPLY, "Exceeds max supply");
        require(numberOfNfts > 0, "Cannot buy 0");
        require(reserved[msg.sender] >= numberOfNfts, "Not enough reserve allowance");

        reserved[msg.sender] = reserved[msg.sender].sub(numberOfNfts);

        _mint(numberOfNfts);
    }    

    function mintPresale(uint256 numberOfNfts) external nonReentrant payable {
        require(salePhase >= SalePhase.PRESALE, "Sale phase did not start");
        require(totalSupply().add(numberOfNfts) <= MAX_SUPPLY , "Exceeds max supply");
        require(numberOfNfts > 0, "Cannot buy 0");
        require(PRICE.mul(numberOfNfts) == msg.value, "Ether value sent is not correct");
        require(whitelist[msg.sender] >= numberOfNfts, "Not enough presale allowance");

        whitelist[msg.sender] = whitelist[msg.sender].sub(numberOfNfts);

        _mint(numberOfNfts);
    }

    function mint(uint256 numberOfNfts) external nonReentrant payable {
        require(salePhase >= SalePhase.PUBLIC, "Sale phase did not start");
        require(totalSupply().add(numberOfNfts) <= MAX_SUPPLY, "Exceeds max supply");
        require(numberOfNfts > 0, "Cannot buy 0");
        require(numberOfNfts <= MAX_PURCHASE, "You may not buy that many NFTs at once");
        require(PRICE.mul(numberOfNfts) == msg.value, "Ether value sent is not correct");

        _mint(numberOfNfts);
    }

    function _mint(uint256 numberOfNfts) internal {
        for (uint256 i = 0; i < numberOfNfts; i++) {
            _safeMint(msg.sender, nextTokenId); 
            nextTokenId = nextTokenId.add(1);
        }
    }
    
    function addWhitelist(address[] calldata addresses, uint256 numberOfMints) onlyOwner external {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = numberOfMints;
        }
    }

    function addReserved(address[] calldata addresses, uint256 numberOfMints) onlyOwner external {
        for (uint256 i = 0; i < addresses.length; i++) {
            reserved[addresses[i]] = numberOfMints;
        }
    }    

    function setSalePhase(SalePhase _salePhase) external onlyOwner {
        salePhase = _salePhase;
    }

    function withdraw() onlyOwner public {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory baseURI = _baseURI();
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function setTokenBaseURI(string memory _tokenBaseURI) public onlyOwner {
        tokenBaseURI = _tokenBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return tokenBaseURI;
    }

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