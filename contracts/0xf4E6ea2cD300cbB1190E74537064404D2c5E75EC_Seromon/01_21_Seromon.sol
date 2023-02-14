// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import 'operator-filter-registry/src/DefaultOperatorFilterer.sol';

contract Seromon is ERC721AQueryable, Ownable, ReentrancyGuard, DefaultOperatorFilterer {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => uint256) public OGClaimed;
  mapping(address => uint256) public WLClaimed;
  mapping(address => uint256) public WL2Claimed;
  
  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  bool public paused = true;
  bool public OGMintEnabled = false;
  bool public WLMintEnabled = false;
  bool public WL2MintEnabled = false;
  bool public revealed = false;
  

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
    //OG Airdrops
   _safeMint(0x51d947Bd36633eB971C7b4e9eD7fe8215b965Eb0, 1);
_safeMint(0x2649f1968fB5b5B5A393a82F697c96F35920b35C, 1);
_safeMint(0x945563D08a3EF291C5E1d3fD57D119F4c9192570, 1);
_safeMint(0x3203b61dc7d5a0B61eb2FBF9A5E795B633090235, 1);
_safeMint(0x1f422D82F119b3e5660E273135a2D0Fce1c8C561, 1);
_safeMint(0xadFBC0CC593c64D68fd1c8a1B72f2DC73b65c700, 1);
_safeMint(0xbcd1784C094aDd0133513ff9473F6eF989821e14, 1);
_safeMint(0x4b00962C020a4528B8d37Ef9792Cf7E57835928d, 1);
_safeMint(0xB6F41C58614A71EcEFd43e491809624F742d3E89, 1);
_safeMint(0x0cF09F6CA8065866e9B810e064fc2ED2d83ee3ed, 1);
_safeMint(0x739C5618af58a1F474342bC556273deD404276b7, 1);
_safeMint(0x9655bFf551b67FFd3E8D4CEF8b529cC461B7Ed64, 1);
_safeMint(0x47CEb07315a624B7c48775b7cA54a9ea261B0d25, 1);
_safeMint(0x638f027e745363d27eB2B2A03C15B1c69bA4D95A, 1);
_safeMint(0x5DE51b7944c766b1CAdce299463059bdEc38C1BF, 1);
_safeMint(0xC2F1Fb024fc5ce57Bfac460d799a4314E13bEeD2, 1);
_safeMint(0x438FF821973C68Be4E419516cC817AbEe8bfb927, 1);
_safeMint(0x5e89E05ba98790F12F3DEfd336cC090aAAE71693, 1);
_safeMint(0x739cAEc4f5D085c2Fa96EaA2b1642c0995A8EbFb, 1);
_safeMint(0xf2F104344BEED2E635202eb16C8e13A59cF09495, 1);
_safeMint(0x6d4e450f902d09a9EA21A0b17a055F30dd36899A, 1);
_safeMint(0xdC419116a1F72EBbE2f75e3fB493c5bbdD43EccA, 1);
_safeMint(0x335e79eE13F7B2BBaB287193b356aEB085dD3A3c, 1);
_safeMint(0xA097d71baA9eAb44704eea9ff01081DfFd1B8E56, 1);
_safeMint(0x6A7d9F55AD22dE51285E21895cB39BE957af25d8, 1);
_safeMint(0x62F6CD51a8444d694108eb33a6f4146c32F3e237, 1);
_safeMint(0x11212242Ba29E3544b7FE2Bd18ae328914b0eC5e, 1);
_safeMint(0x92Ab39755B4B137133217f245D43c16323938Dc1, 1);
_safeMint(0x7960f148f7d2f5ffe7A80fD4F3D016d2b2396042, 1);
_safeMint(0xf18977B29C1F87F9871B8a7a5aF1e4059e39b9FE, 1);
_safeMint(0x4d4Ae94F2370D3BE1C938aC8550C4A2f26f48313, 1);
_safeMint(0x084dC098f1F6D38B821c00f0CF1a5e3f6Ba87108, 1);
_safeMint(0x67A7be6067fB0600947DcD6ABc9bE9eD12978242, 1);
_safeMint(0x0F872d4501f8960EfF99CaB1361FC1B048B0e59B, 1);
_safeMint(0x51F6A1e18E8178D24812c44755a8A5EcCf692BCA, 1);
_safeMint(0x2BD59FdAdC1cD55E28Bed07B9e7DCa15CA140388, 1);
_safeMint(0x5083E2Ae9A06CeB31AF58019B095aa8A71323181, 1);
_safeMint(0xa3A01E631B86aF6c0C3536156CD42048CbF387D0, 1);
_safeMint(0x4aff0d14853172Ef7446aea557B41B10506dAF38, 1);
_safeMint(0x36ff5e86e0021cb6f15Fe0d6c43f3aCf57f76C29, 1);
_safeMint(0x0fFfF45105270Ed5D814D6356D07F2dE67846cEf, 1);
_safeMint(0x63A86ec1004152233923A1e584DF918887Dda9A2, 1);
_safeMint(0x37EeC0a770A7Aed73f43C0098C4F297B982b933B, 1);
_safeMint(0x2A90c8BA96D0f0FC8e869C36017Ce094097fb261, 1);
_safeMint(0xc0992D8E5eEb436f84e735F17588f4ab306c11B4, 1);
_safeMint(0xBC223cafFDC843C38208E609B4824e9bE58bbff0, 1);
_safeMint(0x34e888ECbb92aBDbeD96Cb5Bbbf83D2325f48249, 1);
_safeMint(0xb7f9c016C229F43d1F2A6f79360a56C8AE15d711, 1);
_safeMint(0x7B61ec8BB6bDfF8569a2f0A476D544aB5A48B02E, 1);
_safeMint(0xC37aD3F299e1eaB848D1417620E2aBa41D0DAe89, 1);
_safeMint(0x31D6265244E3ef7f2D7e3684674657B5607a8167, 1);
_safeMint(0x9529b3D7867e9d2F2ADe65cA9358E1bF91f1bBd7, 1);
_safeMint(0xFF0E366C520b47d3E7340c4119887fEfa91116c9, 1);
_safeMint(0x136115627BC848Fd83D7b413BEBb58E80C22C0CA, 1);
_safeMint(0x24b2728A603ec4a0d11910a0D88D260E37D565f5, 1);
_safeMint(0x92535D49c82841eeFC96bc13385f52451827b192, 1);
_safeMint(0x6Bf1886924D090525529c4A8D433E2C2201204Bd, 1);
_safeMint(0xDF93B77A820570838212dB119975E2189A4Fdeb2, 1);
_safeMint(0xFa2e8A69647ad28cCE149C3256be2b3c40aD9732, 1);
_safeMint(0xf958fb8450B0ba0FC4D545A2f129F0be7f370D95, 1);
_safeMint(0x5Bf7f1552a8e2E02ab42969a267A30F927eFAd60, 1);
_safeMint(0x83F2E6adE217bFFB29B76b2f8090aC1D9aC782F0, 1);
_safeMint(0x37281E235fedE3AAED6DE7377Ec4914731c9f0aa, 1);
_safeMint(0xBb209d8F0497e7b64813a7F91960a88d182331E9, 1);
_safeMint(0x4Af3ebC691988Fc6FC4690896315564706F56Bd4, 1);
_safeMint(0x513db322a397701BF624B517B00291F82B665884, 1);
_safeMint(0xBe38cb4f2e0f46CF3Cce5E59E218dD1F4f1A6067, 1);
_safeMint(0x6B069Bfd5557289981f8e78913Ad2894B0c1dc17, 1);
_safeMint(0x5F89b80c55425FF187d134472585d37AA69DA27E, 1);
_safeMint(0x1FA0F3cE114AF23f779Dea8FDF8198B71Df0e4DF, 1);
_safeMint(0xCE0143D650e9C7C9D580a9A144939440864B6d4A, 1);
_safeMint(0x33c41E6251C694Ae868F4Fb6D5ef0143d2eECF6d, 1);
_safeMint(0x6a1A35F4E1D2C74F3805285EA346f3eC32696C54, 1);
_safeMint(0x2BdCf6de9E28a2F14105D98e0e88c65A3b6513d7, 1);
_safeMint(0x816E4566c01d9499789d54cEE384567103b25Fe5, 1);
_safeMint(0x470fC41468e1868E3C1887882e6b98F28fbf0EBa, 1);
_safeMint(0x85FDC14C1BaFBB972479b0E6A787d746E51B1f3A, 1);


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

  function OGMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
  // Verify OG requirements
  require(OGMintEnabled, 'OG Sale not enabled!');
  require(OGClaimed[_msgSender()]+_mintAmount<=5, 'Exceeding maximum allowed mint amount!');
  bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
  require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid!');

  OGClaimed[_msgSender()] = OGClaimed[_msgSender()]+_mintAmount;
  _safeMint(_msgSender(), _mintAmount);
  }
  function WLMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
  // Verify WL requirements
  require(WLMintEnabled, 'WL Sale not enabled!');
  require(WLClaimed[_msgSender()]+_mintAmount<=5, 'Exceeding maximum allowed mint amount!');
  bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
  require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid!');

  WLClaimed[_msgSender()] = WLClaimed[_msgSender()]+_mintAmount;
  _safeMint(_msgSender(), _mintAmount);
  }
   function WL2Mint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
  // Verify WL2 requirements
  require(WL2MintEnabled, 'WL2 Sale not enabled!');
  require(WL2Claimed[_msgSender()]+_mintAmount<=5, 'Exceeding maximum allowed mint amount!');
  bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
  require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid!');

  WL2Claimed[_msgSender()] = WL2Claimed[_msgSender()]+_mintAmount;
  _safeMint(_msgSender(), _mintAmount);
  }
 
  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');

    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }
  
  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'nonexistent token');

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

  function setOGMintEnabled(bool _state) public onlyOwner {
    OGMintEnabled = _state;
  }
  function setWLMintEnabled(bool _state) public onlyOwner {
    WLMintEnabled = _state;
  }
 function setWL2MintEnabled(bool _state) public onlyOwner {
    WL2MintEnabled = _state;
  } 
  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
  
    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
address private constant SeromonMain = 0x51d947Bd36633eB971C7b4e9eD7fe8215b965Eb0;

function withdrawAll() private onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0);
    _withdraw(SeromonMain, address(this).balance);
}

function _withdraw(address _address, uint256 _amount) private {
    (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
}
}