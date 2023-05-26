// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/*
Baby Dragon
*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract BabyDragon is ERC721Enumerable, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
  uint256 public MAX_SUPPLY = 1111;
  string private baseURI;
  uint256 public publicMintPrice = 60;
  bool public publicMintEnabled = true;
  uint256[] public alphaBabyList10p;
  uint256[] public alphaBabyList25p;

  mapping(address => uint256) public publicMinted;

  constructor(string memory uri) ERC721("BabyDragon", "BabyDragon") {
    baseURI = uri;

    // Set Epic IDs
    isEpic[620] = true;
    isEpic[707] = true;
    isEpic[741] = true;
    isEpic[913] = true;
    isEpic[1012] = true;
    isEpic[1172] = true;
    isEpic[1246] = true;
    isEpic[1256] = true;
    isEpic[1271] = true;
    isEpic[1526] = true;
    isEpic[1705] = true;
    isEpic[3023] = true;
    isEpic[3555] = true;
    isEpic[4104] = true;
    isEpic[4105] = true;
    isEpic[4164] = true;
    isEpic[4251] = true;
    isEpic[4640] = true;
    isEpic[4704] = true;
    isEpic[4904] = true;
    isEpic[5061] = true;
    isEpic[5233] = true;
    isEpic[5248] = true;
    isEpic[5825] = true;
    isEpic[6491] = true;

    // Set Normal IDs
    isNormal[21] = true;
    isNormal[28] = true;
    isNormal[51] = true;
    isNormal[73] = true;
    isNormal[88] = true;
    isNormal[92] = true;
    isNormal[98] = true;
    isNormal[101] = true;
    isNormal[113] = true;
    isNormal[155] = true;
    isNormal[166] = true;
    isNormal[203] = true;
    isNormal[221] = true;
    isNormal[222] = true;
    isNormal[274] = true;
    isNormal[296] = true;
    isNormal[335] = true;
    isNormal[360] = true;
    isNormal[401] = true;
    isNormal[410] = true;
    isNormal[459] = true;
    isNormal[519] = true;
    isNormal[547] = true;
    isNormal[596] = true;
    isNormal[603] = true;
    isNormal[635] = true;
    isNormal[679] = true;
    isNormal[690] = true;
    isNormal[747] = true;
    isNormal[755] = true;
    isNormal[757] = true;
    isNormal[786] = true;
    isNormal[789] = true;
    isNormal[813] = true;
    isNormal[826] = true;
    isNormal[868] = true;
    isNormal[883] = true;
    isNormal[905] = true;
    isNormal[908] = true;
    isNormal[923] = true;
    isNormal[963] = true;
    isNormal[975] = true;
    isNormal[1000] = true;
    isNormal[1005] = true;
    isNormal[1013] = true;
    isNormal[1072] = true;
    isNormal[1092] = true;
    isNormal[1154] = true;
    isNormal[1158] = true;
    isNormal[1165] = true;
    isNormal[1166] = true;
    isNormal[1167] = true;
    isNormal[1175] = true;
    isNormal[1182] = true;
    isNormal[1216] = true;
    isNormal[1219] = true;
    isNormal[1237] = true;
    isNormal[1252] = true;
    isNormal[1272] = true;
    isNormal[1273] = true;
    isNormal[1274] = true;
    isNormal[1284] = true;
    isNormal[1306] = true;
    isNormal[1334] = true;
    isNormal[1359] = true;
    isNormal[1367] = true;
    isNormal[1397] = true;
    isNormal[1404] = true;
    isNormal[1410] = true;
    isNormal[1424] = true;
    isNormal[1425] = true;
    isNormal[1463] = true;
    isNormal[1475] = true;
    isNormal[1489] = true;
    isNormal[1522] = true;
    isNormal[1534] = true;
    isNormal[1539] = true;
    isNormal[1555] = true;
    isNormal[1571] = true;
    isNormal[1575] = true;
    isNormal[1579] = true;
    isNormal[1623] = true;
    isNormal[1625] = true;
    isNormal[1639] = true;
    isNormal[1719] = true;
    isNormal[1772] = true;
    isNormal[1775] = true;
    isNormal[1781] = true;
    isNormal[1823] = true;
    isNormal[1829] = true;
    isNormal[1846] = true;
    isNormal[1852] = true;
    isNormal[1865] = true;
    isNormal[1901] = true;
    isNormal[1920] = true;
    isNormal[1922] = true;
    isNormal[1927] = true;
    isNormal[1936] = true;
    isNormal[1991] = true;
    isNormal[1992] = true;
    isNormal[2004] = true;
    isNormal[2008] = true;
    isNormal[2029] = true;
    isNormal[2046] = true;
    isNormal[2067] = true;
    isNormal[2074] = true;
    isNormal[2106] = true;
    isNormal[2150] = true;
    isNormal[2173] = true;
    isNormal[2182] = true;
    isNormal[2184] = true;
    isNormal[2268] = true;
    isNormal[2275] = true;
    isNormal[2315] = true;
    isNormal[2320] = true;
    isNormal[2322] = true;
    isNormal[2328] = true;
    isNormal[2357] = true;
    isNormal[2395] = true;
    isNormal[2396] = true;
    isNormal[2399] = true;
    isNormal[2404] = true;
    isNormal[2405] = true;
    isNormal[2409] = true;
    isNormal[2452] = true;
    isNormal[2454] = true;
    isNormal[2475] = true;
    isNormal[2477] = true;
    isNormal[2479] = true;
    isNormal[2536] = true;
    isNormal[2538] = true;
    isNormal[2600] = true;
    isNormal[2656] = true;
    isNormal[2657] = true;
    isNormal[2669] = true;
    isNormal[2705] = true;
    isNormal[2712] = true;
    isNormal[2733] = true;
    isNormal[2734] = true;
    isNormal[2761] = true;
    isNormal[2772] = true;
    isNormal[2839] = true;
    isNormal[2842] = true;
    isNormal[2845] = true;
    isNormal[2866] = true;
    isNormal[2875] = true;
    isNormal[2879] = true;
    isNormal[2883] = true;
    isNormal[2890] = true;
    isNormal[2891] = true;
    isNormal[2923] = true;
    isNormal[2940] = true;
    isNormal[2998] = true;
    isNormal[2999] = true;
    isNormal[3027] = true;
    isNormal[3036] = true;
    isNormal[3041] = true;
    isNormal[3114] = true;
    isNormal[3129] = true;
    isNormal[3140] = true;
    isNormal[3151] = true;
    isNormal[3208] = true;
    isNormal[3249] = true;
    isNormal[3261] = true;
    isNormal[3334] = true;
    isNormal[3343] = true;
    isNormal[3361] = true;
    isNormal[3368] = true;
    isNormal[3374] = true;
    isNormal[3404] = true;
    isNormal[3432] = true;
    isNormal[3460] = true;
    isNormal[3554] = true;
    isNormal[3588] = true;
    isNormal[3595] = true;
    isNormal[3660] = true;
    isNormal[3724] = true;
    isNormal[3770] = true;
    isNormal[3814] = true;
    isNormal[3826] = true;
    isNormal[3838] = true;
    isNormal[3848] = true;
    isNormal[3852] = true;
    isNormal[3855] = true;
    isNormal[3895] = true;
    isNormal[3909] = true;
    isNormal[3950] = true;
    isNormal[3959] = true;
    isNormal[3965] = true;
    isNormal[4006] = true;
    isNormal[4008] = true;
    isNormal[4057] = true;
    isNormal[4126] = true;
    isNormal[4161] = true;
    isNormal[4166] = true;
    isNormal[4192] = true;
    isNormal[4212] = true;
    isNormal[4223] = true;
    isNormal[4254] = true;
    isNormal[4261] = true;
    isNormal[4272] = true;
    isNormal[4285] = true;
    isNormal[4311] = true;
    isNormal[4315] = true;
    isNormal[4324] = true;
    isNormal[4335] = true;
    isNormal[4346] = true;
    isNormal[4387] = true;
    isNormal[4409] = true;
    isNormal[4453] = true;
    isNormal[4488] = true;
    isNormal[4490] = true;
    isNormal[4495] = true;
    isNormal[4500] = true;
    isNormal[4514] = true;
    isNormal[4518] = true;
    isNormal[4569] = true;
    isNormal[4591] = true;
    isNormal[4614] = true;
    isNormal[4619] = true;
    isNormal[4657] = true;
    isNormal[4773] = true;
    isNormal[4774] = true;
    isNormal[4787] = true;
    isNormal[4809] = true;
    isNormal[4850] = true;
    isNormal[4863] = true;
    isNormal[4864] = true;
    isNormal[4887] = true;
    isNormal[4890] = true;
    isNormal[4891] = true;
    isNormal[4913] = true;
    isNormal[4954] = true;
    isNormal[4965] = true;
    isNormal[4981] = true;
    isNormal[5003] = true;
    isNormal[5038] = true;
    isNormal[5053] = true;
    isNormal[5066] = true;
    isNormal[5069] = true;
    isNormal[5075] = true;
    isNormal[5103] = true;
    isNormal[5161] = true;
    isNormal[5174] = true;
    isNormal[5175] = true;
    isNormal[5194] = true;
    isNormal[5234] = true;
    isNormal[5238] = true;
    isNormal[5254] = true;
    isNormal[5269] = true;
    isNormal[5277] = true;
    isNormal[5304] = true;
    isNormal[5318] = true;
    isNormal[5322] = true;
    isNormal[5378] = true;
    isNormal[5392] = true;
    isNormal[5447] = true;
    isNormal[5478] = true;
    isNormal[5494] = true;
    isNormal[5503] = true;
    isNormal[5515] = true;
    isNormal[5535] = true;
    isNormal[5610] = true;
    isNormal[5623] = true;
    isNormal[5666] = true;
    isNormal[5699] = true;
    isNormal[5700] = true;
    isNormal[5716] = true;
    isNormal[5719] = true;
    isNormal[5734] = true;
    isNormal[5744] = true;
    isNormal[5804] = true;
    isNormal[5862] = true;
    isNormal[5874] = true;
    isNormal[5879] = true;
    isNormal[5886] = true;
    isNormal[5891] = true;
    isNormal[5918] = true;
    isNormal[5962] = true;
    isNormal[5999] = true;
    isNormal[6022] = true;
    isNormal[6066] = true;
    isNormal[6091] = true;
    isNormal[6103] = true;
    isNormal[6110] = true;
    isNormal[6115] = true;
    isNormal[6149] = true;
    isNormal[6172] = true;
    isNormal[6205] = true;
    isNormal[6215] = true;
    isNormal[6262] = true;
    isNormal[6289] = true;
    isNormal[6319] = true;
    isNormal[6342] = true;
    isNormal[6383] = true;
    isNormal[6392] = true;
    isNormal[6394] = true;
    isNormal[6397] = true;
    isNormal[6455] = true;
    isNormal[6464] = true;
    isNormal[6470] = true;
    isNormal[6493] = true;
    isNormal[6511] = true;
    isNormal[6517] = true;
    isNormal[6559] = true;
    isNormal[6595] = true;
    isNormal[6627] = true;
    isNormal[6702] = true;
    isNormal[6710] = true;
    isNormal[6712] = true;
    isNormal[6779] = true;
    isNormal[6783] = true;
    isNormal[6792] = true;
    isNormal[6807] = true;
    isNormal[6830] = true;
    isNormal[6840] = true;
    isNormal[6868] = true;
    isNormal[6897] = true;
    isNormal[6922] = true;

    isNormal[1961] = true;
    isNormal[2377] = true;
    isNormal[291] = true;
    isNormal[3536] = true;
    isNormal[4063] = true;
    isNormal[4181] = true;
    isNormal[4288] = true;
    isNormal[452] = true;
    isNormal[4826] = true;
    isNormal[4987] = true;
    isNormal[5597] = true;
    isNormal[6132] = true;
    isNormal[6142] = true;
    isNormal[6338] = true;
    isNormal[950] = true;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string memory newBaseURI) external onlyOwner {
    baseURI = newBaseURI;
  }

  function setMaxSupply(uint256 newMaxSupply) public onlyOwner {
    require(newMaxSupply != MAX_SUPPLY, "Same value as current max supply");
    require(newMaxSupply >= totalSupply(), "Value lower than total supply");
    MAX_SUPPLY = newMaxSupply;
  }

  function togglePublicMint() external onlyOwner {
    publicMintEnabled = !publicMintEnabled;
  }

  function setPublicMintPrice(uint256 newPrice) external onlyOwner {
    publicMintPrice = newPrice;
  }

  function getTokenIDs(address addr) external view returns (uint256[] memory) {
    uint256 total = totalSupply();
    uint256 count = balanceOf(addr);
    uint256[] memory tokens = new uint256[](count);
    uint256 tokenIndex = 0;
    for (uint256 i; i < total; i++) {
      if (addr == ownerOf(i)) {
        tokens[tokenIndex] = i;
        tokenIndex++;
      }
    }
    return tokens;
  }

  function airDrop(address[] calldata recipient, uint256[] calldata quantity) external onlyOwner {
    require(quantity.length == recipient.length, "Please provide equal quantities and recipients");

    uint256 totalQuantity = 0;
    uint256 supply = totalSupply();
    for (uint256 i = 0; i < quantity.length; ++i) {
      totalQuantity += quantity[i];
    }
    require(supply + totalQuantity <= MAX_SUPPLY, "Not enough supply");
    delete totalQuantity;

    for (uint256 i = 0; i < recipient.length; ++i) {
      for (uint256 j = 0; j < quantity[i]; ++j) {
        _safeMint(recipient[i], supply++);
      }
    }
  }

  function publicMint(uint256 amount) external nonReentrant {
    uint256 totalMinted = totalSupply();

    require(publicMintEnabled, "Public mint not enabled");
    require(amount * publicMintPrice <= burnPoints[_msgSender()], "More Points please");
    require(amount + totalMinted <= MAX_SUPPLY, "Please try minting with less, not enough supply!");

    burnPoints[_msgSender()] = burnPoints[_msgSender()] - (amount * publicMintPrice);
    bulkMint(_msgSender(), amount);
    publicMinted[_msgSender()] += amount;
  }

  function bulkMint(address creator, uint batchSize) internal returns (bool) {
    require(batchSize > 0, "MintZeroQuantity()");
    uint256 totalMinted = totalSupply();
    for (uint i = 0; i < batchSize; i++) {
      uint256 tokenId = totalMinted + i;
      if (alphaBaby25p[_msgSender()] > 0) {
        alphaBaby25p[_msgSender()] = alphaBaby25p[_msgSender()] - 1;
        alphaBabyList25p.push(tokenId);
      } else if (alphaBaby10p[_msgSender()] > 0) {
        alphaBaby10p[_msgSender()] = alphaBaby10p[_msgSender()] - 1;
        alphaBabyList10p.push(tokenId);
      }
      _safeMint(creator, tokenId);
    }
    return true;
  }

  function setApprovalForAll(address operator, bool approved) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override(ERC721, IERC721) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  // BURN
  address public PRIME_APE_CONTRACT = 0x6632a9d63E142F17a668064D41A21193b49B41a0;
  address public PRIME_KONG_CONTRACT = 0x5845E5F0571427D0ce33550587961262CA8CDF5C;
  address public PRIME_INFECTED_CONTRACT = 0xFD8917a36f76c4DA9550F26DB2faaaA242d6AE2c;
  address public PRIME_DRAGON_CONTRACT = 0x3B81f59B921eD8E037c4F12E631fb7c46D821138;
  address public BURN_WALLET = 0x000000000000000000000000000000000000dEaD;

  function setContractAddress(address a1, address a2, address a3, address a4, address a5) external onlyOwner {
    PRIME_DRAGON_CONTRACT = a1;
    PRIME_APE_CONTRACT = a2;
    PRIME_KONG_CONTRACT = a3;
    PRIME_INFECTED_CONTRACT = a4;
    BURN_WALLET = a5;
  }

  using Counters for Counters.Counter;
  using EnumerableSet for EnumerableSet.AddressSet;
  using EnumerableSet for EnumerableSet.UintSet;

  event Burn(address contractAddress, uint256 tokenId, address owner);

  bool public burnPhase1Enabled = true;
  bool public burnBulkEnabled = false;

  mapping(address => mapping(address => EnumerableSet.UintSet)) private addressToBurnedTokensSet;
  mapping(address => mapping(uint256 => address)) private contractTokenIdToOwner;
  mapping(address => mapping(uint256 => uint256)) private contractTokenIdToBurnedTimestamp;
  mapping(address => uint256) public burnPoints;
  mapping(address => uint256) public alphaBaby10p;
  mapping(address => uint256) public alphaBaby25p;

  mapping(uint => bool) public isEpic;
  mapping(uint => bool) public isNormal;

  function toggleBurnPhase1() external onlyOwner {
    burnPhase1Enabled = !burnPhase1Enabled;
  }

  function toggleBurnBulk() external onlyOwner {
    burnBulkEnabled = !burnBulkEnabled;
  }

  function burnPhase1(uint256[] memory dragonIds) external nonReentrant {
    require(burnPhase1Enabled, "phase 1 burn not enabled");

    for (uint256 i = 0; i < dragonIds.length; i++) {
      uint256 tokenId = dragonIds[i];
      if (isEpic[tokenId]) {
        alphaBaby25p[_msgSender()] = alphaBaby25p[_msgSender()] + 1;
      } else if (isNormal[tokenId]) {
        alphaBaby10p[_msgSender()] = alphaBaby10p[_msgSender()] + 1;
      } else {
        revert("Not Epic or Normal Dragon with Baby.");
      }

      contractTokenIdToOwner[PRIME_DRAGON_CONTRACT][tokenId] = _msgSender();
      IERC721(PRIME_DRAGON_CONTRACT).transferFrom(_msgSender(), BURN_WALLET, tokenId);
      addressToBurnedTokensSet[PRIME_DRAGON_CONTRACT][_msgSender()].add(tokenId);
      contractTokenIdToBurnedTimestamp[PRIME_DRAGON_CONTRACT][tokenId] = block.timestamp;

      burnPoints[_msgSender()] = burnPoints[_msgSender()] + 60;

      emit Burn(PRIME_DRAGON_CONTRACT, tokenId, _msgSender());
    }
  }

  function burnBulk(uint256[] memory dragonIds, uint256[] memory apeIds, uint256[] memory kongIds, uint256[] memory infectedIds) external nonReentrant {
    require(burnBulkEnabled, "bulk burn not enabled");

    for (uint256 i = 0; i < dragonIds.length; i++) {
      uint256 tokenId = dragonIds[i];
      contractTokenIdToOwner[PRIME_DRAGON_CONTRACT][tokenId] = _msgSender();
      IERC721(PRIME_DRAGON_CONTRACT).transferFrom(_msgSender(), BURN_WALLET, tokenId);
      addressToBurnedTokensSet[PRIME_DRAGON_CONTRACT][_msgSender()].add(tokenId);
      contractTokenIdToBurnedTimestamp[PRIME_DRAGON_CONTRACT][tokenId] = block.timestamp;

      burnPoints[_msgSender()] = burnPoints[_msgSender()] + 8;

      emit Burn(PRIME_DRAGON_CONTRACT, tokenId, _msgSender());
    }

    for (uint256 i = 0; i < apeIds.length; i++) {
      uint256 tokenId = apeIds[i];
      contractTokenIdToOwner[PRIME_APE_CONTRACT][tokenId] = _msgSender();
      IERC721(PRIME_APE_CONTRACT).transferFrom(_msgSender(), BURN_WALLET, tokenId);
      addressToBurnedTokensSet[PRIME_APE_CONTRACT][_msgSender()].add(tokenId);
      contractTokenIdToBurnedTimestamp[PRIME_APE_CONTRACT][tokenId] = block.timestamp;

      burnPoints[_msgSender()] = burnPoints[_msgSender()] + 12;

      emit Burn(PRIME_APE_CONTRACT, tokenId, _msgSender());
    }

    for (uint256 i = 0; i < kongIds.length; i++) {
      uint256 tokenId = kongIds[i];
      contractTokenIdToOwner[PRIME_KONG_CONTRACT][tokenId] = _msgSender();
      IERC721(PRIME_KONG_CONTRACT).transferFrom(_msgSender(), BURN_WALLET, tokenId);
      addressToBurnedTokensSet[PRIME_KONG_CONTRACT][_msgSender()].add(tokenId);
      contractTokenIdToBurnedTimestamp[PRIME_KONG_CONTRACT][tokenId] = block.timestamp;

      burnPoints[_msgSender()] = burnPoints[_msgSender()] + 6;

      emit Burn(PRIME_KONG_CONTRACT, tokenId, _msgSender());
    }

    for (uint256 i = 0; i < infectedIds.length; i++) {
      uint256 tokenId = infectedIds[i];
      contractTokenIdToOwner[PRIME_INFECTED_CONTRACT][tokenId] = _msgSender();
      IERC721(PRIME_INFECTED_CONTRACT).transferFrom(_msgSender(), BURN_WALLET, tokenId);
      addressToBurnedTokensSet[PRIME_INFECTED_CONTRACT][_msgSender()].add(tokenId);
      contractTokenIdToBurnedTimestamp[PRIME_INFECTED_CONTRACT][tokenId] = block.timestamp;

      // 1-7979 = L1, 7980 and above = L2
      if (tokenId > 7979) {
        burnPoints[_msgSender()] = burnPoints[_msgSender()] + 10;
      } else {
        burnPoints[_msgSender()] = burnPoints[_msgSender()] + 5;
      }

      emit Burn(PRIME_INFECTED_CONTRACT, tokenId, _msgSender());
    }
  }

  function burnedTokensOfOwner(address contractAddress, address owner) external view returns (uint256[] memory) {
    EnumerableSet.UintSet storage userTokens = addressToBurnedTokensSet[contractAddress][owner];
    uint256[] memory tokenIds = new uint256[](userTokens.length());

    for (uint256 i = 0; i < userTokens.length(); i++) {
      tokenIds[i] = userTokens.at(i);
    }

    return tokenIds;
  }

  function burnedTokenOwner(address contractAddress, uint256 tokenId) external view returns (address) {
    return contractTokenIdToOwner[contractAddress][tokenId];
  }

  function burnedTokenTimestamp(address contractAddress, uint256 tokenId) external view returns (uint256) {
    return contractTokenIdToBurnedTimestamp[contractAddress][tokenId];
  }

  function alphaBabyList10pView() external view returns (uint256[] memory) {
    return alphaBabyList10p;
  }

  function alphaBabyList25pView() external view returns (uint256[] memory) {
    return alphaBabyList25p;
  }
}