// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import {LicenseVersion, CantBeEvil} from "@a16z/contracts/licenses/CantBeEvil.sol";

contract TOKYBiRDS is ERC721A, Ownable, CantBeEvil, ReentrancyGuard {

  constructor() ERC721A("THE TOKYBiRDS: PENGUIN", "TTKBP") CantBeEvil(LicenseVersion.PERSONAL) {
    _safeMint(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, 419); 
    _safeMint(0x1D7F6Cd734be0F2891a3dcDAc7e37C3153742D24, 5);
    _safeMint(0x4273954Bb49EA84f3274a6D249d183D4CB2b092C, 5);
    _safeMint(0x6b8aD1a74dd8df635214dac0c7456A7Cc283131A, 5);
    _safeMint(0x6348fC81ba0eC56fE2416f3e3aeC320fEdc2dbEC, 5);
    _safeMint(0x01B41F68175EFa2Bc63cEd2fE661d56e604A411E, 5);
    _safeMint(0xF06024af14Bf684b95E912709f84aacDc70Dc149, 5);
    _safeMint(0xf10984224cA28F357883E387932CfEEd178a7A19, 10);
    _safeMint(0x43F92F608E9b07Ea4Fe81a27A7E500Ed857dFFAC, 2);
    _safeMint(0x397Bc3A4DA2B9e50dC8FdA61f21b2f9060914B85, 5);
    _safeMint(0x4Ef388101B4FbE7fD047b9a7DF725012BB5ddE19, 30);
    _safeMint(0xebE7E229783dC3fadfa4dD8b2e3C42e5E9180337, 1);
    _safeMint(0x75BD899F753fc78B8506A203C0D27851cBFdbCA2, 1);
    _safeMint(0x205BBBE1b5EE65efFe19c5DD59b84AD1413BBB77, 1);
    _safeMint(0x99f5de92ce243C25793Bc4a5183391B8c78a24A1, 1);

    internalList[0x505F8439C86FDc49058a601F6d64D5f76585BC1d] = true;
    internalList[0xd56995A017969BFc4c934dDcA9Fa9fbf6E5b1eC2] = true;
    internalList[0x62E1Ab51A839c87dBB6e124c51E714118199CD7E] = true;
    internalList[0x4eC3B52C788f58a6f273F33e4cbC38ae2cBfE6C8] = true;
    internalList[0x5aD1AeE54c4DD5E7967A5B6c0014C11f95f5D7fc] = true;
    internalList[0x98dFe9a86e6a80D914C2D246980d70A221fe0f1E] = true;
    internalList[0x1B385720270eA9Aa5923597D8d79DCa3Baa87A65] = true;
    internalList[0x306de2e49B06BA91e36c50F6e73f57A1BD02a746] = true;
    internalList[0x98697CD87E42540F545ec445e864cc788369B097] = true;
    internalList[0x0d216B7cd5039a8Af360B57c79360f01C42Ae090] = true;
    internalList[0x1A2Be848d7958570966cC20b1C521d8945cDA8C1] = true;
    internalList[0x23E31129bfA2d2E4bda3d3C0c20695b7E666e329] = true;
    internalList[0x285d75F141a9A7A283849dF381697029cC6F37c9] = true;
    internalList[0x2a654A3508513E4a3890d75E47962821F2B7D09d] = true;
    internalList[0x40d4b664317E57dBAa71d261A576d9bcd4a4f602] = true;
    internalList[0x4E8Ada817B9d0469191f2aB00722e189Cd0cf717] = true;
    internalList[0x51DC203b441608b7eB99c35f076C05e1A0aD3931] = true;
    internalList[0x5e757456b2b6A66B6facF9d285fBD28a8b9a0530] = true;
    internalList[0x72BB8b8fC002d9F09dF9C5ccE23E932262BAEb05] = true;
    internalList[0x83F7fB78d50250619EEf4b1c4B082c21fa68D9D3] = true;
    internalList[0xc7230D095b012A4E5EA9A4A98961Fd90c369857a] = true;
    internalList[0xc7A6968B09CC80a48B7faE3DF0ffc959eeD9Ff2d] = true;
    internalList[0xcf17004d58758CAd61eB5ac475F8e06C3619E6da] = true;
    internalList[0xD436e550282161DC6ADD1dd266049eb4C13FC685] = true;
    internalList[0xe5dcB8d2DeeBBD756A401ad3daDd8d5c7Ce6d081] = true;
    internalList[0x10dCe864331D19db5Ed32756E853088f2e20453A] = true;
    internalList[0x205BBBE1b5EE65efFe19c5DD59b84AD1413BBB77] = true;
    internalList[0x4f59722B18de4D618F8285aAcE57a71978178C3d] = true;
    internalList[0x32417DC69162e493CAE4648E6919e468b28a2F56] = true;
    internalList[0xc33677886f9980C429Bc64a7BE5E9Ed18E354384] = true;
    internalList[0x8255ba454dB61eEDE8347482d71372469569D7D2] = true;
    internalList[0xe6bAECf4Fb5889CF998D04F3c2ae970C3b12E7e6] = true;
    internalList[0x9163f3249fea0663F324B52dfc97F4f7EDdD6aF6] = true;
    internalList[0xD63270bEe3075a2cd9cdC25BfBb246657791B0F8] = true;
    internalList[0x5B25aDe8dba55FE6d3d7F77190185048998729E2] = true;
    internalList[0x7C5361F5BB5e2Bb123C95e69BEd331f3b0b8f094] = true;
    internalList[0xF06024AF148F684b95e912709f84AacDC70dc149] = true;
    internalList[0xbe50b30E098a5c17c5F993b832914ba682200c20] = true;
    internalList[0x0b5F351101F03A343bABa870b7C7929da6317da1] = true;
    internalList[0x0b8DCF6d34E60C0A38B8620Af5db467D873B99aD] = true;


    allowList[0xb823A2af2B296426899199C683fFb51aBD8a24dA] = true;
    allowList[0xa5f146cBd3eE13F482315dD0F873c2bFbBc5F2C4] = true;
    allowList[0x32417DC69162e493CAE4648E6919e468b28a2F56] = true;
    allowList[0xf9bDCe15F2723a58b5B40539C1C0b32876beB73c] = true;
    allowList[0xc33677886f9980C429Bc64a7BE5E9Ed18E354384] = true;
    allowList[0x0b5F351101F03A343bABa870b7C7929da6317da1] = true;
    allowList[0xEDD000b7dB3cB8931d4E0Cb1D0dbe68947CEB09A] = true;
  }
  
  mapping(address => bool) private allowList;
  mapping(address => bool) private internalList;
  mapping(address => uint256) private mintCountMap;

  uint256 public constant MAX_SUPPLY = 3000;  
  bool public saleIsActive = false;
  bool public saleIsAllowlist = false;
  bool public saleIsPublic = false;
  uint256 private price = 55000000000000000; // 0,055eth
  uint256 private MINT_LIMIT_PER_WALLET = 9;
  uint256 private MINT_LIMIT_PER_TX = 6;
  string private customBaseURI = "https://tokybirds.mypinata.cloud/ipfs/QmXQThhRkeETYykVrMtSxRqzGvirudVovLYPmoYzFKEBC6/";

  /** functions **/
  function mint(address receiver, uint256 count) public payable nonReentrant {
    require(saleIsActive, "Sale not active");
    require(totalSupply() < MAX_SUPPLY, "Exceeds max supply");
    require(count <= MINT_LIMIT_PER_TX, "max number of mint per transaction is to high");
    require(msg.value <= ( price * count ), "Insufficient payment, 0.055 ETH per item * your count of token");
    
    if(
        internalList[receiver] && !saleIsPublic || 
        allowList[receiver] && saleIsAllowlist || 
        saleIsPublic) {

          if (allowedMintCount(receiver) >= 1 && allowedMintCount(receiver) >= count) {
            updateMintCount(receiver, count);
          } else {
            revert("Minting limit exceeded");
          }

          _safeMint(receiver, count);
    } else {
        revert("public sale is not active");
    }
  }

  function mintTo(address receiver, uint256 count) public nonReentrant onlyOwner {
    require(totalSupply() < MAX_SUPPLY, "Exceeds max supply");
    _safeMint(receiver, count);
  }

  function allowedMintCount(address minter) public view returns (uint256) {
    return MINT_LIMIT_PER_WALLET - mintCountMap[minter];
  }

  function updateMintCount(address minter, uint256 count) private {
    mintCountMap[minter] += count;
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

  function addInternalListMember(address member) public onlyOwner {
      require(!internalList[member], "Already a member");
      internalList[member] = true;
  }

  function removeInternalListMember(address member) public onlyOwner {
      internalList[member] = false;
  }

  function isMemberInInternalList(address member) public view returns (bool) {
    return internalList[member];
  }

  function setSaleIsActive(bool saleIsActive_) external onlyOwner {
    saleIsActive = saleIsActive_;
  }

  function setAllowlistIsActive(bool allowlistIsActive_) external onlyOwner {
    saleIsAllowlist = allowlistIsActive_;
  }
  
  function setSaleIsPublic(bool saleIsPublic_) external onlyOwner {
    saleIsPublic = saleIsPublic_;
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

  function setMintCount(uint256 newcount_) external onlyOwner {
      MINT_LIMIT_PER_WALLET = newcount_;
  }

  function getMintCount() public view returns (uint256) {
      return MINT_LIMIT_PER_WALLET;
  }

  function setLimitPerTransaction(uint256 newcount_) external onlyOwner {
      MINT_LIMIT_PER_TX = newcount_;
  }

  function getLimitPerTransaction() public view returns (uint256) {
      return MINT_LIMIT_PER_TX;
  }

  /** PAYOUT **/
  address private constant mytokybirdAddress = 0xc2bb2a8a79B1086E4C64C4Fdc46Ff80209731b47;
  address private constant nonProfitAddress = 0x031EDf9FA6bD1AAB882aCa7bA2115D567E69cC17; 
  address private constant brainfartAddress = 0xf10984224cA28F357883E387932CfEEd178a7A19; 
  address private constant fundThePlanetAddress = 0xC6dF2D88D7752b53ECEC7a5FcBa7C9298c6e6b1a; 
  address private constant apollxAddress = 0x4Ef388101B4FbE7fD047b9a7DF725012BB5ddE19;

  function withdraw() public nonReentrant onlyOwner {
    uint256 balance = address(this).balance;

    Address.sendValue(payable(mytokybirdAddress), balance * 800 / 1000);
    Address.sendValue(payable(nonProfitAddress), balance * 78 / 1000);
    Address.sendValue(payable(brainfartAddress), balance * 50 / 1000);
    Address.sendValue(payable(fundThePlanetAddress), balance * 22 / 1000);
    Address.sendValue(payable(apollxAddress), balance * 50 / 1000);
    
  }

  /** ROYALTIES **/
  function royaltyInfo(uint256, uint256 salePrice) external view
    returns (address receiver, uint256 royaltyAmount)
  {
    return (address(this), (salePrice * 600) / 10000);
  }
  
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721A, CantBeEvil)
    returns (bool)
  {
    return (
      interfaceId == type(IERC721).interfaceId ||
      super.supportsInterface(interfaceId)
    );
  }
  
}