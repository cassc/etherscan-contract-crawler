// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import './MultisigOwnable.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

error ChunkAlreadyProcessed();
error MismatchedArrays();
error InsufficientBalance();
error ClaimWindowNotOpen();
error MismatchedTokenOwner();
error JacketCannotBeClaimed();
error AzukiNotOwnedLongEnough();
error RedeemWindowNotOpen();

interface Azuki {
  struct TokenOwnership {
    address addr;
    uint64 startTimestamp;
  }

  function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory);
}

contract Tiger is
  ERC1155Pausable,
  ERC1155Burnable,
  MultisigOwnable,
  ReentrancyGuard
{
  // Represents un-redeemed jacket token
  uint256 public constant BLUE = 1;
  // Represents redeemed jacket token
  uint256 public constant RED = 2;

  uint256 public constant MIN_OWNERSHIP_TIME_FOR_CLAIM = 120;

  bool public canRedeem;

  struct ClaimWindow {
    uint128 startTime;
    uint128 endTime;
  }
  ClaimWindow public claimWindow;
  Azuki public immutable azuki;
  // Keys are azuki token ids
  mapping(uint256 => bool) public azukiCanClaim;
  mapping(uint256 => bool) private processedChunksForAirdrop;
  mapping(address => uint256) public numRedeemed;

  constructor(address _azukiAddress) ERC1155('') {
    azuki = Azuki(_azukiAddress);
  }

  function airdrop(
    address[] calldata receivers,
    uint256[] calldata numAzukiTokens,
    uint256 chunkNum
  ) external onlyRealOwner {
    if (receivers.length != numAzukiTokens.length || receivers.length == 0)
      revert MismatchedArrays();
    if (
      processedChunksForAirdrop[chunkNum] || balanceOf(receivers[0], BLUE) > 0
    ) revert ChunkAlreadyProcessed();

    for (uint256 i; i < receivers.length; ) {
      _mint(receivers[i], BLUE, numAzukiTokens[i], '');
      unchecked {
        ++i;
      }
    }
    processedChunksForAirdrop[chunkNum] = true;
  }

  function claim(uint256[] calldata azukiTokenIds) external {
    ClaimWindow memory window = claimWindow;
    uint256 curTime = block.timestamp;
    if (
      curTime < uint256(window.startTime) || curTime > uint256(window.endTime)
    ) {
      revert ClaimWindowNotOpen();
    }

    for (uint256 i; i < azukiTokenIds.length; ) {
      uint256 azukiId = azukiTokenIds[i];

      Azuki.TokenOwnership memory tokenOwnership = azuki.getOwnershipData(
        azukiId
      );
      address tokenOwner = tokenOwnership.addr;
      if (tokenOwner != msg.sender) revert MismatchedTokenOwner();
      if (!azukiCanClaim[azukiId]) revert JacketCannotBeClaimed();
      uint256 ownershipStart = uint256(tokenOwnership.startTimestamp);
      // Prevent flash loans
      if (block.timestamp - ownershipStart < MIN_OWNERSHIP_TIME_FOR_CLAIM) {
        revert AzukiNotOwnedLongEnough();
      }
      azukiCanClaim[azukiId] = false;
      unchecked {
        ++i;
      }
    }
    _mint(msg.sender, BLUE, azukiTokenIds.length, '');
  }

  function redeemJacketToken(uint256 numTokens) external nonReentrant {
    if (!canRedeem) revert RedeemWindowNotOpen();
    if (balanceOf(msg.sender, BLUE) < numTokens) revert InsufficientBalance();
    unchecked {
      numRedeemed[msg.sender] += numTokens;
    }
    _burn(msg.sender, BLUE, numTokens);
    _mint(msg.sender, RED, numTokens, '');
  }

  function getNumRedeemed(address user) external view returns (uint256) {
    return numRedeemed[user];
  }

  function ownerMint(address to, uint256 amount) external onlyRealOwner {
    _mint(to, BLUE, amount, '');
  }

  function setClaimWindow(uint128 _startTime, uint128 _endTime)
    external
    onlyRealOwner
  {
    claimWindow.startTime = _startTime;
    claimWindow.endTime = _endTime;
  }

  function setCanClaim(uint256[] calldata azukiIds) external onlyRealOwner {
    for (uint256 i; i < azukiIds.length; ++i) {
      azukiCanClaim[azukiIds[i]] = true;
    }
  }

  function setCanRedeem(bool _canRedeem) external onlyRealOwner {
    canRedeem = _canRedeem;
  }

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual override(ERC1155, ERC1155Pausable) {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }

  function pause() external onlyRealOwner {
    _pause();
  }

  function unpause() external onlyRealOwner {
    _unpause();
  }

  function setTokenUri(string calldata newUri) external onlyRealOwner {
    _setURI(newUri);
  }

  string private _name = 'Twin Tigers';
  string private _symbol = 'TIGER';

  function name() public view returns (string memory) {
    return _name;
  }

  function symbol() public view returns (string memory) {
    return _symbol;
  }

  function setNameAndSymbol(
    string calldata _newName,
    string calldata _newSymbol
  ) external onlyRealOwner {
    _name = _newName;
    _symbol = _newSymbol;
  }
}