//SPDX-License-Identifier: BSL 1.1
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface BequestWill {
  function isClaimable(address _owner) external view returns (bool);
}

/**
 * @title BequestTimelockVest
 * @author Bequest Finance Inc.
 * @notice Allows tokens and NFTs to be timelocked and vested. Deployed once.
 */
contract BequestTimelockVest is IERC165, IERC721Receiver, IERC1155Receiver {
  // Empty slot0 for proxy contract
  address private empty;

  BequestWill immutable bequestWillContract;

  bytes32 public constant moduleType = "TimelockVestV1";

  address public owner;
  address public recipient;

  uint256 public lockedUntil;
  uint256 public yearsToVest;
  uint256 public vestedUntil;
  uint256 public lastClaimed;

  /*
   * @dev: Ensures implementation contract cannot be tampered with.
   */
  constructor(address _bequestWillContract) {
    bequestWillContract = BequestWill(_bequestWillContract);
    owner = address(1);
  }

  /*
   * @dev: Can only be called once
   * @param _owner: The owner of the Timelock contract
   * @param _recipient: Recipient to which the timelock/vesting applies
   * @param _lockedUntil: Assets cannot be claimed at all before this time
   * @param _yearsToVest: Number of years over which vesting occurs
   * @param _vestedUntil: At this time vesting stops and all assets can be claimed
   */
  function setup(
    address _owner,
    address _recipient,
    uint256 _lockedUntil,
    uint256 _yearsToVest,
    uint256 _vestedUntil
  ) public {
    require(owner == address(0), "Already initialized");
    require(_owner != address(0) || _recipient != address(0), "Invalid address");
    
    owner = _owner;
    recipient = _recipient;
    lockedUntil = _lockedUntil;
    yearsToVest = _yearsToVest;
    vestedUntil = _vestedUntil;
  }

  /*
   * @dev: Can only be called by Bequest will owner
   * @param _lockedUntil: Assets cannot be claimed at all before this time
   * @param _yearsToVest: Number of years over which vesting occurs
   * @param _vestedUntil: At this time vesting stops and all assets can be claimed
   */
  function configureTimelock(
    uint256 _lockedUntil,
    uint256 _yearsToVest,
    uint256 _vestedUntil
  ) external {
    require(msg.sender == owner, "Only owner");

    lockedUntil = _lockedUntil;
    yearsToVest = _yearsToVest;
    vestedUntil = _vestedUntil;
  }

  /*
   * @dev: Lets recipient claim their tokens according to timelock/vesting setup
   * @param _tokens: List of tokens recipient wants
   */
  function claim(IERC20[] calldata _tokens) external {
    // Ensures assets cannot be claimed when a Bequest will is active, does not revert
    require(bequestWillContract.isClaimable(owner), "Will not claimable");

    require(block.timestamp > lockedUntil, "Tokens still locked");

    bool enableVesting = yearsToVest != 0 && block.timestamp < vestedUntil;

    if (enableVesting) {
      require(block.timestamp > lastClaimed + 365 days, "Tokens still vested");
      lastClaimed = block.timestamp;
    }

    for (uint256 i; i < _tokens.length; ) {
      uint256 amount;

      try _tokens[i].balanceOf(address(this)) returns (uint256 balance) {
        amount = balance;
      } catch (bytes memory) {}

      if (enableVesting) {
        amount /= yearsToVest;
      }

      try _tokens[i].transfer(recipient, amount) {} catch (bytes memory) {}

      unchecked {
        i++;
      }
    }

    if (enableVesting) {
      unchecked {
        yearsToVest--;
      }
    }
  }

  /*
   * @dev: Returns interfaces this smart contract implements
   * @param interfaceId: Interface ID of the NFT contract
   */
  function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
    return
      interfaceId == type(IERC165).interfaceId ||
      interfaceId == type(IERC721Receiver).interfaceId ||
      interfaceId == type(IERC1155Receiver).interfaceId;
  }

  /*
   * @dev: Instantly transfers an ERC721 to the recipient
   */
  function onERC721Received(
    address,
    address,
    uint256 tokenId,
    bytes memory
  ) external returns (bytes4) {
    IERC721(msg.sender).transferFrom(address(this), recipient, tokenId);
    return this.onERC721Received.selector;
  }

  /*
   * @dev: Instantly transfers an ERC1155 to the recipient
   */
  function onERC1155Received(
    address,
    address,
    uint256 tokenId,
    uint256 amount,
    bytes memory data
  ) external returns (bytes4) {
    IERC1155(msg.sender).safeTransferFrom(
      address(this),
      recipient,
      tokenId,
      amount,
      data
    );
    return this.onERC1155Received.selector;
  }

  /*
   * @dev: Instantly transfers multiple ERC1155 to the recipient
   */
  function onERC1155BatchReceived(
    address,
    address,
    uint256[] calldata tokenIds,
    uint256[] calldata values,
    bytes calldata data
  ) external returns (bytes4) {
    IERC1155(msg.sender).safeBatchTransferFrom(
      address(this),
      recipient,
      tokenIds,
      values,
      data
    );
    return this.onERC1155BatchReceived.selector;
  }
}