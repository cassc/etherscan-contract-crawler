// SPDX-License-Identifier: MIT

/**
 *
 * @title NiftyMoves.sol. Convenient and gas efficient protocol for sending multiple NFTs from multiple
 * collections to multiple recipients, or the burn address
 *
 * @author niftymoves https://niftymoves.io/
 *
 */

pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

// Included to allow setting of ENS reverse registration for contract:
abstract contract ENSReverseRegistrar {
  function setName(string memory name) public virtual returns (bytes32);
}

contract NiftyMoves is Ownable, IERC721Receiver, Pausable {
  address constant NIFTY_MOVES_ADMIN =
    0xE40Cf12aE18855aD4dB59dED35d12aCA53e2Da21;

  // Struct object that represents a single transfer request.
  // This has one to address with 1 to n collections and 1 to n
  // tokens within each collection
  struct ERC721Transfers {
    address toAddress;
    address[] erc721Addresses;
    uint256[][] tokenIds;
  }

  // ETH fee for transfers, if any:
  uint96 public ethFee = 0;

  // Treasury to receive any ETH fees, if any:
  address public treasury;

  // Address of the ENS reverse registrar to allow assignment of an ENS
  // name to this contract:
  ENSReverseRegistrar public ensReverseRegistrar;

  // Disable the burning method:
  bool burningDisabled = false;

  event NiftyMovesMade(address sender, uint256 totalTransfers);
  event NiftyBurnsMade(address sender, uint256 totalBurns);
  event ETHFeeUpdated(uint256 newEthFee);
  event TreasuryUpdated(address newTreasury);
  event ENSReverseRegistrarUpdated(address newENSReverseRegistrar);
  event BurnDisabled();
  event BurnEnabled();

  /**
   * @dev constructor
   */
  constructor() {
    _transferOwnership(NIFTY_MOVES_ADMIN);
  }

  /**
   *
   * @dev pause: Pause the contract.
   *
   */
  function pause() public onlyOwner {
    _pause();
  }

  /**
   *
   * @dev pause: Unpause the contract.
   *
   */
  function unpause() public onlyOwner {
    _unpause();
  }

  /**
   *
   * @dev setENSReverseRegistrar: set the ENS register address
   *
   * @param ensRegistrar_: ENS Reverse Registrar address
   *
   */
  function setENSReverseRegistrar(address ensRegistrar_) external onlyOwner {
    ensReverseRegistrar = ENSReverseRegistrar(ensRegistrar_);
    emit ENSReverseRegistrarUpdated(ensRegistrar_);
  }

  /**
   *
   * @dev setENSName: used to set reverse record so interactions with this contract
   * are easy to identify
   *
   * @param ensName_: string ENS name
   *
   */
  function setENSName(string memory ensName_) external onlyOwner {
    ensReverseRegistrar.setName(ensName_);
  }

  /**
   *
   * @dev setETHFee: set an ETH fee per transfer (default is 0)
   *
   * @param ethFee_: the new ETH fee
   *
   */
  function setETHFee(uint96 ethFee_) external onlyOwner {
    ethFee = ethFee_;
    emit ETHFeeUpdated(ethFee_);
  }

  /**
   *
   * @dev setTreasury: set a new treasury address
   *
   * @param treasury_: the new treasury address
   *
   */
  function setTreasury(address treasury_) external onlyOwner {
    treasury = treasury_;
    emit TreasuryUpdated(treasury_);
  }

  /**
   *
   * @dev disableBurn: disable niftyBurn
   *
   */
  function disableBurn() external onlyOwner {
    burningDisabled = true;
    emit BurnDisabled();
  }

  /**
   *
   * @dev enableBurn: enable niftyBurn
   *
   */
  function enableBurn() external onlyOwner {
    burningDisabled = false;
    emit BurnEnabled();
  }

  /**
   *
   * @dev withdrawETH: onlyOwner withdrawal to the treasury address.
   *
   * @param amount_: amount to withdraw
   *
   */
  function withdrawETH(uint256 amount_) external onlyOwner {
    (bool success, ) = treasury.call{value: amount_}("");
    require(success, "Transfer failed");
  }

  /**
   *
   * @dev niftyMove: function to transfer NFTs
   *
   * @param transfers_: struct object containing an array of transfers
   *
   */
  function niftyMove(
    ERC721Transfers[] calldata transfers_
  ) external payable whenNotPaused {
    // Perform ERC721 transfers:
    uint256 transferCount = _performERC721Moves(msg.sender, transfers_);

    // Check fee and amount received equals total of transfers:
    require(msg.value == (ethFee * transferCount), "Incorrect Fee");

    emit NiftyMovesMade(msg.sender, transferCount);
  }

  /**
   *
   * @dev _performERC721Moves: move ERC721s on-chain.
   *
   * @param sender_: the calling address for this transaction
   * @param erc721Transfers_: the struct object containing the transfers
   *
   */
  function _performERC721Moves(
    address sender_,
    ERC721Transfers[] calldata erc721Transfers_
  ) internal returns (uint256 transferCount_) {
    // Iterate through the list of transfer objects. There is one transfer
    // object per 'to' address:
    for (uint256 transfer = 0; transfer < erc721Transfers_.length; ) {
      // Check that the addresses and tokenID lists for this transfer match length:
      require(
        erc721Transfers_[transfer].erc721Addresses.length ==
          erc721Transfers_[transfer].tokenIds.length,
        "Length mismatch"
      );

      // Iterate through the list of collections for this "to" address:
      for (
        uint256 collection = 0;
        collection < erc721Transfers_[transfer].erc721Addresses.length;

      ) {
        // Iterate through the list of tokenIDs for this "to" address and
        // collection:
        uint256 item;
        for (
          item = 0;
          item < erc721Transfers_[transfer].tokenIds[collection].length;

        ) {
          // Check ownership:
          _ownershipCheck(
            erc721Transfers_[transfer].erc721Addresses[collection],
            erc721Transfers_[transfer].tokenIds[collection][item],
            sender_
          );

          // Transfer:
          IERC721(erc721Transfers_[transfer].erc721Addresses[collection])
            .safeTransferFrom(
              sender_,
              erc721Transfers_[transfer].toAddress,
              erc721Transfers_[transfer].tokenIds[collection][item]
            );

          unchecked {
            item++;
          }
        }
        unchecked {
          transferCount_ += item;
          collection++;
        }
      }
      unchecked {
        transfer++;
      }
    }

    return (transferCount_);
  }

  /**
   *
   * @dev niftyBurn: function to burn NFTs
   *
   * @param transfers_: struct object containing an array of transfers
   *
   */
  function niftyBurn(
    ERC721Transfers[] calldata transfers_
  ) external payable whenNotPaused {
    require(!burningDisabled, "niftyBurn is currently disabled");

    // Only permissable for a single transfer where the recipient is the Zero address:
    require(transfers_.length == 1, "Can only burn in a single transfer");

    // Check this was noted as a burn address transfer:
    require(
      transfers_[0].toAddress == address(0),
      "Cannot burn to non-0 address"
    );

    // Perform ERC721 burns:
    uint256 transferCount = _performERC721Burns(msg.sender, transfers_);

    // Check fee and amount received equals total of burns:
    require(msg.value == (ethFee * transferCount), "Incorrect Fee");

    emit NiftyBurnsMade(msg.sender, transferCount);
  }

  /**
   *
   * @dev _performERC721Burns: burn ERC721s on-chain.
   *
   * @param sender_: the calling address for this transaction
   * @param erc721Transfers_: the struct object containing the transfers
   *
   */
  function _performERC721Burns(
    address sender_,
    ERC721Transfers[] calldata erc721Transfers_
  ) internal returns (uint256 transferCount_) {
    for (
      uint256 collection = 0;
      collection < erc721Transfers_[0].erc721Addresses.length;

    ) {
      // Iterate through the list of tokenIDs for this "to" address and
      // collection:
      uint256 item;
      for (item = 0; item < erc721Transfers_[0].tokenIds[collection].length; ) {
        // Check ownership:
        _ownershipCheck(
          erc721Transfers_[0].erc721Addresses[collection],
          erc721Transfers_[0].tokenIds[collection][item],
          sender_
        );

        ERC721Burnable(erc721Transfers_[0].erc721Addresses[collection]).burn(
          erc721Transfers_[0].tokenIds[collection][item]
        );

        unchecked {
          item++;
        }
      }
      unchecked {
        transferCount_ += item;
        collection++;
      }
    }
  }

  /**
   *
   * @dev onERC721Received: allow transfer from owner (for the ENS token).
   *
   * @param from_: used to check this is only from the contract owner
   *
   */
  function onERC721Received(
    address,
    address from_,
    uint256,
    bytes memory
  ) external view override returns (bytes4) {
    if (from_ == owner()) {
      return this.onERC721Received.selector;
    } else {
      return ("");
    }
  }

  /**
   *
   * @dev withdrawERC721: Retrieve ERC721s (likely only the ENS
   * associated with this contract)
   *
   * @param erc721Address_: The token contract for the withdrawal
   * @param tokenIds_: the list of tokenIDs for the withdrawal
   *
   */
  function withdrawERC721(
    address erc721Address_,
    uint256[] memory tokenIds_
  ) external onlyOwner {
    for (uint256 i = 0; i < tokenIds_.length; ) {
      IERC721(erc721Address_).transferFrom(
        address(this),
        owner(),
        tokenIds_[i]
      );
      unchecked {
        ++i;
      }
    }
  }

  /**
   *
   * @dev _ownershipCheck: Redundant check for safety - transferFrom will fail on
   * call from non-owner sender address in ERC721. But we include this check here
   * in case anyone has failed to correctly implement ERC721, and relies solely on
   * owner / approved caller authority (!).
   *
   * @param collectionContract_: The token contract for the collection
   * @param tokenId_: the tokenId being transfered
   * @param sender_: the sender making this transaction call
   *
   */
  function _ownershipCheck(
    address collectionContract_,
    uint256 tokenId_,
    address sender_
  ) internal view {
    require(
      IERC721(collectionContract_).ownerOf(tokenId_) == sender_,
      "Call from non-owner"
    );
  }

  /**
   *
   * @dev Revert unexpected ETH and function calls
   *
   */
  receive() external payable {
    require(msg.sender == owner(), "Only owner can fund contract");
  }

  fallback() external payable {
    revert();
  }
}