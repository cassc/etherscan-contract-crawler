// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {PaymentSplitter} from "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ERC721} from "./lib/ERC721.sol";
import {IDelegateCash} from "./lib/IDelegateCash.sol";

error NotAuthorized();
error MaxSupplyReached();
error ClaimingTooEarly();
error ClaimingTooLate();
error AlreadyClaimed();
error SupplyLocked();

interface IGoldRenderer {
  function tokenURI(uint256 tokenId) external view returns (string memory);

  function numberOfBonusPlates(uint256 tokenId) external view returns (uint256);
}

/// @title Gold
/// @author @0x_jj
contract Gold is ERC721, PaymentSplitter, AccessControl, Ownable, Pausable {
  using SafeCast for uint256;

  uint256 public totalSupply = 0;
  uint256 public maxSupply;
  bool public supplyLocked;

  address public minter;

  IGoldRenderer public renderer;
  IERC20 public wethContract;

  struct TokenData {
    uint256 transferCount;
    uint256[HISTORY_LENGTH] latestTransferTimestamps;
    uint256 mintTimestamp;
    bytes32 seed;
    address held6MonthsClaimedBy;
    address held12MonthsClaimedBy;
    address held24MonthsClaimedBy;
    address held60MonthsClaimedBy;
    address held120MonthsClaimedBy;
    address held240MonthsClaimedBy;
  }

  /// @dev Mapping from token ID to token data
  mapping(uint256 => TokenData) public tokenData;

  /// @dev Track when we receive royalty payments
  struct RoyaltyReceipt {
    uint64 timestamp;
    uint192 amount;
  }
  uint256 public ethReceivedCount;
  RoyaltyReceipt[HISTORY_LENGTH] public ethReceipts;

  /// @dev Track WETH roughly by checking balances between transfers
  struct WethStats {
    uint64 wethReceivedCount;
    uint192 latestWethBalance;
  }
  WethStats private wethStats;
  RoyaltyReceipt[HISTORY_LENGTH] public wethReceipts;

  /// @dev Number of transfers that have happened on the contract
  uint256 public transferCount;

  /// @dev Timestamp of the last transfer that happened on the contract
  uint256[HISTORY_LENGTH] public latestTransferTimestamps;

  /// @dev Base timestamp to use to calculate averages in the art script
  uint256 public baseTimestamp;

  /// @dev Delegate cash contract address
  IDelegateCash public delegateCash;

  constructor(
    address[] memory payees,
    uint256[] memory shares,
    address[] memory admins_,
    address wethContract_,
    address goldRenderer_,
    uint256 maxSupply_,
    address delegateCash_
  ) PaymentSplitter(payees, shares) ERC721("GOLD", "GOLD") {
    _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    for (uint256 i = 0; i < admins_.length; i++) {
      _grantRole(DEFAULT_ADMIN_ROLE, admins_[i]);
    }

    wethContract = IERC20(wethContract_);
    renderer = IGoldRenderer(goldRenderer_);
    baseTimestamp = block.timestamp;
    maxSupply = maxSupply_;
    delegateCash = IDelegateCash(delegateCash_);
  }

  receive() external payable override {
    emit PaymentReceived(_msgSender(), msg.value);
    ethReceipts[ethReceivedCount % HISTORY_LENGTH] = RoyaltyReceipt(
      block.timestamp.toUint64(),
      msg.value.toUint192()
    );
    ethReceivedCount += 1;
  }

  function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
    _unpause();
  }

  function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
    _pause();
  }

  function setBaseTimestamp(uint256 _baseTimestamp) external onlyRole(DEFAULT_ADMIN_ROLE) {
    baseTimestamp = _baseTimestamp;
  }

  function setMinterAddress(address _minter) external onlyRole(DEFAULT_ADMIN_ROLE) {
    minter = _minter;
  }

  function setRendererAddress(address _renderer) external onlyRole(DEFAULT_ADMIN_ROLE) {
    renderer = IGoldRenderer(_renderer);
  }

  function endMint() external onlyRole(DEFAULT_ADMIN_ROLE) {
    maxSupply = totalSupply;
  }

  function mint(address to) public whenNotPaused {
    if (totalSupply >= maxSupply) revert MaxSupplyReached();
    if (!(_msgSender() == minter || _msgSender() == owner())) revert NotAuthorized();

    uint256 tokenId = totalSupply;
    totalSupply++;
    tokenData[tokenId].mintTimestamp = block.timestamp;
    tokenData[tokenId].seed = keccak256(
      abi.encodePacked(blockhash(block.number - 1), block.number, block.timestamp, _msgSender(), tokenId)
    );
    _safeMint(to, tokenId);
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    return renderer.tokenURI(tokenId);
  }

  function _afterTokenTransfer(address from, address, uint256 tokenId, uint256) internal override {
    if (from == address(0)) {
      return;
    }

    // Record latest transfer on contract
    latestTransferTimestamps[transferCount % HISTORY_LENGTH] = block.timestamp;

    // Record latest transfer on token. Unordered, to be sorted by timestamp off chain
    tokenData[tokenId].latestTransferTimestamps[tokenData[tokenId].transferCount % HISTORY_LENGTH] = block
      .timestamp;

    // Increase transfer counts on token and contract. Important so that we can correctly write to history arrays in a loop
    tokenData[tokenId].transferCount++;
    transferCount++;

    // Record WETH receipts, if any, attempting to match how we record native ETH receipts
    // We do this by checking the balance of the contract before and after the transfer, taking into account any WETH that has been released to payees
    // Of course this means we don't know when WETH was received multiple times between two transfers occurring, but that's fine, it's just a rough estimate
    WethStats memory stats = wethStats;
    uint256 prevBalance = stats.latestWethBalance;
    uint256 currentBalance = wethContract.balanceOf(address(this)) + totalReleased(wethContract);

    if (currentBalance > prevBalance) {
      stats.latestWethBalance = currentBalance.toUint192();
      wethReceipts[stats.wethReceivedCount % HISTORY_LENGTH] = RoyaltyReceipt(
        block.timestamp.toUint64(),
        (currentBalance - prevBalance).toUint192()
      );
      stats.wethReceivedCount++;

      wethStats = stats;
    }
  }

  function claimBonusPlates(uint256 tokenId, uint8 milestone, address vaultAddress) external {
    address claimant = _msgSender();

    if (vaultAddress != address(0) && vaultAddress != _msgSender()) {
      bool isDelegateValid = delegateCash.checkDelegateForContract(_msgSender(), vaultAddress, address(this));
      require(isDelegateValid, "invalid delegate-vault pairing");
      claimant = vaultAddress;
    }

    if (ownerOf(tokenId) != claimant) revert NotAuthorized();

    uint256 lastTransferTimestamp = latestTransferTimestamp(tokenData[tokenId]);

    if (milestone == 1) {
      if (tokenData[tokenId].held6MonthsClaimedBy != address(0)) {
        revert AlreadyClaimed();
      }

      uint256 eligibleAt = lastTransferTimestamp + (6 * 30 days);

      if (block.timestamp < eligibleAt) revert ClaimingTooEarly();
      if (block.timestamp > (eligibleAt + (24 days))) revert ClaimingTooLate();

      tokenData[tokenId].held6MonthsClaimedBy = claimant;
    }

    if (milestone == 2) {
      if (tokenData[tokenId].held12MonthsClaimedBy != address(0)) {
        revert AlreadyClaimed();
      }

      uint256 eligibleAt = lastTransferTimestamp + (12 * 30 days);

      if (block.timestamp < eligibleAt) revert ClaimingTooEarly();
      if (block.timestamp > (eligibleAt + (24 days))) revert ClaimingTooLate();

      tokenData[tokenId].held12MonthsClaimedBy = claimant;
    }

    if (milestone == 3) {
      if (tokenData[tokenId].held24MonthsClaimedBy != address(0)) {
        revert AlreadyClaimed();
      }

      uint256 eligibleAt = lastTransferTimestamp + (24 * 30 days);

      if (block.timestamp < eligibleAt) revert ClaimingTooEarly();
      if (block.timestamp > (eligibleAt + (24 days))) revert ClaimingTooLate();

      tokenData[tokenId].held24MonthsClaimedBy = claimant;
    }

    if (milestone == 4) {
      if (tokenData[tokenId].held60MonthsClaimedBy != address(0)) {
        revert AlreadyClaimed();
      }

      uint256 eligibleAt = lastTransferTimestamp + (60 * 30 days);

      if (block.timestamp < eligibleAt) revert ClaimingTooEarly();
      if (block.timestamp > (eligibleAt + (24 days))) revert ClaimingTooLate();

      tokenData[tokenId].held60MonthsClaimedBy = claimant;
    }

    if (milestone == 5) {
      if (tokenData[tokenId].held120MonthsClaimedBy != address(0)) {
        revert AlreadyClaimed();
      }

      uint256 eligibleAt = lastTransferTimestamp + (120 * 30 days);

      if (block.timestamp < eligibleAt) revert ClaimingTooEarly();
      if (block.timestamp > (eligibleAt + (24 days))) revert ClaimingTooLate();

      tokenData[tokenId].held120MonthsClaimedBy = claimant;
    }

    if (milestone == 6) {
      if (tokenData[tokenId].held240MonthsClaimedBy != address(0)) {
        revert AlreadyClaimed();
      }

      uint256 eligibleAt = lastTransferTimestamp + (240 * 30 days);

      if (block.timestamp < eligibleAt) revert ClaimingTooEarly();
      if (block.timestamp > (eligibleAt + (24 days))) revert ClaimingTooLate();

      tokenData[tokenId].held240MonthsClaimedBy = claimant;
    }
  }

  function getContractMetrics()
    external
    view
    returns (
      uint256,
      uint256[HISTORY_LENGTH] memory,
      uint256,
      uint256[HISTORY_LENGTH] memory,
      uint256,
      RoyaltyReceipt[HISTORY_LENGTH] memory,
      RoyaltyReceipt[HISTORY_LENGTH] memory,
      uint256
    )
  {
    return (
      approvalCount,
      latestApprovalTimestamps,
      transferCount,
      latestTransferTimestamps,
      getHolderCount(),
      ethReceipts,
      wethReceipts,
      totalSupply
    );
  }

  function getTokenMetrics(
    uint256 tokenId
  ) external view returns (uint256, uint256[HISTORY_LENGTH] memory, uint256, bytes32, uint256, uint256) {
    return (
      tokenData[tokenId].transferCount,
      tokenData[tokenId].latestTransferTimestamps,
      tokenData[tokenId].mintTimestamp,
      tokenData[tokenId].seed,
      balanceOf(ownerOf(tokenId)),
      renderer.numberOfBonusPlates(tokenId)
    );
  }

  function getHolderCount() internal view returns (uint256) {
    uint256 count = 0;
    address[] memory seen = new address[](totalSupply);
    for (uint256 i = 0; i < totalSupply; i++) {
      address owner = ownerOf(i);
      if (findElement(seen, owner) == false) {
        count++;
        seen[i] = owner;
      } else {
        seen[i] = address(0);
      }
    }
    return count;
  }

  function latestTransferTimestamp(TokenData memory _tokenData) internal pure returns (uint256) {
    if (_tokenData.transferCount == 0) return _tokenData.mintTimestamp;

    return _tokenData.latestTransferTimestamps[(_tokenData.transferCount - 1) % HISTORY_LENGTH];
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function findElement(address[] memory arr, address element) internal pure returns (bool) {
    for (uint256 i = 0; i < arr.length; i++) {
      if (arr[i] == element) {
        return true;
      }
    }
    return false;
  }

  function toHexDigit(uint8 d) internal pure returns (bytes1) {
    if (0 <= d && d <= 9) {
      return bytes1(uint8(bytes1("0")) + d);
    } else if (10 <= uint8(d) && uint8(d) <= 15) {
      return bytes1(uint8(bytes1("a")) + d - 10);
    }
    revert();
  }

  function fromCode(bytes4 code) internal pure returns (string memory) {
    bytes memory result = new bytes(10);
    result[0] = bytes1("0");
    result[1] = bytes1("x");
    for (uint i = 0; i < 4; ++i) {
      result[2 * i + 2] = toHexDigit(uint8(code[i]) / 16);
      result[2 * i + 3] = toHexDigit(uint8(code[i]) % 16);
    }
    return string(result);
  }

  function getSelectors() public pure returns (string memory, string memory) {
    return (fromCode(this.getContractMetrics.selector), fromCode(this.getTokenMetrics.selector));
  }
}