// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';

/*
                                                                                                                                                  ,----,           
                ,--.                                                                                   ,----..                                  ,/   .`|           
   ,---,      ,--.'| .--.--.     ,---,   ,---,       ,---,,-.----.    .--.--.             .--.--.     /   /   \   ,----..    ,---,   ,---,.   ,`   .'  :           
,`--.' |  ,--,:  : |/  /    '.,`--.' | .'  .' `\   ,'  .' \    /  \  /  /    '.          /  /    '.  /   .     : /   /   \,`--.' | ,'  .' | ;    ;     /     ,---, 
|   :  ,`--.'`|  ' |  :  /`. /|   :  ,---.'     \,---.'   ;   :    \|  :  /`. /         |  :  /`. / .   /   ;.  |   :     |   :  ,---.'   .'___,/    ,'     /_ ./| 
:   |  |   :  :  | ;  |  |--` :   |  |   |  .`\  |   |   .|   | .\ :;  |  |--`          ;  |  |--` .   ;   /  ` .   |  ;. :   |  |   |   .|    :     |,---, |  ' : 
|   :  :   |   \ | |  :  ;_   |   :  :   : |  '  :   :  |-.   : |: ||  :  ;_            |  :  ;_   ;   |  ; \ ; .   ; /--`|   :  :   :  |-;    |.';  /___/ \.  : | 
'   '  |   : '  '; |\  \    `.'   '  |   ' '  ;  :   |  ;/|   |  \ : \  \    `.          \  \    `.|   :  | ; | ;   | ;   '   '  :   |  ;/`----'  |  |.  \  \ ,' ' 
|   |  '   ' ;.    ; `----.   |   |  '   | ;  .  |   :   .|   : .  /  `----.   \          `----.   .   |  ' ' ' |   : |   |   |  |   :   .'   '   :  ; \  ;  `  ,' 
'   :  |   | | \   | __ \  \  '   :  |   | :  |  |   |  |-;   | |  \  __ \  \  |          __ \  \  '   ;  \; /  .   | '___'   :  |   |  |-,   |   |  '  \  \    '  
|   |  '   : |  ; .'/  /`--'  |   |  '   : | /  ;'   :  ;/|   | ;\  \/  /`--'  /         /  /`--'  /\   \  ',  /'   ; : .'|   |  '   :  ;/|   '   :  |   '  \   |  
'   :  |   | '`--' '--'.     /'   :  |   | '` ,/ |   |    :   ' | \.'--'.     /         '--'.     /  ;   :    / '   | '/  '   :  |   |    \   ;   |.'     \  ;  ;  
;   |.''   : |       `--'---' ;   |.';   :  .'   |   :   .:   : :-'   `--'---'            `--'---'    \   \ .'  |   :    /;   |.'|   :   .'   '---'        :  \  \ 
'---'  ;   |.'                '---'  |   ,.'     |   | ,' |   |.'                                      `---`     \   \ .' '---'  |   | ,'                   \  ' ; 
       '---'                         '---'       `----'   `---'                                                   `---`          `----'                      `--`  
                                                                                                                                                                   
*/

contract InsidersSociety is ERC721AQueryable, Ownable, ReentrancyGuard, ERC2981 {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => uint256) public alredyMinted;
  mapping(address => uint256) public freeMint;  

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public price;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;
  uint256 public maxMintAmountPerWallet;
  uint256 public ownersMint;
  uint256 public whitelistStart;

  bool public paused = true;
  bool public whitelistMintEnabled = true;
  bool public revealed = false;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _price,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    uint256 _maxMintAmountPerWallet,
    uint256 _ownersMint,
    uint256 _whitelistStart,
    string memory _hiddenMetadataUri,
    address _receiver,
    uint96 _royaltyNumerator
  ) ERC721A(_tokenName, _tokenSymbol) {
    setprice(_price);
    maxSupply = _maxSupply;
    setOwnersMint(_ownersMint);
    setWhitelistStart(_whitelistStart);
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setMaxMintAmountPerWallet(_maxMintAmountPerWallet);
    setHiddenMetadataUri(_hiddenMetadataUri);
    _setDefaultRoyalty(_receiver, _royaltyNumerator);
  }

  function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(alredyMinted[_msgSender()] + _mintAmount <= maxMintAmountPerWallet, 'Address will surpass the maximum amount allowed per wallet!');
    require(totalSupply() + _mintAmount <= maxSupply-ownersMint, 'Collection sold out!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    if(_mintAmount > freeMint[msg.sender]){
      require(msg.value >= price * (_mintAmount-freeMint[msg.sender]), 'Insufficient funds!');
    }
    _;
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    require(!paused, 'The contract is paused!');
    require(whitelistMintEnabled, 'The whitelist sale is not active yet!');
    require(block.timestamp >= whitelistStart, "Whitelist has not started yet");
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Proof not valid or not in the whitelist!');
    if(_mintAmount > freeMint[msg.sender]){
      freeMint[msg.sender] = 0;
    } else {
      freeMint[msg.sender] = freeMint[msg.sender]-_mintAmount;
    }
    alredyMinted[_msgSender()] += _mintAmount;
    _safeMint(_msgSender(), _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');
    require(!whitelistMintEnabled, 'The public sale is not active!');
    if(_mintAmount > freeMint[msg.sender]){
      freeMint[msg.sender] = 0;
    } else {
      freeMint[msg.sender] = freeMint[msg.sender]-_mintAmount;
    }
    alredyMinted[_msgSender()] += _mintAmount;
    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    require(ownersMint > 0, 'Owners cant mint more NFTs');
    require(_mintAmount <= ownersMint, 'Amount minteable by owners exceded');
    require(_mintAmount > 0, 'The amount must be more than 0');
    setOwnersMint(ownersMint - _mintAmount);
    _safeMint(_receiver, _mintAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override(ERC721A) returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setprice(uint256 _price) public onlyOwner {
    price = _price;
  }

  function setOwnersMint(uint256 _ownersMint) public onlyOwner {
    ownersMint = _ownersMint;
  }

  function setWhitelistStart(uint256 _whitelistStart) public onlyOwner {
    whitelistStart = _whitelistStart;
  }

  function addFreemintAddress(address _adr, uint256 _amount) public onlyOwner {
    freeMint[_adr] = _amount;
  }

  function addFreemintAddresses(address[] memory _adrs, uint256[] memory _amounts) public onlyOwner {
    for(uint256 i = 0; i < _adrs.length; i++){
      freeMint[_adrs[i]] = _amounts[i];
    }    
  }

  function removeFreemintAddress(address _adr) public onlyOwner {
    freeMint[_adr] = 0;
  }

  function removeFreemintAddresses(address[] memory _adrs) public onlyOwner {
    for(uint256 i = 0; i < _adrs.length; i++){
      freeMint[_adrs[i]] = 0;
    }   
  }

  function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) public onlyOwner {
      _setDefaultRoyalty(_receiver, _feeNumerator);
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setMaxMintAmountPerWallet(uint256 _maxMintAmountPerWallet) public onlyOwner {
    maxMintAmountPerWallet = _maxMintAmountPerWallet;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function isInWhitelist(address _adr, bytes32[] calldata _merkleProof) public view  returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(_adr));
    bool isWl = MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    return isWl;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
    // This will transfer the remaining contract balance to the owner.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool success, ) = payable(owner()).call{value: address(this).balance}('');
    require(success);
    // =============================================================================
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}