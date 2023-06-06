// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract AcidHeadz is ERC721, ERC721Enumerable, ERC721Burnable, ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    string public PROVENANCE = "6ebf9db40be092eb13fc1ab30aafa19351019eb6dcf7cdc0569df5b4e3ea64a3";

    uint256 public constant MAX_SUPPLY = 2690;

    uint256 public constant RESERVED_SUPPLY = 90; // Marketing/Giveaways/Team

    uint256 public constant MAX_PURCHASE = 10;

    uint256 public constant PRICE = 0.69 ether;

    ERC721Burnable public shroomz;

    bool public saleIsActive = false;

    mapping(address => uint256) public whitelist;

    uint256 public mintedReserved;    

    mapping(uint256 => uint256) public mintsPerShroomz;

    uint256 private nextTokenId;

    uint256 private startingIndex;

    string private tokenBaseURI;    

    event WhitelistAdded(address indexed addr, uint256 indexed tokenAmount);

    constructor(ERC721Burnable _shroomz) ERC721("Acid Headz", "ACIDHEADZ")
    {
        shroomz = _shroomz;
    }

    function mint(uint256 numberOfNfts) external nonReentrant payable {
        require(saleIsActive, "Sale did not start");
        require(totalSupply().sub(mintedReserved).add(numberOfNfts) <= MAX_SUPPLY - RESERVED_SUPPLY, "Exceeds max supply");
        require(numberOfNfts > 0, "Cannot buy 0");
        require(numberOfNfts <= MAX_PURCHASE, "You may not buy that many NFTs at once");
        require(PRICE.mul(numberOfNfts) == msg.value, "Ether value sent is not correct");

        for (uint256 i = 0; i < numberOfNfts; i++) {
            _safeMint(msg.sender, nextTokenId); 
            nextTokenId = nextTokenId.add(1).mod(MAX_SUPPLY);
        }
    }

    function mintReserve(uint256 numberOfNfts) external nonReentrant {
        require(saleIsActive, "Sale did not start");
        require(totalSupply().add(numberOfNfts) <= MAX_SUPPLY, "Exceeds max supply");
        require(numberOfNfts > 0, "Cannot buy 0");
        require(numberOfNfts <= MAX_PURCHASE, "You may not buy that many NFTs at once");
        require(whitelist[msg.sender] >= numberOfNfts, "Not enough reserve allowance");

        whitelist[msg.sender] = whitelist[msg.sender].sub(numberOfNfts);

        for (uint256 i = 0; i < numberOfNfts; i++) {
            _safeMint(msg.sender, nextTokenId); 
            nextTokenId = nextTokenId.add(1).mod(MAX_SUPPLY);
        }

        mintedReserved += numberOfNfts;
    }    

    function burnAndMint(uint256 shroomzTokenId) external nonReentrant {
        require(saleIsActive, "Sale did not start");
        require(msg.sender == shroomz.ownerOf(shroomzTokenId), "Must own specified Shroomz Token ID");

        uint256 numberOfNfts = mintsPerShroomz[shroomzTokenId];
        if (numberOfNfts == 0) {
            numberOfNfts = 1; // Micro
        }
        require(totalSupply().add(numberOfNfts) <= MAX_SUPPLY, "Exceeds max supply");

        shroomz.burn(shroomzTokenId);

        for (uint256 i = 0; i < numberOfNfts; i++) {
            _safeMint(msg.sender, nextTokenId); 
            nextTokenId = nextTokenId.add(1).mod(MAX_SUPPLY);
        }
    }

    function withdraw() onlyOwner public {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function addWhitelist(address addr, uint256 tokenAmount) onlyOwner external {
        whitelist[addr] = tokenAmount;
        emit WhitelistAdded(addr, tokenAmount);
    }    

    function addMintsPerShroomz(uint256 shroomzTokenId, uint256 mintsPerBurn) onlyOwner external {
        mintsPerShroomz[shroomzTokenId] = mintsPerBurn;
    }

    function addMintsPerShroomz(uint256[] calldata shroomzTokenIds, uint256 mintsPerBurn) onlyOwner external {
        for (uint256 i = 0; i < shroomzTokenIds.length; i++) {
            mintsPerShroomz[shroomzTokenIds[i]] = mintsPerBurn;
        }
    }    

    function toggleSale() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function setStartingIndex() external onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        
        startingIndex = uint256(blockhash(block.number - 1)) % MAX_SUPPLY;
   
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }

        nextTokenId = startingIndex;
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