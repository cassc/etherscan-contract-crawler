// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";



contract OkayBearsAI is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    bytes32 public root;
    uint256 public maxSupply = 10000;
    uint256 public _price = 0.0069 ether; 
    uint256 public whitelistReserved = 2000; 
    uint256 public maxPerTx = 5;
    uint256 public maxPerWallet = 5;

    bool public paused = false;
    bool public revealed = false;
    bool public presaleM = true;

    address artist = 0x74e25c7C6B9Ac77Ed1e1aC8fB4bB1f6a3F61eb5d;
    string public baseURI; 
    string public notRevealedUri = "ipfs://QmNanWoRJyLE5pXc2gb8owTy9C8GsZ8RoHeEDCWa6n8SN5/";
    
    
    mapping(address => uint256) public _presaleClaimed; 
    
    uint256 public totalFreeminted;
    


    constructor(bytes32 merkleroot)
        ERC721A("Okay Bears AI", "AIBear")
        ReentrancyGuard() {
            root = merkleroot;
        }

    function setBaseURI(string memory _tokenBaseURI) public onlyOwner {
        baseURI = _tokenBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setMerkleRoot(bytes32 merkleroot) public onlyOwner {
        root = merkleroot;
    }

    modifier onlyAccounts () {
        require(msg.sender == tx.origin, "Not allowed origin");
        _;
    }

    modifier isValidMerkleProof(bytes32[] calldata _proof) {
         require(MerkleProof.verify(
            _proof,
            root,
            keccak256(abi.encodePacked(msg.sender))
            ) == true, "Not allowed origin");
        _;
   }

    function toggleSale() public onlyOwner {
        paused = !paused;
    }

    function togglePresale() public onlyOwner {
        presaleM = !presaleM;
    }

    function setWhitelistReserved(uint256 _reserved) public onlyOwner {
        whitelistReserved = _reserved;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        _price = _newPrice;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setMaxSupply(uint256 _newMaxSupply) public onlyOwner {
        maxSupply = _newMaxSupply;
    }

    function setMaxPerWallet(uint256 _amount) public onlyOwner{
        maxPerWallet = _amount;
    }

    function devMint(uint256 _amount) public payable onlyOwner{
        uint256 supply = totalSupply();
		require(_amount > 0, "Cant mint 0." );
		require(supply + _amount <= maxSupply, "Cant go over supply." );
        totalFreeminted += _amount;
        _safeMint(msg.sender, _amount);
		delete supply;
    }

    function whitelistMint(
    address account, 
    uint8 _amount,
    bytes32[] calldata _proof
    )
    external
    payable
    isValidMerkleProof(_proof)
    onlyAccounts
    {
        uint256 supply = totalSupply();
        require(_amount > 0, "Cant mint 0." );
        require(paused, "Contract is paused");
        require(presaleM, "WL sale is OFF");
        if (_presaleClaimed[msg.sender] < 1) {
            require(msg.sender == account, "Not allowed");
            require(_amount <= maxPerTx, "You can't mint so much tokens");
            require(supply + _amount <= maxSupply, "Max supply exceeded");
            require(balanceOf(msg.sender) + _amount <= maxPerWallet, "Max per wallet tokens exceeded");
            require(_price * (_amount - 1) <= msg.value, "Not enough ethers sent"); 
            require(1 + totalFreeminted <= whitelistReserved, "Free mints ended");
            require(_amount - 1 <= maxSupply - whitelistReserved - (supply - totalFreeminted), "Rest supply is reserved");
            _presaleClaimed[msg.sender]++;
            totalFreeminted++;
        } else { 
            require(msg.sender == account, "Not allowed");
            require(_amount <= maxPerTx, "You can't mint so much tokens");
            require(supply + _amount <= maxSupply, "Max supply exceeded");
            require(balanceOf(msg.sender) + _amount <= maxPerWallet, "Max per wallet tokens exceeded");
            require(_price * _amount <= msg.value, "Not enough ethers sent"); 
            require(_amount <= maxSupply - whitelistReserved - (supply - totalFreeminted), "Rest supply is reserved");
        }
        _safeMint(msg.sender, _amount);
		delete supply;
    }

    function publicSaleMint(uint256 _amount) 
    external 
    payable
    onlyAccounts
    {   
        uint256 supply = totalSupply();
        if (presaleM) {
            require(_amount <= maxSupply - whitelistReserved - (supply - totalFreeminted), "Rest supply is reserved");
        } else {
            require(_amount + supply <= maxSupply, "Max supply exceeded");
        }
        require(_amount + supply <= maxSupply, "Max supply exceeded");
        require(paused, "Contract is paused");
        require(_amount > 0, "Zero amount");
        require(_price * _amount <= msg.value, "Not enough ethers sent");
        require(_amount <= maxPerTx, "You can't mint so much tokens");
        require(balanceOf(msg.sender) + _amount <= maxPerWallet, "Max per wallet tokens exceeded");
        _safeMint(msg.sender, _amount);
		delete supply;
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        if (revealed == false) {
            return notRevealedUri;
        }
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"))
                : "";
    }

    function withdraw() public payable onlyOwner {

    (bool hs, ) = payable(artist).call{value: address(this).balance * 40 / 100}("");
    require(hs);
    
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    }

}