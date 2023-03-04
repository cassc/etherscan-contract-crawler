// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol"; //
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract ContendersEGNFT is
    Initializable,
    ERC2981Upgradeable,
    OwnableUpgradeable,
    IERC721Upgradeable,
    PausableUpgradeable,
    ERC721BurnableUpgradeable,
    ReentrancyGuardUpgradeable,
    OperatorFiltererUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using StringsUpgradeable for uint256;

    CountersUpgradeable.Counter private _tokenIdCounter;

    bytes32 public rootWhite;
    bytes32 public rootSuper;

    mapping(address => uint256) public mintedNFTSPerPublic; // tracks the number of NFTs minted by each whitelisted wallet
    mapping(address => uint256) public mintedNFTSPerSuper;
    uint256 public publicSupply; // the initial number of NFTs available for public minting
    uint256 public superSupply; // super whitelist
    uint256 public withheldSupply; // the initial number of NFTs withheld for the team

    bool public isRevealed; // flag for revealing

    // Variables for minting NFTs
    uint256 public mintCost; // the cost to mint a single NFT
    uint256 public maxNFTSPerPublic; // the maximum number of NFTs that can be minted by a single wallet
    uint256 public maxNFTSPerSuper;

    string public baseMetadataURI;
    bool public isStopped;
    bool public isPublic;

    // Events
    event Mint(address indexed _minter, address indexed _owner, uint256 _id); // emitted when a wallet mints an NFT
    event Burn(address indexed _from, uint256 _id); // emitted when an NFT is burned

    function initialize() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        publicSupply = 7750;
        withheldSupply = 650;
        superSupply = 1600;
        mintCost = 0.01 ether;
        maxNFTSPerPublic = 4;
        maxNFTSPerSuper = 8;
        isRevealed = false;
        isPublic = false;
        _setDefaultRoyalty(msg.sender, 650); //royalty of 6.5%
        baseMetadataURI = "https://ipfs.io/ipfs/QmPHt9rZHiNF4K6suydBq7mfbGWsoMcMk5f42EPqKTZ7jz";
    }

    function supportsInterface(
        bytes4 interfaceId //erc2981
    )
        public
        view
        virtual
        override(ERC721Upgradeable, ERC2981Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function isValidWhite(bytes32[] memory _proof)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encode(msg.sender));
        return MerkleProofUpgradeable.verify(_proof, rootWhite, leaf);
    }

     function isValidSuper(bytes32[] memory _proof)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encode(msg.sender));
        return MerkleProofUpgradeable.verify(_proof, rootSuper, leaf);
    }

    function setRootWhite(bytes32 _root) public onlyOwner {
        rootWhite = _root;
    }

    function setRootSuper(bytes32 _root) public onlyOwner {
        rootSuper = _root;
    }


    function mintPublic(uint256 _numberOfNFTs, bytes32[] memory _proof) public payable nonReentrant {
        require(!isStopped, "Mint Stopped");
        require(isValidWhite(_proof), "Not whitelisted");
        require(
            mintedNFTSPerPublic[msg.sender] + _numberOfNFTs <= maxNFTSPerPublic,
            "Max mint limit NFTs per wallet reached"
        );
        require(
            _numberOfNFTs >= 1 && _numberOfNFTs <= 4,
            "Incorrect mint count"
        );
        require(msg.value >= mintCost * _numberOfNFTs, "Insufficient funds");
        require(
            publicSupply >= _numberOfNFTs,
            "The public supply of NFTs has been exhausted."
        );

        //check number of nfts to mint
        if (_numberOfNFTs == 1) {
            uint256 tokenId = _tokenIdCounter.current();
            _safeMint(msg.sender, tokenId);
            mintedNFTSPerPublic[msg.sender]++;
            publicSupply--;
            _tokenIdCounter.increment();
            emit Mint(msg.sender, msg.sender, tokenId);
        } else if (_numberOfNFTs > 1 && _numberOfNFTs <= maxNFTSPerPublic) {
            for (uint256 i = 0; i < maxNFTSPerPublic; i++) {
                uint256 tokenId = _tokenIdCounter.current();
                _safeMint(msg.sender, tokenId);
                mintedNFTSPerPublic[msg.sender]++;
                publicSupply--;
                _tokenIdCounter.increment();
                emit Mint(msg.sender, msg.sender, tokenId);
            }
        }
    }

    function mintSuper(bytes32[] memory _proof) public payable nonReentrant {
        require(!isStopped, "Mint Stopped");
        require(isValidSuper(_proof), "Not super-whitelisted");
        require(msg.value >= mintCost * maxNFTSPerSuper, "Insufficient funds");
        require(
            mintedNFTSPerSuper[msg.sender] < maxNFTSPerSuper,
            "Already minted 8 NFTs, superSupply"
        );

        for (uint256 i = 0; i < maxNFTSPerSuper; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _safeMint(msg.sender, tokenId);
            mintedNFTSPerSuper[msg.sender]++;
            superSupply--;
            _tokenIdCounter.increment();
            emit Mint(msg.sender, msg.sender, tokenId);
        }
    }

    function mintWithheld(address _to, uint256 _numberOfNFTs)
        public
        onlyOwner
        nonReentrant
    {
        require(!isStopped, "Mint Stopped");
        require(
            withheldSupply > 0,
            "The withheld supply of NFTs has been exhausted."
        );
        if (_numberOfNFTs == 1) {
            uint256 tokenId = _tokenIdCounter.current();
            _safeMint(_to, tokenId);
            withheldSupply--;
            _tokenIdCounter.increment();
            emit Mint(msg.sender, _to, tokenId);
        } else if (_numberOfNFTs > 1) {
            for (uint256 i = 0; i < _numberOfNFTs; i++) {
                uint256 tokenId = _tokenIdCounter.current();
                _safeMint(msg.sender, tokenId);
                withheldSupply--;
                _tokenIdCounter.increment();
                emit Mint(msg.sender, msg.sender, tokenId);
            }
        }
    }

    function mintPublicAll(uint256 _numberOfNFTs) public payable nonReentrant{
        require(isPublic, "We are not open for public mint!");
        require(!isStopped, "Mint Stopped");
        require(
            _numberOfNFTs >= 1 && _numberOfNFTs <= 8,
            "Incorrect mint count"
        );
        require(msg.value >= mintCost * _numberOfNFTs, "Insufficient funds");
        require(
            publicSupply >= _numberOfNFTs,
            "The public supply of NFTs has been exhausted."
        );

        //check number of nfts to mint
        if (_numberOfNFTs == 1) {
            uint256 tokenId = _tokenIdCounter.current();
            _safeMint(msg.sender, tokenId);
            publicSupply--;
            _tokenIdCounter.increment();
            emit Mint(msg.sender, msg.sender, tokenId);
        } else if (_numberOfNFTs > 1 && _numberOfNFTs <= 8) {
            for (uint256 i = 0; i < _numberOfNFTs; i++) {
                uint256 tokenId = _tokenIdCounter.current();
                _safeMint(msg.sender, tokenId);
                publicSupply--;
                _tokenIdCounter.increment();
                emit Mint(msg.sender, msg.sender, tokenId);
            }
        }


    }

    function burn(uint256 _id) public override nonReentrant {
        _burn(_id);
        emit Burn(msg.sender, _id);
    }

    function revealAll() public onlyOwner {
        isRevealed = true;
    }

    function tokenURI(uint256 _id) public view override returns (string memory) {
        if (isRevealed)
            return string(abi.encodePacked(baseMetadataURI, _id.toString()));
        return baseMetadataURI;
    }


    //operator-filterer-registry part

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperatorApproval(operator)
        nonReentrant
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperatorApproval(operator)
        nonReentrant
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }
    //operator-filterer-registry part-end//

    function withdraw(address _to) external onlyOwner {
        uint256 balance = address(this).balance;
        payable(_to).transfer(balance);
    }

    function setMintCost(uint256 _cost) public onlyOwner {
        mintCost = _cost;
    }

    function setBaseMetadataURI(string memory _newBaseMetadataUri)
        public
        onlyOwner
    {
        baseMetadataURI = _newBaseMetadataUri;
    }

    function setAction(bool _action)   ///activate or deactivate minting(true --> stopped)
        public
        onlyOwner
    {
        isStopped = _action;
    }

    function setPublic(bool _action) public onlyOwner{
        isPublic = _action;
    }

    //superSupply decreased to zero, publicSupply increased for not minted super

    function addToPublicSupply() public onlyOwner {

        require(superSupply > 0, "Nothing to add");

        publicSupply += superSupply;
        superSupply = 0; 
    }

    function lowerPublicSupply(uint256 _amountToDecrease) public onlyOwner{
        publicSupply -= _amountToDecrease;
    }


}