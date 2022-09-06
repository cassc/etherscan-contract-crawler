// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/********************
 * @author: Techoshi.eth *
        <(^_^)>
 ********************/

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";


contract IGLPresaleNFT is Ownable, ERC721, ERC721URIStorage {
    using Counters for Counters.Counter;
    using ECDSA for bytes32;
    using Strings for uint256;

    struct user {
        address userAddress;
        uint8 entries;
        bool isExist;
    }
    // mapping(address => user) public giveAwayAllowance;
    // mapping(address => uint256) public giveAwayMints;
    // uint16 public remainingReserved;

    Counters.Counter private _tokenSupply;
    Counters.Counter private _freeSupply;

    uint256 public constant MAX_TOKENS = 3000;
    uint256 public publicMintMaxLimit = 1;
    uint256 public tokenPrice = 0.00 ether;

    bool public publicMintIsOpen = false;
    bool public revealed = false;

    string _baseTokenURI;
    string public baseExtension = ".json";
    string public hiddenMetadataUri;

    address private _ContractVault = 0x0000000000000000000000000000000000000000;
    address private _ClaimsPassSigner = 0x0000000000000000000000000000000000000000;

    mapping(address => bool) public addressMinted;
    mapping(address => uint256) public claimedByOwner;

    string public Author = "techoshi.eth";
    string public ProjectTeam = "nftpumps";     

    constructor(
        string memory contractName,
        string memory contractSymbol,
        address _vault,
        address _signer,
        string memory __baseTokenURI,
        string memory _hiddenMetadataUri
    ) ERC721(contractName, contractSymbol) {
        _ContractVault = _vault;
        _ClaimsPassSigner = _signer;
        _tokenSupply.increment();
        _tokenSupply.increment();
        _safeMint(msg.sender, 1);
        _baseTokenURI = __baseTokenURI;
        hiddenMetadataUri = _hiddenMetadataUri;
         
    }
    
    function withdraw() external onlyOwner {
        payable(_ContractVault).transfer(address(this).balance);
    }

    function openMint(uint256 quantity) external payable {
        require(tokenPrice * quantity <= msg.value, "Not enough ether sent");
        uint256 supply = _tokenSupply.current();
        require(publicMintIsOpen == true, "Public Mint Closed");
        require(quantity <= publicMintMaxLimit, "Mint amount too large");
        require(quantity + (supply-1) <= MAX_TOKENS, "Not enough tokens remaining");
        require(!addressMinted[msg.sender], "This address has already minted");

        for (uint256 i = 0; i < quantity; i++) {
            _tokenSupply.increment();
            addressMinted[msg.sender] = true;
            _safeMint(msg.sender, supply + i);            
        }
    }

    function teamMint(address to, uint256 amount) external onlyOwner {
        uint256 supply = _tokenSupply.current();
        require((supply-1) + amount <= MAX_TOKENS, "Not enough tokens remaining");
        for (uint256 i = 0; i < amount; i++) {
            _tokenSupply.increment();
            _safeMint(to, supply + i);
        }
    }

    function setParams(
        uint256 newPrice,
        uint256 setOpenMintLimit,
        bool setPublicMintState
    ) external onlyOwner {
        tokenPrice = newPrice;
        publicMintMaxLimit = setOpenMintLimit;
        publicMintIsOpen = setPublicMintState;
    }

    function setTransactionMintLimit(uint256 newMintLimit) external onlyOwner {
        publicMintMaxLimit = newMintLimit;
    }

    function setTokenPrice(uint256 newPrice) external onlyOwner {
        tokenPrice = newPrice;
    }

    function togglePublicMint() external onlyOwner {
        publicMintIsOpen = !publicMintIsOpen;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenSupply.current() - 1;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    function setVaultAddress(address newVault) external onlyOwner {
        _ContractVault = newVault;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    //receive() external payable {}

    function setBaseExtension(string memory _baseExtension) public onlyOwner {
        baseExtension = _baseExtension;
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function burn(uint256 tokenId) public onlyOwner {
        _burn(tokenId);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setSignerAddress(address newSigner) external onlyOwner {
        _ClaimsPassSigner = newSigner;
    }


}