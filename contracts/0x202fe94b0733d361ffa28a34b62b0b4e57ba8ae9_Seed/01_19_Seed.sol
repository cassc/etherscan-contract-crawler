// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract Seed is ERC721, ERC721Enumerable, Pausable, Ownable, ERC721Burnable {
  using Strings for uint256;

  // max supply amount
  uint256 public maxSupply;

  // NFT URI base
  string public baseURI;
  // URI level range rules
  uint256[] public uriLevelRanges;
  // SCR contract address
  address public scr;

  // ------ ------ ------ ------ ------ ------ ------ ------ ------
  // ------ ------ ------ ------ ------ ------ ------ ------ ------

  constructor(address scr_) ERC721("SeeDAO Seed NFT", "SEED") {
    scr = scr_;

    // set default max supply
    maxSupply = 100_000;
    // set default uri level ranges
    uriLevelRanges.push(20_000);
    uriLevelRanges.push(300_000);
    uriLevelRanges.push(3_000_000);
    uriLevelRanges.push(30_000_000);

    // pause contract default
    pause();
  }

  /// @dev mint method
  function mint(address to, uint256 tokenId) public onlyOwner {
    require(totalSupply() + 1 <= maxSupply, "Exceeds the maximum supply");

    // this check code already exists in `_safeMint(address, uint256)` method
    // require(!_exists(tokenId), "ERC721: token already minted");

    _safeMint(to, tokenId);
  }

  // ------ ------ ------ ------ ------ ------ ------ ------ ------
  // ------ ------ ------ ------ ------ ------ ------ ------ ------

  /// @dev set max supply
  function setMaxSupply(uint256 maxSupply_) external onlyOwner {
    maxSupply = maxSupply_;
  }

  /// @dev set SCR contract address
  function setSCR(address scr_) external onlyOwner {
    scr = scr_;
  }

  /// @dev set NFT URI base, don't include the last "/"
  /// e.g：ipfs://QmSDdbLq2QDEgNUQGwRH7iVrcZiTy6PvCnKrdawGbTa7QD
  function setBaseURI(string memory baseURI_) external onlyOwner {
    baseURI = baseURI_;
  }

  /// @dev set URI level range rules
  /// For example, we have 5 levels, their range rule is as follows:
  ///   level1 range: (0 ~ 20_000)
  ///   level2 range: (20_000 ~ 300_000)
  ///   level3 range: (300_000 ~ 3_000_000)
  ///   level4 range: (3_000_000 ~ 30_000_000)
  ///   level5 range: (30_000_000 ~ ∞)
  /// We just need to use level1's top value, level2's top value, level3's top value, level4's top value as the input array param's elements.
  /// For this example, the input param is: `[20_000, 300_000, 3_000_000, 30_000_000]`.
  function setURILevelRange(
    uint256[] calldata uriLevelRanges_
  ) external onlyOwner {
    uriLevelRanges = uriLevelRanges_;
  }

  // ------ ------ ------ ------ ------ ------ ------ ------ ------
  // ------ ------ ------ ------ ------ ------ ------ ------ ------

  /// @dev get NFT URI, the method will return different NFT URI according to the the `tokenId` owner's amount of SCR, so as to realize Dynamic NFT
  /// e.g：
  /// ipfs://QmSDdbLq2QDEgNUQGwRH7iVrcZiTy6PvCnKrdawGbTa7QD/1_1.json
  /// ipfs://QmSDdbLq2QDEgNUQGwRH7iVrcZiTy6PvCnKrdawGbTa7QD/1_2.json
  /// ipfs://QmSDdbLq2QDEgNUQGwRH7iVrcZiTy6PvCnKrdawGbTa7QD/404.json
  function tokenURI(
    uint256 tokenId
  ) public view override returns (string memory) {
    _requireMinted(tokenId);

    if (paused()) {
      // ipfs://QmSDdbLq2QDEgNUQGwRH7iVrcZiTy6PvCnKrdawGbTa7QD/404.json
      return string(abi.encodePacked(baseURI, "/404.json"));
    } else {
      uint256 level = _parseLevel(tokenId);

      // ipfs://QmSDdbLq2QDEgNUQGwRH7iVrcZiTy6PvCnKrdawGbTa7QD/1_1.json
      return
        string(
          abi.encodePacked(
            baseURI,
            "/",
            tokenId.toString(),
            "_",
            level.toString(),
            ".json"
          )
        );
    }
  }

  /// @dev get level by owner's SCR amount
  function _parseLevel(uint256 tokenId) internal view returns (uint256) {
    uint256 de = 10 ** IERC20Metadata(scr).decimals();
    uint256 scrBalance = IERC20(scr).balanceOf(ownerOf(tokenId));

    for (uint i = 0; i < uriLevelRanges.length; i++) {
      if (scrBalance < uriLevelRanges[i] * de) {
        return i + 1;
      }
    }
    return uriLevelRanges.length + 1;
  }

  // ------ ------ ------ ------ ------ ------ ------ ------ ------
  // ------ ------ ------ ------ ------ ------ ------ ------ ------

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId,
    uint256 batchSize
  ) internal override(ERC721, ERC721Enumerable) {
    // don't use `whenNotPaused` modifier, because minter can mint even contract is paused
    require(!paused() || msg.sender == owner(), "Pausable: paused");

    super._beforeTokenTransfer(from, to, tokenId, batchSize);
  }

  // The following functions are overrides required by Solidity.

  function supportsInterface(
    bytes4 interfaceId
  ) public view override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}