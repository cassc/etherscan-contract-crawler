// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
contract TenFTGiraffes is ERC721AQueryable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    bytes32 public merkleRoot;
    mapping(address => uint256) public hasMinted;
    uint256 public cost;
    uint256 public maxSupply;
    uint256 public maxPerWallet;
    uint256 public maxPerWalletGiraffelist = 1;
    string private baseURI;
    bool public saleActive = false;
    bool public giraffelistMintEnabled = true;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256  _cost,
        uint256 _maxSupply,
        uint256 _maxPerWallet
    ) ERC721A(_tokenName, _tokenSymbol) {
        setCost(_cost);
        maxSupply = _maxSupply;
        setmaxPerWallet(_maxPerWallet);
    }

    function giraffelistMint( bytes32[] calldata _merkleProof)
        public
        payable
        nonReentrant
    {
        require(giraffelistMintEnabled, "The giraffelist sale is not enabled!");
        uint256 _mintAmount = maxPerWalletGiraffelist;
        require(hasMinted[msg.sender] < _mintAmount, "Address already mint!");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf),"Invalid proof!");
        hasMinted[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    function mint(uint256 _mintAmount)
        public
        payable
        nonReentrant
    {
        require(saleActive, "The contract is not saleActive!");
        require(hasMinted[msg.sender]+_mintAmount <= maxPerWallet,"You can't mint more!");
        require(totalSupply() + _mintAmount <= maxSupply,"Max supply exceeded!");
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");
       hasMinted[msg.sender] += _mintAmount;
        _safeMint(msg.sender, _mintAmount);
    }

    function mintForAddress(uint256 _mintAmount, address _receiver)
        public
        nonReentrant
        onlyOwner
    {
         require(totalSupply() + _mintAmount <= maxSupply,"Max supply exceeded!");
        _safeMint(_receiver, _mintAmount);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

  
    function tokenURI(uint256 _tokenId) public view virtual override returns(string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    string memory currentBaseURI = baseURI;
    return bytes(currentBaseURI).length > 0
      ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), '.json'))
      : '';
  }


    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setmaxPerWallet(uint256 _maxPerWallet)
        public
        onlyOwner
    {
        maxPerWallet = _maxPerWallet;
    }


    function setsaleActive(bool _state) public onlyOwner {
        saleActive = _state;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setgiraffelistMintEnabled(bool _state) public onlyOwner {
        giraffelistMintEnabled = _state;
    }
      function setBase(string memory _base) public onlyOwner {
        baseURI = _base;
    }
    function reserve(uint256 quantity) public payable onlyOwner {
        require(
            totalSupply() + quantity <= maxSupply,
            "Not enough tokens left"
        );
        _safeMint(msg.sender, quantity);
    }

     function withdraw() public payable onlyOwner {
     require(payable(msg.sender).send(address(this).balance));
    } 

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}