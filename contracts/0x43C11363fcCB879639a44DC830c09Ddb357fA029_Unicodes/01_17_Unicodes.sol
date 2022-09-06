// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*
 ██╗   ██╗███╗   ██╗██╗ ██████╗ ██████╗ ██████╗ ███████╗███████╗
 ██║   ██║████╗  ██║██║██╔════╝██╔═══██╗██╔══██╗██╔════╝██╔════╝
 ██║   ██║██╔██╗ ██║██║██║     ██║   ██║██║  ██║█████╗  ███████╗
 ██║   ██║██║╚██╗██║██║██║     ██║   ██║██║  ██║██╔══╝  ╚════██║
 ╚██████╔╝██║ ╚████║██║╚██████╗╚██████╔╝██████╔╝███████╗███████║
  ╚═════╝ ╚═╝  ╚═══╝╚═╝ ╚═════╝ ╚═════╝ ╚═════╝ ╚══════╝╚══════╝
*/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import '@openzeppelin/contracts/finance/PaymentSplitter.sol';
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Unicodes is 
    ERC721, 
    Ownable, 
    ReentrancyGuard, 
    PaymentSplitter 
{
    using Strings for uint256;
    using Counters for Counters.Counter;

    bytes32 public root;
    
    address proxyRegistryAddress;

    uint256 public maxSupply = 65536;

    string public baseURI; 
    string public notRevealedUri = "https://cdn.jsdelivr.net/gh/unicoded/metadata/json/65536.json"; //* update this
    string public baseExtension = ".json";

    bool public paused = false;
    bool public revealed = true;
    bool public presaleM = false;
    bool public publicM = true;

    uint256 presaleAmountLimit = 10;
    mapping(address => uint256) public _presaleClaimed;

    uint256 _price = 10000000000000000; //* 0.01 ETH

    Counters.Counter private _tokenIds;

    uint256[] private _teamShares = [31, 69];
    address[] private _team = [
        0x945fE27749F564173237FdDF47749b676a14111F,
        0xBfac80a2aDcDa8B02B0E6aDfaf19826E0cB81f83
    ];

    constructor(string memory uri, bytes32 merkleroot, address _proxyRegistryAddress)
        ERC721("Unicodes", "UNICODE")
        PaymentSplitter(_team, _teamShares)
        ReentrancyGuard()
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
        require(msg.sender == account, "Unicodes: Not allowed");
        require(presaleM, "Unicodes: Presale is OFF");
        require(!paused, "Unicodes: Contract is paused");
        require(_amount <= presaleAmountLimit, "Unicodes: You can't mint so much tokens");
        require(_presaleClaimed[msg.sender] + _amount <= presaleAmountLimit,  "Unicodes: You can't mint so much tokens");


        uint current = _tokenIds.current();

        require(
            current + _amount <= maxSupply,
            "Unicodes: max supply exceeded"
        );
        require(
            _price * _amount <= msg.value,
            "Unicodes: Not enough ethers sent"
        );
             
        _presaleClaimed[msg.sender] += _amount;

        for (uint i = 0; i < _amount; ++i) {
            mintInternal();
        }
    }

    function publicSaleMint(uint256 _amount) 
    external 
    payable
    onlyAccounts
    {
        require(publicM, "Unicodes: PublicSale is OFF");
        require(!paused, "Unicodes: Contract is paused");
        require(_amount > 0, "Unicodes: zero amount");

        uint current = _tokenIds.current();

        require(
            current + _amount <= maxSupply,
            "Unicodes: Max supply exceeded"
        );
        require(
            _price * _amount <= msg.value,
            "Unicodes: Not enough ethers sent"
        );
        
        
        for (uint i = 0; i < _amount; ++i) {
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

    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {

        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}