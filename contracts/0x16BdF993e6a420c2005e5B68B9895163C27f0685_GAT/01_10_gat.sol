// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "erc721a/contracts/ERC721A.sol"; 
import "@openzeppelin/contracts/utils/Address.sol"; 
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IRoyaltyMint {
  function mintForAddress(uint256 _mintAmount, address _receiver) external;
}

contract GAT is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;
  using ECDSA for bytes32;
  
  string public uriPrefix = "";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;
  uint256 public cost = .075 ether;
  uint256 public maxSupply = 2000;
  uint256 public maxMintAmountPerTx = 3;
  bool public paused = true;
  bool public revealed = false;
  address private _signer;
  address public royalty_contract_address; 
  address private PROJECT_WALLET;
  address[2] private _shareholders;
  uint[2] private _shares;
  uint256 shareholders0Balance=0;
  uint256 shareholders1Balance=0;
  

  mapping(address => uint256[]) public mintAddresses;
  mapping(string => bool) public usedMessages;
  mapping(address => uint) public TolatestTokenTransfer;
  mapping(address => uint) public FromlatestTokenTransfer;
  mapping(address => bool) public nftPayWalletAddress;
  

  error DirectMintFromContractNotAllowed();
  error InvalidSignature();
  error saltAlreadyUsed();
  error cannotWithdraw();
  event PaymentReleased(address to, uint256 amount);
  
  constructor() ERC721A("Gods & Titans - Titanomachy War", "GAT") {    
    _shareholders[0] = 0x5799459Fd460a6487Bac1Ac48932DfB561b42DbC; // O
    _shareholders[1] = 0x357d10D121fD77d3fd6fA5dcebef006E200dE003; // P
    _shares[0] = 10;
    _shares[1] = 90;
    setHiddenMetadataUri("ipfs://QmeBQd4hb9mhrHkMKkVocdEiWo1WEtb1hNGXPpVj3PX9Z5/hidden.json");    
  }  

  modifier callerIsUser() {
    if (tx.origin != msg.sender)
        revert DirectMintFromContractNotAllowed();
    _;
  }  

  function _setSigner(address _newSigner) external onlyOwner {
    _signer = _newSigner;
  }

  function _setProjectWallet(address _PROJECT_WALLET, string calldata _salt, bytes calldata _token, uint256 _amount) external onlyOwner {
    if (!verifyTokenForAddress(_salt, _token, msg.sender, _amount, 0x60c0aC7b6294Cd13F78a336dB810Cfba24d242Cb))
      revert InvalidSignature();    
    if(_PROJECT_WALLET != address(0)) {
      PROJECT_WALLET = _PROJECT_WALLET;
    }    
  }

  function setRoyaltyContractTokenAddress(address _address) external onlyOwner {
    royalty_contract_address = _address;
  }

  function setMaxSupply(uint256 _maxSupply) external onlyOwner {
    maxSupply = _maxSupply;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) external onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalidmint amount!");
    uint256 totalGods = totalSupply();
    require(totalGods + _mintAmount <= maxSupply, "Max supply exceeded!");    
    _;
  }
  function _verify(bytes32 hash, bytes memory token, address signer)
      internal
      pure
      returns (bool)
  {
      return (hash.toEthSignedMessageHash().recover(token) == signer);
  }

  function verifyTokenForAddress(string calldata _salt, bytes calldata _token, address _address, uint256 _amount , address signer) internal pure returns (bool) {
      return _verify(keccak256(abi.encode(_salt, _address, _amount)), _token, signer);
  }  
    
  function mint(uint256 _mintAmount, string calldata _salt, bytes calldata _token) external payable nonReentrant mintCompliance(_mintAmount) {
    require(!paused, "Paused");
    require(cost * _mintAmount <= msg.value, "Ether value sent is not correct");
    if(usedMessages[_salt] == true)  
      revert saltAlreadyUsed();      
    if (!verifyTokenForAddress(_salt, _token, msg.sender, msg.value, _signer))
      revert InvalidSignature();    
      
    usedMessages[_salt] = true;    
    _safeMint(msg.sender, _mintAmount);
    IRoyaltyMint(royalty_contract_address).mintForAddress(_mintAmount, msg.sender);
  }
  
  function claimRoblox(string calldata _salt, bytes calldata _token) external payable nonReentrant {
    require(!paused, "Paused");
    if (!verifyTokenForAddress(_salt, _token, msg.sender, msg.value, _signer))
      revert InvalidSignature();
    usedMessages[_salt] = true;
  }

  function mintForAddress(uint256 _mintAmount, address _receiver) external nonReentrant onlyOwner {
    uint256 totalGods = totalSupply();
    require(totalGods + _mintAmount <= maxSupply, "Max supply exceeded!");
    _safeMint(_receiver, _mintAmount);
    IRoyaltyMint(royalty_contract_address).mintForAddress(_mintAmount, msg.sender);
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;
    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      address currentTokenOwner = ownerOf(currentTokenId);
      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;
        ownedTokenIndex++;
      }
      currentTokenId++;
    }
    return ownedTokenIds;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "nonexistent token"
    );

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  /**
  * @dev Returns the starting token ID.
  */
  function _startTokenId() internal view virtual override returns (uint256) {
      return 1;
  }
    
  function setRevealed(bool _state) external onlyOwner callerIsUser {
    revealed = _state;
  }


  function setCost(uint256 _cost) external onlyOwner {
    cost = _cost;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) external onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setPaused(bool _state) external onlyOwner {
    paused = _state;
  }
  
  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
  function withdraw() external onlyOwner {
    if(address(this).balance > 0) {
      (bool os, ) = payable(PROJECT_WALLET).call{value: address(this).balance}("");
      require(os);
    }
  }  

  function getMintAddresses(address _address) public view returns(uint256 [] memory){
        return mintAddresses[_address];
  }

  function _afterTokenTransfers(address from, address to, uint256 tokenId, uint256 quantity) internal override {
    if(from != address(0)) {
        TolatestTokenTransfer[to] = (tokenId+quantity)-1;
        FromlatestTokenTransfer[to] = 0;
        FromlatestTokenTransfer[from] = (tokenId+quantity)-1;
        TolatestTokenTransfer[from] = 0;
    }
    if(from == address(0)) {
      uint256 end = tokenId + quantity;
      do {
          mintAddresses[to].push(tokenId++);
      } while (tokenId < end);
    }    
  }
  function withdrawToWallet() external nonReentrant onlyOwner {
      if(address(this).balance == 0)
        revert cannotWithdraw();
      shareholders0Balance += SafeMath.mul(SafeMath.div(address(this).balance, 100), _shares[0]);        
      shareholders1Balance += SafeMath.mul(SafeMath.div(address(this).balance, 100), _shares[1]);
      Address.sendValue(payable(_shareholders[0]), shareholders0Balance);
      Address.sendValue(payable(_shareholders[1]), shareholders1Balance);
      emit PaymentReleased(_shareholders[0], shareholders0Balance);      
  }
}