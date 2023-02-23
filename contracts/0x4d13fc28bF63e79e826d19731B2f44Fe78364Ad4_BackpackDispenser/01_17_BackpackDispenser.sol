// SPDX-License-Identifier: UNLICENSED

//                            ,╓╓╓╓╓,
//                         ,≥╙""""└╚╩╠▒╠╦
//                        ]░░ ,,;»≥≥≥≥;╙╙╙,
//                      ,≥░░░░░░░░░░░░░░░░░░░░░≥≥,
//                   ≤▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░≥
//            ,,  ,≥▒▒▒▒▒▒▒▒▒▒░▒░░░░░░░░░░░░▒▒░░░░░░░░░,
//       ,╔▒▒░░░░░▒╠╬▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░▒░░░░░░░▒
//     ╔╠╚░░╙╚▒░░▒╠╬╬╠▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░▒░░░░░░░░░░░░░≥
//    ê▒░░░╚   ░░▒╠╬╬╬▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░▒▒▒▒▒▒░░▒▒░░░░░,
//   ╒▒▒░░░   ╔░▒▒╢╬╬╬▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒Å╬░▒░▒╬░░▒╠░▒░▒▒▒░░▒░░░
//   ╬▒░░░░   ░╬╬▒╠╠╬╬╬▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╬▒▒▒╢▒▒▒╠░▒░░░░▒▒░▒▒░░░
//   ╬▒░░░    ╬╚░▒╠╠╠╬╣▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╬╠▒▒╠╩▒▒▒▒╬▒░░▒░▒░▒▒▒░░
//  ]▒▒░░░    │░░▒▒╠╬╠╬╬▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░▒░▒t
//  ²╬▒░░░    ╘░░▒▒▒╠▒╬╬╠╬╣╬▒▒▒╠╣╬╬╬▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠╬▒▒╠▒▒▒▒▒▒
//   ╬▒░░░     ░░░▒▒╠╠╠╬▒▒╠╠╠╬╬╬╣╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬▓▓▒▒▒╠▒▒▒▒▒░
//   └╠░░░     ░░░▒▒╠╬╬╬▒▒▒▒▒▒╠╠╬╬╚╚▒▒▒▒▒▒▒▒▒▒▒▒▒▒╠╬╬▒╙╚▒▒▒▒▒▒░
//    └╠░░     ⌠░░▒▒╠╬╬╬╠▒▒▒▒▒▒╠╬╬▒░╚╠▒▒▒▒▒▒▒▒▒▒▒▒▒╠╬╬▒╦▒▒▒▒▒▒▒≥
//      ╠▒░    '░░▒╠╬╬╣╬╬▒▒▒▒▒╠╠╬╬╬▒╦▒▒▒▒▒▒▒▒▒▒▒▒▒╠╠╠╠▒▒▒▒▒▒▒▒▒▒
//       ╚╠╓    ░░▒╠╬╬╬╬╬▒▒▒▒▒╠╠╠╠╠╠╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒⌐
//        ⌠╠╦   ░░▒╠╬╬╬╬╬╬▒▒▒▒▒▒▒▒╠╠╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
//         "░▒, ░░▒╠╬╬╬╬╬╬▒▒▒▒▒▒▒▒╠╠╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
//           ░░▒░░▒╠╬╬╬╬╬╬╬▒▒▒▒▒▒▒╠╠╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒≥
//            ░░░░▒╠╬╬╬╬╬╬╬╬╝╢╢╫╣▓╬╠╬╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠▒
//             7▒░▒╠╬╬╬╬╬╬╬╠╠╠╠╬▓▓▒╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒[
//              `░░╠╠╬╬╬╬╬╬╬╠╬╬╣▓╠╬▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
//               ]░▒╠╬╬╬╬╬╬╬╬╬╬╠╬╠▒▒╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
//                ░▒╠╠╠╬╬╬╬╬╠╠╠╠╠╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░
//                ░▒▒╠╠╬╬╠╬╬╬╠╠╠╠▒▒╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░
//                ░▒▒╠╬╠╬╬╬╠╬╬▒╠╠▒╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒Γ
//                ╘╚░▒╠╠╠╠╠▒╠╠╬╠╠▒╠╠▒▒╠▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╩╩╩╚╙
//                 ▒▒▒▒▒▒▒░░░░░╙╙╙╚╙╙╙╙╙╙╙╙╙╙░░░░░░░░░░░░░░░░≥"
//                  ╠░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░≥²"
//                    `"²²====²²ⁿ"""""```

pragma solidity ^0.8.18;

import "./mason/utils/Administrable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IYellowBackpack.sol";
import "./IBackpackItem.sol";

error BurnRuleNotDefined();
error SwapRuleNotDefined();
error InvalidInput();
error NotApproved();

// TODO: Different Burn Wallets for Different
// TODO: Protect Burn Aku Handmades, Partners, MegaOG
//  56 handmades (56), Non Aku Partners.

contract BackpackDispenser is Administrable, ReentrancyGuard {
  event TokenSwapped(address contractAddress, uint256 tokenId);

  // This is the contract that will issue tokens
  address public backpackContract;

  // This is the vault address where the token(s) being swapped
  // will be sent, these will later be transferred to the burn
  // address
  address public vault;

  struct SwapRule {
    uint256 newTokenId;
    uint256 requiredTokens;
  }

  // A swap rule represents a rule governing how an existing Akutar/Chapters
  // token can be swapped for a specific type of Yellow Backpack
  mapping(address => SwapRule) private swapRules;

  // A burn rule represents a linkage between a type of Yellow Backpack and a
  // fulfillment contract which adheres to the IBAckpackItem interface
  mapping(uint256 => address) private burnRules;

  constructor(address _backpackContract, address _vault) {
    backpackContract = _backpackContract;
    vault = _vault;
  }

  // ****** SWAPPING ******

  function supportsSwaps(address contractAddress) public view returns (bool) {
    return swapRules[contractAddress].requiredTokens > 0;
  }

  function canSwapToken(address contractAddress, uint256 tokenId) public view returns (bool) {
    SwapRule memory swapRule = swapRules[contractAddress];
    if (swapRule.requiredTokens == 0) revert SwapRuleNotDefined();

    return _isApproved(contractAddress);
  }

  function _isApproved(address contractAddress) internal view returns (bool) {
    return IERC721(contractAddress).isApprovedForAll(msg.sender, address(this));
  }

  function swapToken(address[] memory contracts, uint256[] memory tokenIds) external nonReentrant noContracts {
    for (uint256 i = 0; i < contracts.length; ) {
      address contractAddress = contracts[i];
      uint256 tokenId = tokenIds[i];

      SwapRule memory swapRule = swapRules[contractAddress];
      if (swapRule.requiredTokens == 0) revert SwapRuleNotDefined();
      if (!_isApproved(contractAddress)) revert NotApproved();

      IERC721(contractAddress).transferFrom(msg.sender, vault, tokenId);
      IYellowBackpack(backpackContract).swap(swapRule.newTokenId, msg.sender, 1);

      emit TokenSwapped(contractAddress, tokenId);

      unchecked {
        ++i;
      }
    }
  }

  function setSwapRule(
    address tokenContract,
    uint256 tokenIdToIssue,
    uint256 requiredTokens
  ) external onlyOperatorsAndOwner {
    swapRules[tokenContract] = SwapRule(tokenIdToIssue, requiredTokens);
  }

  // ****** BURNING ******

  function canBurnToken(uint256 tokenId) public view returns (bool) {
    address backpackItemContract = burnRules[tokenId];
    if (backpackItemContract == address(0)) revert BurnRuleNotDefined();

    return true;
  }

  function burnBackpack(uint256 tokenId) external nonReentrant noContracts {
    address backpackItemContract = burnRules[tokenId];
    if (backpackItemContract == address(0)) revert BurnRuleNotDefined();

    IYellowBackpack(backpackContract).burnToken(msg.sender, tokenId);
    IBackpackItem(backpackItemContract).fulfill(msg.sender, tokenId == 1 ? true : false);

    emit TokenSwapped(backpackContract, tokenId);
  }

  function setBurnRule(uint256 tokenId, address backpackItemContract) external onlyOperatorsAndOwner {
    burnRules[tokenId] = backpackItemContract;
  }

  // ******* MISC *******

  function setBackpackContract(address _backpackContract) external onlyOperatorsAndOwner {
    backpackContract = _backpackContract;
  }

  function setVaultContract(address _vault) external onlyOperatorsAndOwner {
    vault = _vault;
  }
}