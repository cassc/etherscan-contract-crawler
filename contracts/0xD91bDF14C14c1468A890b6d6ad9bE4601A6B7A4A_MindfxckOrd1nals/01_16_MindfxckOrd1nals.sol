//                                           ;              ,                                    
//                                           ED.            Et                                   
//                            L.             E#Wi           E#t                      .,G:        
//                        t   EW:        ,ft E###G.         E##t                    ,WtE#,    :  
//             ..       : Ej  E##;       t#E E#fD#W;        E#W#t                  i#D.E#t  .GE  
//            ,W,     .Et E#, E###t      t#E E#t t##L       E#tfL.   :KW,      L  f#f  E#t j#K;  
//           t##,    ,W#t E#t E#fE#f     t#E E#t  .E#K,     E#t       ,#W:   ,KG.D#i   E#GK#f    
//          L###,   j###t E#t E#t D#G    t#E E#t    j##f ,ffW#Dffj.    ;#W. jWi:KW,    E##D.     
//        .E#j##,  G#fE#t E#t E#t  f#E.  t#E E#t    :E#K: ;LW#ELLLf.    i#KED. t#f     E##Wi     
//       ;WW; ##,:K#i E#t E#t E#t   t#K: t#E E#t   t##L     E#t          L#W.   ;#G    E#jL#D:   
//      j#E.  ##f#W,  E#t E#t E#t    ;#W,t#E E#t .D#W;      E#t        .GKj#K.   :KE.  E#t ,K#j  
//    .D#L    ###K:   E#t E#t E#t     :K#D#E E#tiW#G.       E#t       iWf  i#K.   .DW: E#t   jD  
//   :K#t     ##D.    E#t E#t E#t      .E##E E#K##i         E#t      LK:    t#E     L#,j#t       
//   ...      #G      ..  E#t ..         G#E E##D.          E#t      i       tDj     jt ,;       
//            j           ,;.             fE E#t            ;#t                                  
//        :                ED.             , L:              :;                                  
//       t#,               E#Wi            L.                                                   .
//      ;##W.   j.         E###G.          EW:        ,ft                          i           ;W
//     :#L:WE   EW,        E#fD#W;         E##;       t#E            ..           LE          f#E
//    .KG  ,#D  E##j       E#t t##L     jt E###t      t#E           ;W,          L#E        .E#f 
//    EE    ;#f E###D.     E#t  .E#K,  G#t E#fE#f     t#E          j##,         G#W.       iWW;  
//   f#.     t#iE#jG#W;    E#t    j##f E#t E#t D#G    t#E         G###,        D#K.       L##Lffi
//   :#G     GK E#t t##f   E#t    :E#K:E#t E#t  f#E.  t#E       :E####,       E#K.       tLLG##L 
//    ;#L   LW. E#t  :K#E: E#t   t##L  E#t E#t   t#K: t#E      ;W#DG##,     .E#E.          ,W#i  
//     t#f f#:  E#KDDDD###iE#t .D#W;   E#t E#t    ;#W,t#E     j###DW##,    .K#E           j#E.   
//      f#D#;   E#f,t#Wi,,,E#tiW#G.    E#t E#t     :K#D#E    G##i,,G##,   .K#D          .D#j     
//       G#t    E#t  ;#W:  E#K##i      E#t E#t      .E##E  :K#K:   L##,  .W#G          ,WK,      
//        t     DWi   ,KK: E##D.       tf, ..         G#E ;##D.    L##, :W##########Wt EG.       
//                         E#t                         fE ,,,      .,,  :,,,,,,,,,,,,,.,         
//                         L:                           ,                                        



















// SPDX-License-Identifier: MIT 
pragma solidity >=0.8.9 <0.9.0;
import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
contract MindfxckOrd1nals is ERC721AQueryable, Ownable, ReentrancyGuard {
  using Strings for uint256;
  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;
  string public ORD1NAL_MAX_SUPPLY = '444';
  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;

  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;
  uint256 public gatherHolderWallets;

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;
  bool public ordinalDropped = false;


  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setHiddenMetadataUri(_hiddenMetadataUri);
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

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');

    _safeMint(_msgSender(), _mintAmount);
  }
  
  function safemint(uint256 _mintAmount, address _receiver) public onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
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

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }
  
  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
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

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
    // This will transfer the remaining contract balance to the owner.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
    // =============================================================================
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}