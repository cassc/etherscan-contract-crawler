// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import 'erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol';
import {DefaultOperatorFiltererUpgradeable} from "./DefaultOperatorFiltererUpgradeable.sol";
import 'erc721a-upgradeable/contracts/ERC721A__Initializable.sol';

// Twitter: https://twitter.com/shadowhunterio
// Docs: https://docs.shadowhunter.io/
// Website: https://shadowhunter.io/


contract shadowHunter is ERC721AQueryableUpgradeable, OwnableUpgradeable, PausableUpgradeable, DefaultOperatorFiltererUpgradeable  {

  string public baseURI;
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public reserveTeam;
  uint256 public maxWallet;
  uint256 public teamminted;
  uint256 public BlocksValid;
  uint256 public BlockTransferTime;
  uint256 public maxPerFree;
  uint256 public totalFree;
  mapping (address => uint256) public addressMinted;
  mapping (uint256 => bool) public tokenKilled;
  mapping (uint256 => uint256) public blockTokenKilled;
  address public signer;

  event assassinKilled (address killer, uint256 tokenId);

    function initialize() initializerERC721A initializer public {

        __ERC721A_init("Shadow Hunter", "SH");
        __ERC721AQueryable_init();
        __Ownable_init();
        __Pausable_init();
        __DefaultOperatorFilterer_init();



        cost = 0.004 ether;
        maxSupply = 3300;
        reserveTeam = 120;
        maxWallet = 10;
        teamminted;
        BlocksValid = 100;
        BlockTransferTime = 10;
        maxPerFree = 1;
        _pause();

  }


  /** Public Write Function */

  function mint(uint256 tokens) public payable  whenNotPaused {
    require(tokens > 0 , "Invalid Mint Amount");
    address msgSender = _msgSenderERC721A();
    uint256 _cost  = cost * tokens;
    if (addressMinted[msgSender] < maxPerFree) _cost = _cost - cost;
    require(totalSupply() + tokens <= maxSupply, "Sold Out");
    require(addressMinted[msgSender] + tokens <= maxWallet, "Max mint for address reached - 1");
    require(msg.value >= _cost, "Insufficient funds");
    addressMinted[msgSender] += tokens;
    _safeMint(msgSender, tokens);
  }

  function setKilled(uint256 _tokenId, bytes memory  _signature, uint256 blockSigned) public  whenNotPaused {
   address msgSender = _msgSenderERC721A();
    require(!tokenKilled[_tokenId],"Token has been assassinated");
    require(tx.origin == msgSender,  "You're not allowed to call this function");
    require(block.number - blockSigned <= BlocksValid, "Sigature is not Valid" );
    address msgSigner = signatureWallet(msgSender,_tokenId,_signature,blockSigned);
    require(msgSigner == signer, "Not authorized to kill");
    tokenKilled[_tokenId] = true;
    blockTokenKilled[_tokenId] = block.number;
    emit assassinKilled(msgSender,_tokenId);
  }

  /** Owner Functions - Write */
  
  function teamMint(uint256 _mintAmount, address destination) public onlyOwner  {
    require(teamminted + _mintAmount <= reserveTeam, "max NFT limit exceeded");
    teamminted += _mintAmount;
    _safeMint(destination, _mintAmount);
  }

  function setmaxWallet(uint256 _limit) public onlyOwner {
    maxWallet = _limit;
  }

  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setMaxsupply(uint256 _newsupply) public onlyOwner {
    maxSupply = _newsupply;
  }


  function setSigner(address _signer) public onlyOwner {
    signer = _signer;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setPaused(bool _paused) external onlyOwner {
    if (_paused) _pause();
    else _unpause();
  }

  function withdraw() public payable onlyOwner  {
    uint256 balance = address(this).balance;
    payable(_msgSenderERC721A()).transfer(balance);
  }

  function setSigValid(uint256 _newBlockTime) public onlyOwner {
      BlocksValid = _newBlockTime;
  }

  function setBlockTransferTime (uint256 _newBlockTime) public onlyOwner {
      BlockTransferTime = _newBlockTime;
  }






  /** Read Only Functions */

  function numberMinted(address owner) public view returns (uint256) {
      return _numberMinted(owner);
  }

  function isKilled(uint256 tokenID) public view returns (bool) {
    return tokenKilled[tokenID];
  }

  function getTokenStatus(uint256[] memory _tokenIDs) public view returns (bool[] memory _tokenStatus) {
    _tokenStatus = new bool[](_tokenIDs.length);
    for (uint256 i; i < _tokenIDs.length; i++){
        _tokenStatus[i] = tokenKilled[_tokenIDs[i]];
    }
  }
  
  function getTokenStatusOwner(address _owner) public view returns (bool[] memory _tokenStatus) {
    _tokenStatus = new bool[](balanceOf(_owner));
    uint256[] memory _tokensOfOwner = tokensOfOwner(_owner);
    for (uint256 i; i < balanceOf(_owner); i++){
        _tokenStatus[i] = tokenKilled[_tokensOfOwner[i]];
    }
  }


  /** ERC 721 Functions  */

  function tokensOfOwner(address owner) public view override(ERC721AQueryableUpgradeable)  returns (uint256[] memory) {
    unchecked {
        uint256 tokenIdsIdx;
        address currOwnershipAddr;
        uint256 tokenIdsLength = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenIdsLength);
        TokenOwnership memory ownership;
        for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
            ownership = _ownershipAt(i);
            if (ownership.burned) {
                continue;
            }
            if (ownership.addr != address(0)) {
                currOwnershipAddr = ownership.addr;
            }
            if (currOwnershipAddr == owner) {
                tokenIds[tokenIdsIdx++] = i;
            }
        }
        return tokenIds;
    }
  }

  function _baseURI() internal view virtual override(ERC721AUpgradeable) returns (string memory) {
    return baseURI;
  }

  function _startTokenId() internal view virtual override(ERC721AUpgradeable) returns (uint256) {
    return 1;
  }


  /** Sig. Functions  */
  function signatureWallet(address wallet, uint256  _tokenId, bytes memory  _signature, uint256 blockSigned) public view returns (address){
      return ECDSAUpgradeable.recover(keccak256(abi.encode(wallet, _tokenId,blockSigned)), _signature);
  }

  modifier BlockTransfer  (uint256 _tokenId) {
    if (tokenKilled[_tokenId]) {
      require(block.number - blockTokenKilled[_tokenId] >= BlockTransferTime,"Token has been assassinated. Cant be Transfered");      
    }
    _;
  }

  /** Opensea Royalties */

  function transferFrom(address from, address to, uint256 _tokenId) public payable override(ERC721AUpgradeable, IERC721AUpgradeable)  onlyAllowedOperator(from)  BlockTransfer(_tokenId) {
    super.transferFrom(from, to, _tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 _tokenId) public payable override(ERC721AUpgradeable, IERC721AUpgradeable)  onlyAllowedOperator(from) BlockTransfer(_tokenId) {
    super.safeTransferFrom(from, to, _tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 _tokenId, bytes memory data) public payable override(ERC721AUpgradeable, IERC721AUpgradeable)  onlyAllowedOperator(from)  BlockTransfer(_tokenId) {
    super.safeTransferFrom(from, to, _tokenId, data);
  } 
    
}