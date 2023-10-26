// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BongTown is 
    ERC721, 
    Ownable, 
    ReentrancyGuard, 
    PaymentSplitter 

{
    using Strings for uint256;
    using Counters for Counters.Counter;

    bytes32 public root;
    
    address proxyRegistryAddress;

    uint256 public maxSupply = 4200;

    string public baseURI; 
    string public notRevealedUri = "ipfs://QmTz52QX1vQYeBaoTFaVPP6vA7MfA4vzCMrGSZu31chwRH/hidden.json";
    string public baseExtension = ".json";

    bool public paused = false;
    bool public revealed = false;
    bool public freeM = false;
    bool public whitelistM = true;
    bool public publicM = false;

    uint256 whitelistAmountLimit = 2;
    mapping(address => uint256) public _whitelistClaimed;

    uint256 freemintAmountLimit = 2;
    mapping(address => uint256) public _freemintClaimed;

    uint256 publicAmountLimit = 21;
    mapping(address => uint256) public _publicClaimed;

    uint256 _price = 4200000000000000; // 0.00420 ETH

    Counters.Counter private _tokenIds;

    uint256[] private _teamShares = [33, 33, 34]; // 333
    address[] private _team = [
        0x9152cB4b93e9F68Ce9fB7eE9790c131895407eA3, // Mayor gets 33% of the total revenue
        0xcF5298fB30bC2b620f47B0d27f7bA006106B6a78, // Sheriff gets 33% of the total revenue
        0x34aD76DdDe5A2E9FFAD2EE1c543C8afA2948b1F9 // Bongtown treasury gets 34% of the total revenue
    ];

    constructor(string memory uri, bytes32 merkleroot, address _proxyRegistryAddress)
        ERC721("BongTown", "BONG")
        PaymentSplitter(_team, _teamShares) // Split the payment based on the teamshares percentages
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
function freeMint(uint256 _amount) 
    external 
    payable
    onlyAccounts
    {
        require(freeM, "BongTown: Freemint is OFF");
        require(
            _freemintClaimed[msg.sender] + _amount <= freemintAmountLimit,  "BongTown: You can't mint so much tokens");


        uint current = _tokenIds.current();

        require(
            current + _amount < 1001,
            "BongTown: Max freemint supply exceeded"
        );

        _freemintClaimed[msg.sender] += _amount;
          
        for (uint i = 0; i < _amount; i++) {
            mintInternal();
        }
        
    }

    function toggleFree() public onlyOwner {
        freeM = !freeM;
    }

    function toggleWhitelist() public onlyOwner {
        whitelistM = !whitelistM;
    }

    function togglePublic() public onlyOwner {
        publicM = !publicM;
    }


    function whitelistMint(address account, uint256 _amount, bytes32[] calldata _proof)
    external
    payable
    isValidMerkleProof(_proof)
    onlyAccounts
    {
        require(msg.sender == account,          "BongTown: Not allowed");
        require(whitelistM,                       "BongTown: Whitelist is OFF");
        require(
            _amount < whitelistAmountLimit,      "BongTown: You can't mint so much tokens");
        require(
            _whitelistClaimed[msg.sender] + _amount < whitelistAmountLimit,  "BongTown: You can't mint so much tokens");


        uint current = _tokenIds.current();

        require(
            current + _amount < 1001,
            "BongTown: max supply exceeded"
        );
        require(
            msg.value == 0,
            "BongTown: Free WL mint"
        );
             
        _whitelistClaimed[msg.sender] += _amount;

        for (uint i = 0; i < _amount; i++) {
            mintInternal();
        }
    }

    function publicSaleMint(uint256 _amount) 
    external 
    payable
    onlyAccounts
    {
        require(publicM,                        "BongTown: PublicSale is OFF");
        require(_amount > 0, "BongTown: zero amount");
        require(_amount < publicAmountLimit);
        require(_publicClaimed[msg.sender] + _amount < publicAmountLimit, 
        "BongTown: You can't mint so much tokens");

        uint current = _tokenIds.current();

        require(
            current + _amount < 3781,
            "BongTown: Max supply exceeded"
        );
        require(
            _price * _amount <= msg.value,
            "BongTown: Not enough ethers sent"
        );
        
        
        for (uint i = 0; i < _amount; i++) {
            mintInternal();
        }
    }

    function treasuryMint(uint256 _amount) 
    external
    onlyOwner
    {
     
        require (_amount > 0);

        uint current = _tokenIds.current();
        require (current + _amount < 4201);

        
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

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function totalSupply() public view returns (uint) {
        return _tokenIds.current();
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