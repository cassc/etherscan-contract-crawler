//          _____                        _____                        _____                            _____          
//         /\    \                      /\    \                      |\    \                          /\    \         
//        /::\    \                    /::\    \                     |:\____\                        /::\    \        
//       /::::\    \                   \:::\    \                    |::|   |                       /::::\    \       
//      /::::::\    \                   \:::\    \                   |::|   |                      /::::::\    \      
//     /:::/\:::\    \                   \:::\    \                  |::|   |                     /:::/\:::\    \     
//    /:::/__\:::\    \                   \:::\    \                 |::|   |                    /:::/  \:::\    \    
//   /::::\   \:::\    \                  /::::\    \                |::|   |                   /:::/    \:::\    \   
//  /::::::\   \:::\    \                /::::::\    \               |::|___|______            /:::/    / \:::\    \  
// /:::/\:::\   \:::\ ___\              /:::/\:::\    \              /::::::::\    \          /:::/    /   \:::\    \ 
///:::/__\:::\   \:::|    |            /:::/  \:::\____\            /::::::::::\____\        /:::/____/     \:::\____\
//\:::\   \:::\  /:::|____|           /:::/    \::/    /           /:::/~~~~/~~              \:::\    \      \::/    /
// \:::\   \:::\/:::/    /           /:::/    / \/____/           /:::/    /                  \:::\    \      \/____/ 
//  \:::\   \::::::/    /           /:::/    /                   /:::/    /                    \:::\    \             
//   \:::\   \::::/    /           /:::/    /                   /:::/    /                      \:::\    \            
//    \:::\  /:::/    /            \::/    /                    \::/    /                        \:::\    \           
//     \:::\/:::/    /              \/____/                      \/____/                          \:::\    \          
//      \::::::/    /                                                                              \:::\    \         
//       \::::/    /                                                                                \:::\____\        
//        \::/____/                                                                                  \::/    /        
//         ~~                                                                                         \/____/         
                                                                                                                    

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract boredtigeryc is ERC721A, Ownable {
  bool public mintEnabled = false;
  bytes32 public merkleRoot;
  mapping(address => uint256) public _walletMintedCount;
  string public baseURI = '';
  uint256 public wlFreePerWallet = 1;
  uint256 public mintPrice = 0.004 ether;
  uint256 public maxMintPerWallet = 20;
  uint256 public maxSupply = 5555;

  constructor() ERC721A("Bored Tiger YC", "BTYC") {}

  function _startTokenId() internal view override virtual returns (uint256) {
    return 1;
  }

  function mintTo(address to, uint256 _mintAmount) external onlyOwner {
    require(_totalMinted() + _mintAmount <= maxSupply, 'Max supply exceeded!');
	_safeMint(to, _mintAmount);
  }

   modifier mintCompliance(uint256 _mintAmount) {
    require(mintEnabled, 'The sale is not enabled!');
    require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
    require(_walletMintedCount[msg.sender] + _mintAmount <= maxMintPerWallet, "You can mint maximum 20 per wallet!");
    require(_mintAmount > 0 && _mintAmount <= maxMintPerWallet, "Invalid mint amount!");
    _;
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) external payable mintCompliance(_mintAmount) {
    require(_walletMintedCount[msg.sender] <= 0, "You have already minted, please check secondary or public.");
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    uint256 payForCount = _mintAmount;
    if(_mintAmount > wlFreePerWallet) {
        payForCount = _mintAmount - wlFreePerWallet;
    }
    else {
            payForCount = 0;
    }
    require(msg.value >= (mintPrice * payForCount), "Insufficient funds!");
    _safeMint(_msgSender(), _mintAmount);
    _walletMintedCount[msg.sender] += _mintAmount;
  }

    function publicMint(uint256 _mintAmount) external payable mintCompliance(_mintAmount) {
        require(msg.value >= (mintPrice * _mintAmount), "Insufficient funds!");
        _safeMint(msg.sender, _mintAmount);
        _walletMintedCount[msg.sender] += _mintAmount;
    }

    function mintedCount(address owner) external view returns (uint256) {
        return _walletMintedCount[owner];
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setMintEnabled(bool _state) public onlyOwner {
        mintEnabled = _state;
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMaxMintPerWallet (uint256 _maxMintPerWallet) public onlyOwner {
        maxMintPerWallet = _maxMintPerWallet;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }
}