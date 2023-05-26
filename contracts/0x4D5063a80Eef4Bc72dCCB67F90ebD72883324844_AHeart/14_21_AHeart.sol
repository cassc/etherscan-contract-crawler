// SPDX-License-Identifier: MIT

// Project A-Heart: https://a-he.art
//
//                                          @@@
//                    #@@#*,,,,,,,,,@@//@@@,,,,,,,@@
//                @  ,,,,,,,,,,,,,,,,,,,,/@,,,,,,,,,,@@
//             @  ,,,,,,,,,,,,,,,,,,,,,,,,,,,@,,,,,,,,,,@
//          @  .,,,,,,,,,,,,,,,,,@@,,,,,,,,,,,,@,,,,,,,,,,*@
//        .  .,,,,,,,,,,,,,,,,,,*#,,,/@,,,,,,,,,,@,,,,,,,,,,,@@
//       @  ,,,,,,@,,,,  ,,,,,,,,,,,,,#//*,,,,,,,,@,,,,,,,,,,,,,@@
//      @         @  ,,,,,,,,,@@,,,,,,,*/#@,,,,,,,,@,,,,,,,,@,,,,,,,@
//      %        ,@,,,,,,,,,,,,  & @%,,,//##,,,,#,,,@,,,,,,,,,,@(,,,,,,,@@
//   %//  .,,,,,,*@.,,,,,,,,,,,&./,@(@    @@@,,,#,,@/@/@,,,,,,,,,,@@@@@///////
//  ,//@ ,,,,,@,,@ @ @,,,,,,,,,,@,@%///%    %,,,,,%,,**@  @@,,,,,,,,,,@@@@@@@@
//  @//@ ,,,,,@,,      /,,,,,,,#,@%         @,#,,@#%,,,@       @,,,,,,*,,,,@@@
//  @//, ,,,,,@/*   %%,,,@,@@,,,,,#       ..,/,@[email protected]  @%,@          %@,,,,,@@,,,
//  @//@ ,,,,#,@//@((&@/%  #          .,[email protected]@.  .,%@  @@              @(,,,/@@
//   //%  ,,,,#,#*(* . ..             , .    @ (@@,*@@   @@@@@  @@@@@@   @,,,@
//   @//@ ,,,,,,,@@                 , @&      [email protected]    @@ @# @  %  @@&%((((@   @,
//   @///@@@,,@,,#, %% ,...      (  &&&&&     ,,@&@@       #&@%,,,,@(&(&((@@@@
//    @///@//@*/@@*,#@.....    @@@&%((((     @,,,,@@[email protected]%@  @   *,,@%#&(((@@@((
//     ///////@@@@@@@,,         @@(((((    &@,,,,,,@[email protected]/  @@@%%%%%(&%(((((
//     @///////@@@@   @[email protected]  #      [email protected](@   @@@,,,,,,*...... @@@&%%&&%%%%((((((((
//      @///////@@@  @     @@@@@*      @@@@,,,,,,,@....   @%%%@@@%%%%(((((((((
//      @/////////@  @@@                [email protected],,,,,,@....    @%%%%((@@@@@@@&%((((
//      @////@///#/   @@  .            @@[email protected],,@[email protected]@.     %%%&%(((@@@@@@%%%%%
//       #///@///@ @             @@@@@@@@@[email protected]  .%@%/////@%(((((((&@@%%%%%%
//       @///@@/@   @,     @ @@&%%&@@@@%%%@[email protected]@%%@///&//////@(((((@((((@%%%%%%
//       @///@@@  %,@  @@@  @@%%%%%%%%@%%%%%[email protected]///%%%.&&///#((&&&(@(((((((@%%@
//       @////@@@@,,@@@   %@((@%%%%%%%%%%%%%%(/////&//////@((((((((@((((%%@%%@
//       @////@%%%%%%%%&%&(#(((@%%%%%%%%%@%%%%%&&@@@///&///&((((((%@@%%%%%%%%@
//       @////@@(%&%%%%(&(&((((@@%%%%%%%%%@%%%%%%&%%&//@..&&&%%%%%%@@@%%%%%@@@
//       @/////@@@((((((((((@@@@&%@@%%%%%%@@@%%&%%%%#(#@[email protected]%%%%%%%%@@@@@%%@@@@

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

import "./interfaces/IAHeart.sol";
import "./ERC4906.sol";

contract AHeart is IAHeart, ERC721, ERC2981, ERC4906, Ownable, DefaultOperatorFilterer {
  using Strings for uint256;

  uint256 public constant MAX_SUPPLY = 2690;

  uint256 private constant REWARD_PER_SECOND = 11574074074075;

  uint256 private constant CHEMISTRY_MAX_LEVEL = 20;

  uint256 private constant CHEMISTRY_MULTIPLE = 1e4;

  uint256 private constant EMISSION_RATE_BASE = 1e5;

  uint96 private constant DEFAULT_ROYALTY_FEE_NUMERATOR = 690; // 6.9%

  uint256 public totalSupply;

  address public minter;

  mapping(address => bool) public extensions;

  string public baseTokenURI;

  mapping(uint256 => string) public suffixKeys;

  uint256 public suffixKeyCount = 0;

  mapping(uint256 => mapping(uint256 => string)) public suffixValues;

  struct TokenInfo {
    uint256 transferLastTimestamp;
    uint256 rewardLastTimestamp;
    uint256 settledRewardAmount;
    uint96 emissionRateDelta;
  }

  mapping(uint256 => TokenInfo) public tokenInfo;

  modifier onlyMinter() {
    require(minter == _msgSender(), "caller is not the minter");
    _;
  }

  modifier onlyExtension() {
    require(extensions[_msgSender()], "caller is not the extension");
    _;
  }

  constructor(string memory initialBaseTokenURI, address royaltyReceiver) ERC721("A-Heart", "AHE") {
    _setDefaultRoyalty(royaltyReceiver, DEFAULT_ROYALTY_FEE_NUMERATOR);
    baseTokenURI = initialBaseTokenURI;
  }

  function setRoyaltyInfo(address receiver, uint96 feeBasisPoints) external onlyOwner {
    _setDefaultRoyalty(receiver, feeBasisPoints);
  }

  function supportsInterface(bytes4 interfaceId) public view override(IERC165, ERC721, ERC2981, ERC4906) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function emitBatchMetadataUpdate(uint256 fromTokenId, uint256 toTokenId) external onlyOwner {
    emit BatchMetadataUpdate(fromTokenId, toTokenId);
  }

  function setMinter(address newMinter) external onlyOwner {
    minter = newMinter;
  }

  function mint(address to, uint256 tokenId) external onlyMinter {
    require(1 <= tokenId && tokenId <= MAX_SUPPLY, "invalid token id");
    unchecked {
      totalSupply++;
    }
    _mint(to, tokenId);
    _resetTokenInfo(tokenId);
  }

  function setExtension(address extension, bool value) external onlyOwner {
    extensions[extension] = value;
  }

  function setBaseTokenURI(string calldata newBaseTokenURI) external onlyOwner {
    baseTokenURI = newBaseTokenURI;
    emit BatchMetadataUpdate(1, type(uint256).max);
  }

  function addSuffixKey(string calldata key) external onlyOwner {
    suffixKeys[suffixKeyCount] = key;
    unchecked {
      suffixKeyCount++;
    }
  }

  function removeSuffixKey(uint256 keyIndex) external onlyOwner {
    require(keyIndex < suffixKeyCount, "The key is not registered");
    suffixKeys[keyIndex] = "";
    emit BatchMetadataUpdate(1, type(uint256).max);
  }

  function setSuffixValue(uint256 keyIndex, uint256 tokenId, string calldata value) external onlyExtension {
    require(keyIndex < suffixKeyCount, "The key is not registered");
    suffixValues[keyIndex][tokenId] = value;
    emit MetadataUpdate(tokenId);
  }

  function tokenURISuffix(uint256 tokenId) public view returns (string memory) {
    string memory output = "";
    for (uint256 i = 0; i < suffixKeyCount; i++) {
      if (bytes(suffixKeys[i]).length > 0 && bytes(suffixValues[i][tokenId]).length > 0) {
        output = string.concat(output, "__", suffixKeys[i], "_", suffixValues[i][tokenId]);
      }
    }
    return output;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return string(abi.encodePacked(baseTokenURI, tokenId.toString(), tokenURISuffix(tokenId), ".json"));
  }

  function setEmissionRateDelta(uint256 tokenId, uint96 value) external onlyExtension {
    uint256 currentAmount = rewardAmount(tokenId);
    tokenInfo[tokenId].rewardLastTimestamp = block.timestamp;
    tokenInfo[tokenId].settledRewardAmount = currentAmount;
    tokenInfo[tokenId].emissionRateDelta = value;
  }

  function chemistry(address tokenOwner, uint256 tokenId) public pure returns (uint256) {
    if (tokenOwner == address(0)) {
      return 0;
    }
    uint256 hashedValue = uint256(keccak256(abi.encodePacked(tokenOwner, tokenId)));
    uint256 value = (hashedValue % CHEMISTRY_MAX_LEVEL) + 1;
    return value * CHEMISTRY_MULTIPLE;
  }

  function emissionRate(uint256 tokenId) public view returns (uint256) {
    return chemistry(_ownerOf(tokenId), tokenId) + uint256(tokenInfo[tokenId].emissionRateDelta);
  }

  function rewardAmount(uint256 tokenId) public view returns (uint256) {
    return (((block.timestamp - tokenInfo[tokenId].rewardLastTimestamp) * REWARD_PER_SECOND * emissionRate(tokenId)) / EMISSION_RATE_BASE) + tokenInfo[tokenId].settledRewardAmount;
  }

  function addReward(uint256 tokenId, uint256 amount) external onlyExtension {
    uint256 newAmount = rewardAmount(tokenId) + amount;
    tokenInfo[tokenId].rewardLastTimestamp = block.timestamp;
    tokenInfo[tokenId].settledRewardAmount = newAmount;
  }

  function removeReward(uint256 tokenId, uint256 amount) external onlyExtension {
    require(rewardAmount(tokenId) >= amount, "amount is greater than the current reward amount");
    uint256 newAmount = rewardAmount(tokenId) - amount;
    tokenInfo[tokenId].rewardLastTimestamp = block.timestamp;
    tokenInfo[tokenId].settledRewardAmount = newAmount;
  }

  function _resetTokenInfo(uint256 tokenId) internal {
    tokenInfo[tokenId].transferLastTimestamp = block.timestamp;
    tokenInfo[tokenId].rewardLastTimestamp = block.timestamp;
    tokenInfo[tokenId].settledRewardAmount = 0;
    tokenInfo[tokenId].emissionRateDelta = 0;
  }

  function transferWithReward(address to, uint256 tokenId) external {
    super.transferFrom(_msgSender(), to, tokenId);
  }

  function setApprovalForAll(address operator, bool approved) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
    _resetTokenInfo(tokenId);
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override(ERC721, IERC721) onlyAllowedOperator(from) {
    _resetTokenInfo(tokenId);
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override(ERC721, IERC721) onlyAllowedOperator(from) {
    _resetTokenInfo(tokenId);
    super.safeTransferFrom(from, to, tokenId, data);
  }
}