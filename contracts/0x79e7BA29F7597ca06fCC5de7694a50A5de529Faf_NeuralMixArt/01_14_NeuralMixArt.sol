// SPDX-License-Identifier: MIT


// ███╗   ██╗███████╗██╗   ██╗██████╗  █████╗ ██╗     ███╗   ███╗██╗██╗  ██╗     █████╗ ██████╗ ████████╗
// ████╗  ██║██╔════╝██║   ██║██╔══██╗██╔══██╗██║     ████╗ ████║██║╚██╗██╔╝    ██╔══██╗██╔══██╗╚══██╔══╝
// ██╔██╗ ██║█████╗  ██║   ██║██████╔╝███████║██║     ██╔████╔██║██║ ╚███╔╝     ███████║██████╔╝   ██║   
// ██║╚██╗██║██╔══╝  ██║   ██║██╔══██╗██╔══██║██║     ██║╚██╔╝██║██║ ██╔██╗     ██╔══██║██╔══██╗   ██║   
// ██║ ╚████║███████╗╚██████╔╝██║  ██║██║  ██║███████╗██║ ╚═╝ ██║██║██╔╝ ██╗    ██║  ██║██║  ██║   ██║   
// ╚═╝  ╚═══╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝╚═╝  ╚═╝    ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   

// Project Website: https://neuralmix.art
// Project Twitter: https://twitter.com/NeuralMixArt
// Minting date: Nov 15th '22 4PM UTC
// Minting info: no WL, first 1500 free FCFS 2 per wallet, then 0.02 ETH 10 per tx

// by @bilozir_eth


pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NeuralMixArt is 
    ERC721, 
    Ownable, 
    ReentrancyGuard 
{
    using Strings for uint256;
    using Counters for Counters.Counter;

    bytes32 public root;
    
    address proxyRegistryAddress;

    uint256 public maxSupply = 5000;
    uint256 public maxFreeSupply = 1500;

    string public baseURI; 
    string public notRevealedUri = "ipfs://QmUGvfT2GatG4i3Auo3YQ2UYJfkipQrUjS9PXyvGvmAJ7N/hidden.json";
    string public baseExtension = ".json";

    bool public paused = true;
    bool public revealed = false;
    bool public presaleM = false;
    bool public publicM = false;

    uint256 freeAmountLimit = 2;
    uint256 public maxMintAmount = 10;
    mapping(address => uint256) public _freeClaimed;

    uint256 public _price = 20000000000000000; // 0.02 ETH
    uint256 public _freePrice = 0; // 0 ETH

    Counters.Counter private _tokenIds;


    constructor(string memory uri, bytes32 merkleroot, address _proxyRegistryAddress)
        ERC721("NeuralMixArt", "NMA")
        ReentrancyGuard() // A modifier that can prevent reentrancy during certain functions
    {
        root = merkleroot;
        proxyRegistryAddress = _proxyRegistryAddress;

        setBaseURI(uri);
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

    function setMerkleRoot(bytes32 merkleroot) 
    onlyOwner 
    public 
    {
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

    function togglePause() public onlyOwner {
        paused = !paused;
    }

    function togglePresale() public onlyOwner {
        presaleM = !presaleM;
    }

    function togglePublicSale() public onlyOwner {
        publicM = !publicM;
    }


    function freeMint(uint256 _amount)
    external
    payable
    onlyAccounts
    {
        require(presaleM,                       "Presale is OFF");
        require(!paused,                        "Contract is paused");
        require(
            _amount <= freeAmountLimit,      "You can't mint so much tokens");
        require(
            _freeClaimed[msg.sender] + _amount <= freeAmountLimit,  "You can't mint so much tokens");


        uint current = _tokenIds.current();

        require(
            current + _amount <= maxFreeSupply,
            "Max presale supply exceeded"
        );
        require(
            _freePrice * _amount <= msg.value,
            "Not enough ethers sent"
        );
             
        _freeClaimed[msg.sender] += _amount;

        for (uint i = 0; i < _amount; i++) {
            mintInternal();
        }
    }

    function publicSaleMint(uint256 _amount) 
    external 
    payable
    onlyAccounts
    {
        require(publicM, "PublicSale is OFF");
        require(!paused, "Contract is paused");
        require(_amount > 0, "Zero amount");
        require(
            _amount <= maxMintAmount,      "You can't mint more then 10 per tx");
        uint current = _tokenIds.current();

        require(
            current + _amount <= maxSupply,
            "Max supply exceeded"
        );
        require(
            _price * _amount <= msg.value,
            "Not enough ethers sent"
        );
        
        
        for (uint i = 0; i < _amount; i++) {
            mintInternal();
        }
    }

    function mintInternal() internal nonReentrant {
        _tokenIds.increment();

        uint256 tokenId = _tokenIds.current();
        _safeMint(msg.sender, tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
    
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }
    function setMintPrice(uint256 newPrice) public onlyOwner {
        require(newPrice >= 0, "NMA price must be greater than zero");
        _price = newPrice;
    }
    function setPreSaleMintPrice(uint256 newPresalePrice) public onlyOwner {
        require(newPresalePrice >= 0, "NMA price must be greater than zero");
        _freePrice = newPresalePrice;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function totalSupply() public view returns (uint) {
        return _tokenIds.current();
    }
    address private constant treasuryAddress =
        0x17411a22029FdEad32BDff0788350725D426A322;

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(treasuryAddress), balance);
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }
}



/**
  @title An OpenSea delegate proxy contract which we include for whitelisting.
  @author OpenSea
*/
contract OwnableDelegateProxy {}

/**
  @title An OpenSea proxy registry contract which we include for whitelisting.
  @author OpenSea
*/
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}