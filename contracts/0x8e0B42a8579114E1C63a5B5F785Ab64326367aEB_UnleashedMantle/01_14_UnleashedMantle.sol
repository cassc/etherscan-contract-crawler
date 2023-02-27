// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

  //////////////////////////////////////////////////////////////////////////////////////
  //        ___           ___           ___       ___           ___           ___     //
  //      /\__\         /\__\         /\__\     /\  \         /\__\         /\  \     //
  //     /:/  /        /::|  |       /:/  /    /::\  \       /:/  /        /::\  \    //
  //    /:/  /        /:|:|  |      /:/  /    /:/\ \  \     /:/__/        /:/\:\  \   //
  //   /:/  /  ___   /:/|:|  |__   /:/  /    _\:\~\ \  \   /::\  \ ___   /:/  \:\__\  //
  //  /:/__/  /\__\ /:/ |:| /\__\ /:/__/    /\ \:\ \ \__\ /:/\:\  /\__\ /:/__/ \:|__| //
  //  \:\  \ /:/  / \/__|:|/:/  / \:\  \    \:\ \:\ \/__/ \/__\:\/:/  / \:\  \ /:/  / //
  //   \:\  /:/  /      |:/:/  /   \:\  \    \:\ \:\__\        \::/  /   \:\  /:/  /  //
  //    \:\/:/  /       |::/  /     \:\  \    \:\/:/  /        /:/  /     \:\/:/  /   //
  //     \::/  /        /:/  /       \:\__\    \::/  /        /:/  /       \::/__/    //
  //      \/__/         \/__/         \/__/     \/__/         \/__/         ~~        //
  //////////////////////////////////////////////////////////////////////////////////////
// @author viekortech - UNLEASHED COMICS UNIVERSE 
// @contact [email protected]

contract UnleashedMantle is 
    ERC721, 
    Ownable, 
    ReentrancyGuard
     
{
    using Strings for uint256;
    using Counters for Counters.Counter;

    bytes32 public root;
    
    address proxyRegistryAddress;
    
    uint256 public maxSupply = 10000;
    uint256 private _freeMintCount;
    uint256 public maxFreeMints = 300;
    uint256 presaleAmountLimit = 3;

    string public baseURI; 
    string public notRevealedUri = "ipfs://QmTfHWJ6XNcWeZeTnYp7GriUJuwT6XtHC3fNgcDdRqJ4iR/hidden.json";
    string public baseExtension = ".json";

    bool public paused = false;
    bool public revealed = false;
    bool public presaleM = false;
    bool public publicM = false;
    bool public freeM = false;

    event FreeMintEnded(string message);

    mapping(address => uint256) public _presaleClaimed;
    mapping(address => uint256) public freeMintClaimed;

    uint256 public _price;
    // Define the contract price as a public state variable
    uint256 private _presaleMintPrice = 1700000000000000; // Default price of 0.017 ETH
    // Define the contract price as a public state variable
    uint256 private _publicSaleMintPrice = 2700000000000000; // Default price of 0.027 ETH

    Counters.Counter private _tokenIds;


    constructor(string memory uri, bytes32 merkleroot, address _proxyRegistryAddress )
        ERC721("Unleashed", "UMNTL") 
        ReentrancyGuard() // A modifier that can prevent reentrancy during certain functions
        
    {
        root = merkleroot;
        proxyRegistryAddress = _proxyRegistryAddress;

        setBaseURI(uri);
       
        }

   

    function setMaxFreeMints(uint256 _maxFreeMints) external onlyOwner {
        maxFreeMints = _maxFreeMints;
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
            ) == true, "Not allowed origin proof");
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

    function toggleFreeMint() public onlyOwner {
        freeM = !freeM;
    }

    function publicSaleMintPrice() public view returns (uint256) {
        return _publicSaleMintPrice;
    }

    function presaleMintPrice() public view returns (uint256) {
        return _presaleMintPrice;
    }

    function updatePrice(uint256 _newPrice) public onlyOwner {
        _price = _newPrice;
    }

    function getPrice(uint256 mintStep) public view returns (uint256) {
    if (mintStep == 0) {
        return presaleMintPrice();
    } else if (mintStep == 1) {
        return publicSaleMintPrice();
    }
    // add a default return statement
    return 0;
    }

    function presaleMint(address account, uint256 _amount, bytes32[] calldata _proof)
    external
    payable
    isValidMerkleProof(_proof)
    onlyAccounts
    {
        require(msg.sender == account,          "Unleashed: Not allowed");
        require(presaleM,                       "Unleashed: Presale is OFF");
        require(!paused,                        "Unleashed: Contract is paused");
        require(
            _amount <= presaleAmountLimit,      "Unleashed: You maxed and took your presale token limit to the MOON!");
        require(
            _presaleClaimed[msg.sender] + _amount <= presaleAmountLimit,  "Unleashed: You maxed and took your presale token limit to the MOON!");


        uint current = _tokenIds.current();

        require(
            current + _amount <= maxSupply,
            "Unleashed: max supply exceeded"
        );
        require(
            _presaleMintPrice * _amount <= msg.value,
            "Unleashed: Not enough ethers sent"
        );
             
        _presaleClaimed[msg.sender] += _amount;

        for (uint i = 0; i < _amount; i++) {
            mintInternal();
        }
     }

    function freeMint() external onlyAccounts {
        require(publicM, "Unleashed: PublicSale is OFF");
        require(!paused, "Unleashed: Contract is paused");
        require(!freeM, "Unleased: Free Mint is OFF");
        require(_tokenIds.current() < maxSupply, "Unleashed: Max free mint reached");
        //require(balanceOf(msg.sender) == 0, "Unleashed: Only one free mint per address");

        uint256 freeMintsClaimed = freeMintClaimed[msg.sender];
        require(freeMintsClaimed == 0, "Unleashed: You have already claimed your free mint");

        require(_freeMintCount < maxFreeMints, "Unleashed: Max free mint limit reached");

        _freeMintCount++;
        freeMintClaimed[msg.sender] = 1;
            
            mintInternal();

        if (_freeMintCount == maxFreeMints) {
            emit FreeMintEnded("Free mint has ended. Public sale is still active while supply lasts.");
        }
    }

    function publicSaleMint(uint256 _amount) 
    external 
    payable
    onlyAccounts
    {
        require(publicM,                        "Unleashed: PublicSale is OFF");
        require(!paused, "Unleashed: Contract is paused");
        require(_amount > 0, "Unleashed: zero amount");

        uint current = _tokenIds.current();

        require(
            current + _amount <= maxSupply,
            "Unleashed: Max supply exceeded"
        );
        
        require(
            publicSaleMintPrice() * _amount <= msg.value,
            "Unleashed: Not enough ethers sent"
        );
        
        
        for (uint i = 0; i < _amount; i++) {
            mintInternal();
        }
    }

    function mintInternal() internal nonReentrant {
        _tokenIds.increment();

        uint256 tokenId = _tokenIds.current();
        _safeMint(msg.sender, tokenId);
        _freeMintCount++;
    }

    function withdraw(address payable _to, uint _amount) public onlyOwner nonReentrant {
    require(address(this).balance >= _amount, "Insufficient balance");
    (bool success, ) = _to.call{value: _amount}("");
    require(success, "Transfer failed");
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

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
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