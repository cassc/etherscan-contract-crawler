// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";

contract LarvaDucks is Ownable, ReentrancyGuard, ERC721A {
    address private immutable _ogCardsAddress = 0x96AaF5008913C3Ae12541f6ea7717c9A0DD74F4d;
    address private immutable _doodlesAddress = 0x8a90CAb2b38dba80c64b7734e58Ee1dB38B8992e;
    address private immutable _punksAddress = 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;
    address private immutable _azukiAddress = 0xED5AF388653567Af2F388E6224dC7C4b3241C544;
    address private immutable _cryptoKittiesAddress = 0x06012c8cf97BEaD5deAe237070F9587f8E7A266d;

    string public baseURI;
    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    bool public publicSaleOpened = false;
    uint256 public maxSupply = 5000;

    // Public
    uint256 public publicMaxMintsPerTx = 5;
    uint256 public publicPrice = 0.03 ether;

    // Allowlist
    uint256 public allowListMaxMintsPerWallet = 3;
    mapping(address => bool) public hasClaimedAllowList;

    constructor() ERC721A("LarvaDucks", "LVDUCK") {}
    
    receive() payable external {}

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function claimNumber(address _wallet) public view returns (uint256) {
        uint256 totalBalance;
        ERC721 doodlesContract = ERC721(_doodlesAddress);
        if(doodlesContract.balanceOf(_wallet) > 0) {
            totalBalance += 1;
        }
        ERC721 punksContract = ERC721(_punksAddress);
        if(punksContract.balanceOf(_wallet) > 0) {
            totalBalance += 1;
        }
        ERC721 ogCardsContract = ERC721(_ogCardsAddress);
        if(ogCardsContract.balanceOf(_wallet) > 0) {
            totalBalance += 2;
        }
        ERC721 azukiContract = ERC721(_azukiAddress);
        if(azukiContract.balanceOf(_wallet) > 0) {
            totalBalance += 1;
        }
        ERC721 cryptoKittiesContract = ERC721(_cryptoKittiesAddress);
        if(cryptoKittiesContract.balanceOf(_wallet) > 0) {
            totalBalance += 1;
        }

        return (totalBalance > allowListMaxMintsPerWallet) ? allowListMaxMintsPerWallet : totalBalance;
    }

    function claimMint(address _wallet, uint256 numToMint) external nonReentrant {
        require(publicSaleOpened, "Sale not open");
        require(msg.sender == tx.origin, "Contract mint not allowed");
        uint256 maxToClaim = claimNumber(_wallet);
        require(maxToClaim > 0, "Wallet not allowlisted");
        require(!hasClaimedAllowList[_wallet], "Already claimed with this wallet");
        require(numToMint > 0, "Should mint at least one");
        require((numToMint + totalSupply()) <= maxSupply, "Not enough tokens left");
        require(numToMint <= maxToClaim, "Too many tokens claimed");

        _safeMint(_wallet, numToMint);

        hasClaimedAllowList[_wallet] = true;
    }

    // Public
    function publicMint(address _wallet, uint256 numToMint) payable external nonReentrant {
        require(publicSaleOpened, "Sale not open");
        require(msg.sender == tx.origin, "Contract mint not allowed");
        require(numToMint > 0, "Should mint at least one");
        require((numToMint + totalSupply()) <= maxSupply, "Not enough token left");
        require(numToMint <= publicMaxMintsPerTx, "Too many tokens claimed");
        require(msg.value >= publicPrice * numToMint, "Not enough ETH sent");

        _safeMint(_wallet, numToMint);
    }

    // Admin
    function airdrop(address[] memory recipients, uint256[] memory amounts) external onlyOwner {
        require(recipients.length == amounts.length, "Arrays lengths are different");
        
        uint256 numToMint = 0;
        for (uint256 i=0; i<amounts.length; i++) {
            numToMint += amounts[i];
        }
        require((numToMint + totalSupply()) <= maxSupply, "Not enough token left");

        for (uint256 i=0; i<recipients.length; i++) {
            _safeMint(recipients[i], amounts[i]);
        }
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];

        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }

        return super.tokenURI(tokenId);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOwner {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function setSaleOpen(bool _publicSaleOpened) public onlyOwner {
	    publicSaleOpened = _publicSaleOpened;
	}

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        require(_maxSupply < maxSupply, "Can only reduce the max supply");
        require(_maxSupply >= totalSupply(), "Max supply must be greater than the current supply");
        maxSupply = _maxSupply;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
	    baseURI = _newBaseURI;
    }

    function withdraw() external payable onlyOwner returns (bool success) {
        (success,) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Withdraw Error");
    }
}