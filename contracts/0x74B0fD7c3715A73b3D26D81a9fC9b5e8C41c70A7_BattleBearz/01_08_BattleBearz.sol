// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract BattleBearz is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
 
  uint256 public maxSupply = 5555;
  uint256 public maxPublicMintAmountPerTx = 2; // Stays public
  uint256 public maxTeamMintAmountPerWallet = 3; // Change to Team whitelist
  uint256 public maxWhitelistMintAmountPerWallet = 2; // Change to Whitelist

  uint256 public publicMintCost = 0 ether;
  uint256 public teamMintCost = 0 ether;
  uint256 public whitelistMintCost = 0 ether;

  bytes32 public merkleRoot1;
  bytes32 public merkleRoot2;
  bool public paused = true;
  bool public teamMintEnabled = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;

  constructor(
      string memory _tokenName, 
      string memory _tokenSymbol, 
      string memory _hiddenMetadataUri)  ERC721A(_tokenName, _tokenSymbol)  {
    hiddenMetadataUri = _hiddenMetadataUri;       
    ownerClaimed();
   
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  function teamMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) {
    require(teamMintEnabled, 'The team sale is not enabled!');
    require(_numberMinted(_msgSender()) + _mintAmount <= maxTeamMintAmountPerWallet, 'Max limit per wallet!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot1, leaf), 'Invalid proof for team member!');

    _safeMint(_msgSender(), _mintAmount);
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) {
    
    require(whitelistMintEnabled, 'The whitelist is not enabled!');
    require(_numberMinted(_msgSender()) + _mintAmount <= maxWhitelistMintAmountPerWallet, 'Max limit per wallet!');
   
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot2, leaf), 'Invalid proof for whitelist!');

    _safeMint(_msgSender(), _mintAmount);
  }

  function publicMint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) nonReentrant {
    require(!paused, 'The mint is paused!');
    require(_mintAmount <= maxPublicMintAmountPerTx, 'Max limited per Transaction!');
    _safeMint(_msgSender(), _mintAmount);
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

  function setMaxPublicMintAmountPerTx(uint256 _maxPublicMintAmountPerTx) public onlyOwner {
    maxPublicMintAmountPerTx = _maxPublicMintAmountPerTx;
  }

  function setMaxTeamMintAmountPerWallet(uint256 _maxTeamMintAmountPerWallet) public onlyOwner {
    maxTeamMintAmountPerWallet = _maxTeamMintAmountPerWallet;
  }

  function setMaxWhitelistMintAmountPerWallet(uint256 _maxWhitelistMintAmountPerWallet) public onlyOwner {
    maxWhitelistMintAmountPerWallet = _maxWhitelistMintAmountPerWallet;
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

  function setMerkleRoot1(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot1 = _merkleRoot;
  }

  function setMerkleRoot2(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot2 = _merkleRoot;
  }

  function setTeamMintEnabled(bool _state) public onlyOwner {
    teamMintEnabled = _state;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

  function withdraw() public onlyOwner {
  
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  address constant Address1 = 0x2cd98D640F570916Dc19De33dFED43a13f3Fa7f9; 
  address constant Address2 = 0x00e38dDcbd8E58a8D49eaFBE16b11cb8842c3B9a; 
  address constant Address3 = 0x9Df3a93A502Fdc6bC2a759D978D182C2353279a3;
  address constant Address4 = 0x91AE4fC1A176e5F4E2b21f655d7391b61b57e2ef;  
  address constant Address5 = 0xb4FAfACA3780dF9928dC26e4DA9bdb28B5949855;
  address constant Address6 = 0x62B3D7C811254eEA5905e56ED3Cf0B00CD655f1e;
  address constant Address7 = 0x43E8a1759995D1240D1D6f3896c801b14ADBa9da; 
  address constant Address8 = 0x47734B0f659e8fCee5ADd2f4D29f50E09D232BF0; 
  address constant Address9 = 0x6eeF5898826F1925f06e633743b23Bf0683Db3F6; 
  address constant Address10 = 0x3f1e358784D0aBdb88D880f3B451332FbCbB34B3;
  address constant Address11 = 0xeD28AF504dC907600dCBe4bb7814C812e70671BE; 
  address constant Address12 = 0x9268237f8acCc682026b0b9B3E76d1B613817466;
  address constant Address13 = 0x1F894Cd977A23a37F5031175DCC9faA8dfb871D4;
  address constant Address14 = 0x6E0BF0D25F84cd8A36763355070b63aD8DeC3a7a;
  address constant Address15 = 0x9Fc96c63E9Fb9596c0100d1a3528A46109Fded6d;
  address constant Address16 = 0xA3447da1B58de4D7fE32d75de5DA6be21Ea0b14a;
  address constant Address17 = 0x778c538A014CC741Fb3D09200E2138B88156720A;
  address constant Address18 = 0xa495FB3EF5Ad8323ebE5B369f81785DB8236E018;
  address constant Address19 = 0x976bc4E3ADE2e8E3bE3901dB731B5B92720AeD92;
  address constant Address20 = 0xbeEa49fD389fC2b89705b9Db12001227BA7072fe;
  address constant Address21 = 0x9e85280CB47aE823Ff1d817E8bc969fc08ABA6fB;
  address constant Address22 = 0xE1a528Bf5EA0594DA3C596Fc95Ed6dcb239E6885;
  address constant Address23 = 0x56A16C11DCEd05B6cC129A526c644Ff93E7a3d0c;
  address constant Address24 = 0x9661F77fe895F8936558F3AF950229BB062256F5;
  address constant Address25 = 0x503524A6d99196Eb5CC8d92b7e8F89DeA26878B9;
  address constant Address26 = 0x44a82b1C154C7b6e4beB9884Db4F01Dbf040E877;
  address constant Address27 = 0x90A1B6586001b534c9031281b119B279dD447e4B;
  address constant Address28 = 0x8cCdf543A307CeA0288e1736f8bBf2442ca8Cf9C;
  address constant Address29 = 0x274F2946D33a9Ae97bDE423f27C7915765EAE8f1;
  address constant Address30 = 0x6d9ed472Da62B604eD479026185995889ae8f80e;
  address constant Address31 = 0xf35E516367d346191b56cD96821BFEcB11CF9348;
  address constant Address32 = 0x68f0FAA81837D10aaF23974fa0CEb40220717f4e;

  function ownerClaimed() internal {
    _mint(Address1, 100);
    _mint(Address2, 100);
    _mint(Address3, 100);
    _mint(Address4, 50);
    _mint(Address5, 50);
    _mint(Address6, 33);
    _mint(Address7, 27);
    _mint(Address8, 33);
    _mint(Address9, 117);
    _mint(Address10, 50);
    _mint(Address11, 18);
    _mint(Address12, 33);
    _mint(Address13, 99);
    _mint(Address14, 45);
    _mint(Address15, 60);
    _mint(Address16, 36);
    _mint(Address17, 18);
    _mint(Address18, 18);
    _mint(Address19, 18);
    _mint(Address20, 18);
    _mint(Address21, 18);
    _mint(Address22, 21);
    _mint(Address23, 60);
    _mint(Address24, 36);
    _mint(Address25, 9);
    _mint(Address26, 12);
    _mint(Address27, 12);
    _mint(Address28, 12);
    _mint(Address29, 50);
    _mint(Address30, 50);
    _mint(Address31, 50);
    _mint(Address32, 50);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}