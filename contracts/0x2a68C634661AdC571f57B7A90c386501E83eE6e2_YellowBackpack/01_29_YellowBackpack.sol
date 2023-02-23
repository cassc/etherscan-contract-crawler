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

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./mason/utils/Administrable.sol";
import "./mason/utils/EIP712Common.sol";
import "./erc/ERC2981.sol";

error BurnAmountExceedsBalance();
error BurnNotActive();
error InsufficientFunds();
error MaxPerWalletReached();
error MaxSupplyReached();
error MaxSupplyTooLow();
error RoyaltiesTooHigh();
error SaleRuleUndefined();
error SwapLimitReached();
error SwapNotActive();
error SwapQuotaReached();

contract YellowBackpack is
  DefaultOperatorFilterer,
  ERC1155Burnable,
  ERC1155Supply,
  ERC1155URIStorage,
  ERC2981,
  EIP712Common,
  Administrable
{
  string public name;
  string public symbol;

  RoyaltyInfo private _royalties;

  address private treasuryAddress;

  struct SaleRule {
    uint256 salePrice;
    uint24 maxSupply;
    uint24 swapSupply;
    uint24 maxPerWallet;
    uint24 swapLimit;
    bool saleActive;
    bool allowlistActive;
    bool swapActive;
    bool burnActive;
    bool exists;
  }

  struct TokenOwnership {
    uint24 quantityMinted;
    uint24 quantitySwapped;
    uint24 quantityBurned;
    uint24 quantityAirdropped;
  }

  mapping(uint256 => SaleRule) private saleRules;
  mapping(address => mapping(uint256 => TokenOwnership)) private tokenOwnerships;
  mapping(uint256 => uint256) private swapCounter;

  constructor(string memory tokenURI) ERC1155(tokenURI) {
    name = "Aku's Yellow Backpack";
    symbol = "YBP";

    // Set initial royalties to 10%
    _setRoyaltyInfo(msg.sender, 1000);
    _setTreasuryAddress(msg.sender);
  }

  function mint(uint256 tokenId, uint256 quantity) external payable noContracts {
    SaleRule memory rule = saleRules[tokenId];

    if (!rule.exists) revert SaleRuleUndefined();
    if (!rule.saleActive) revert SaleNotActive();
    if (totalSupply(tokenId) + quantity > rule.maxSupply - rule.swapSupply) revert MaxSupplyReached();
    if (msg.value < rule.salePrice * quantity) revert InsufficientFunds();

    TokenOwnership memory ownership = tokenOwnerships[msg.sender][tokenId];
    if (ownership.quantityMinted + quantity > rule.maxPerWallet) revert MaxPerWalletReached();

    tokenOwnerships[msg.sender][tokenId].quantityMinted += uint24(quantity);
    _mint(msg.sender, tokenId, quantity, "");
  }

  function allowlistMint(
    uint256 tokenId,
    uint256 quantity,
    bytes calldata signature
  ) external payable requiresAllowlist(signature) noContracts {
    SaleRule memory rule = saleRules[tokenId];

    if (!rule.exists) revert SaleRuleUndefined();
    if (!rule.allowlistActive) revert AllowlistNotActive();
    if (totalSupply(tokenId) + quantity > rule.maxSupply - rule.swapSupply) revert MaxSupplyReached();
    if (msg.value < rule.salePrice * quantity) revert InsufficientFunds();

    TokenOwnership memory ownership = tokenOwnerships[msg.sender][tokenId];
    if (ownership.quantityMinted + quantity > rule.maxPerWallet) revert MaxPerWalletReached();

    tokenOwnerships[msg.sender][tokenId].quantityMinted += uint24(quantity);
    _mint(msg.sender, tokenId, quantity, "");
  }

  function airdropBatch(
    uint256 tokenId,
    address[] memory recipients,
    uint256[] memory quantities
  ) external onlyOperatorsAndOwner {
    SaleRule memory rule = saleRules[tokenId];

    uint256 totalQuantity = 0;
    for (uint256 i = 0; i < quantities.length; ) {
      totalQuantity += quantities[i];
      unchecked {
        ++i;
      }
    }
    if (totalSupply(tokenId) + totalQuantity > rule.maxSupply - rule.swapSupply) revert MaxSupplyReached();

    for (uint256 i = 0; i < recipients.length; ) {
      uint256 quantity = quantities[i];
      address recipient = recipients[i];

      tokenOwnerships[recipient][tokenId].quantityAirdropped += uint24(quantity);
      _mint(recipient, tokenId, quantity, "");
      unchecked {
        ++i;
      }
    }
  }

  function airdrop(uint256 tokenId, address recipient, uint256 quantity) external onlyOperatorsAndOwner {
    SaleRule memory rule = saleRules[tokenId];

    if (totalSupply(tokenId) + quantity > rule.maxSupply - rule.swapSupply) revert MaxSupplyReached();

    tokenOwnerships[recipient][tokenId].quantityAirdropped += uint24(quantity);

    _mint(recipient, tokenId, quantity, "");
  }

  function burnToken(address owner, uint256 tokenId) external onlyOperatorsAndOwner {
    if (!saleRules[tokenId].burnActive) revert BurnNotActive();
    if (balanceOf(owner, tokenId) < 1) revert BurnAmountExceedsBalance();

    tokenOwnerships[owner][tokenId].quantityBurned += 1;

    _burn(owner, tokenId, 1);
  }

  function swap(uint256 tokenId, address recipient, uint256 quantity) external onlyOperatorsAndOwner {
    SaleRule memory rule = saleRules[tokenId];

    if (!rule.exists) revert SaleRuleUndefined();
    if (!rule.swapActive) revert SwapNotActive();
    if (swapCounter[tokenId] >= saleRules[tokenId].swapSupply) revert SwapQuotaReached();
    if (tokenOwnerships[recipient][tokenId].quantitySwapped >= saleRules[tokenId].swapLimit) revert SwapLimitReached();

    swapCounter[tokenId] += 1;
    tokenOwnerships[recipient][tokenId].quantitySwapped += uint24(quantity);

    _mint(recipient, tokenId, quantity, "");
  }

  function swapCount(uint256 tokenId) external view returns (uint256) {
    return swapCounter[tokenId];
  }

  function tokenOwnershipsOf(address owner, uint256 tokenId) external view returns (TokenOwnership memory) {
    return tokenOwnerships[owner][tokenId];
  }

  function getSaleRules(uint256 tokenId) external view returns (SaleRule memory) {
    return saleRules[tokenId];
  }

  function setSaleRules(
    uint256 tokenId,
    uint256 salePrice,
    uint24 maxSupply,
    uint24 swapSupply,
    uint24 maxPerWallet,
    uint24 swapLimit
  ) external onlyOperatorsAndOwner {
    SaleRule memory rule = saleRules[tokenId];

    if (maxSupply < totalSupply(tokenId)) revert MaxSupplyTooLow();

    if (rule.exists) {
      rule.salePrice = salePrice;
      rule.maxSupply = maxSupply;
      rule.maxPerWallet = maxPerWallet;
      rule.swapLimit = swapLimit;
      rule.swapSupply = swapSupply;

      saleRules[tokenId] = rule;
    } else {
      saleRules[tokenId] = SaleRule(
        salePrice,
        maxSupply,
        swapSupply,
        maxPerWallet,
        swapLimit,
        false,
        false,
        false,
        false,
        true
      );
    }
  }

  function flipSaleState(uint256 tokenId) external onlyOperatorsAndOwner {
    SaleRule memory rule = saleRules[tokenId];
    rule.saleActive = !rule.saleActive;

    saleRules[tokenId] = rule;
  }

  function flipAllowlistState(uint256 tokenId) external onlyOperatorsAndOwner {
    SaleRule memory rule = saleRules[tokenId];
    rule.allowlistActive = !rule.allowlistActive;

    saleRules[tokenId] = rule;
  }

  function flipSwapState(uint256 tokenId) external onlyOperatorsAndOwner {
    SaleRule memory rule = saleRules[tokenId];
    rule.swapActive = !rule.swapActive;

    saleRules[tokenId] = rule;
  }

  function flipBurnState(uint256 tokenId) external onlyOperatorsAndOwner {
    SaleRule memory rule = saleRules[tokenId];
    rule.burnActive = !rule.burnActive;

    saleRules[tokenId] = rule;
  }

  function uri(uint256 tokenId) public view override(ERC1155, ERC1155URIStorage) returns (string memory) {
    return super.uri(tokenId);
  }

  function setBaseURI(string memory tokenURI) external onlyOperatorsAndOwner {
    _setBaseURI(tokenURI);
  }

  function setURI(uint256 tokenId, string memory tokenURI) external onlyOperatorsAndOwner {
    _setURI(tokenId, tokenURI);
  }

  function royaltyInfo(
    uint256 _tokenId,
    uint256 _salePrice
  ) external view returns (address receiver, uint256 royaltyAmount) {
    RoyaltyInfo memory royalties = _royalties;
    receiver = royalties.recipient;
    royaltyAmount = (_salePrice * royalties.amount) / 10000;
  }

  function setRoyaltyInfo(address _royaltyAddress, uint256 _percentage) external onlyOperatorsAndOwner {
    _setRoyaltyInfo(_royaltyAddress, _percentage);
  }

  function _setRoyaltyInfo(address recipient, uint256 value) internal {
    if (value >= 10000) revert RoyaltiesTooHigh();
    _royalties = RoyaltyInfo(recipient, uint24(value));
  }

  function setTreasuryAddress(address _treasuryAddress) external onlyOperatorsAndOwner {
    _setTreasuryAddress(_treasuryAddress);
  }

  function _setTreasuryAddress(address _treasuryAddress) internal {
    treasuryAddress = _treasuryAddress;
  }

  function setSigningAddress(address _signingAddress) public virtual onlyOperatorsAndOwner {
    signingKey = _signingAddress;
  }

  function release() external virtual onlyOperatorsAndOwner {
    uint256 balance = address(this).balance;
    Address.sendValue(payable(treasuryAddress), balance);
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

  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(AccessControlEnumerable, ERC1155, ERC2981) returns (bool) {
    return super.supportsInterface(interfaceId);
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
}