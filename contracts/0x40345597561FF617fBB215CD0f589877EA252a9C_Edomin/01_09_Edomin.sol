// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./DefaultOperatorFilterer.sol";

contract Edomin is DefaultOperatorFilterer, ERC721A, Ownable {

    string baseURI;
    string public baseExtension = ".json";
    uint256 public cost = 0;
    uint256 public maxSupply = 3000;
    uint256 public maxMintAmountPerTransaction = 1;
    uint256 public whitelistMaxMintAmountPerAddress = 1;
    uint256 public publicSaleMaxMintAmountPerAddress = 1;
    bool public paused = true;
    bool public freeMint = true;
    bool public onlyWhitelisted = true;
    bool public mintCount = true;
    mapping(address => uint256) public freeMintedAmount;
    mapping(address => uint256) public whitelistMintedAmount;
    mapping(address => uint256) public publicSaleMintedAmount;
    address public constant WITHDRAW_ADDRESS = 0x14145DDf324BC975Ee621044D662739d9A6EDe96;
    
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract.");
        _;
    }

    constructor(
    ) ERC721A('Edomin', 'EDO') {
        setBaseURI('https://edo-1.com/data/edomin/json/');
        _safeMint(0x72055004578e5084F6F6581e652182a94865Bc40, 1);
        _safeMint(0x1fa6096F902220528b42963a84D171e4de67aC85, 3);
        _safeMint(0x24F037ffbAf3D40540D19A32f8b4E6fD09b04Cd9, 3);
        _safeMint(0xe45e55B7Cd819f5AF6F98E6dfEb6c1b4b5624816, 3);
        _safeMint(0x7B05286C955a954647f7558C1C3ee35Ef0c6bB3A, 3);
        _safeMint(0x272209e695B92fe1803B0cAe0E4d5ECFcF16262E, 5);
        _safeMint(0xde1d3A35855DB09bd2eeEb0E61C6d76d15A1c1b8, 5);
        _safeMint(0x57ea25d951b2F6499708B3B75075e814F115BC99, 10);
        _safeMint(0x004b6653D16A6defc070dd6fE9438a07145611bf, 30);
        _safeMint(0x2E9BaDD597b87a6236DB494364F36ebb66d44Ef3, 30);
        _safeMint(0x4bE0D14b5B3776570170c835Dd78Ad4290eDF4f3, 30);
        _safeMint(0x4849A28A0aD851994a5De1E85792F4C36541CA09, 30);
        _safeMint(0x28Cab85F5DA9E500CE48A2e00AE71B1adeDAc677, 30);
        _safeMint(0xFF84bEeD418DCE792309CB3F7Efc1fF7Cdc0FD55, 30);
        _safeMint(0xfa4e9dc8D6077443D668CdFe7dC13E5040C2A9A6, 30);
        _safeMint(0xE3b439bbBD9006Ca68B177Fb09d875433f3Ed756, 30);
        _safeMint(0x14145DDf324BC975Ee621044D662739d9A6EDe96, 120);
        setMerkleRoot(0xccc6ff775fe8274c9351f6dc4089d90562593a06931339aa0fd2e3f5b4e51bd4);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

      //mint with merkle tree
      bytes32 public merkleRoot;
      function mint(uint256 _mintAmount , uint256 _maxMintAmount , bytes32[] calldata _merkleProof) public payable callerIsUser{
          require(!paused, "the contract is paused");
          require(0 < _mintAmount, "need to mint at least 1 NFT");
          require(_mintAmount <= maxMintAmountPerTransaction, "max mint amount per session exceeded");
          require(totalSupply() + _mintAmount <= maxSupply, "max NFT limit exceeded");
          require(cost * _mintAmount <= msg.value, "insufficient funds");
          if(freeMint == true) {
              bytes32 leaf = keccak256( abi.encodePacked(msg.sender, _maxMintAmount) );
              require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "user is not whitelisted");
              if(onlyWhitelisted == true){
                  require(_mintAmount <= _maxMintAmount - freeMintedAmount[msg.sender] , "max NFT per address exceeded");
                  freeMintedAmount[msg.sender] += _mintAmount;
              }
          }else if(onlyWhitelisted == true) {
              bytes32 leaf = keccak256( abi.encodePacked(msg.sender, _maxMintAmount) );
              require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "user is not whitelisted");
              if(mintCount == true){
                  require(_mintAmount <= _maxMintAmount - whitelistMintedAmount[msg.sender] , "max NFT per address exceeded");
                  whitelistMintedAmount[msg.sender] += _mintAmount;
              }
          }else{
              bytes32 leaf = keccak256( abi.encodePacked(msg.sender, _maxMintAmount) );
              require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "user is not whitelisted");
              if(mintCount == true){
                  require(_mintAmount <= publicSaleMaxMintAmountPerAddress - publicSaleMintedAmount[msg.sender] , "max NFT per address exceeded");
                  publicSaleMintedAmount[msg.sender] += _mintAmount;
              }
          }
          _safeMint(msg.sender, _mintAmount);
      }
  
      function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
          merkleRoot = _merkleRoot;
      }

    

    function airdropMint(address[] calldata _airdropAddresses , uint256[] memory _UserMintAmount) public onlyOwner{
        uint256 supply = totalSupply();
        uint256 _mintAmount = 0;
        for (uint256 i = 0; i < _UserMintAmount.length; i++) {
            _mintAmount += _UserMintAmount[i];
        }
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

        for (uint256 i = 0; i < _UserMintAmount.length; i++) {
            _safeMint(_airdropAddresses[i], _UserMintAmount[i] );
        }
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory){
        return string(abi.encodePacked(ERC721A.tokenURI(tokenId), baseExtension));
    }

    //only owner  
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setfreeMint(bool _state) public onlyOwner {
        freeMint = _state;
    }   

    function setOnlyWhitelisted(bool _state) public onlyOwner {
        onlyWhitelisted = _state;
    }    

    function setMaxMintAmountPerTransaction(uint256 _maxMintAmountPerTransaction) public onlyOwner {
        maxMintAmountPerTransaction = _maxMintAmountPerTransaction;
    }

    function setwhitelistMaxMintAmountPerAddress(uint256 _whitelistMaxMintAmountPerAddress) public onlyOwner() {
        whitelistMaxMintAmountPerAddress = _whitelistMaxMintAmountPerAddress;
    }
    
    function setPublicSaleMaxMintAmountPerAddress(uint256 _publicSaleMaxMintAmountPerAddress) public onlyOwner() {
        publicSaleMaxMintAmountPerAddress = _publicSaleMaxMintAmountPerAddress;
    }
  
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setMintCount(bool _state) public onlyOwner {
        mintCount = _state;
    }
 
    function withdraw() external onlyOwner {    
    require( WITHDRAW_ADDRESS != address(0), "The address shouldn't be 0" );
    (bool os, ) = WITHDRAW_ADDRESS.call{value: address(this).balance}("");
    require(os);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }    

}