// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/*
 * @title ERC721 token for DAOTaiFung genesis collection

    8888888b.        d8888  .d88888b. 88888888888       d8b 8888888888                         
    888  "Y88b      d88888 d88P" "Y88b    888           Y8P 888                                
    888    888     d88P888 888     888    888               888                                
    888    888    d88P 888 888     888    888   8888b.  888 8888888 888  888 88888b.   .d88b.  
    888    888   d88P  888 888     888    888      "88b 888 888     888  888 888 "88b d88P"88b 
    888    888  d88P   888 888     888    888  .d888888 888 888     888  888 888  888 888  888 
    888  .d88P d8888888888 Y88b. .d88P    888  888  888 888 888     Y88b 888 888  888 Y88b 888 
    8888888P" d88P     888  "Y88888P"     888  "Y888888 888 888      "Y88888 888  888  "Y88888 
                                                                                        888 
                                                                                    Y8b d88P 
                                                                                    "Y88P"  
    .d8888b.                                      d8b                                         
    d88P  Y88b                                     Y8P                                         
    888    888                                                                                 
    888         .d88b.  88888b.   .d88b.  .d8888b  888 .d8888b                                 
    888  88888 d8P  Y8b 888 "88b d8P  Y8b 88K      888 88K                                     
    888    888 88888888 888  888 88888888 "Y8888b. 888 "Y8888b.                                
    Y88b  d88P Y8b.     888  888 Y8b.          X88 888      X88                                
    "Y8888P88  "Y8888  888  888  "Y8888   88888P' 888  88888P'                                
                                                                     
 */
contract DtfGenesis is ERC721A, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenSupply;

    string baseURI;
    string public baseExtension = ".json";
    uint256 public cost = 0.088 ether;
    uint256 public maxSupply = 888;
    uint256 public AMOUNT_RESERVED_FOR_DAO = 88;

    address public daoAddress =  address(0x005a8413dfefb75899c93ea5a6152eb5afe01a956e);

    // DEFAULT: Each address can only mint at most 2 token
    uint256 public maxMintAmount = 2;

    bool public paused = true;
    bool public pausedPublic = true;
    bool public revealed = false;
    string public notRevealedUri;

    bytes32 public mintMerkleRoot;

    // Mapping from address to the amount of tokens that the address has minted
    mapping(address => uint256) public mintTxs;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721A(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
    }

    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address is not in the allowlist"
        );
        _;
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mintPublic(uint256 _mintAmount) external payable {
        uint256 supply = totalSupply();
        require(!paused, "Minting paused");
        require(!pausedPublic, "Public minting paused");
        require(
            _mintAmount > 0,
            "_mintAmount cannot be less than or equal to 0"
        );
        require(
            _mintAmount <= maxMintAmount,
            "Attempting to mint too many NFTs"
        );
        require(
            mintTxs[msg.sender] + _mintAmount <= maxMintAmount,
            "Attempting to mint more than the allowed amount per wallet"
        );
        require(
            supply + _mintAmount <= maxSupply,
            "Minting would exceed the max supply of NFTs"
        );

        if (msg.sender != owner()) {
            require(
                msg.value >= cost * _mintAmount,
                "Not enough ETH to mint the NFT"
            );
        }

        mintTxs[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    function mint(uint256 _mintAmount, bytes32[] calldata merkleProof)
        external
        payable
        isValidMerkleProof(merkleProof, mintMerkleRoot)
    {
        uint256 supply = totalSupply();
        require(!paused, "Minting paused");
        require(
            _mintAmount > 0,
            "_mintAmount cannot be less than or equal to 0"
        );
        require(
            _mintAmount <= maxMintAmount,
            "Attempting to mint too many NFTs"
        );
        require(
            mintTxs[msg.sender] + _mintAmount <= maxMintAmount,
            "Attempting to mint more than the allowed amount per wallet"
        );
        require(
            supply + _mintAmount <= maxSupply,
            "Minting would exceed the max supply of NFTs"
        );

        if (msg.sender != owner()) {
            require(
                msg.value >= cost * _mintAmount,
                "Not enough ETH to mint the NFT"
            );
        }

        mintTxs[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    function mintForDAO() external onlyOwner {
        uint256 supply = totalSupply();
        require(
            supply + AMOUNT_RESERVED_FOR_DAO <= maxSupply,
            "Minting would exceed the max supply of NFTs"
        );
        _safeMint(daoAddress, AMOUNT_RESERVED_FOR_DAO);
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

    //only owner
    function setMaxPerWallet(uint256 _maxMintAmount) external onlyOwner {
        maxMintAmount = _maxMintAmount;
    }

    function setDaoAddress(address _daoAddress) external onlyOwner {
        daoAddress = _daoAddress;
    }

    function setMintMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        mintMerkleRoot = _merkleRoot;
    }

    function pause(bool _state) external onlyOwner {
        paused = _state;
    }

    function pausePublic(bool _state) external onlyOwner {
        pausedPublic = _state;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setCost(uint256 _newCost) external onlyOwner {
        cost = _newCost;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function withdraw() public payable onlyOwner {
        // Do not remove this otherwise you will not be able to withdraw the funds.
        // =============================================================================
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
        // =============================================================================
    }
}