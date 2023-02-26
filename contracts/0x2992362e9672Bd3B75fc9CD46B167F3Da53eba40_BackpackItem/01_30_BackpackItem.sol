// SPDX-License-Identifier: UNLICENSED

//              :----     .---   :--- .---    :--:   .     :-==-.           :----     .------:    :--------:
//             :@@@@@%    *@@@= [email protected]@@* [email protected]@@=  [email protected]@@@  [email protected]@: [email protected]@@@@@@#         [email protected]@@@@#    #@@@@@@@@%: @@@@@@@@@@
//             %@@@@@@+   *@@@=*@@@+  [email protected]@@=  [email protected]@@@ :@@-  @@@@-:+=-         @@@@@@@=   #@@@*[email protected]@@@ [email protected]@@@++=
//            [email protected]@@=%@@@.  *@@@@@@@=   [email protected]@@=  [email protected]@@@       *@@@@@%*-        *@@@-%@@@.  #@@@#+#@@@%    @@@@
//           :@@@@=*@@@#  *@@@#@@@%.  [email protected]@@*  [email protected]@@%        .=+*%@@@%      [email protected]@@@=*@@@#  #@@@@@@@@#.    @@@@
//           %@@@@@@@@@@= *@@@=:@@@@: :@@@@@@@@@@+      .#@@#+#@@@%     [email protected]@@@@@@@@@@= #@@@=.%@@@-    @@@@
//          [email protected]@@*   :@@@@[email protected]@@- .%@@@- :*%@@@@@#-        -#@@@@@%+      [email protected]@@*   :@@@% *@@@- .#@@@:   %@@%
//
//     -+***+-     -=+*+=-    .+++:     .+++:     .++++++++.   .=+**+=:  =++++++++= :+++.    -=+*+=-    :+++:   =+++
//   [email protected]@@@@@@@@= [email protected]@@@@@@@@+  [email protected]@@*     [email protected]@@*     [email protected]@@@@@@@- :%@@@@@@@@# @@@@@@@@@@.*@@@=  [email protected]@@@@@@@@+  [email protected]@@@=  @@@@:
//  #@@@%=-=#+: #@@@%=-=%@@@# [email protected]@@*     [email protected]@@*     [email protected]@@#:::: :@@@@+--+*-  :[email protected]@@@=-- *@@@= #@@@%=-=%@@@# [email protected]@@@@* @@@@:
// [email protected]@@%        @@@@     @@@@[email protected]@@*     [email protected]@@*     [email protected]@@@@@@# *@@@=           @@@@:   *@@@[email protected]@@@     @@@@[email protected]@@@@@#@@@@:
//  @@@@+. .=:  %@@@+. [email protected]@@@ [email protected]@@*     [email protected]@@*     [email protected]@@%---: [email protected]@@%:  :-.     @@@@:   *@@@= %@@@+. [email protected]@@@ [email protected]@@[email protected]@@@@@:
//  .%@@@@@@@@@-.%@@@@@@@@@%: [email protected]@@@@@@@:[email protected]@@@@@@@[email protected]@@@%%%%- [email protected]@@@@@@@@#    @@@@:   *@@@= .%@@@@@@@@@%. [email protected]@@+ :@@@@@:
//    -+#%@%#+-   :+#%@%#*-   :#%%%%%%#.:#%%%%%%#::#%%%%%%%-  .=*%%%%*=.    *%%#.   =%%#:   -+#%@%#+-   -%%%=  .*%%#.

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "./mason/utils/Administrable.sol";
import "./IBackpackItem.sol";
import "./IBackpackOracle.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./erc/ERC2981.sol";
import {Utils} from "./Utils.sol";
import "hardhat/console.sol";

error MaxSupplyIsTooLow();
error ExceedsMaxSupply();
error NotEnoughReservedTokens();
error RoyaltiesTooHigh();

contract BackpackItem is
  DefaultOperatorFilterer,
  ERC1155Supply,
  ERC1155Burnable,
  ERC2981,
  Administrable,
  IBackpackItem
{
  string public name;
  string public symbol;

  mapping(uint256 => fulfillmentRule) private fulfillmentRules;
  mapping(uint256 => address) private royaltyAddress;

  address private backpackOracle;

  uint256 royaltyPercent = 1000; // 10%
  address private defaultRoyaltyAddress;

  struct fulfillmentRule {
    uint256 maxSupply;
    bool eligible;
  }

  // Tracks how many tokens should be dropped when fulfillment, if > available tokens,
  // then drop all available tokens, if < then we will randomly select from the available tokens
  uint256 public fulfillmentQuantity = 2;
  // Limits iterations over rule mapping, this should be updated as more active tokens are added
  uint256 public tokenIdCount = 5;
  // How many tokens should be reserved for special drops (either Airdrop or Fire Backpack)
  uint256 public reservedQuantity = 2;
  // Keep track of tokens minted - this should be reset when changing rules.
  uint256 private reservedCount = 0;
  uint256 private standardCount = 0;

  constructor(string memory _name, string memory _symbol, string memory uri) ERC1155(uri) {
    name = _name;
    symbol = _symbol;

    _setURI(uri);
    defaultRoyaltyAddress = msg.sender;
  }

  function setURI(string memory _uri) external onlyOperatorsAndOwner {
    _setURI(_uri);
  }

  function setTokenIdCount(uint256 count) external onlyOperatorsAndOwner {
    tokenIdCount = count;
  }

  function setBackpackOracle(address _backpackOracle) external onlyOperatorsAndOwner {
    backpackOracle = _backpackOracle;
  }

  function setFulfillmentRule(uint256 tokenId, uint256 maxSupply, bool eligible) external onlyOperatorsAndOwner {
    fulfillmentRules[tokenId] = fulfillmentRule(maxSupply, eligible);
  }

  function getFulfillmentRule(uint256 tokenId) external view returns (fulfillmentRule memory) {
    return fulfillmentRules[tokenId];
  }

  function setMaxSupply(uint256 tokenId, uint256 max) external onlyOperatorsAndOwner {
    if (totalSupply(tokenId) > max) revert MaxSupplyIsTooLow();

    fulfillmentRules[tokenId].maxSupply = max;
  }

  function setFullfillmentQuantity(uint256 quantity) external onlyOperatorsAndOwner {
    fulfillmentQuantity = quantity;
  }

  function setReservedQuantity(uint256 quantity) external onlyOperatorsAndOwner {
    reservedQuantity = quantity;
  }

  function resetReservedCount() external onlyOperatorsAndOwner {
    reservedCount = 0;
  }

  function setEligibility(uint256 tokenId, bool eligible) external onlyOperatorsAndOwner {
    fulfillmentRules[tokenId].eligible = eligible;
  }

  function fulfill(address recipient, bool includeReserved) external onlyOperatorsAndOwner {
    if (includeReserved && reservedCount > reservedQuantity) revert NotEnoughReservedTokens();

    uint256[] memory selectedTokens = IBackpackOracle(backpackOracle).selectTokens(
      includeReserved ? tokenIdCount : fulfillmentQuantity
    );

    if (includeReserved) {
      unchecked {
        ++reservedCount;
      }
    } else {
      unchecked {
        ++standardCount;
      }
    }

    _mintBatch(recipient, selectedTokens, _quantities(selectedTokens.length), "");
  }

  function _quantities(uint256 count) internal pure returns (uint256[] memory) {
    uint256[] memory fulfillmentQuantities = new uint256[](count);

    for (uint256 i = 0; i < count; ) {
      fulfillmentQuantities[i] = 1;

      unchecked {
        ++i;
      }
    }

    return fulfillmentQuantities;
  }

  function _hasAvailableSupply(uint256 tokenId, uint256 quantity) internal view returns (bool) {
    fulfillmentRule memory rule = fulfillmentRules[tokenId];
    if (rule.maxSupply == 0) return true;

    return totalSupply(tokenId) + quantity <= rule.maxSupply;
  }

  function airdrop(uint256 tokenId, address recipient, uint256 quantity) external onlyOperatorsAndOwner {
    if (!_hasAvailableSupply(tokenId, quantity)) revert ExceedsMaxSupply();

    _mint(recipient, tokenId, quantity, "");
  }

  function airdropBatch(
    uint256 tokenID,
    address[] calldata addresses,
    uint256[] calldata amounts
  ) external onlyOperatorsAndOwner {
    if (!_hasAvailableSupply(tokenID, Utils.sumArray(amounts))) revert ExceedsMaxSupply();

    for (uint256 i = 0; i < addresses.length; ) {
      _mint(addresses[i], tokenID, amounts[i], "");
      unchecked {
        ++i;
      }
    }
  }

  function batchMint(
    address recipient,
    uint256[] calldata tokenIDs,
    uint256[] calldata amounts
  ) external onlyOperatorsAndOwner {
    for (uint256 i = 0; i < tokenIDs.length; ) {
      if (!_hasAvailableSupply(tokenIDs[i], amounts[i])) revert ExceedsMaxSupply();
      unchecked {
        ++i;
      }
    }

    _mintBatch(recipient, tokenIDs, amounts, "");
  }

  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(ERC1155, ERC2981, AccessControlEnumerable) returns (bool) {
    return
      interfaceId == type(IERC1155).interfaceId ||
      interfaceId == type(IERC1155MetadataURI).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    uint256 amount,
    bytes memory data
  ) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, amount, data);
  }

  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public virtual override onlyAllowedOperator(from) {
    super.safeBatchTransferFrom(from, to, ids, amounts, data);
  }

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal override(ERC1155, ERC1155Supply) {
    ERC1155Supply._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }

  function royaltyInfo(
    uint256 _tokenId,
    uint256 _salePrice
  ) external view returns (address receiver, uint256 royaltyAmount) {
    receiver = royaltyAddress[_tokenId];
    if (receiver == address(0)) receiver = defaultRoyaltyAddress;

    royaltyAmount = (_salePrice * royaltyPercent) / 10000;
  }

  function setRoyaltyPercent(uint256 _percentage) external onlyOperatorsAndOwner {
    royaltyPercent = _percentage;
  }

  function setDefaultRoyaltyAddress(address _royaltyAddress) external onlyOperatorsAndOwner {
    defaultRoyaltyAddress = _royaltyAddress;
  }

  function setRoyaltyAddress(uint256 _tokenId, address _royaltyAddress) external onlyOperatorsAndOwner {
    royaltyAddress[_tokenId] = _royaltyAddress;
  }
}