// SPDX-License-Identifier: MIT
//
//
//
//
//    Pindar Van Arman's
//       __  __            __          __       _________    _   _______
//      / /_/ /_  ___     / /_  __  __/ /____  / ____/   |  / | / / ___/
//     / __/ __ \/ _ \   / __ \/ / / / __/ _ \/ / __/ /| | /  |/ /\__ \ 
//    / /_/ / / /  __/  / /_/ / /_/ / /_/  __/ /_/ / ___ |/ /|  /___/ / 
//    \__/_/ /_/\___/  /_.___/\__, /\__/\___/\____/_/  |_/_/ |_//____/  
//                           /____/                                     
//
//    bitGANS on-chained 
//
//
//  
//
//    100% on-chain contract courtesy of Justin Highland
//
//


pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "./Base64.sol";

contract BYTEGANS is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;

  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  bool public paused = true;
  bool public whitelistMintEnabled = false;

  address public ownerAddress;
  address public adminAddress;
  string public collectionDescription = "bitGANs on-chained";
  string public collectionName = "the byteGANs by Pindar Van Arman";
  string public defaultMeta = "data:application/json;base64,ewogICAgIm5hbWUiOiJsb2FkaW5nIGJhckdBTiIsCiAgICAiY29sbGVjdGlvbl9uYW1lIjoiYnl0ZUdBTnMgYnkgVmFuIEFybWFuIiwgCiAgICAiZGVzY3JpcHRpb24iOiJiaXRHQU5zIG9uLWNoYWluZWQiLCAKICAgICJpbWFnZSI6ImRhdGE6aW1hZ2Uvc3ZnK3htbDt1dGY4LDxzdmcgd2lkdGg9JzExMTEnIGhlaWdodD0nMTExMScgeG1sbnM9J2h0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnJyB4bWxuczp4bGluaz0naHR0cDovL3d3dy53My5vcmcvMTk5OS94bGluayc+IDxpbWFnZSBpbWFnZS1yZW5kZXJpbmc9J3BpeGVsYXRlZCcgd2lkdGg9JzExMTEnIGhlaWdodD0nMTExMScgeGxpbms6aHJlZj0nZGF0YTppbWFnZS9naWY7YmFzZTY0LFIwbEdPRGxoQ3dBTEFQRUFBTUFBQURDUGoyQmZYd0MvdnlIL0MwNUZWRk5EUVZCRk1pNHdBd0VBQUFBaCtRUUVGQUFBQUN3QUFBQUFDd0FMQUFBQ0lKeVBDQ3M1QzV0NlR3UUZnVlJDajNzRW91aUlnZ1Fhd1dsOWlia2hKM2tVQUNINUJBVVVBQUFBTEFFQUFRQUlBQW9BZ2dBQUFNQUFBRENQajJCZlh3Qy92d0FBQUFBQUFBQUFBQU1hQ0txMER1M0I2Q2dFNHBJTk04TVpFU2paQUFYbDR3RW1rQUFBSWZrRUJSUUFBQUFzQWdBQkFBY0FDZ0NDQUFBQXdBQUFNSStQWUY5ZkFMKy9BQUFBQUFBQUFBQUFBeG9JczlEVENnWXdJUUVYaU1rMS9jMGxZRTB3bnRRd2VpSUVKQUFoK1FRRkZBQUFBQ3dEQUFNQUJnQUlBSUlBQUFEQUFBQXdqNDlnWDE4QXY3OEFBQUFBQUFBQUFBQURFUWlxc2tvT3dEV25DbU13dklUSWdKY0FBQ0g1QkFVVUFBQUFMQUlBQVFBSEFBb0FnZ0FBQU1BQUFEQ1BqMkJmWHdDL3Z3QUFBQUFBQUFBQUFBTWFDTFRRTkMwMDJFQjROd01heFE1RDREVmpaVGxFVktWRFNTUUFJZmtFQlJRQUFBQXNBZ0FDQUFjQUNRQ0NBQUFBd0FBQU1JK1BZRjlmQUwrL0FBQUFBQUFBQUFBQUF4VUlCTXpiVE1BNGw1Uk5FSUpibU1DM0RBQ3BBUWtBSWZrRURSUUFBQUFzQVFBQ0FBZ0FDUUNDQUFBQXdBQUFNSStQWUY5ZkFMKy9BQUFBQUFBQUFBQUFBeGtJSUtLaEM0SUhSaUNYRGhuWUVCMEZDWnZrbUtmU1JFb0NBQ0g1QkFVVUFBQUFMQUlBQWdBSEFBa0FnUUFBQU1BQUFEQ1Bqd0MvdndJWEJHUmhhS0FTUm56TkdRblJPTFVGVlgzQUlKUWJVQUFBSWZrRUJSUUFBQUFzQVFBQ0FBZ0FDUUNCQUFBQXdBQUFNSStQQUwrL0FoaEVQbWtISUNQQ2tCSk01cUF4d3JiV2ZlSVhqRTBwaGdVQUlma0VCUlFBQUFBc0FRQUJBQWtBQ1FDQ0FBQUF3QUFBTUkrUFlGOWZBTCsvQUFBQUFBQUFBQUFBQXhvSUN0RkxoTFVBNEtpVUVqR3lzeEdqQ0ZFMENFdXFyaUliSkFBaCtRUUZGQUFBQUN3QkFBRUFDQUFLQUlJQUFBREFBQUF3ajQ5Z1gxOEF2NzhBQUFBQUFBQUFBQUFER3dnYU9ncnNrVVZDRmVzQnZJT3d3RFJ0NFNZNG82YXVDcFlDQ1FBNycgLz4gPC9zdmc+IiAgCn0=";

  struct tokenData {
        string name;
        string GIF;
        string trait;
        bool updated;
  }

  mapping (uint256 => tokenData) public tokens;

  modifier requireAdminOrOwner() {
    require(adminAddress == msg.sender || ownerAddress == msg.sender,"Requires admin or owner privileges");
    _;
  }

  function setAdminAddress(address _adminAddress) public onlyOwner{
        adminAddress = _adminAddress;
  }

//Set permissions for relayer
  function setTokenInfo(uint _tokenId, string memory _name, string memory _GIF, string memory _trait) public requireAdminOrOwner() { 
        //require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");
        tokens[_tokenId].name = _name;
        tokens[_tokenId].trait = _trait;
        tokens[_tokenId].GIF = _GIF;
        tokens[_tokenId].updated = true;
  }

  function buildImage(uint256 _tokenId) public view returns(string memory) {
      return Base64.encode(bytes(
          abi.encodePacked(
            '<svg width="500" height="500" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"> <image width="500" height="500" image-rendering="pixelated" xlink:href="data:image/gif;base64,',tokens[_tokenId].GIF,'"/> </svg>'
          )
      ));
  }

  function buildMetadata(uint256 _tokenId) public view returns(string memory) {

        if(tokens[_tokenId].updated != true){
            return defaultMeta;
        }
        else{
           return string(abi.encodePacked(
              'data:application/json;base64,', Base64.encode(bytes(abi.encodePacked(
                          '{"name":"', 
                          tokens[_tokenId].name,
                          '", "description":"', 
                          collectionDescription,
                          '", "attributes":', 
                          tokens[_tokenId].trait,
                          ', "image": "', 
                          'data:image/svg+xml;base64,', 
                          buildImage(_tokenId),
                          '"}'))))); 
        }     
      
  }

  function getTokenInfo(uint _tokenId) public view returns (string memory, string memory, string memory) {
        return (tokens[_tokenId].name,tokens[_tokenId].GIF, tokens[_tokenId].trait);
  }   

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
      require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");
      return buildMetadata(_tokenId);
  } 


  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx
    ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    whitelistClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

  function ownerMint(uint256 _mintAmount) public onlyOwner {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    _safeMint(_msgSender(), _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');

    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = _startTokenId();
    uint256 ownedTokenIndex = 0;
    address latestOwnerAddress;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId < _currentIndex) {
      TokenOwnership memory ownership = _ownerships[currentTokenId];

      if (!ownership.burned) {
        if (ownership.addr != address(0)) {
          latestOwnerAddress = ownership.addr;
        }

        if (latestOwnerAddress == _owner) {
          ownedTokenIds[ownedTokenIndex] = currentTokenId;

          ownedTokenIndex++;
        }
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
    
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
    // =============================================================================
  }

}