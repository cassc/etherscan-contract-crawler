// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {UpdatableOperatorFilterer} from "operator-filter-registry/src/UpdatableOperatorFilterer.sol";
import {RevokableDefaultOperatorFilterer} from "operator-filter-registry/src/RevokableDefaultOperatorFilterer.sol";
import "./ERC721R.sol";

contract ForeverPunks is ERC721r, ERC2981, Ownable, ReentrancyGuard, RevokableDefaultOperatorFilterer {
  using Counters for Counters.Counter;
  using Strings for uint256; //allows for uint256var.tostring()

  uint256 public MAX_MINT_PER_WALLET_SALE = 35;
  uint256 public price = 0.0088 ether;

  string private baseURI;
  bool public holdersMintEnabled = false;
  bool public whitelistMintEnabled = false;
  bool public mintEnabled = false;

  mapping(address => uint256) public users;
  mapping(address => bool) public whitelist;
  mapping(address => uint256) public holders;

  constructor() ERC721r("ForeverPunks", "FPUNK", 10_000) {
    _setDefaultRoyalty(0x57C0C7E8b0fF7c1A6ae26d6e526A6e4C45cEa3e6, 690);

    addWhitelistedAddresses();
    addHolderAddresses();
  }

  function calculatePrice(uint256 _amount) public view returns (uint256) {
    if (_amount < 10) {
      return price * _amount;
    } else if (_amount >= 10 && _amount < 30) {
      return price * (_amount - 1);
    } else {
      // 30 or more minting
      return price * (_amount - 5);
    }
  }

  function mintWhitelist(uint256 _amount) public payable {
    require(whitelistMintEnabled, "Whitelist sale is not enabled");
    require(whitelist[msg.sender] || holders[msg.sender] >= 0, "Wallet is not whitelisted");
    require(calculatePrice(_amount) <= msg.value, "Not enough ETH");

    users[msg.sender] += _amount;
    _mintRandomly(msg.sender, _amount);
  }

  function mintHolder(uint256 _amount) public {
    require(holdersMintEnabled, "Holder sale is not enabled");
    require(
      _amount <= holders[msg.sender],
      "Exceeds max mint holder limit per wallet");

    holders[msg.sender] -= _amount;
    _mintRandomly(msg.sender, _amount);
  }

  function mintSale(uint256 _amount) public payable {
    require(mintEnabled, "Sale is not enabled");
    require(calculatePrice(_amount) <= msg.value, "Not enough ETH");

    users[msg.sender] += _amount;
    _mintRandomly(msg.sender, _amount);
  }

  /// ============ INTERNAL ============
  function _mintRandomly(address to, uint256 amount) internal {
    _mintRandom(to, amount);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  /// ============ ONLY OWNER ============
  function setBaseURI(string calldata _newBaseURI) external onlyOwner {
    baseURI = _newBaseURI;
  }

  function toggleWhitelistSale() external onlyOwner {
    whitelistMintEnabled = !whitelistMintEnabled;
  }

  function toggleHolderSale() external onlyOwner {
    holdersMintEnabled = !holdersMintEnabled;
  }

  function togglePublicSale() external onlyOwner {
    mintEnabled = !mintEnabled;
  }

  function setMaxMintPerWalletSale(uint256 _limit) external onlyOwner {
    require(MAX_MINT_PER_WALLET_SALE != _limit, "New limit is the same as the existing one");
    MAX_MINT_PER_WALLET_SALE = _limit;
  }

  function setPrice(uint256 price_) external onlyOwner {
    price = price_;
  }

  function setRoyalty(address wallet, uint96 perc) external onlyOwner {
    _setDefaultRoyalty(wallet, perc);
  }

  function setWhitelist(address wallet, bool canMint) external onlyOwner {
    whitelist[wallet] = canMint;
  }

  function setHolder(address wallet, uint96 _amount) external onlyOwner {
    holders[wallet] = _amount;
  }

  function reserve(address to, uint256 tokenId) external onlyOwner {
    require(_ownerOf(tokenId) == address(0), "Token has been minted.");
    _mintAtIndex(to, tokenId);
  }

  function withdraw() external onlyOwner {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  /// ============ ERC2981 ============
  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721r, ERC2981) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {ERC721-_burn}. This override additionally clears the royalty information for the token.
   */
  function _burn(uint256 tokenId) internal virtual override {
    ERC721r._burn(tokenId);
    _resetTokenRoyalty(tokenId);
  }

  /// ============ OPERATOR FILTER REGISTRY ============
  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
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

  function owner() public view override(UpdatableOperatorFilterer, Ownable) returns (address) {
    return Ownable.owner();
  }

  function addWhitelistedAddresses() internal {
    whitelist[0x5881513A30cec2C84D61166b258b04789a92d9e4] = true;
    whitelist[0xfeD79641f2f8AEca217a25a57bf9dA1B0cca3575] = true;
    whitelist[0x8eB514633F8fC1aEE4B405F8165f3EEb42826F6d] = true;
    whitelist[0x75671888fD4090FbE05bD130aB8999E72e21B7c0] = true;
    whitelist[0x2dAe7853C288473546BA4fEb957070f0E5e6FDd4] = true;
    whitelist[0x327b84fcA0b85f30175729C5806Bf2faea59446F] = true;
    whitelist[0x9774F8c06aDC0209f14d77aA41f1f8bBa1fF939A] = true;
    whitelist[0xF29240b873b77EC51a9B09329Ae750237eebc197] = true;
    whitelist[0xC20E05e3C514EfbBD1734e875147260b68b31c5E] = true;
    whitelist[0xA8b31BDC10585aDBFd78443584759f979F4c90ac] = true;
    whitelist[0xA5D4A2c359C958C0530E37d801e851f7b7F7D69c] = true;
    whitelist[0x1bD7730ce07ABb27F9E1Cd6fe73eC723e2a043A6] = true;
    whitelist[0x0ebe58070fF62D4df79D5363b32126EC14e73F32] = true;
    whitelist[0x0EAedcC200f7ADC3fc19AEE6d03615A7F4896047] = true;
    whitelist[0x93a324461459F9d05e254f5E2280EC954Ad37F41] = true;
    whitelist[0x92Fc22c73E0Fc9C330d65Bc35FC5a0e341E490F7] = true;
    whitelist[0x470A6671329a9DD986F1fE5Ffc03d59D3E69Fb38] = true;
    whitelist[0xe795D84c17913E9217b10621f0eA1d543EF8c604] = true;
    whitelist[0xC1e6902198bA29B5A79f11CC8Dd66692957218E0] = true;
    whitelist[0xcfb3AdAc1F63fCaE9b9c559aFd60fD2D6B52008E] = true;
    whitelist[0x899bFF3d1A3592DcbbA5Fe11ff230cb87539c5C5] = true;
    whitelist[0xa0FE4628dFFb4C9e751148cf909aECf67E3AB198] = true;
    whitelist[0xe0957DD9da46a421f06af4437dDbde19394E9cB3] = true;
    whitelist[0x8160DEeDe29fFDf6248809D2962B4a17b4f2E1BA] = true;
    whitelist[0xeaE9b59AcfBa111B7792E1a50B581F28c9c6d387] = true;
    whitelist[0xFe231A4581AE7D1420eF3a63795736b85B3F32d6] = true;
    whitelist[0xAB5f3586E0552d6dd96b54eF6ee0cC62A27628A6] = true;
    whitelist[0xAb7654552f6FA96501336854aD96C2257105c9c9] = true;
    whitelist[0x90204beACaCB2D585a8628a33BCDF23A27150c56] = true;
    whitelist[0x6B67623ff56c10d9dcFc2152425f90285fC74DDD] = true;
    whitelist[0x8450Ea347024d5b4F6bF8F0279feC174f8DC9375] = true;
    whitelist[0x76e30FA74a2387A434c613B6946D838C12393382] = true;
    whitelist[0x25B91Dcc2397CBd5e326E336faF652dAb897A882] = true;
    whitelist[0x42E0492613eb391d0f1d736D37E0DFCe66665939] = true;
    whitelist[0xCa9EFC20c129853E134f74d3c3249305bB387EFd] = true;
    whitelist[0xF40E6ef9Cfb2135f9DC3788AaAd1e4e008bA776F] = true;
    whitelist[0xBDaD4e473B1Ea1aD59Ac7034368305367BAAB0df] = true;
    whitelist[0xE920Ba2D30e812fCb02004B0253ebe168c623C66] = true;
    whitelist[0x1aBCf617CAE0a686054b95E1720b34235C3a2500] = true;
    whitelist[0xFd12EE8EE98f57d046A53D07e0B655bE5F865C4F] = true;
    whitelist[0xe1ee9E80E9CF310aef6669E8A200De68fa16258E] = true;
    whitelist[0xaf4A98251650054dEd2275dfF736cB86CbF82AeF] = true;
    whitelist[0xEE8dBE16568254450d890C1CB98180A770e82724] = true;
    whitelist[0x6113812dc9e1Ca33b18dc169f3d8bFE2Ae18ba10] = true;
    whitelist[0x525A738a85125FaA8D4e4221d58Bef1fde4a2A2d] = true;
    whitelist[0x2A8Bf5A552347012E1C82Fa3284277bf456A0Ca9] = true;
    whitelist[0xA32B7797eC0D58B8d1293Cd4b8fdD6952FF6a5d3] = true;
    whitelist[0xE537c862B36A670CAdD8d0B34f9C97a941c363F7] = true;
    whitelist[0x69392F1d58BcbD6b181FDf68f3dA89fDB7beA0e0] = true;
    whitelist[0x043C419888A9912e9d85326f326e6f89145732aF] = true;
    whitelist[0x355Ef9a820Dc10773ad66e0f01f59C14948C7921] = true;
    whitelist[0x2Bf201CA17F53CB16e66526Ac073595E206Fe656] = true;
    whitelist[0x802D6cD1650a4418D262b2C3040E4e7a6E30C563] = true;
    whitelist[0xB9013220fc3ef41E8Ac53274B463D8d595ae81c0] = true;
    whitelist[0x1Ff5fD0c5A7Fc3c74Ab2E407e23ED0855Ee20697] = true;
    whitelist[0xB886E39046561F0D3Fcf9A3057c3FAff3FbbDD1C] = true;
    whitelist[0x32F2895b0b5F00fF53EC6279F02876a6cABC3c85] = true;
    whitelist[0x33Bb477E9286ca2fFA2E4584f1a58D894A9326D2] = true;
    whitelist[0xE92f5a12D7BeC3C586C7127d64e89f5ee13d292F] = true;
    whitelist[0xe69fd96BC32B090dB80C1b2C4aB0C6B280cEd656] = true;
    whitelist[0x6358845902610dcF1aFFCbC8B8dFa89830eB7Bcf] = true;
    whitelist[0x816A4A7Db3F04a4Fe7C96bFB1692C7D8698821Ed] = true;
    whitelist[0xCbB28523892a7b0E53927569108e6281C7A26A01] = true;
    whitelist[0x2F631b5190ba4e1879E5B2Ca494c0A87914D9296] = true;
    whitelist[0xF7EfF0CF3E09809da959FA8B163239697259bAFf] = true;
    whitelist[0x3De5a1343324b8BeaE954df867563fDa750004b9] = true;
    whitelist[0x20bb3f80a00341B40f8A90A787b31D575FBC4240] = true;
    whitelist[0xBF0E8949b153DF206088a4C4534715e5219787c2] = true;
    whitelist[0x9FF1d6681508243f9C78C3e4629841BADf7C324b] = true;
    whitelist[0x6144f73C63f5683035e2417baD46374eCe916260] = true;
    whitelist[0xF6269f7Ac21fa56e2bb5B6ABdE67A7040e6F3937] = true;
    whitelist[0x8B200E05047800b0845BCc2ABE08A73AB7946e1c] = true;
    whitelist[0xa10d998F221C2deCD8209277edAad0DAf91654b0] = true;
    whitelist[0xb8a5f175D3868717C2826FA28Ab351870Ab6AB19] = true;
    whitelist[0x81A2DE75C2b324F4d330978349465097BFbB62C3] = true;
    whitelist[0x32F2895b0b5F00fF53EC6279F02876a6cABC3c85] = true;
    whitelist[0xc320E1d56521cF7Bd3D4553B5A1d3a1885298DEe] = true;
    whitelist[0x1641d72805ec0753CE1DBcF3de48E9AD2c1adACC] = true;
    whitelist[0xb78C5F9E3dce3A03d8E086BE52F0367C90eF000a] = true;
    whitelist[0x0afB2649bB2D986e48Ea28e4b4B68Cd94727cD33] = true;
    whitelist[0xFD431Cf4e3A763251f16eC64a2901F842532bb37] = true;
    whitelist[0x843F7C1561DE5a41b94A467496648BCAbad82ABb] = true;
    whitelist[0xDeFA5675CDf2c7482AcEC6A16626D14941F0ACbE] = true;
    whitelist[0xf9d056B6f6b34997e0eE0739Ee5CDAF7E9E40033] = true;
    whitelist[0x7f290cE2Acc8058Bc625870BcB262876A92394B4] = true;
    whitelist[0x8007CB96f8e2B554848EEEf264d0374997f01eF3] = true;
    whitelist[0x098b995b093140565724ED5Be5004FD8a1d0979a] = true;
    whitelist[0x811Da71B116A8FD6200256A1D579F8255cAdACB3] = true;
    whitelist[0xa2a5840165a163DB4b291Ade9B2aE5b083bFA22b] = true;
    whitelist[0x9DA3AE635d01adadA305D8F8f960b6811CcA41b7] = true;
    whitelist[0xb0ed9703eFfA36C4286D3ECb9CFa37D992f88abC] = true;
    whitelist[0x746a646dEaEDA59AeCf679813e97F659467f43BC] = true;
    whitelist[0xE52026106A3015F88774a30c1705aC325043c222] = true;
    whitelist[0x4E03C2Bf6584Ac074b017E2468349Ffd25354359] = true;
    whitelist[0xc93e979C7Ea358Cd3c26100eb14f3C13f57A2F88] = true;
    whitelist[0x5f4F59301E46Bf6f6603a8c4cF826BdaC70339d1] = true;
    whitelist[0x0DB7B02820b8826Dadebe2b0a92AC279D95ccFDD] = true;
    whitelist[0xee1401bc875aaF08e761CC9227058ad383C22B77] = true;
    whitelist[0xa3E14B0e7726C6b26e52522A4a28ac13AF40FcC6] = true;
    whitelist[0xDeDb918A4207049FAd9c0FD51e787cA1346b98AC] = true;
    whitelist[0xC80E4Af36C8759d9ff7E015EE097ba1b2Bb50752] = true;
    whitelist[0x7c2bB67A04B62b553a80d1498f4c58478677A8aa] = true;
    whitelist[0x0d5D10C539ceA9f5B7Db9412f93048deE6FD9B2e] = true;
    whitelist[0xeCAd356FA7eEEe984Cef5951ff74318C7d422b7f] = true;
    whitelist[0x4d09Da932D4983Bb8D7033C37017aC17dcAD36C4] = true;
    whitelist[0x2431aFD252f3599E27DDE47551fACe45971F045F] = true;
    whitelist[0x3e57efEf507b4db7aCFa2eE79CeCA6B19e18D106] = true;
    whitelist[0xD430dE36f41a1773A320494521a2f20Cc102781D] = true;
    whitelist[0x4536778854067CF5b63C6942e4110968A323DF23] = true;
    whitelist[0x96Ee4daeA1BBA5fCA92C51CBa5116d5BdA02A716] = true;
    whitelist[0xC20B3953f5A388bd3E62070a94246C7dCd58D64E] = true;
    whitelist[0xE174C218aca513Be78c61A46795c2D3002FA3573] = true;
    whitelist[0x369cf4a0733e24fD2158dd78C12C2f691cef078D] = true;
    whitelist[0x1a8dEF8E87903B2b852f14e8b3EEd38C575e375a] = true;
    whitelist[0x53B8e895346Bc83ea9C1F51a5010c91f892438d5] = true;
    whitelist[0xe60EF4317d4a9F0422A90617734f996A54BCb6df] = true;
    whitelist[0x02CE51592Cad04ED45d6F9D13833238d6BEa2C9d] = true;
    whitelist[0xA65e83994BC7dbdf4d29811C741D5BBf4a2FCB2d] = true;
    whitelist[0xFbD5bD432F653d611C5A942eCF18409c78FC34b6] = true;
    whitelist[0x0888Ad7d13C91A1c76EcFBa6Cd572801d5aFCeb6] = true;
    whitelist[0xA0fE83611d0971801FADd7C149A3743b3e78dfb2] = true;
    whitelist[0x1440Ae8Dca563CcE8aaC9B0D664214543bF84173] = true;
    whitelist[0xFfcd936E37AEEb7C587D4fDd982cD467480EAA01] = true;
    whitelist[0x5a9681b30F543E29Dc363b9c6Dd4a72894512192] = true;
    whitelist[0x0B1a887c3AA0316cC9e7a6683BC09A4Bb56c9e94] = true;
    whitelist[0xB6e47C3864549a961f66162DBC4a7c8CdD80B751] = true;
    whitelist[0x86Bd57Ea9bA28676036a2E80363f863B7d35d164] = true;
    whitelist[0x0247aBDB741074aff8c49351CBd8f848E922eaF2] = true;
    whitelist[0x966fE65D5e88824aC0BC5603e7fe0068Be6cc649] = true;
    whitelist[0x878a17144EC49F9eFC1E83903778c9C86e61aBdE] = true;
    whitelist[0x158b0600Da9eEfC914e89f9c4c43C4326eb3c353] = true;
    whitelist[0x9833bD1c2E629a5d2e7D5B15eBe250e8Ffa4AA96] = true;
    whitelist[0xd85Ef6A04B9270F992f9cd83AEA9380b3172E383] = true;
    whitelist[0x266efE26bC5112F1B0e85e8E2130940DFB4865eF] = true;
    whitelist[0x87038419450db8C0bbD9897Df8F8199659a43047] = true;
    whitelist[0xc3F8E3dB511e2e109A9123e966611D357847b54e] = true;
    whitelist[0xaf0A27118d9b88d867bC05a12c5964bB8388ccab] = true;
    whitelist[0x30755BF9849a20d91761df270C6823419fC5ed7a] = true;
    whitelist[0xC0d524ac24Ade60507cB59084a34463888Eb3370] = true;
    whitelist[0x4818e7c8cd65662c9272Fe2eC7F1CC2516149530] = true;
    whitelist[0x7e90ecEED693823EECd927f359CC6C816aaF53c8] = true;
    whitelist[0xA580F6DB19825990cDFE69f3D04803b7C5c81235] = true;
    whitelist[0xeA9B13b35239482BF2BC05D7CBadF5ec47a0085F] = true;
    whitelist[0xAE91CB00C413A8D6089Ba0bc8bF66fbA47A912Ea] = true;
    whitelist[0x2F631b5190ba4e1879E5B2Ca494c0A87914D9296] = true;
    whitelist[0x6b5Eee440aed19E066bBb255E236e7b4efD0f9e6] = true;
    whitelist[0xB8f3f8F25f38F5fA968fE7e624cF8E64f1Ed1BCE] = true;
    whitelist[0x0103B8C1124c2D70b9e7d81b60d20CEd79D3d9c2] = true;
    whitelist[0xe76E808b5873445d9059a51C4626992F560BeF8C] = true;
    whitelist[0x8E0AAadAeB308ef62AfBf52D53797977755907BF] = true;
    whitelist[0x4536778854067CF5b63C6942e4110968A323DF23] = true;
    whitelist[0x886039c3eABbf3613870511A72fbac74Ce25e4d5] = true;
    whitelist[0x1890E5713a9dBc98cd2146D0Dc2fe5A9a157DF92] = true;
    whitelist[0xb87Ebf06f8C99F43ecad940e4F1ACe84EECE776b] = true;
    whitelist[0xE8CC7A9e523886eF71783C6b3a8B49B421f8254d] = true;
    whitelist[0x61AB5003df44b49e115AfD9AC4e8c7Aa7D4B4A6E] = true;
    whitelist[0x830CB87bED6eB9b165Af962275550e8F32cfEd1b] = true;
    whitelist[0xF32249de62c49a8f3EF55ce564f8D4079db8564f] = true;
    whitelist[0xB2f51C8995224FF6e9a43371f25699ceBD2e5758] = true;
    whitelist[0xA022a5A072eAD080798c4E771710674406754b0e] = true;
    whitelist[0x43Ec5640E18F7384761d8817AA55d38C9a03D855] = true;
    whitelist[0x7fE0291F068BeC0cA18921756683dF8a73759fe6] = true;
    whitelist[0xE28E27239D891762024863D40A19338DA8559792] = true;
    whitelist[0x5540ec65a1Ac7eCC1EA39d81ef32192Da00439e1] = true;
    whitelist[0x7F7B584316CA0BC62dFe3e2165a45C2e40b04972] = true;
    whitelist[0x71D11243995F3003B4950E6FAEd483531F82eCA3] = true;
    whitelist[0xA8a51aB18B7cCD7474a4248Ee66E9C7E12D63A7f] = true;
    whitelist[0x36387ecCD493D4cDF6D4660D127390e0e1c55dA9] = true;
    whitelist[0xABF7FE1fB3ED2d5b14A46704824035A663acAcb0] = true;
    whitelist[0x8a5412601362654083409d6b5328fF7601822cf4] = true;
    whitelist[0x2Ac6A9338182c40fbC8C98ba522c3612Ee75b9e9] = true;
    whitelist[0x68fe4F773F50b15D396Aae30Da83Fa2f1285E5dd] = true;
    whitelist[0xb0dE71cE781c5161B41FF0A6773d7814E238A7a3] = true;
    whitelist[0xeaCb4fb49a94FdDAc3dCB7dAd5C63C3807A235Ee] = true;
    whitelist[0x08Deb89d3A895f535C8a9f865d93C146Fd7b5dA8] = true;
    whitelist[0xCD03b446d62d4df2f0A490385C920836BB9DC00d] = true;
    whitelist[0x78dac94Cc6D45c0D3100c2998b3e2753dF51BE74] = true;
    whitelist[0xfeD79641f2f8AEca217a25a57bf9dA1B0cca3575] = true;
    whitelist[0x888a02C76Dd3eabDB1bC6C381f438B4D0FA5d139] = true;
    whitelist[0xBF4Ba91Ff978559e597ae600bDeF71B8E352D47a] = true;
    whitelist[0xE52EA50aB6a3e481A555181aa01bD68150984b93] = true;
    whitelist[0x1448407b29d8e8a14785fE6496A75B5eB017c356] = true;
    whitelist[0xB90D71a2E044671DD254AB76A7F93782F8cDaBc7] = true;
    whitelist[0x7A7F7bC8737284A7523e92cA0ec018Dc7d51D3e9] = true;
    whitelist[0xf8681c75e84f1526695734FC2e0B8d57047afdF1] = true;
    whitelist[0xF7EfF0CF3E09809da959FA8B163239697259bAFf] = true;
    whitelist[0x07c08019870EdDE4dab631221C1483DEb35522Ab] = true;
    whitelist[0x246575a13ee62782e5A45436720Ba953e5Fb38Fc] = true;
    whitelist[0x727A630fC1Ba3E3e71e9e4b16Ae118526644e6FA] = true;
    whitelist[0x02380eb61a3560a34D76c0aD6f95F647Ae607922] = true;
    whitelist[0x1DDc2822e0f28AE5CF5188392FD487756CBa8b3C] = true;
    whitelist[0x2F7e7145417f3d7977f6B083F650640ddc77446b] = true;
    whitelist[0xeCf8dd1B2F532EeF1d3157B9E89Ca1dfd50fB51a] = true;
    whitelist[0x6f6C0bCD874Ec6352529Ed30AEbdeCA0b8Fc5c42] = true;
    whitelist[0x1e0754Cb0545444789411D1874c82ef1C5bb5Aec] = true;
    whitelist[0xe2e163c84e35c58cbA2E406BE079FBBDE86129A0] = true;
    whitelist[0xB32E083709588a1b3fA9C115C48051e61CBEba0a] = true;
    whitelist[0x463545d705EfE124E8bcE5d6273E3439F866527d] = true;
    whitelist[0xcc9D2aE32187D7087417EB236f552faf50A8CDf3] = true;
    whitelist[0xeeeeD7b12ceb4A81d73dA09fa915C847f7d6fCDA] = true;
    whitelist[0x38eaa9C3a73c807139F271D180fbfC23734c5661] = true;
    whitelist[0x6761BcAF2b2156C058634D9772F07374D6eDeF1d] = true;
    whitelist[0xAd188F0D79A5A1fF9c2bf506a20494cd04976545] = true;
    whitelist[0x42A2eDC109223860a19a3D0C1f1A31800505755D] = true;
    whitelist[0x605fDC424e7a6431D83aF0C9a3271Cd40877d532] = true;
    whitelist[0xb09ac06985bccdaE518F0E9cA3a0c4f335812F12] = true;
    whitelist[0x33352D8D29E293f4b379E28411337D9F80963574] = true;
    whitelist[0xe32fCd2aB4167C62328A539C70AB5878c67d327a] = true;
    whitelist[0xdeCe737bA8E9D72432Adac9C0e09c9cFDE20fd98] = true;
    whitelist[0x6db59d87046899232Ff5E89f29853B5aEa71896A] = true;
    whitelist[0xb4b6cB2789BAD42A9907493068996c358e1E5e0e] = true;
    whitelist[0xF8AF8b05323C61C6c48e4Df67f49f6CA4cEDC066] = true;
    whitelist[0xe47a92b4a21F99F145cF79BA13179757A5845ce3] = true;
    whitelist[0xc5FdaA35D33e72634aBc8C3EBbb84255a5Cd20b0] = true;
    whitelist[0xFaA10ddEf55E6C73Ac12239975580cEa755958E7] = true;
    whitelist[0x3b4e2496d5766994A87b25f99cF1d80802213172] = true;
    whitelist[0x6C89aC0F159aec29531aD2Ac57464e7788751687] = true;
    whitelist[0x412572dF27b3F0baEbCE8Ec0d138A737Db439112] = true;
    whitelist[0x2181f884b1aBDaBF6cce49687608A9779bf61A42] = true;
    whitelist[0xbD6b34a1d5db3FF53386307C6d505bB4afDC9cf4] = true;
    whitelist[0xcfa222e8C747A7BA317da66441517b4498A16b91] = true;
    whitelist[0x164b252a75AE99Cc172a2863e23790d68D8D58D3] = true;
    whitelist[0x0ACe27EbA543FCDa9412039b309A321346D395FE] = true;
    whitelist[0xAE91CB00C413A8D6089Ba0bc8bF66fbA47A912Ea] = true;
    whitelist[0xcabC8491816d5fA9F141c722FD8A08f2fd538333] = true;
    whitelist[0xf6A7Ac57755d77F90b66A7BC7C57feBadA87f24D] = true;
    whitelist[0x0907B14771F2b04c5A4643E611d23f7e988bD35D] = true;
    whitelist[0x72F711e517e8A7F67f6e44C1d5A19dBb31E96b53] = true;
    whitelist[0xA9B3E7810192733E08FC887256d0fD694644ab3e] = true;
    whitelist[0xBD16D508c99f3cFb137e38643eEaEFabde9cF1c9] = true;
    whitelist[0x008524Ae46fbB63bcd1DCB1BB766eb9eD798B1B4] = true;
    whitelist[0xa1Fbc680C30E5E1b19f5c5DAcd74fCB7645FFb57] = true;
    whitelist[0x70256b77453d6f1868741a52150DceD00D7231fF] = true;
    whitelist[0xe56B72d428c1A513f88F3d3BBAa3028F3Fe0f3F3] = true;
    whitelist[0x17476d0Ed31f81d95b5ba8960b2D0b4dE4675e64] = true;
    whitelist[0x17476d0Ed31f81d95b5ba8960b2D0b4dE4675e64] = true;
    whitelist[0x1ea39aB6f0d2113D99CC534d4E78106Be40927Ac] = true;
    whitelist[0xc4bD5d119bf3BDDDBF1D96bB65c2ea3BEFeAb212] = true;
    whitelist[0x0456728ecDe574eD1E3F5149da8Aef6772a911d3] = true;
    whitelist[0x4Bf5335C585846ED76b2E8702BdcEb9235B59F13] = true;
    whitelist[0xf8500be9E6A73C0412BCe8641634A770bd1ECa6d] = true;
    whitelist[0x962549Ab93A17F83F457B5177E7F21c59E4CF66d] = true;
    whitelist[0xBFe2F34Bc286E9e5EaC80F4BF968F91690BCDd5F] = true;
    whitelist[0x17b920Fb5dEf4395076Ca0A7f95c04454FAf9D6F] = true;
    whitelist[0xbfF29b6cfD0c6BC845D4f70BDeeb3378a4AD39BF] = true;
    whitelist[0x71157223A91189713B0B46f59815035cf2F82143] = true;
    whitelist[0x344302A1Adfd32e76177fF5a7cccbBfbF535279b] = true;
    whitelist[0x1dfd7c9f16d10fecb0A1c85654C4a0Aeaa92c137] = true;
    whitelist[0x740cf202C71BFc4DA5Cb8372E79ad88214DF1a05] = true;
    whitelist[0x05961Fc27913EfF9B11CdE8F0d6D2349e8B9a5eB] = true;
    whitelist[0x70ee76816B7ACA98F70dcd20802aF98448B9156B] = true;
    whitelist[0x0b1B848Dd5436412EcC8c0CF1E1d7dfFE92f2c25] = true;
    whitelist[0xcC9ec80aCB6ca0190A89C7825e14317eB5Cb43d9] = true;
    whitelist[0xB1258f8C92c969F7FEBC1AC266eA7ABB6249885b] = true;
    whitelist[0xb054CBe6aa8dC1b999e84DA9289C867FB580aFB2] = true;
    whitelist[0xbFc2B209406d4cA12231095de760f514E4A39559] = true;
    whitelist[0x5601b9447b984EDCFfacafD0dFA79077b755039b] = true;
    whitelist[0x6f6C0bCD874Ec6352529Ed30AEbdeCA0b8Fc5c42] = true;
    whitelist[0x00BddE1e87Ff78e1270E45C7EDE67d932B11C5Bb] = true;
    whitelist[0x00f903a27295c1BB22Cf685b9452e3183d07e5FC] = true;
    whitelist[0x724df920406dC0a47cd58EB838df5512D25fbA02] = true;
    whitelist[0x9c7Da566f9b64Fb310DA316cd00332677E736F18] = true;
    whitelist[0x5CA2dC754353C692b0dbFBFCF4574938754dEd4D] = true;
    whitelist[0xD283AC6b8dD58CDE7EdE41002219D976115Dca36] = true;
    whitelist[0xC5bc9715874C91ded9313A06baEfa1307BD72299] = true;
    whitelist[0xC76eC56Cd15A7FC2ca7d1005710c06ac6E5B28F7] = true;
    whitelist[0x14B177fE4B22199fA26C0c98Dcf0082a0125e0e2] = true;
    whitelist[0x51ecDC62FeA43E8596F82EBbE288FED29f909634] = true;
    whitelist[0x5881513A30cec2C84D61166b258b04789a92d9e4] = true;
    whitelist[0x822F2c20B49b8BDB8d62Eb11a558371049bFa951] = true;
    whitelist[0x867Eb0804eACA9FEeda8a0E1d2B9a32eEF58AF8f] = true;
    whitelist[0xf97090f5D3E0e96E1c9Cc6f07153602c2922D0E1] = true;
    whitelist[0xeedcC4D7d9ea1C9c1d1944717a1dFc73663d7D45] = true;
    whitelist[0x627eEBc2c3b21129D98D17816b8bA05aF0c9ac66] = true;
    whitelist[0xb0ed9703eFfA36C4286D3ECb9CFa37D992f88abC] = true;
    whitelist[0x3c3710bF782cf67f025AdD26C3D7Db4767C98D5F] = true;
    whitelist[0x38B29d63E93fc3D2D6670cf047E37bE1e9d84c5c] = true;
    whitelist[0x200d029F48ED9fB76A11307Ae55c8fcB2b7Aff73] = true;
    whitelist[0xE4Bb5b561D23313c89f53d80f049545f1AFD2CAF] = true;
    whitelist[0x85e8505b9C139e48a7Bb1E20cDaA9efA9379A68f] = true;
    whitelist[0xb4C95EaEA8eD720CF0d9450A5bf868711EcD06D3] = true;
    whitelist[0x9D55E92DA14498C97039867a8AaB200e7d37123f] = true;
    whitelist[0xE5463558a8241EC7bC70B202e7CB3D1465DbB124] = true;
    whitelist[0x4b15bDA13573A2d619B61065302CC6a703Bd4226] = true;
    whitelist[0x8BDdA04420f66B19194cF6a0c108291c1B8536D9] = true;
    whitelist[0xA50A9a55811d105C2d5451C688B4B74954161185] = true;
    whitelist[0x775BF864087e10FE0722F0e028c9f943d3fa62e9] = true;
    whitelist[0x0eEBbb2a7A718AFe461583d391dBa7F34cD95735] = true;
    whitelist[0xf22D096F6Fc9693B67D6B3401845A7E6FE16192a] = true;
    whitelist[0x85aA5f089EabBc67dA4b89Af5eC3140DCD3d8Cb9] = true;
    whitelist[0x3Ed483BE178d2ea17E53cCe86F19b37974d65868] = true;
    whitelist[0x0c0ffaaF6378cc0B4118F2752209a206A046d56E] = true;
    whitelist[0x945a5dbc95fDD6c0Aa873ACfc0d3CD4888E28E61] = true;
    whitelist[0xE6931F9804E194a15c9371E7A0841129f5b66FB2] = true;
    whitelist[0x69353ce89dcD43D3d8ED1AD996Be652b6f37C38e] = true;
    whitelist[0x3d66B618Dbcb3ea2001821c6844A9ad9Ca9370A8] = true;
    whitelist[0x3e72cd9D721279300121f54910E30b25de55B24f] = true;
    whitelist[0x392AfA384BcD9d884466A830DBAef17fECB43397] = true;
    whitelist[0xACF967E499F8cACd2eAc27A3cF3b956BCB748DA9] = true;
    whitelist[0x7A5EEcBef4DEC2533D81A7535A9C57B74Ef1EBD1] = true;
    whitelist[0xf52B6A3CcA0f68Ceee778547F6C4A43D423defed] = true;
    whitelist[0x99a7BEE5AaA9B3bBE1842Bfa4D563B5C7F6d100d] = true;
    whitelist[0x20d41C09Ae21132a2909f77bAEE4F39303250Dd6] = true;
    whitelist[0x4aB7ea50930b28b6A5d60879E8705faB67d36722] = true;
    whitelist[0x7d0AADcee7365FC0dD22575736F8B9F73014aeBf] = true;
    whitelist[0xb9074044b4A8d60112701Be1177d6676de43A662] = true;
    whitelist[0x207a1868C0063039461b953B811eBE84d14DA5BF] = true;
    whitelist[0x1Ff5fD0c5A7Fc3c74Ab2E407e23ED0855Ee20697] = true;
    whitelist[0x2F631b5190ba4e1879E5B2Ca494c0A87914D9296] = true;
    whitelist[0x22c3052464e684Afed272789a9108eF66606C46e] = true;
    whitelist[0xAa263edb6bb2eab2E4013bBE90e726753fCF5AF8] = true;
    whitelist[0x5E7794141088d49F95b11E0D96527d639e66392E] = true;
    whitelist[0x7c18db094612b2e43f8a3aB58dd412dF81dd3A76] = true;
    whitelist[0x75Dd1a37187773347FE7c319A3077099043Dd6B4] = true;
    whitelist[0xf9d056B6f6b34997e0eE0739Ee5CDAF7E9E40033] = true;
    whitelist[0x4c3CA732DcA1eb35CE3e68005B94103628d687f8] = true;
    whitelist[0x97C86496af9BA5478258562C370275D04474C19d] = true;
    whitelist[0xE4F7B6d11c8A25c778e70bFC8CCAfF690e017BcB] = true;
    whitelist[0x14B177fE4B22199fA26C0c98Dcf0082a0125e0e2] = true;
    whitelist[0xfF5c5df35ec7cD6Efe36a63B2bd5f4df9A7211aE] = true;
    whitelist[0x88cCcd08296F8dfA666478A7187c408f832b8E98] = true;
    whitelist[0x2F631b5190ba4e1879E5B2Ca494c0A87914D9296] = true;
    whitelist[0x9A782Ab347F19F7AB2bf8d2AbB1B968384273988] = true;
    whitelist[0xb78C5F9E3dce3A03d8E086BE52F0367C90eF000a] = true;
    whitelist[0x9937D915BFF7Bcb091C5d93Cb5F2fb757Be6554E] = true;
    whitelist[0xeAb3cfBF53AeEA4D9ddd138ed9EE379ff30dDA3f] = true;
    whitelist[0x7D31A4758267d65AE9A9Cc68700FD00279B463CA] = true;
    whitelist[0xdB5dc95BF080dd3921C2C6Aa5c30F108d55158ec] = true;
    whitelist[0x4E03C2Bf6584Ac074b017E2468349Ffd25354359] = true;
    whitelist[0x0eEBbb2a7A718AFe461583d391dBa7F34cD95735] = true;
    whitelist[0x394F290C9C89e51f150F40A565381F79396adD33] = true;
    whitelist[0xB0736A8436f4F226D63d6f0447968479C39c8F41] = true;
    whitelist[0x4d09Da932D4983Bb8D7033C37017aC17dcAD36C4] = true;
    whitelist[0x16Bd3527128aAC9061dfDe0B05fcf26B148c7cf6] = true;
    whitelist[0xF924232D18c1Fc74c47BA623633C1B643eEEb319] = true;
    whitelist[0x2F7e7145417f3d7977f6B083F650640ddc77446b] = true;
    whitelist[0xB35cFe9ea3Ae22902eef91bA5584CdaBDa7a3b59] = true;
    whitelist[0x3D2E21E911f780406471854233656C01C1b4E5ae] = true;
    whitelist[0x58d55449E4Cc7719970A27bD1Be569cd6834483F] = true;
    whitelist[0xe53455412f627aA4586CB9C33030D9D51dC3B56A] = true;
    whitelist[0x5bBA33f03671B7AEEC91cbD05Eb31776Bc05337d] = true;
    whitelist[0xF63E7E364bA2A8cE99c34563A9768B3BAfF65D1a] = true;
    whitelist[0xD6587a974C7D3ecE23Fa53d5606da6B291311F6f] = true;
    whitelist[0xa1e58D3853A938c75D1A54FEd332A5814F94FaDc] = true;
    whitelist[0xBDaD4e473B1Ea1aD59Ac7034368305367BAAB0df] = true;
    whitelist[0x6A20dFbB6F4Ee6476AeF9aCE825cC6e12c50835a] = true;
    whitelist[0xf1E07E08C90bd411FFE296140d3F886e249b94a3] = true;
    whitelist[0x06F9d88ddEf658A4491e46078FEEDB0e3c18cbF1] = true;
    whitelist[0x535EFa407b36889c3280d75E264a7d122b63539C] = true;
    whitelist[0xe7096dAf78c15bF0889230a328e3482930F3c936] = true;
    whitelist[0xDb1486005448686beDda0D52175cbE2C9a739EAd] = true;
    whitelist[0x8fe067dEaa37CECE05601223a763B9961769E6F0] = true;
    whitelist[0xA7Aa4B444A75F6Df5fcaE6E563755b14CF573728] = true;
    whitelist[0x97B68f5D84F931a144d829E17b0C97dAE0912283] = true;
    whitelist[0x76dB815a1C977124F2EcC8861c3215161d9c1a89] = true;
    whitelist[0xeAb3cfBF53AeEA4D9ddd138ed9EE379ff30dDA3f] = true;
    whitelist[0x7D07cBa0Db193A340D3466e8596c4Cfe0Dc33DE9] = true;
    whitelist[0xD20C80897Eb88cDB84664aECfeD3AB9f1051C6Df] = true;
    whitelist[0xB6354C33576069d677C73b15abc9FE20DA80Dc0a] = true;
    whitelist[0x671249ef1bDb683C37A893aff13C70eD37BdF977] = true;
    whitelist[0x4aA1F597164871347ED33B2be7bba2Db2EBE5799] = true;
    whitelist[0x8290326F3d2A01659996B0DC1638c3374b49BF65] = true;
    whitelist[0xA2427cD956602612Eb9cF36a01b6bD67ACF81A59] = true;
    whitelist[0xc3Bd7EEfC1e30E351A64F764621aecc0B9825394] = true;
    whitelist[0xa44abB19Ac28C10Dcb11454e0A1D2b91351c0B57] = true;
    whitelist[0x5A6D4C34C6A43C39aC7787AD88f0EE6e5F537740] = true;
    whitelist[0x75C8cF229D0b50c04dD264AAcc8539898cf6c9F8] = true;
    whitelist[0xD209A08E6aDb55C6F7BB74F6D0cE7444Eff47578] = true;
    whitelist[0xd2488630C14CA417cE41a0Ea801b3E11CD20cAFb] = true;
    whitelist[0xF4E115673718Bb540665Ae901f392f96996fb336] = true;
    whitelist[0x4536778854067CF5b63C6942e4110968A323DF23] = true;
    whitelist[0xEdD4BefD928C15e02D0FC3d4a2998dedb9252188] = true;
    whitelist[0xF04addc585002735C378b5e51A813513Ad8E3B64] = true;
    whitelist[0xa05f6ae479C84a404641bbBF58f2a3aD364D73fD] = true;
    whitelist[0x1304F7DfCaDc3d30bA8510E328650eCBEFBB4c1d] = true;
    whitelist[0x85a4a13f408f3D275980379A8e3Eb1Ab6f9232E9] = true;
    whitelist[0x09C406bd813364C406f183104AB2E9Cca77CDFe3] = true;
    whitelist[0x3e72cd9D721279300121f54910E30b25de55B24f] = true;
    whitelist[0x85e8505b9C139e48a7Bb1E20cDaA9efA9379A68f] = true;
    whitelist[0x5CA2dC754353C692b0dbFBFCF4574938754dEd4D] = true;
    whitelist[0xB40f05Ad72E7Bcb0d8ff05A3D6C47E9331e759be] = true;
    whitelist[0xdBfEa76bCf122B8F62EAb66e36f2f1F378ab7d9B] = true;
    whitelist[0xF22b63bFaF049C9a91e9933b962131dBdDaFc838] = true;
    whitelist[0xa0501600eD268594c6710c7531D6093c0fAd29DD] = true;
    whitelist[0xcf25A23D533F9156eAb5Dfb6c2520901b475214c] = true;
    whitelist[0x3cAc7E12dc3bae6EBe2909C82ADDb04DA4CC340b] = true;
    whitelist[0xeeB2FFA13F4eF4381647FE642eBFaD0CC1BBc467] = true;
    whitelist[0x169bfe7762F05385894b0989A8aAa7fE899524E5] = true;
    whitelist[0xcc9D3DD3F433De6c14E8881B13D4BcfE1A3E59f5] = true;
    whitelist[0x377E13c59F0aDb62de0C12b4F6eECD4E7a8d04d5] = true;
    whitelist[0x7Ef082b9a971f198f9ddE7f3c331B16a43D76EFf] = true;
    whitelist[0xbb2dC6Ca53A9D03219b10916125038e29Ae695e2] = true;
    whitelist[0x448427b62249AcC4C2d69e56D2723e21924B27ad] = true;
    whitelist[0x0B1a887c3AA0316cC9e7a6683BC09A4Bb56c9e94] = true;
    whitelist[0xe1852a39d6865BCA5922F71696E22d4065263626] = true;
    whitelist[0xA669D9B0e6b89e661Fa125DB990498fE84886bfb] = true;
    whitelist[0x48F1ef35C0E7B9921102f4b8F2AfDaeEeE62Efa8] = true;
    whitelist[0x5339026Ba61Fe0fFC2774D2c4cBb4C91c6CB5c22] = true;
    whitelist[0xd09e7Af426b05c4c4fB79632f1be6391470cC7Cb] = true;
    whitelist[0x9BF43BfD38F96F459e261f5531291CE9D3913588] = true;
    whitelist[0xF9756e4f4355228dc6f11Df58683E85303828268] = true;
    whitelist[0x75B81Ca1C61A7e59d3bdcd9d293E6f7e68ca1031] = true;
    whitelist[0x6aBfF48E92FDd073b497756089253E43d42747FC] = true;
    whitelist[0x7b17d8c2e5d8518c4D25d97e6A1EB1D0D7ee4a71] = true;
    whitelist[0x2F631b5190ba4e1879E5B2Ca494c0A87914D9296] = true;
    whitelist[0x694CD0eFDFA527233aa1d324798AcDE775812aF3] = true;
    whitelist[0x1D6FA76b3a383cb9ab4151f9AB1597BC95948A4C] = true;
    whitelist[0x13bdEf348c679FBa043b96195536A404cDd8E66f] = true;
    whitelist[0x899bFF3d1A3592DcbbA5Fe11ff230cb87539c5C5] = true;
    whitelist[0x716428E298a00937bd4F07a55c06B69019266133] = true;
    whitelist[0xe1E44529a2E9166C153993c7Fc55C39be6072b94] = true;
    whitelist[0x010349096105E83557fD8ecc2b269d2d2DBFf593] = true;
    whitelist[0x6d3C4f01Fe5C5Ce3acfdafc234bB3C610F0B088d] = true;
    whitelist[0xEdD4BefD928C15e02D0FC3d4a2998dedb9252188] = true;
    whitelist[0x26915Ac15d6B30Ca180c343E52FaF33C04f26F5a] = true;
    whitelist[0x531bf9FdC6da22aF543f579C1f733C6863f60abb] = true;
    whitelist[0xEE293E4ceb7Aec9f70387e850F5dD2d58764B4C4] = true;
    whitelist[0x2Bb456d6580f3c6BEaE4131182cF64b791202a0b] = true;
    whitelist[0x70F6Feb191F3E235aB3231740840d132800a16dB] = true;
    whitelist[0xa2d887d384a8D71faEf4F7433db3709c1b385533] = true;
    whitelist[0x0eEBbb2a7A718AFe461583d391dBa7F34cD95735] = true;
    whitelist[0x06D6f74C14ca13505220751ED21Da78c644a9144] = true;
    whitelist[0x9e0b2573059699AbB244b5bcAad8C9924f9f9422] = true;
    whitelist[0xEE08323d41cbA6C0b72f8d952da8d364bc1Ea71d] = true;
    whitelist[0xFb054de87c048fE9f9D859afE6059d023529E0d8] = true;
    whitelist[0x27aadfa8c75cEf8c3B02B63C626360649f5D2C83] = true;
    whitelist[0x5EA707f72EF17ff394d020Efdc6E5A6044872662] = true;
    whitelist[0xB970f60495B36Ac66c06f9b01e3b1520c2a2Fcd7] = true;
    whitelist[0x4eC3B52C788f58a6f273F33e4cbC38ae2cBfE6C8] = true;
    whitelist[0x78224A21316204f52C548F0de5F4aC38289D8148] = true;
    whitelist[0xfe535192BD5cD07eB2A5Cd14e9B442396F4Ff9a8] = true;
    whitelist[0x83dEcCcB466c913a6728BeFbae0C84169EE8BDdf] = true;
    whitelist[0xc56609d9bF20f92c79bD5ea83FF4b5CfF5327346] = true;
    whitelist[0x7152275089DDbc2704D31C5A7B70ffb0eFf949a7] = true;
    whitelist[0x25217b4A6138350350A2ce1f97A6B0111bbFdB56] = true;
    whitelist[0x65Ec79127a65543287A665fBaf791D9950F0ccD4] = true;
    whitelist[0xD4f0dF7005d0533768073896ef42D528172AC4Cb] = true;
    whitelist[0x2dE3BA92ff11baD1D8a7Efc40458368aBe7056a0] = true;
    whitelist[0x1234630A271A09d8cf10D2CEBC54caD1B1fb87fc] = true;
    whitelist[0x8bB59a952c3E9369f3ceE04B62c1340E0938dB7A] = true;
    whitelist[0xEC8637A34a5851308c9795F0eEA546aa71A5be21] = true;
    whitelist[0xB63c8F6F2d1bd1ec17a063c422B4282d871704e8] = true;
    whitelist[0x863e71979c2941D654124C69B905F42256F3D7ad] = true;
    whitelist[0x9254faD610D5AF7c2AF34532f41DD8c0f9C6871A] = true;
    whitelist[0x7f78369116DA61F4fDaB029745f6A86CA55Ee76d] = true;
    whitelist[0x6BeD91Db4C11a37842BbaB1A8e6A463fE09418ee] = true;
    whitelist[0x3912d7eA8140e16dAc355892653F3512C3cf3749] = true;
    whitelist[0x29e3bdd9D22Acc8218De137F3f50C733e0CaC30B] = true;
    whitelist[0x181ea61Ad520715E17eae17096BDa2F03207EC58] = true;
    whitelist[0x2594c567255FAa27b914E0B1a69bA07B473775fD] = true;
    whitelist[0xF3Bf4cADebEe8427f6fC87F4D846F21D78Efe2Dc] = true;
    whitelist[0xD43b91df4Cd2a48a6D2Ae22C91fCF44ae3877d7F] = true;
    whitelist[0xb32F3e7810b563BdDbF021679309395342f35923] = true;
    whitelist[0xaeae1a9Bb55e9c5593657010c57Af03385871CB7] = true;
    whitelist[0x07617900F0a489c66CB048933C3a043c0D0C130F] = true;
    whitelist[0x7B127A9e5bF16CCBFc1a83A65103A11aC70c72eF] = true;
    whitelist[0xb29f00014179028f0Fed2a2c96Ad9C96CD2C20e7] = true;
    whitelist[0xa2132aE11FFa79235da955aD68de9B52B291b921] = true;
    whitelist[0xCC3cEf3Ce97bF809AebaD89eaF53F05b92Cb3152] = true;
    whitelist[0x6DE6EADe4F726F94679C4695D64a5Aa81fcBbFE7] = true;
    whitelist[0xAF3c20498ff9AB190af36764428FCE9017C54758] = true;
    whitelist[0xCC68b310CDFfc3054b38843601A5F27ed9794d39] = true;
    whitelist[0x77e0292FEfDa350Eb91653c9694Ab645dF80404e] = true;
    whitelist[0x4b95F69A5375E7BB15A9e74412082DCe283Bd497] = true;
    whitelist[0xA13e7aF1B3c0446c7A331d64b35bF52D2c541F02] = true;
    whitelist[0x4245015AD786b6Af1ACed544127aF4DC8C6083fa] = true;
    whitelist[0x273689a39EB1018A5c2fedB0A9846871fF8d8050] = true;
    whitelist[0xE7921F821F86D16BF31CD3790175061a965d5270] = true;
    whitelist[0x273689a39EB1018A5c2fedB0A9846871fF8d8050] = true;
    whitelist[0xAa263edb6bb2eab2E4013bBE90e726753fCF5AF8] = true;
    whitelist[0x832A1c22272Ba7d57223f05312A7352A8F83063E] = true;
    whitelist[0x605fDC424e7a6431D83aF0C9a3271Cd40877d532] = true;
    whitelist[0xc101598AC79799585D67B0801544c260A427448B] = true;
    whitelist[0x358421FA33B71eB6f40809bc10e6C4c4Ed12e089] = true;
    whitelist[0xf85AAcA6DA3230e7b9000Db66705D329374A716f] = true;
    whitelist[0xE015938865c3e27c7cc9dE16c9c9521D316955A9] = true;
    whitelist[0x3b68B541aF74A55C5aF69c07bA5072317A4a3288] = true;
    whitelist[0x91a9692957BEECba901495E02F2AAEA991c40cee] = true;
    whitelist[0x6b2d6e1ECD4aA797d0E5009971aDD1151362Af78] = true;
    whitelist[0xa71AF61633645D9a38C9600104e025B427b1f501] = true;
    whitelist[0x593d4E0590fa8c32cE03cB3D9b9bEa6bB9Dd5201] = true;
    whitelist[0x753054Dfe7a80A0c53dEb4FFE5E06fC6C3BD566F] = true;
    whitelist[0xC49A0406771F6542c754E80790f165F6c69d33B1] = true;
    whitelist[0xE6923D4e676Dc5a1E3620790C31306EaBf38eb26] = true;
    whitelist[0xA7949B4De5F5D6D19b1b83665B75A017b0A1B265] = true;
    whitelist[0xb3D85409993310F5Cd14b7cb3e2b92bE6D0b48eb] = true;
    whitelist[0xE27116b4E637e0b700ef213743fA1bE45499899D] = true;
    whitelist[0x54deA17cA6f0a62BD482b7c0d1Cf0805E11cE648] = true;
    whitelist[0xaad08feA58A5822a076bbA2F562F4bE5E7db6f41] = true;
    whitelist[0x1c4b57AE93a298392a5D41B188AB19021B00b4cD] = true;
    whitelist[0x220d482B44F0A5048CbA7719048BdCBfD91B3c6a] = true;
    whitelist[0x6cd8488A870cEDa037260f1041a8886C8725F534] = true;
    whitelist[0xfA02f156c508DF8bC2fFd1fd34Ac7Fa4A598b6b5] = true;
    whitelist[0x69f5ab3D3129D3101fa52CCa6b74398966691f7c] = true;
    whitelist[0x67b847858EcEc3F56800d059045e8E686D5B32C6] = true;
    whitelist[0x1920dbCFDF0fd291A71BeC0b66e20Ff8674b01A7] = true;
    whitelist[0x435D4599c1A4992Dac4F8Db6f73E6b90169f6a0D] = true;
    whitelist[0x3f8F896C4E2C7ACF74B183Ecc742799C11CFB474] = true;
    whitelist[0x97AF989C937C02F763ffA0ceE07A829b4D2B6341] = true;
    whitelist[0x5394A45C1Ae75F54D14A539344263a52fAefEFb3] = true;
    whitelist[0x50F12dbffA732B3e30B0fdf7344D409547026609] = true;
    whitelist[0xd8a13d98eA4A70686b1ABa21fAb4a9a147124609] = true;
    whitelist[0xf33CcD747B1e3E4CA2d896DFA419f85b884eEB3b] = true;
    whitelist[0xAc2511B6817813411d7CC8669eeBF4C998e4320e] = true;
    whitelist[0xb77489bdf08D76e28D2884A07C2C2088dde3Ec24] = true;
    whitelist[0xf27335acd15AFA18e45585811E1be89adDBDb5B6] = true;
    whitelist[0x6D56403D5a6E1Ed520E0C99c0e8134c1e7bFd67a] = true;
    whitelist[0x51A6a7c3a80EEa15d8e8F20Df9B38A902a9e4A98] = true;
    whitelist[0xDA305Cf14AD95d13b332e3d84f639c7Fea7DAeaA] = true;
    whitelist[0x91FFe0Db1acbe42c20D0EE627AB1Ea52DE6818D8] = true;
    whitelist[0xd2a2d64690602bAd517480048dE908045AC0305B] = true;
    whitelist[0x3Bce4AA0337A20313486c49B741764430fd8423a] = true;
    whitelist[0x9dD34548F3Bc18F47E5441790810BD06C5C6fF40] = true;
    whitelist[0x0351bdb23B065c241c0B3C743Bc25F28c695477F] = true;
    whitelist[0x676f41D0B727Da0Cc8b6811700310cF5140b6F16] = true;
    whitelist[0x257FA15F9f60cB4Bfa257E6F91700570F027905E] = true;
    whitelist[0xeB94464aD93BF669DEA59461e144d6f2f3387Fb7] = true;
    whitelist[0x1DDc2822e0f28AE5CF5188392FD487756CBa8b3C] = true;
    whitelist[0xE107b4c78C55685F3A607A5eDdB4F7f3bbC8B41A] = true;
    whitelist[0x8DFD4f307B6011D4CB21007FD5658f0686523938] = true;
    whitelist[0x642c591Ebba2eF6992C90a25702EAa0F1e89f339] = true;
    whitelist[0x4cd8E0Bd4A991b2d7763d80c4C63dde5582942A5] = true;
    whitelist[0xfB87E3382a9490808bD91f0bb748D7CcF96fD8F5] = true;
    whitelist[0xf4141AEF39803327497F6B81a21BB3f2ACFa2436] = true;
    whitelist[0xd47Fe94Ed7Bb7EA874ddc42De13c37C2cAD0Df74] = true;
    whitelist[0xd5B5a02954fFf261d4ec1374dae2783457910240] = true;
    whitelist[0x0bB4358B7c74129624260d67e80FAec306D2D234] = true;
    whitelist[0x169a44dDb61255479A1C66641aA52af3C2F7a0b6] = true;
    whitelist[0x85C258C7b41d9CcC5e8F208d1E80d09990327731] = true;
    whitelist[0x2D4099c2F78091182C36B50cd4de37D7012886C3] = true;
    whitelist[0xFB89f15B4808e6FD5826969e4EEf9e50CfE441E5] = true;
    whitelist[0xBe21DF66356570F2f0C0AE8550Fb5B1eFf2cf010] = true;
    whitelist[0xB1570895eB0F0dA6A0e671d73A54696C4A85887e] = true;
    whitelist[0x875681c6B1C8398aAA3F61d75939a072A74c7974] = true;
    whitelist[0x60dC0c4130fe69Ab247f2386ADf39062859BeFDf] = true;
    whitelist[0x02Be8b4298B77Baf7c120F64C0B93F9D33824180] = true;
    whitelist[0x67054B888E68E7DaB50475eC34987A036fdb4E4B] = true;
    whitelist[0xE1E457AFED36037f3f9DD2F8B6bB9674E1A666f4] = true;
    whitelist[0x1EDB66c1D1D518aeAbd08fb13Ef7B4D382838442] = true;
    whitelist[0x902C236f3a77F2bd781ab0A3e06A6f76AE2Ce587] = true;
    whitelist[0xcc8B1776626e2E1047500bAC15b908b3FE5924d1] = true;
    whitelist[0x1730ABF8A9a92F8E249B0f217Ab1b757dc1c2B1f] = true;
    whitelist[0xBBe846566F2172AdC9c0bCdCCf8D280Ad60dfa67] = true;
    whitelist[0x61D34A0Bf48e0009995C0E48eFbB7c07eeEF1391] = true;
    whitelist[0xB4B8Bb5A5ceA4FeB48d0F2bFF040086A98E31d76] = true;
    whitelist[0x48D0B1c900b4F363F6ca4F29aFE115057F7725fE] = true;
    whitelist[0x252019C2b80334eE0d04854e1Cf01eC15F949B62] = true;
    whitelist[0xAa8C41D4B0c66709Cf6F1487623e14E347545DBe] = true;
    whitelist[0x71406d643244bCa86a1C4011Bc7b2940B4B454A9] = true;
    whitelist[0x1d842Fa7B6E657Ec7AA31Af4D1c0D6bCD2336dfe] = true;
    whitelist[0xB8108bbcc4DeA4724F9DDf16d1CEe6Ed5b144161] = true;
    whitelist[0x6B268881e12BcB9e4d550B009bA39eBB9cBaf9D7] = true;
    whitelist[0xa2C43cA0976E0d89D202FEE6368855Cf57d256Dd] = true;
    whitelist[0xbFc2B209406d4cA12231095de760f514E4A39559] = true;
    whitelist[0x5Fa8Fa0D0f3d45c997e5d31441f56A4f2881085d] = true;
    whitelist[0xB6F643B57f3B2fE4d6F2d0562f14Eae67149f2B2] = true;
    whitelist[0xe5CA69a2392A7c95F1d36dECA49bBf482899E0e1] = true;
    whitelist[0xE5463558a8241EC7bC70B202e7CB3D1465DbB124] = true;
    whitelist[0x52E446158aA8E75608f0AEe0Bc1B1419076e0A5a] = true;
    whitelist[0x709c0eB4BA7D5b79d7Ef2c139BbBA71b65897f48] = true;
    whitelist[0x604B0f9eE051A1EE1F58508ed0f97a7bA5050E2E] = true;
    whitelist[0x96e3BAA591C9Cf4d5f44dd44D02A3d4cE9290ac2] = true;
    whitelist[0x604B0f9eE051A1EE1F58508ed0f97a7bA5050E2E] = true;
    whitelist[0xaF2E919B59734B8d99F6Bc1f62Dc63d6519d14BC] = true;
    whitelist[0x75fbbedF1351af278d621F2E52FA18beCFC1D506] = true;
    whitelist[0x8d6C61Aa3D5A45700A7b7792970616EDa941Bb2f] = true;
    whitelist[0x6296bd898CB887e790aE384Ee839D697916927e6] = true;
    whitelist[0x61FDa626e156a234f0159ef7AFBe591E88c0D6D5] = true;
    whitelist[0xa079ba6293E8D4bDd59dbaa431A9A0FdF3d9595A] = true;
    whitelist[0xfFf9F1F85FB17d3C4b5cF376f6299cB63c757242] = true;
    whitelist[0x38b966ee9766407fE7A06D5b2015EDd8b3338f76] = true;
    whitelist[0x825e825D65ce535bac38617d25D0F6182ACa5A80] = true;
    whitelist[0xaaAE0556EC7ed5d18AA5696a9ff6B961c5763B99] = true;
    whitelist[0x7F34d0Fc862374dc03cb62EC58be5Bae3CbF4BBC] = true;
    whitelist[0xF32249de62c49a8f3EF55ce564f8D4079db8564f] = true;
    whitelist[0x758F2f3A95488C7d89fDF10CDec72fcbB70dB51f] = true;
    whitelist[0x604B0f9eE051A1EE1F58508ed0f97a7bA5050E2E] = true;
    whitelist[0x65DA609AFa670e69405f405eEacD00088af44DB6] = true;
    whitelist[0x9BF43BfD38F96F459e261f5531291CE9D3913588] = true;
    whitelist[0x0E76e625e1A7bA420f1dc35C5aA75E68f01c7222] = true;
    whitelist[0x90656c502De935C119538Cacd1f17930174866A1] = true;
    whitelist[0x4811E28A654D544887686926D9c330F2De695caD] = true;
    whitelist[0x66832959Ff9094FF57a89DD8e87a885fD03BC59a] = true;
    whitelist[0xB579523CD4B80B95A3F8e7D0f840Cbe422C81B9A] = true;
    whitelist[0x75E2baC34FfF6f470267E53b3f348f8Fa377a551] = true;
    whitelist[0x5e275704cCf404782Ae78608Ef7B0BfefbFf43d5] = true;
    whitelist[0x4B5aEAE280E2bFDb6401B83cdC81EF6368319443] = true;
    whitelist[0x4E5a8C7DA50087a9229da9Ccd86c9E1c4C1770Bd] = true;
    whitelist[0x3EC1d622D3e76a41A73Bfdd872077648851D32Dc] = true;
    whitelist[0x20c91ED06463c57845BD2b582c593b0d3D9f08E3] = true;
    whitelist[0x9c786733e9aF618b459250831833eDE285F56301] = true;
    whitelist[0xEa3ad2F3950bca65D56d0Fcd180a872f36549385] = true;
    whitelist[0x20c91ED06463c57845BD2b582c593b0d3D9f08E3] = true;
    whitelist[0xC86C7E14a7F4E092128a984C883b576Aa76075F2] = true;
    whitelist[0xa2C75E8736e446149d5F368db640dd46771B4C2F] = true;
    whitelist[0x66c667B52C244D7502b126Ef10537ed1B690d42B] = true;
    whitelist[0x9CA4692f1DDa3E3be64Be8520b1ae35E980F64a3] = true;
    whitelist[0xFAf9f63bAf57b19cA4E9490aaab1edE8b66Cc2b5] = true;
    whitelist[0x6556751caf10474B9Bd8b31eE4b0bb4420aAfFB4] = true;
  }

  function addHolderAddresses() internal {
    holders[0x41a02e6db99A86Dd737B03223903c8333eb55E79] = 55;
    holders[0x69E6e0cb93a807B9f991A22e0a4d540f36F6b34F] = 30;
    holders[0xE48ab528F2B51Fa68E22d57069CfFaFCd4aA2b6C] = 195;
    holders[0xE92E8Cbb68b017c679e2Ee1E0Cbc20227d35C2B6] = 30;
    holders[0x2c07681E81B5F98c615cd2Dd807A1b141982914d] = 24;
    holders[0x3c6575D71C02991dBE974703D0895622729A0450] = 44;
    holders[0xa25803ab86A327786Bb59395fC0164D826B98298] = 24;
    holders[0xf532920bb32122D6475aD4Cc7634dC3a69631902] = 44;
    holders[0x0c9A83120E744533FC78c02ACA5d25784Ca3825D] = 18;
    holders[0x679B3E6c39c07BAC7d4d55B8b7E9a9aA40c94C8f] = 183;
    holders[0x94de7E2c73529EbF3206Aa3459e699fbCdfCD49b] = 28;
    holders[0x00de86CbE88e953C38Ec6Afb20E34F3c0F5762C9] = 12;
    holders[0x8D1ca5aA9c95BE98Bae314B67B839c700278BFFD] = 12;
    holders[0x0907B14771F2b04c5A4643E611d23f7e988bD35D] = 22;
    holders[0x8fc082B2e73f89c6aacd7154871E11e102b554bF] = 22;
    holders[0x7Ef082b9a971f198f9ddE7f3c331B16a43D76EFf] = 22;
    holders[0x4D200d3e268B4A33a831e7ba58aCdF93eA79A1e5] = 12;
    holders[0x5654967Dc2C3f207b68bBd8003bc27A0A4106B56] = 22;
    holders[0x81b9A5F21efDB5DF0210471B9A94E0d4ad9951Ed] = 12;
    holders[0x82B1F29C5608238DF2618F996827933c0d844079] = 42;
    holders[0x34816B3DF346aB26077e32a6749A4E117Fea6A0D] = 12;
    holders[0x952440136379bA4cEEf92FF49fb122C4Ace0B810] = 12;
    holders[0x9D35001Ad4Bd89a33aF351660fe64970A5bea966] = 22;
    holders[0xA17b595EDCb5C66c532C830E34e823A3E0033c8E] = 12;
    holders[0xb89c2F6Bb674BD6aACe2a1E274D40E6dC4775b15] = 22;
    holders[0xD36F809FF66a9923A19F501794BfC0e7Ded82F1C] = 12;
    holders[0xFAf9f63bAf57b19cA4E9490aaab1edE8b66Cc2b5] = 22;
    holders[0x4Cdbc5B55B7D8dB0Db547aCca098985c325dBba9] = 11;
    holders[0x5b54A0DdF261C08eeAC0A95EF27403F4541afd36] = 6;
    holders[0x632463e42b3bD9Be625F6008934Fc2770FCdE2C3] = 6;
    holders[0x77D649c13e5d5Ffe27318fECD365542384874ae9] = 16;
    holders[0x7c18db094612b2e43f8a3aB58dd412dF81dd3A76] = 11;
    holders[0x83F0AA19eF7aD4C79e995DD684E06B5b44D3647c] = 16;
    holders[0x86bf68e0ef16F5789479bbDB7b338645A9695Ff6] = 11;
    holders[0x9125d4df196BD2B218A23e050A1c2d70d3CB8451] = 6;
    holders[0x94db5F225A1F6968Cd33c84580c0ADAe52a04eDF] = 6;
    holders[0x06c58575561e80fEa3F50CafbFd3C1968206F532] = 6;
    holders[0x1118675842630a06bb517C1C3CB93E682D31E4E7] = 11;
    holders[0x98aDF18918eB2702629387914854584B9D76d0F0] = 6;
    holders[0x12Cba59f5A74DB81a12ff63C349Bd82CBF6007C2] = 6;
    holders[0x1F41d663B8428986F0d0a2147b903C37419de265] = 6;
    holders[0x006fD9F7547c8b7320eC83EB253F09a69cDd8452] = 11;
    holders[0xA334123911E9C7cD938C020826c93101ef15A9EA] = 6;
    holders[0xaA9D28DFDC86D5B9ad6cd1A6E9178230836d086C] = 6;
    holders[0xAd8D22b89E55490e72bB5b06971F47C4B329e8b2] = 11;
    holders[0xb6E523cFB6176339331C68d33eC7133aa5E5CFD8] = 6;
    holders[0x2F371d7bA024B605c663FF07f713b78891dAb077] = 11;
    holders[0xbbE7148F4e5D7c607845b60C39A21173c0E0a77b] = 11;
    holders[0xC16FCfAD0A200bA8eB1dd428d90a9064841B8e52] = 16;
    holders[0xc265d173ebB98661E2A8647786f9D8549B5026F7] = 6;
    holders[0xc589630A48C26920BD1DEca9DD522Aa547380f4e] = 11;
    holders[0xc5B1aa889bC3f5A926b03b51A930369fd260e825] = 11;
    holders[0xc5b669a4d4550e63bdb4069dB56be0bA570fA1c9] = 6;
    holders[0xc93C7f71581DFEAAb59BEd908888dAC5689F312a] = 11;
    holders[0x2f77ca1F5339bcbdd99d466BEA714D3d87F3a422] = 11;
    holders[0xd8C73bceF080f33E37ea5a415bb0778ECD72Ce3B] = 11;
    holders[0xDa8EF420ed193cC11F69538dc02b1a9f237AFFb8] = 11;
    holders[0xdF5569a35E391E7093Ca75C84e840220556ED483] = 11;
    holders[0x32F2895b0b5F00fF53EC6279F02876a6cABC3c85] = 11;
    holders[0x3E02Ac054398e2C7886A4739AD3214163238872d] = 11;
    holders[0xeCa2444E8672aE3DE62eb816Be0F0e1F4bd03443] = 6;
    holders[0xed8c8316FDDC69bEf4D0ae2442F548278a9b2c79] = 6;
    holders[0xEE667Fd066Dab365E73BBF40Ff63764F890234F5] = 16;
    holders[0xf0c57291206e5220290d7F79853Bf6271aD23873] = 6;
    holders[0xF4cD60A92A7D20997d8dD3ed30eB7B340F05f135] = 11;
    holders[0x2BE830C9c4A3eB3f9eBF736eED948e9ec1f1f33b] = 6;
    holders[0xF65c1c42745606E397bb2993E25E09382a16Fb87] = 26;
    holders[0xFAe9BC4D8cd2B8c9909a35Bc98fBB87AEd6EEFCF] = 6;
    holders[0x48Af2bD40905F8D48d187eCb3c6BBc19Ec21C795] = 6;
    holders[0xfC0d9421eC25bf1e669ad190933CBAFA1666Ac46] = 6;
    holders[0xfe03A6189Bd15ba376bE7D28eF6f4E9d484dB79e] = 11;
    holders[0x74E2560995ba0b3E27539CEa74D40b784F54689c] = 130;
    holders[0x3689c216f8f6ce7e2CE2a27c81a23096A787F532] = 85;
    holders[0x6761BcAF2b2156C058634D9772F07374D6eDeF1d] = 65;
    holders[0x900E7aD1ab18CeBb4c21F71795364E9B636831CA] = 65;
    holders[0xE4Bb5b561D23313c89f53d80f049545f1AFD2CAF] = 65;
    holders[0xDFc11349cB2B6368854318b808B47C87F32C7Efb] = 40;
    holders[0x797108B82F70c2D25af9b0811DEd36b403C6676f] = 25;
    holders[0x882FDC83DBfABF22E5dCb6825771E96e9f35c23D] = 25;
    holders[0xc1EDD3eDBa76046C9768d18a4d472950cFC4B73c] = 25;
    holders[0x5306605E4A0c5b3F9E2CaEcf35D454c8EBe8b22D] = 20;
    holders[0x001b1e09360cdcC6ED239bea65ad038B19B5a4Cc] = 20;
    holders[0x0755FB80b9caA1e4cAfb3ADF9385c4b5b4de7E65] = 20;
    holders[0x087A7AFB6975A2837453BE685EB6272576c0bC06] = 20;
    holders[0x092cfF73c77a9de794D25b0088DeD0e430733dbb] = 20;
    holders[0x0c0ffaaF6378cc0B4118F2752209a206A046d56E] = 20;
    holders[0x0fF0D95050370A1Aed1a1c635272a26F149E48D0] = 20;
    holders[0x16AB039af1c7C2d15b1545729A69A342a4f965cC] = 20;
    holders[0x458Ee444C009BBFe39e7Dc83960Cd81441281cD7] = 20;
    holders[0x6dd9b8A7410b0709b4a98765185e8bdFf7637CA8] = 20;
    holders[0x71be99c9b5362aD07f7f231bC7a547f4119C6073] = 20;
    holders[0x7DECf7a31168778f311c57B9a948aBaa7321001E] = 20;
    holders[0x7fd0E596CAc14dA495D767AB5136D332B4DB094B] = 20;
    holders[0x8Dbbca57Ea56290Efa14D835bBfd34fAF1d89753] = 20;
    holders[0xB1258f8C92c969F7FEBC1AC266eA7ABB6249885b] = 20;
    holders[0xB128b2b054a0D57a0dc3E6CEFBc65573CBC29f74] = 20;
    holders[0xbA6a52F8FAb6d32372E232Bfa0833cEE835F1Dd3] = 20;
    holders[0xBBe846566F2172AdC9c0bCdCCf8D280Ad60dfa67] = 20;
    holders[0xF3b82dD8E52bA3C406a517D3E5F850a409f91462] = 20;
    holders[0x81f92d6083C55033813DAC35B9DB0827F525D9c4] = 15;
    holders[0x02CE51592Cad04ED45d6F9D13833238d6BEa2C9d] = 10;
    holders[0x030742656372b8107801cfB20d7451F9573aa246] = 10;
    holders[0x08074907281C467e0f447a583e328F3054Ba3031] = 10;
    holders[0x38A161d47F01B375f505FCB13e73A315819c7eB3] = 10;
    holders[0x3aBfC7FFA744edc456D361Be957f972D1BaC4991] = 10;
    holders[0x51642A3f1E8242005630cAFcA692561E5A5fb4e6] = 10;
    holders[0x552f01d67B352AAa38bC675e30ceD97f2451DF63] = 10;
    holders[0x585ebfCAd82A7de814290FCf5aC7F929c5411409] = 10;
    holders[0x59560854986b354D2DBc4368a09526daE0B244db] = 10;
    holders[0x6d58491c6F68426966DbD6a1682195aC17b95db4] = 10;
    holders[0x7971e007A4E4D4dc1F8380f5d91d3F52B5e53461] = 10;
    holders[0x945a5dbc95fDD6c0Aa873ACfc0d3CD4888E28E61] = 10;
    holders[0xa5d981BC0Bc57500ffEDb2674c597F14a3Cb68c1] = 10;
    holders[0xb17bFA989e00c7b0d17e52d3e90Db440d2d7Ee5f] = 10;
    holders[0xC2172a6315c1D7f6855768F843c420EbB36eDa97] = 10;
    holders[0xD6587a974C7D3ecE23Fa53d5606da6B291311F6f] = 10;
    holders[0xF6210B4bB2fe841630EB50001E688c4BC058B602] = 10;
    holders[0xf873BeBDD61AB385D6b24C135BAF36C729CE8824] = 10;
    holders[0xFf5A223EED941DA818D57bFe1A84A030b62DEa31] = 10;
    holders[0x09EaA08f8E288d34D416B92c53cADAFB5cf1209B] = 5;
    holders[0x0d5D10C539ceA9f5B7Db9412f93048deE6FD9B2e] = 5;
    holders[0x0e20029447Dbe48e27f8AD9d34d47a32Bc713928] = 5;
    holders[0x0ec348908EE90ADB46622BCb1EceA7f73213Ff34] = 5;
    holders[0x0F44Ba79089D8E6a089575187d7e1d9A81e71A05] = 5;
    holders[0x1688733A26CC3f6689dA840dac602f60E4F501D9] = 5;
    holders[0x17476d0Ed31f81d95b5ba8960b2D0b4dE4675e64] = 5;
    holders[0x1aeB8eb8F40BEEccD58E9359a154309D7014A5E5] = 5;
    holders[0x1D34D0fd5132e4eb8b07d829198752AFB6B4db81] = 5;
    holders[0x1E62E441D2E1D83354aa811464236625ADF4c543] = 5;
    holders[0x1f8dec5061b0D9bF17E5828F249142b39DAB84b4] = 5;
    holders[0x26141f4A62f498A61eDE1eDaA6407525bc023144] = 5;
    holders[0x2ad6FA4db57Ac71479510863643Eb6b1991788E1] = 5;
    holders[0x318073b9c5e6384B581adf0237F4C998D405dbF5] = 5;
    holders[0x32dD9F6885332CCf8633A18CB0c2e25e68fE03d1] = 5;
    holders[0x352bc0714883edAAE33F279B1920C4aAa59C1f15] = 5;
    holders[0x35Ca14EdabB3Cc0D3fA01808Dd9AB5deeB59b63a] = 5;
    holders[0x36A5Bc205DF1ED65C86301022cfc343a6ce546ff] = 5;
    holders[0x38F1DfdcaF2F0d70c29D4AF6a4AA9E920efe8B18] = 5;
    holders[0x3993996B09949BBA655d98C02c87EA6ABf553630] = 5;
    holders[0x3c061e4f94F198c80A7a78b345C4a1D5450f9544] = 5;
    holders[0x3C3471Bf8743aa386C86Ab8111596457E6f222cE] = 5;
    holders[0x3da8D0E54d1860dc6B6f41ea7c45C2B09d4D84Da] = 5;
    holders[0x3deD646035E0aC9A4eEab15496b8Fc008BCF4a49] = 5;
    holders[0x3F1c0EA76342Cc3427962452891F8DE8649a301B] = 5;
    holders[0x4059f3c0064cd380276DE8dbAb6935005535EeD6] = 5;
    holders[0x42Dd10D6315EcDfCBfcc8EcEaCCa0BdC9539acf2] = 5;
    holders[0x461A5B8326bA0e2DFd133651A3b559Dc8d3B0400] = 5;
    holders[0x471817544C1aa78a99BB3eD17123818352946868] = 5;
    holders[0x49ca963Ef75BCEBa8E4A5F4cEAB5Fd326beF6123] = 5;
    holders[0x4d6758BA3561a39ad29507363Edff464303B4695] = 5;
    holders[0x4f764a08c66251e13bdd85B4Bb0652B739736328] = 5;
    holders[0x50c9f760885C3c44316B631Ff92e7C2CbbECb19d] = 5;
    holders[0x526cDD9643A470AED37917630631eBF389F73Fc8] = 5;
    holders[0x558FB213a99EFC4476Ff2F1e0EF4eA7D002Fb85A] = 5;
    holders[0x565E2a7608b2A21700207BFFf860063A6aD2D21b] = 5;
    holders[0x5711541Cf035c906f0ddB073F102dCE0092Fc7a2] = 5;
    holders[0x5747974E9709C7750fb9a812AD16D34F6772D4CE] = 5;
    holders[0x59a65ff3187fE27e2FCeA9e93C90599BE4486Bf0] = 5;
    holders[0x5a3E28c2Bf04989E6a7506A9EF845Ae2dbc6d90A] = 5;
    holders[0x5C67bD4336Fc3592d14a59D3C2d44Fd782839008] = 5;
    holders[0x686ec32C61aE7d3fF16e26403EBea633274cDFB9] = 5;
    holders[0x69da4ccC1e4c56949639558B21ab52Da336E5FbA] = 5;
    holders[0x6A475000F308d195D2E319E8a31ce95867Af5354] = 5;
    holders[0x6B67623ff56c10d9dcFc2152425f90285fC74DDD] = 5;
    holders[0x6E91677c6B020208499AC0fB5a797BCb9e27f886] = 5;
    holders[0x70E680b9493685f72E76243C09993Fca768EEDf1] = 5;
    holders[0x72F711e517e8A7F67f6e44C1d5A19dBb31E96b53] = 5;
    holders[0x7f623AcFCd18a99e7Ce01272D1DC4eE187d46EB6] = 5;
    holders[0x808A023B72260170c95d831F589A1ae0DCa1e43E] = 5;
    holders[0x89d42f152A826E28c69413Ec5C98E6bCCB7c7ABF] = 5;
    holders[0x8a1E60974457ebD606926365eA87A87CC5d46d4B] = 5;
    holders[0x8b7a5B22175614EE194E9e02e9fE0A1B5414C75E] = 5;
    holders[0x8dF3a7934d5Af13bDA4de698fE1B470D3c281F89] = 5;
    holders[0x8eB514633F8fC1aEE4B405F8165f3EEb42826F6d] = 5;
    holders[0x90238A0A150C47e326A19AD38f05700021fCfa62] = 5;
    holders[0x928881096F57781e91c35c8C7090CB0aeEd2213B] = 5;
    holders[0x92b224ec3f99753f5b3f5E2Cc12C09a306D99FFa] = 5;
    holders[0x93b4c52EEb09b613Febf3267914c04ab38F3A635] = 5;
    holders[0x95b8c7B99862AC54372D20307905Ca85978Fdf16] = 5;
    holders[0x97a97445090044357ebcAE34e08D3DD7F1E44bDC] = 5;
    holders[0x9953DA7f2161866afAAD3c844CaaeE35A262a001] = 5;
    holders[0x9CA4692f1DDa3E3be64Be8520b1ae35E980F64a3] = 5;
    holders[0x9CF76F47648D0Baf115ab5633E3da9628C999a0D] = 5;
    holders[0x9cf7cFE084fD48F728CBf300Ada43e94b9AaCc02] = 5;
    holders[0x9d30CA11C4a2Fa4479ca14710c60a3BD4c1CA2f1] = 5;
    holders[0x9e199d8A3a39c9892b1c3ae348A382662dCBaA12] = 5;
    holders[0xA158FFb97Cc5b65c7c762B31D3E8111688ee6940] = 5;
    holders[0xa3246c883e89e9bb51369eC1Ae543F57db7e41b1] = 5;
    holders[0xA37FbD2264b48ED56Dd7dE8B9B83DB35561700eF] = 5;
    holders[0xa5f146cBd3eE13F482315dD0F873c2bFbBc5F2C4] = 5;
    holders[0xA809401d17444C9c26b990abFC6751059687477A] = 5;
    holders[0xaA37e451863b52f3e86521e4805FdDC04658fbb1] = 5;
    holders[0xaC4109A00aF7d892bE8512E82a9C82CaE63DE88b] = 5;
    holders[0xAE91CB00C413A8D6089Ba0bc8bF66fbA47A912Ea] = 5;
    holders[0xaF9208e9a7a67723FaFA9548cf876785C239f4F2] = 5;
    holders[0xb39fF833f6B42D474Bc649E3f435856c8F0CB426] = 5;
    holders[0xB48037BD8eeb113501D7e6690beB44438d5603B5] = 5;
    holders[0xb4Cb5A106A569B3664D3A9eBAA82Ee6995673DA8] = 5;
    holders[0xb9074044b4A8d60112701Be1177d6676de43A662] = 5;
    holders[0xbB2a234ab7f84c2d806D06365Ff8D6DF52e5D367] = 5;
    holders[0xBf00cAeE3f4d0E654b5E1A557914D257f126d055] = 5;
    holders[0xC0ae85CD4bA82cbC440b2F7633fCAf8f4b29Bab1] = 5;
    holders[0xc101598AC79799585D67B0801544c260A427448B] = 5;
    holders[0xc3956F9E14E62bfE00672ac5a4B5d11f84D8b5B2] = 5;
    holders[0xC3ab77cA48Fb64B968DB398e5ED6543141Cd38ce] = 5;
    holders[0xc418E406BF6F52edd4E17e7176a781680b2C2b80] = 5;
    holders[0xc43473fA66237e9AF3B2d886Ee1205b81B14b2C8] = 5;
    holders[0xC4ccf33D34ED3E65fD7EA2cF9407a8727412F213] = 5;
    holders[0xc912F2f8404dA1AD56F899bD2ee9d4a438eC5fD6] = 5;
    holders[0xcf88FA6eE6D111b04bE9b06ef6fAD6bD6691B88c] = 5;
    holders[0xcf90d8bFF11e8Fd22cAAe500d3f3c018cF47e6ff] = 5;
    holders[0xD0cFE8dA409D0FD31908E4913bd4547Ed988b178] = 5;
    holders[0xd13e4780AE2e4DF44D4195A169ED1Be557E8762B] = 5;
    holders[0xD20Ce27F650598c2d790714B4f6a7222B8dDcE22] = 5;
    holders[0xd47Fe94Ed7Bb7EA874ddc42De13c37C2cAD0Df74] = 5;
    holders[0xd5b171571Df3Bc207baF2EdB175B6Ff3820f53A4] = 5;
    holders[0xD6F6ADF60BBDd7b573cae0329EA85978cCB60448] = 5;
    holders[0xD74b2622b7b05FCdcF81E01FeD06F5Dc7Feac5C5] = 5;
    holders[0xD787001237818C10614bc6ceF5D39cCb0348a9da] = 5;
    holders[0xE28E27239D891762024863D40A19338DA8559792] = 5;
    holders[0xe3D78cE35d90BC404A71121C4585b138BB3d419e] = 5;
    holders[0xE4067ED66738dBDC7b8917703C8c380d898033F8] = 5;
    holders[0xe485656EC623115Bf2d445B925DB5D63707Bf74b] = 5;
    holders[0xE6C6E985b8624c2e7D4C27c58f9CD82eE1751f9e] = 5;
    holders[0xe70F96c23565Ef506E229d7537e27367fb4fb034] = 5;
    holders[0xEFCC4C68e1dDFaA4f0FA3a7479F0fB082f96A56b] = 5;
    holders[0xeFFfDc05e7c5B305Fbd504366B01f2d6424cB8c4] = 5;
    holders[0xF1D46B053c5e288C1e83dBDe0598a3984F4cB04e] = 5;
    holders[0xf353b57Ffe0506A44950805395E5412F42181dD0] = 5;
    holders[0xF40Fd88ac59A206D009A07F8c09828a01e2ACC0d] = 5;
    holders[0xF4E115673718Bb540665Ae901f392f96996fb336] = 5;
    holders[0xF63E7E364bA2A8cE99c34563A9768B3BAfF65D1a] = 5;
    holders[0xF6a242191ca16FB561403182a2c7A023F2261eB7] = 5;
    holders[0xF877553C838d12374B0aca57F532c464bCC2550C] = 5;
    holders[0xFd845e07717B0329D3F19fc920C97FBA0bC4ee31] = 5;
    holders[0xfE4F13D15392472fE3849AdC9c559B78243FD6f7] = 5;
    holders[0xAa263edb6bb2eab2E4013bBE90e726753fCF5AF8] = 5;
    holders[0x5b5c07d088B25F8EEbE2A5Bea784A1f07145bCb7] = 1;
    holders[0x67b847858EcEc3F56800d059045e8E686D5B32C6] = 1;
    holders[0x1890E5713a9dBc98cd2146D0Dc2fe5A9a157DF92] = 1;
    holders[0xB4B8Bb5A5ceA4FeB48d0F2bFF040086A98E31d76] = 1;
    holders[0x6db59d87046899232Ff5E89f29853B5aEa71896A] = 1;
    holders[0x6556751caf10474B9Bd8b31eE4b0bb4420aAfFB4] = 35;
  }
}