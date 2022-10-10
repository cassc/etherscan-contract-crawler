// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "erc721a/contracts/ERC721A.sol"; 
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract GenesisHustlers is 
    ERC721A, 
    Ownable, 
    ReentrancyGuard

{
    using Strings for uint256;
    using Counters for Counters.Counter;

    bytes32 public rootWL;

    address proxyRegistryAddress;

    uint256 public maxSupply = 1111;

    string public baseURI; 
    string public notRevealedUri = "";
    string public baseExtension = ".json";

    bool public paused = true;
    bool public revealed = true;
    bool public presaleM = true;
    bool public publicM = false;
    bool public teamMinted = false;

    uint256 presaleAmountLimit = 2;
    uint256 publicAmountLimit=2;

    mapping(address => uint256) public _presaleClaimed;
    mapping(address => uint256) public _publicClaimed;

    uint256 _pricePub = 40000000000000000; // 0.04 ETH
    uint256 _priceWL = 29000000000000000; // 0.029 ETH

    Counters.Counter private _tokenIds;

    constructor(string memory uri, bytes32 merklerootWL, address _proxyRegistryAddress)
        ERC721A("GenesisHustlers", "GH")
        ReentrancyGuard() // A modifier that can prevent reentrancy during certain functions
    {
    
        rootWL = merklerootWL;
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

    modifier onlyAccounts () {
        require(msg.sender == tx.origin, "Not allowed origin");
        _;
    }

    function togglePause() public onlyOwner {
        paused = !paused;
    }
    modifier isValidMerkleProof(bytes32[] calldata _proofWL) {
         require(MerkleProof.verify(
            _proofWL,
            rootWL,
            keccak256(abi.encodePacked(msg.sender))
            ) == true, "Not allowed origin");
        _;
   }


    function SwitchSales() public onlyOwner {
        publicM = !publicM;
        presaleM = !presaleM;
    }
    function wlMint(address account, uint256 _amount, bytes32[] calldata _proofWL)
    external
    payable
    isValidMerkleProof(_proofWL)
    onlyAccounts
    {
        require(msg.sender == account,          " Not allowed");
        require(presaleM,                       "WL phase is OFF");
        require(!paused,                        " Contract is paused");
        require(
            _amount <= presaleAmountLimit,      " You can't mint so much tokens");
        require(
            _presaleClaimed[msg.sender] + _amount <= presaleAmountLimit,  " You can't mint so many tokens");


        //uint current = _tokenIds.current();

        require(
            totalSupply() + _amount <= maxSupply,
            "max supply exceeded"
        );
        require(
            _priceWL * _amount <= msg.value,
            "Not enough ethers sent"
        );
             
        _presaleClaimed[msg.sender] += _amount;

        _safeMint(msg.sender, _amount);
    }

    function setMerkleRoot(bytes32 merkleroot) 
    onlyOwner 
    public 
    {
        rootWL = merkleroot;
    }
    

    function publicMint(uint256 _amount) 
    external 
    payable
    onlyAccounts
    {
        require(publicM, " PublicSale is OFF");
        require(!paused, " Contract is paused");
        require(_amount > 0, " zero amount");
         require(
            _amount <= publicAmountLimit,      " You can't mint so many tokens");
        require(
            _publicClaimed[msg.sender] + _amount <= publicAmountLimit,  " You can't mint so many tokens");

        //uint current = _tokenIds.current();

        require(
            totalSupply() + _amount <= maxSupply,
            " Max supply exceeded"
        );
        require(
            _pricePub * _amount <= msg.value,
            " Not enough ethers sent"
        );
        
        _publicClaimed[msg.sender] += _amount;
        
        _safeMint(msg.sender, _amount);
    }

  //  function mintInternal() internal nonReentrant {
   //     _tokenIds.increment();
  //
   //     uint256 tokenId = _tokenIds.current();
   //     _safeMint(msg.sender, tokenId);
  //  }

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

    //function totalSupply() public view returns (uint) {
        //return _tokenIds.current();
   // }

    function withdraw(address to, uint256 amount) public onlyOwner {
        payable(to).transfer(amount);
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
    function teamMint() external onlyOwner{
        require(!teamMinted, "GnesisHustlers :: Team already minted");
        teamMinted = true;
        _safeMint(msg.sender, 20);
    }
    function _startTokenId()
        internal
        view
        virtual
        override returns (uint256) 
    {
        return 1;
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