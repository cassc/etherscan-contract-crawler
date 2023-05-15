// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// @author: wzrdslim.eth

contract CrystalFrogsV2 is
    ERC721,
    Ownable,
    ReentrancyGuard,
    PaymentSplitter
{
    using Strings for uint256;
    using Counters for Counters.Counter;

    bytes32 public root;
    bytes32 public genesisRoot;

    address proxyRegistryAddress;

    uint256 public maxSupply = 4600;

    string public baseURI;
    string public notRevealedUri = "ipfs://QmS3BTMyVsBUBRTeW5Nt3JQNAD1htGQss1jh7a1DkoULwN/hidden.json";
    string public baseExtension = ".json";

    bool public paused = false;
    bool public revealed = false;
    bool public genesissaleM = true;
    bool public presaleM = true;
    bool public publicM = false;


    uint256 maxAmountLimit = 2;
    uint256 genesisAmountLimit = 5;
    uint256 presaleAmountLimit = 2;
    mapping(address => uint256) public _genesisClaimed;
    mapping(address => uint256) public _presaleClaimed;

    uint256 public maxPublicMintLimit = 500;
    uint256 public publicSaleMinted;

    uint256 _price = 0; // 0 ETH

    Counters.Counter private _tokenIds;

    uint256[] private _teamShares = [20, 20, 20, 20, 20];
    address[] private _team = [
        0xe98BdB5F4B3a3845b47965B288546b8aC6E3ec4C, // Project Funds Account gets 20% of the total revenue
        0x99649Cd8ACeffD624DaE2660559dD70bdF5cA8A1, // Artist Account gets 20 of the total revenue
        0xc1eB5AcD614312bac05Dc8595C18fed3bA043F24, // Project Director Account gets 20% of the total revenue
        0xf0318A36043A19d2A3690E88094C27a206fDf830, // Developer Account gets 20% of the total revenue
        0xaf29ab7418516cc3F22E609dC783D75864AB545a // Marketing Manager Account gets 20% of the total revenue
    ];

    constructor(string memory uri, bytes32 merkleroot, bytes32 genesisMerkleRoot, address _proxyRegistryAddress)
        ERC721("CrystalFrogsV2", "FROGS")
        PaymentSplitter(_team, _teamShares)
        ReentrancyGuard()
    {
        root = merkleroot;
        genesisRoot = genesisMerkleRoot;
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

    function setGenesisMerkleRoot(bytes32 genesisMerkleRoot)
    onlyOwner
    public
    {
        genesisRoot = genesisMerkleRoot;
    }

    function setMerkleRoot(bytes32 merkleroot)
    onlyOwner
    public
    {
        root = merkleroot;
    }

    function setMaxSupply(uint256 newMaxSupply) public onlyOwner {
        maxSupply = newMaxSupply;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        _price = newPrice;
    }

    function setGenesisAmountLimit(uint256 newLimit) public onlyOwner {
        genesisAmountLimit = newLimit;
    }

    function setPreSaleAmountLimit(uint256 newLimit) public onlyOwner {
        presaleAmountLimit = newLimit;
    }

    function setMaxPublicMintLimit(uint256 newLimit) public onlyOwner {
        maxPublicMintLimit = newLimit;
    }

    function updateTeamAddresses(address[] memory newAddresses) public onlyOwner {
        require(newAddresses.length == _team.length, "CrystalFrogsV2: Invalid array length");
    
        for (uint256 i = 0; i < newAddresses.length; i++) {
        _team[i] = newAddresses[i];
        }
    }

    modifier onlyAccounts () {
        require(msg.sender == tx.origin, "Not allowed origin");
        _;
    }

    modifier isValidGenesisMerkleProof(bytes32[] calldata _proof) {
         require(MerkleProof.verify(
            _proof,
            genesisRoot,
            keccak256(abi.encodePacked(msg.sender))
            ) == true, "Not allowed origin");
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

    function toggleGenesisSale() public onlyOwner {
        genesissaleM = !genesissaleM;
    }

    function togglePresale() public onlyOwner {
        presaleM = !presaleM;
    }

    function togglePublicSale() public onlyOwner {
        publicM = !publicM;

        if (publicM) {
            publicSaleMinted = 0; // Reset minted count when publicM is toggled on
        }
    }

    function genesisSaleMint(address account, uint256 _amount, bytes32[] calldata _proof)
    external
    payable
    isValidGenesisMerkleProof(_proof)
    onlyAccounts
    {
        require(msg.sender == account, "CrystalFrogsV2: Not allowed");
        require(genesissaleM, "CrystalFrogsV2: Genesis Mint is OFF");
        require(!paused, "CrystalFrogsV2: Contract is paused");
        require(
            _amount <= genesisAmountLimit, "CrystalFrogsV2: You can not mint so much tokens");
        require(
            _genesisClaimed[msg.sender] + _amount <= genesisAmountLimit, "CrystalFrogsV2: Only 5 Genesis Mints per wallet");


        uint current = _tokenIds.current();

        require(
            current + _amount <= maxSupply,
            "CrystalFrogsV2: max supply exceeded"
        );
        require(
            _price * _amount <= msg.value,
            "CrystalFrogsV2: Not enough ethers sent"
        );

        _genesisClaimed[msg.sender] += _amount;

        for (uint i = 0; i < _amount; i++) {
            mintInternal();
        }
    }

    function preSaleMint(address account, uint256 _amount, bytes32[] calldata _proof)
    external
    payable
    isValidMerkleProof(_proof)
    onlyAccounts
    {
        require(msg.sender == account, "CrystalFrogsV2: Not allowed");
        require(presaleM, "CrystalFrogsV2: WL Mint is OFF");
        require(!paused, "CrystalFrogsV2: Contract is paused");
        require(
            _amount <= presaleAmountLimit, "CrystalFrogsV2: You can not mint so much tokens");
        require(
            _presaleClaimed[msg.sender] + _amount <= presaleAmountLimit, "CrystalFrogsV2: Only 3 WL Mints per wallet");


        uint current = _tokenIds.current();

        require(
            current + _amount <= maxSupply,
            "CrystalFrogsV2: max supply exceeded"
        );
        require(
            _price * _amount <= msg.value,
            "CrystalFrogsV2: Not enough ethers sent"
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
        require(publicM, "CrystalFrogsV2: Public Mint is OFF");
        require(!paused, "CrystalFrogsV2: Contract is paused");
        require(
            _amount <= maxAmountLimit, "CrystalFrogsV2: You can not mint so much tokens");
        require(_amount > 0, "CrystalFrogsV2: zero amount");
        require(publicSaleMinted + _amount <= maxPublicMintLimit, "CrystalFrogsV2: Mint limit reached");

        uint current = _tokenIds.current();

        require(
            current + _amount <= maxSupply,
            "CrystalFrogs: Max supply exceeded"
        );
        require(
            _price * _amount <= msg.value,
            "CrystalFrogs: Not enough ethers sent"
        );

        for (uint i = 0; i < _amount; i++) {
            mintInternal();
        }

        publicSaleMinted += _amount; // Increment minted count
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