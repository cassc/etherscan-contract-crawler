// SPDX-License-Identifier: MIT

// https://chillcowboy.com/terms-of-service
// https://chillcowboy.com/privacy-policy

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "@openzeppelin/contracts/access/AccessControl.sol";


contract ChillCowboyCountryClub is ERC721A, Ownable, ReentrancyGuard, AccessControl {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  string public contractUri = '';
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;
  address public allocator = 0x6d60bcb2b706123581D02D04c8F8944943A60e80;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri,
    string memory _contractUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    cost = _cost;
    maxSupply = _maxSupply;
    maxMintAmountPerTx = _maxMintAmountPerTx;
    setContractUri(_contractUri);
    setHiddenMetadataUri(_hiddenMetadataUri);
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _safeMint(0x21e61bD4104D011583531b32e85682f60788B751,	128);
    _safeMint(0xc18707eC6B1f763edA086A47a300bEE3DE318135,	64);
    _safeMint(0xF30FcFCd8857D40AF365115618D9BFc2EE435DB1,	64);
    _safeMint(allocator,	40);
    _safeMint(0xFbF7bC165bf2e7C7893e58CDaEE56f89b4a875fE,	12);
    _safeMint(0x6106164e2A35AAa5FCDf4734b25a09b275418b41,	10);
    _safeMint(0xBa845adeC0674d903f79F0FF276cfEa04562a6D4,	10);
    _safeMint(0x03Da6156D709b047aEeC6040A1E15D5cb08E21e8,	9);
    _safeMint(0x944058f8aCFe430C40CAEC46817f319Ce74eD78a,	9);
    _safeMint(0xc18707eC6B1f763edA086A47a300bEE3DE318135,	6);
    _safeMint(0x583257dCA4145Af46A780063122d370526Bd5061,	5);
    _safeMint(0x224c59dd5a6F416c41236D9F045464D86a28eBD3,	5);
    _safeMint(0xd5A53ee641abb6813A09eDa4D28AF96B9cBd4aA9,	5);
    _safeMint(0xE23f5E28706355E41049F31Fb6aa4F0F32645b35,	5);
    _safeMint(0xe63cbe0776086c5c10739c3797C43B32a4A3574A,	4);
    _safeMint(0x94Cb91F19C4B03c8085349a9ACbBAFb95741A5F2,	4);
    _safeMint(0x3470151D1c87597623E53FaE98E4Bc585e6cC709,	4);
    _safeMint(0x03Da6156D709b047aEeC6040A1E15D5cb08E21e8,	3);
    _safeMint(0xF30FcFCd8857D40AF365115618D9BFc2EE435DB1,	3);
    _safeMint(0x71891284765892F3eA992BFB5C892F6bbB971192,	3);
    _safeMint(0xF30FcFCd8857D40AF365115618D9BFc2EE435DB1,	2);
    _safeMint(0x62BE58D22e22a97997De01B3BD2cd4e87e6011B7,	2);
    _safeMint(0xB68437998797ED409BEae4df728358e2Cf61689D,	2);
    _safeMint(0xa72c277a20c99Ec7Dc0E169a3288ef2c0691ae94,	2);
    _safeMint(0x6525f0c77B6E6a7962937892ACFDb4296eA0F0B5,	2);
    _safeMint(0x0538738FD1597A0B116c729c7dc94399bE509d80,	2);
    _safeMint(0x7f2a6FA93dBBC5e83E6020f53a179b4F2E1e5847,	2);
    _safeMint(0x6677EA229419c9dc3A1c5009204A2Cfa8938f1bf,	2);
    _safeMint(0x8c0Ec92A6c2d5d1a0088C2758214244CeAA314cb,	2);
    _safeMint(0x9558aC004490166dB0930d338E9b983b147e9997,	2);
    _safeMint(0x8d4Ed7a85C5D818275680f41D3867bd5d8B9048E,	2);
    _safeMint(0x8751c2e643235D250f03feB5ff499d9f7f2d0510,	2);
    _safeMint(0xe6A995063b6fde7692D0C8e71349012c47c313D0,	2);
    _safeMint(0x99e3090B28523307a1A0262b6cD8d55a2330E1ba,	2);
    _safeMint(0x51AB993b99cB0D519359F806D510B093B655ebAc,	2);
    _safeMint(0x03FB33218e2C393A5816057C3ba24648A1263802,	2);
    _safeMint(0x3207BD78b64BE49977e87b035c3562C05EF51e40,	2);
    _safeMint(0x4cB18230e33b9a7217dafb5BB5476c193F7ab684,	2);
    _safeMint(0x80B3fFe911693cF3b542e872996F723FD553A634,	2);
    _safeMint(0x403764296de2084e9A09DE3e67c85C934DC198C1,	2);
    _safeMint(0x27385Bc9a62bBC81Af2d791c83AA5E289a91b5Ec,	2);
    _safeMint(0x26012dE2EFEae02fE05D66f6bDB1C86352b71e75,	1);
    _safeMint(0x6Cc69282E914B1565fd18efD547D2F54629696C6,	1);
    _safeMint(0xE1E28B6066434fb3002077c48941815Dc09E6187,	1);
    _safeMint(0x4f0a28730321BDdb4bD29b0cE8aDf130052dA5Ce,	1);
    _safeMint(0xFCa3928aFdf16E39A0e7E8230C76f4C6C6483695,	1);
    _safeMint(0x5c45bd975898587820201E77e3D5B21F2B96597a,	1);
    _safeMint(0x3dF05b7473bd246ab9aa8Ea9D72945dDF6e6Cd21,	1);
    _safeMint(0xc9F5D74D663CD58E21c9486203dF70Fd8bcb96FB,	1);
    _safeMint(0x6c97b22D070b0681a38E30fb4019a5750FAa60A6,	1);
    _safeMint(0x4277E2416a2ACe9E829DBF6AC9299Ccd663A51C3,	1);
    _safeMint(0xb8F3A399ADC636dbc909A005065761efcf4E68C2,	1);
    _safeMint(0x8751c2e643235D250f03feB5ff499d9f7f2d0510,	1);
    _safeMint(0xaeD614DDF1E206C4b16A4A2Ab7FdDf3B402b5D33,	1);
    _safeMint(0x516DAE1d96A9A0aA6518f278f305dEeA454f5D97,	1);
    _safeMint(0xc3f51beF024796efa428e0B5CbF229Cc8b353647,	1);
    _safeMint(0xD25218d576A5770EB1B0f1336724427e24645F87,	1);
    _safeMint(0xa13132692f42742F1DF86072640a95FDe0a28B1e,	1);
    _safeMint(0x7647Af05e5fCe0e3D7AfC81A9Fa23baA5697E736,	1);
    _safeMint(0x3334d924EcFacE8D85d7002e57B503DCF1D333ab,	1);
    _safeMint(0xFC7CE07a7C4AD643fc978C9e7C2C299E42f00e79,	1);
    _safeMint(allocator,	1);
    _safeMint(0x9618F89B2C3b9A1650ae3f927e7F7C06A59B783E,	1);
    _safeMint(0x950737848b7559D8Cd3FeFe8ac6Df3D1EE1A5CAa,	1);
    _safeMint(0x79e12778FCf392c4f066a6f21BbF99175998B9e6,	1);
    _safeMint(0xb8B3a784040213E2099F26D96601D2EE44db90F2,	1);
    _safeMint(0x142279c6e1dfEB3437D938Bc2Ce6ccC2624A4391,	1);
    _safeMint(0xB13535f3C5987325382dAcAE8e364423B733004C,	1);
    _safeMint(0x0D5aB61E00669835762bdE200097e2C8c865Cd07,	1);
    _safeMint(allocator,	1);
    _safeMint(0x6820D9ad15326e3C346BA380f7f4025672617b71,	1);
    _safeMint(0x73aCea05ef05dD3DAc25C02C92fA4D30D87e6870,	1);
    _safeMint(allocator,	1);
    _safeMint(0x090A006ddD3d1993f7479739B28e9FC7731cc7Ed,	1);
    _safeMint(0x3CCe10EdDE086690fE122fc2F84B3DA8C8961FA3,	1);
    _safeMint(0xED5cc9F2B83292daD83648b4c7ed272F51178484,	1);
    _safeMint(0x8E7Fcd17bC8f736C12f37BBBcF1452C169d3cb08,	1);
    _safeMint(0x634868537C500856b54bd8d0440496b8028a0d3E,	1);
    _safeMint(0x789617FE7DC9D1e12F43A6cA53a6e4ecD669059F,	1);
    _safeMint(0x373e4eaaDA9c21Ea8020004853F9E28361C68422,	1);
    _safeMint(0x4c0d9ECAAEF5Bf70EeEc2F96BB738321b51522F2,	1);
    _safeMint(0x129a2284D41898034528B321ec304cDE1d0673fB,	1);
    _safeMint(0xd3529136d548A49129A870df5A5582b76c7756D2,	1);
    _safeMint(0x4c0d9ECAAEF5Bf70EeEc2F96BB738321b51522F2,	1);
    _safeMint(0xb1A0F37ebb38f97020DA806176c8DD71e1Ca10cC,	1);
    _safeMint(0xBfFa9b84a8F7638bCC04370F177254eb9466feA6,	1);
    _safeMint(0xFF15dDD20D45d04794F343100cF35a12d81F50D6,	2);
    _safeMint(0x3dF5C263CDb33ADaa7dBF0bf8F46A6BF99d53909,	2);
    _safeMint(0x61BEB9877DBBa49CF18C252E5A62B72648F1358F,	2);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721A) returns (bool) {
      return
          interfaceId == type(IERC721).interfaceId ||
          interfaceId == type(IERC721Metadata).interfaceId ||
          interfaceId == type(AccessControl).interfaceId ||
          super.supportsInterface(interfaceId);
  }

  // Access Control
  function isAdmin(address account) public virtual view returns(bool)
  {
    return hasRole(DEFAULT_ADMIN_ROLE, account);
  }

  modifier onlyAdmin() {
    require(isAdmin(msg.sender), "AccessControl: Restricted to admins!");
      _;
  }

  function addAdmin(address account) public virtual onlyAdmin
  {
    grantRole(DEFAULT_ADMIN_ROLE, account);
  }

  /**
  * @dev Removes address from DEFAULT_ADMIN_ROLE. If all admins are removed it will not be possible to call
  * `onlyAdmin` functions anymore. including: addAdmin, mintForAddress
  */
  function removeAdmin(address account) public virtual onlyAdmin
  {
    revokeRole(DEFAULT_ADMIN_ROLE, account);
  }

  // Access Control End

  // OpenSea https://docs.opensea.io/docs/contract-level-metadata  
  function contractURI() public view returns (string memory) {
      return contractUri;
  }

  function setContractUri(string memory _contractUri) public onlyOwner {
    contractUri = _contractUri;
  }
  // OpenSea End

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
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyAdmin {
    _safeMint(_receiver, _mintAmount);
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = _startTokenId();
    uint256 ownedTokenIndex = 0;
    address latestOwnerAddress;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      TokenOwnership memory ownership = _ownerships[currentTokenId];

      if (!ownership.burned && ownership.addr != address(0)) {
        latestOwnerAddress = ownership.addr;
      }

      if (latestOwnerAddress == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
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