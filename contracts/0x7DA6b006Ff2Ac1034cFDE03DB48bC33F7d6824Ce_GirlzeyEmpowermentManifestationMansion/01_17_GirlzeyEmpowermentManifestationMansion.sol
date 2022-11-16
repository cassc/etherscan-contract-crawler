// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import '@openzeppelin/contracts/finance/PaymentSplitter.sol';
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// @author viekortech
// @contact [email protected]

contract GirlzeyEmpowermentManifestationMansion is 
    ERC721, 
    Ownable, 
    ReentrancyGuard, 
    PaymentSplitter 
{
    using Strings for uint256;
    using Counters for Counters.Counter;

    bytes32 public root;
    
    address proxyRegistryAddress;

    uint256 public maxSupply = 10715;

    string public baseURI; 
    string public notRevealedUri = "ipfs://QmTfHWJ6XNcWeZeTnYp7GriUJuwT6XtHC3fNgcDdRqJ4iR/hidden.json";
    string public baseExtension = ".json";

    bool public paused = false;
    bool public revealed = false;
    bool public presaleM = false;
    bool public publicM = false;

    uint256 presaleAmountLimit = 3;
    mapping(address => uint256) public _presaleClaimed;

    uint256 _price = 120000000000000000; // 0.12 ETH

    Counters.Counter private _tokenIds;

    uint256[] private _teamShares = [5, 15, 15, 20, 45]; // 3 PEOPLE IN THE TEAM, Donation to charity Orgs, and Company Reserve
    address[] private _team = [
        0x67D3a454aE98102950b4d2360436cEd8827b349F, // Team Member 3 5% of the initial sale revenue
        0x7309371B14926A25F118E3c05bF2359fB889B93A, // Donation to Orgs supporting Girls gets 15% of the initial sale revenue
        0xa4e82498AE98a1E2D535524e3260c5ae6a051450, // Team Member 2 Account gets 15% of the initial sale revenue
        0x6AC5bA095B28E8Fe6045faf532eC086795D005ca, // Team Member 1 Account gets 20% of the initial sale revenue
        0x61EA1726764B091fEf6Cde220ff99501A3293FE4 // Company Reserve 45%
    ];

    constructor(string memory uri, bytes32 merkleroot, address _proxyRegistryAddress)
        ERC721("GirlzeyEmpowermentManifestationMansion", "GEMM")
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

    function togglePause() public onlyOwner {
        paused = !paused;
    }

    function togglePresale() public onlyOwner {
        presaleM = !presaleM;
    }

    function togglePublicSale() public onlyOwner {
        publicM = !publicM;
    }


    function presaleMint(address account, uint256 _amount, bytes32[] calldata _proof)
    external
    payable
    isValidMerkleProof(_proof)
    onlyAccounts
    {
        require(msg.sender == account,          "GirlzeyEmpowermentManifestationMansion: Not allowed");
        require(presaleM,                       "GirlzeyEmpowermentManifestationMansion: Presale is OFF");
        require(!paused,                        "GirlzeyEmpowermentManifestationMansion: Contract is paused");
        require(
            _amount <= presaleAmountLimit,      "GirlzeyEmpowermentManifestationMansion: You maxed and took your presale token limit to the MOON!");
        require(
            _presaleClaimed[msg.sender] + _amount <= presaleAmountLimit,  "GirlzeyEmpowermentManifestationMansion: You maxed and took your presale token limit to the MOON!");


        uint current = _tokenIds.current();

        require(
            current + _amount <= maxSupply,
            "GirlzeyEmpowermentManifestationMansion: max supply exceeded"
        );
        require(
            _price * _amount <= msg.value,
            "GirlzeyEmpowermentManifestationMansion: Not enough ethers sent"
        );
             
        _presaleClaimed[msg.sender] += _amount;

        for (uint i = 0; i < _amount; i++) {
            mintInternal();
        }
    }

    function publicSaleMint(uint256 _amount) 
    external 
    payable
    onlyAccounts
    {
        require(publicM,                        "GirlzeyEmpowermentManifestationMansion: PublicSale is OFF");
        require(!paused, "GirlzeyEmpowermentManifestationMansion: Contract is paused");
        require(_amount > 0, "GirlzeyEmpowermentManifestationMansion: zero amount");

        uint current = _tokenIds.current();

        require(
            current + _amount <= maxSupply,
            "GirlzeyEmpowermentManifestationMansion: Max supply exceeded"
        );
        require(
            _price * _amount <= msg.value,
            "GirlzeyEmpowermentManifestationMansion: Not enough ethers sent"
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