// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import {LicenseVersion, CantBeEvil} from "@a16z/contracts/licenses/CantBeEvil.sol";

contract Raverbull is ERC721, Ownable, CantBeEvil, ReentrancyGuard {
  using Counters for Counters.Counter;

  struct ClaimOptions {
    string key;
    uint counter;
  }

  constructor() ERC721("Raverbull", "RVB") CantBeEvil(LicenseVersion.CBE_NECR_HS) {
    _mint(owner(), 0);

    allowList[0x1377C0B62f0c8E3bAE326E7B54B177f1856986DC] = true;
    allowList[0x176890a5c1C20aA8518e2aE5f3f218B66E4BF12c] = true;
    allowList[0x17c52379865532213d83fD30c7f4cA95Bf6B6568] = true;
    allowList[0x1a1C58dD9Cc0D22417c4b048C71b9Cc8a94a3e84] = true;
    allowList[0x1c4633F750ccdF4f40C9e88f5986A80c814B851f] = true;
    allowList[0x2A9c716c317287ecd971Aa18925372948eAD86b7] = true;
    allowList[0x2C1203eacA42eEA56323a884a706982EDf01235A] = true;
    allowList[0x3F358b4E54385ba4fc8dD9EA718d360db5C7fDa5] = true;
    allowList[0x4eC3B52C788f58a6f273F33e4cbC38ae2cBfE6C8] = true;
    allowList[0x505F8439C86FDc49058a601F6d64D5f76585BC1d] = true;
    allowList[0x5855CC406044d478A14B9840C1C1f2Df4cEBc2C4] = true;
    allowList[0x5Ac1f5CD023394B18632357901052133Ef66B614] = true;
    allowList[0x62E1Ab51A839c87dBB6e124c51E714118199CD7E] = true;
    allowList[0x6d1Ccd5270AA94E9d06C9E5Aa125fF7E090E7c86] = true;
    allowList[0x7418498722f82840F90D992313d6BB7AAfa8F152] = true;
    allowList[0x74Ca06274bd0D06ef3dBb25630560BaA50d4Bc63] = true;
    allowList[0x7F885D506b878F0EF2a9b58E17f7AD5975FdA0A0] = true;
    allowList[0x7FCbCa1C8C3E36c78Dfb67cc7DF0b71d1c201703] = true;
    allowList[0x83bE780f4147eC883d5ECA080F4B574f4EFDb69a] = true;
    allowList[0x963f7bA3B9053a3c68F112cAEC3878C7b2121a57] = true;
    allowList[0x9c173c872220040Cff865B18A50B112134A4a2Ba] = true;
    allowList[0x9CC091d4ecBD41434079dE3f80283E96912f2421] = true;
    allowList[0xA7BeE1615b17FBBF75483ae6061c6C4dA222e94b] = true;
    allowList[0xB6437104ff3a0eb30402d705dFD3a730FBFa4699] = true;
    allowList[0xb8bc655b69a848A2C7173180CD54A11A03b64493] = true;
    allowList[0xbe1b9738C58289B41840CF1E5888960e20D06F03] = true;
    allowList[0xC0698E334AB328960f53257fB25812813D3B184c] = true;
    allowList[0xC4cFB6bA8B70C414459045D120fB41162850205A] = true;
    allowList[0xc57F0f2E842390fccC9C6E97897d952f54671445] = true;
    allowList[0xcE0d0A205175200CFF87afa13D30f1D6Ea4aBb90] = true;
    allowList[0xcE61597db633cba20f519359B8E8123a5fc86dd9] = true;
    allowList[0xD23eA787D7147966a50fc3397AEe589CcE269Bf8] = true;
    allowList[0xd56995A017969BFc4c934dDcA9Fa9fbf6E5b1eC2] = true;
    allowList[0xE23c434aeaa6C9C76724C4a492D17e7EEa55291D] = true;
    allowList[0xF9BC776A6A4417Ea3de266bF63a6F7c33CF026Bf] = true;
    allowList[0xfc989919B21e927C3248668471C2d35B3F641B36] = true;
    allowList[0x5aD1AeE54c4DD5E7967A5B6c0014C11f95f5D7fc] = true;
    allowList[0x98dFe9a86e6a80D914C2D246980d70A221fe0f1E] = true;
    allowList[0x306de2e49B06BA91e36c50F6e73f57A1BD02a746] = true;
    allowList[0x98697CD87E42540F545ec445e864cc788369B097] = true;
    allowList[0x1A2Be848d7958570966cC20b1C521d8945cDA8C1] = true;
    allowList[0x23E31129bfA2d2E4bda3d3C0c20695b7E666e329] = true;
    allowList[0x285d75F141a9A7A283849dF381697029cC6F37c9] = true;
    allowList[0x2A1701e979ec7c2209964aCbf4686dAAa68e9929] = true;
    allowList[0x2a654A3508513E4a3890d75E47962821F2B7D09d] = true;
    allowList[0x40d4b664317E57dBAa71d261A576d9bcd4a4f602] = true;
    allowList[0x4E8Ada817B9d0469191f2aB00722e189Cd0cf717] = true;
    allowList[0x51DC203b441608b7eB99c35f076C05e1A0aD3931] = true;
    allowList[0x5e757456b2b6A66B6facF9d285fBD28a8b9a0530] = true;
    allowList[0x72BB8b8fC002d9F09dF9C5ccE23E932262BAEb05] = true;
    allowList[0x83F7fB78d50250619EEf4b1c4B082c21fa68D9D3] = true;
    allowList[0xc7230D095b012A4E5EA9A4A98961Fd90c369857a] = true;
    allowList[0xc7A6968B09CC80a48B7faE3DF0ffc959eeD9Ff2d] = true;
    allowList[0xcf17004d58758CAd61eB5ac475F8e06C3619E6da] = true;
    allowList[0xD436e550282161DC6ADD1dd266049eb4C13FC685] = true;
    allowList[0xe5dcB8d2DeeBBD756A401ad3daDd8d5c7Ce6d081] = true;
  }
  
  Counters.Counter private supplyCounter;
  
  mapping(address => bool) private allowList;
  mapping(string => mapping(string => uint)) private Utilities;
  
  uint256 public constant MAX_SUPPLY = 76;  
  bool public saleIsActive = false;
  uint256 private price = 2500000000000000000;
  uint256 private allowSupply = 2;
  string private customBaseURI = "https://raverbulls-metadata.apollx.workers.dev/";

  /** functions **/
  function mint(uint256 id) public payable nonReentrant {
    require(saleIsActive, "Sale not active");
    require(totalSupply() < MAX_SUPPLY, "Exceeds max supply");
    require(totalSupply() <= allowSupply, "Exceeds allow supply");
    require(id <= allowSupply, "your choosen id isn't in the mint range");

    uint256 calculatedPrice;

    if(allowList[msg.sender]) {
        calculatedPrice = price * 90 / 100;
    } else {
        calculatedPrice = price;
    }

    require(msg.value >= calculatedPrice, "Insufficient payment");

    _mint(msg.sender, id);
    supplyCounter.increment();
  }

  function addUtilitie(string memory tokenId, string memory key, uint counter) external onlyOwner {
    Utilities[tokenId][key] = counter;
  }

  function claimUtilitie(string memory tokenId, string memory key, uint count) public onlyOwner{
      require(Utilities[tokenId][key] > 0, "this utilitie is already claimed");
      require(Utilities[tokenId][key] >= count, "you want to much");

      Utilities[tokenId][key] = Utilities[tokenId][key] - count;
  }

  function getUtilitieByToken(string memory tokenId, string memory key) public view returns (uint) {
      return Utilities[tokenId][key];
  }

  function addAllowlistMember(address member) public onlyOwner {
      require(!allowList[member], "Already a member");
      allowList[member] = true;
  }

  function removeAllowlistMember(address member) public onlyOwner {
      allowList[member] = false;
  }

  function isMemberInAllowList(address member) public view returns (bool) {
    return allowList[member];
  }

  function totalSupply() public view returns (uint256) {
    return supplyCounter.current();
  }

  function setSaleIsActive(bool saleIsActive_) external onlyOwner {
    saleIsActive = saleIsActive_;
  }

  function setBaseURI(string memory customBaseURI_) external onlyOwner {
    customBaseURI = customBaseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return customBaseURI;
  }

  function setPrice(uint256 price_) external onlyOwner {
      price = price_;
  }

  function getPrice() public view returns (uint256) {
      return price;
  }

  function setAllowSupply(uint256 allowSupply_) external onlyOwner {
      allowSupply = allowSupply_;
  }

  function getAllowSupply() public view returns (uint256) {
      return allowSupply;
  }

  /** PAYOUT **/

  address private constant payoutAddress1 = 0x98dFe9a86e6a80D914C2D246980d70A221fe0f1E;
  address private constant payoutAddress2 = 0x4Ef388101B4FbE7fD047b9a7DF725012BB5ddE19;
  address private constant payoutAddress3 = 0x76463118B07Fff69a87d7421489ff57882369F20;
  address private constant payoutAddress4 = 0x5aD1AeE54c4DD5E7967A5B6c0014C11f95f5D7fc;

  function withdraw() public nonReentrant {
    uint256 balance = address(this).balance;

    Address.sendValue(payable(payoutAddress1), balance * 25 / 100);
    Address.sendValue(payable(payoutAddress2), balance * 25 / 100);
    Address.sendValue(payable(payoutAddress3), balance * 25 / 100);
    Address.sendValue(payable(payoutAddress4), balance * 25 / 100);
  }

  /** ROYALTIES **/

  function royaltyInfo(uint256, uint256 salePrice) external view
    returns (address receiver, uint256 royaltyAmount)
  {
    return (address(this), (salePrice * 760) / 10000);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721, CantBeEvil)
    returns (bool)
  {
    return (
      interfaceId == type(IERC2981).interfaceId ||
      super.supportsInterface(interfaceId)
    );
  }
}