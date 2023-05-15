// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract MiladyColombiaMusic is ERC721, Pausable, Ownable, ERC721Burnable {
    using Strings for uint256;

    string public uriPrefix = "ipfs://bafkreicraisld4zqjqdbhbxiufgnnk5qtkf5csi53qskwlaa532racsovm/";
    
    uint256 public publicPrice;
    uint256 public miladyPrice;
    uint256 public maxSupply;
    uint256 public totalTokenSupply;

    bytes32 public merkleRoot;

    mapping(address => uint) public miladyClaimentCount;

    address constant MILADY_RAVE = 0x880a965fAe95f72fe3a3C8e87ED2c9478C8e0a29; 
    address constant MILADY_MAKER = 0x5Af0D9827E0c53E4799BB226655A1de152A425a5; 
    address constant PIXELADY_MAKER = 0x8Fc0D90f2C45a5e7f94904075c952e0943CFCCfd; 
    address constant REDACTED_REMILIO = 0x8Fc0D90f2C45a5e7f94904075c952e0943CFCCfd; 
    address constant RADBRO = 0xABCDB5710B88f456fED1e99025379e2969F29610; 
    address constant SCHIZO = 0xBfE47D6D4090940D1c7a0066B63d23875E3e2Ac5; 

    constructor(
        uint256 _publicPrice,
        uint256 _miladyPrice,
        uint256 _maxSupply,
        bytes32 _merkleRoot
    ) ERC721("Milady Colombia Music", "MCM") {
        setPublicPrice(_publicPrice);
        setMiladyPrice(_miladyPrice);
        maxSupply = _maxSupply;
        setMerkleRoot(_merkleRoot);
        totalTokenSupply = 0; // initialize totalTokenSupply to one
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(_mintAmount > 0, "Invalid mint amount!");
        require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
        require(msg.value >= publicPrice * _mintAmount, "Insufficient funds!");
        _;
    }

    modifier hasBluechip(address _account){
    require(
      IERC721(RADBRO).balanceOf(_account) > 0 ||
      IERC721(SCHIZO).balanceOf(_account) > 0 ||
      IERC721(MILADY_RAVE).balanceOf(_account) > 0 ||
      IERC721(MILADY_MAKER).balanceOf(_account) > 0 ||
      IERC721(PIXELADY_MAKER).balanceOf(_account) > 0 ||
      IERC721(REDACTED_REMILIO).balanceOf(_account) > 0, "You dont any Milady's!");
    _;
  }

    function allowListed(address _wallet, bytes32[] memory _proof)
        public
        view
        returns (bool)
        {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_wallet, 1))));
        return
            MerkleProof.verify(
                _proof,
                merkleRoot,
                leaf
            );
        }
    
    function mintAllowList(bytes32[] memory _proof) whenNotPaused external {
        require(totalSupply() + 1 <= maxSupply, "Max supply exceeded!");
        require(allowListed(msg.sender, _proof), "You are not included in snapshot");
        require(miladyClaimentCount[msg.sender] < 1, "You already claimed");
        miladyClaimentCount[msg.sender] = 1;
        _safeMint(_msgSender(), totalTokenSupply + 1);
        totalTokenSupply += 1; // increment totalTokenSupply after minting
    }

    function mintAsHolder(uint256 _mintAmount) public payable whenNotPaused  mintCompliance(_mintAmount) hasBluechip(msg.sender) {
        require(msg.value >= miladyPrice * _mintAmount, "Insufficient funds!");
        if (_mintAmount > 1) {
            for (uint256 i = 0; i < _mintAmount; i++) {
                _safeMint(_msgSender(), totalTokenSupply + 1);
                totalTokenSupply += 1; // increment totalTokenSupply after minting
            }
        } else {
            _safeMint(_msgSender(), totalTokenSupply + 1);
            totalTokenSupply += 1; // increment totalTokenSupply after minting
        }
    }
    
    
    function mint(uint256 _mintAmount) public payable whenNotPaused mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
        for (uint256 i = 0; i < _mintAmount; i++) {
            _safeMint(_msgSender(), totalTokenSupply + 1);
            totalTokenSupply += 1; // increment totalTokenSupply after minting
        }
    }
    
    function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
        for (uint256 i = 0; i < _mintAmount; i++) {
            _safeMint(_receiver, totalTokenSupply + 1);
            totalTokenSupply += 1; // increment totalTokenSupply after minting
        }
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? currentBaseURI
            : '';
    }

    function setPublicPrice(uint256 _publicPrice) public onlyOwner {
        publicPrice = _publicPrice;
    }

    function setMiladyPrice(uint256 _miladyPrice) public onlyOwner {
        miladyPrice = _miladyPrice;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
    internal
    whenNotPaused
    override
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // Increment totalTokenSupply if a new token is being minted
        // if (from == address(0)) {
        //     totalTokenSupply += batchSize;
        // }
        if (to == address(0)) {
            totalTokenSupply -= batchSize;
        }
    }

    function totalSupply() public view returns (uint256) {
        return totalTokenSupply;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function getIsMiladyHolder(address _account) public view returns (bool) {
        if (
            IERC721(RADBRO).balanceOf(_account) > 0 ||
            IERC721(SCHIZO).balanceOf(_account) > 0 ||
            IERC721(MILADY_RAVE).balanceOf(_account) > 0 ||
            IERC721(MILADY_MAKER).balanceOf(_account) > 0 ||
            IERC721(PIXELADY_MAKER).balanceOf(_account) > 0 ||
            IERC721(REDACTED_REMILIO).balanceOf(_account) > 0
        ) {
        return true;
        } else {
        return false;
        }
    }

    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}('');
        require(os);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}