// SPDX-License-Identifier: MIT
// Written by: Rob Secord (https://twitter.com/robsecord)
// Co-founder @ Charged Particles - Visit: https://charged.fi
// Co-founder @ Taggr             - Visit: https://taggr.io

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./lib/ERC721iEnumerable.sol";

/**
 * @dev This implements a Pre-Mint version of {ERC721} that adds the ability to Pre-Mint
 * all the token ids in the contract as assign an initial owner for each token id.
 *
 * On-chain state for Pre-Mint does not need to be initially stored if Max-Supply is known.
 * Minting is a simple matter of assigning a balance to the pre-mint receiver,
 * and modifying the "read" methods to account for the pre-mint receiver as owner.
 * We use the Consecutive Transfer Method as defined in EIP-2309 to signal inital ownership.
 * Almost everything else remains standard.
 * We also default to the contract "owner" as the pre-mint receiver, but this can be changed.
 */
contract ERC721i is
  Ownable,
  ERC721iEnumerable
{
  /// @dev EIP-2309: https://eips.ethereum.org/EIPS/eip-2309
  event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed fromAddress, address indexed toAddress);

  /**
    * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection,
    * as well as a `minter` and a `maxSupply` for pre-minting the collection.
    */
  constructor(
    string memory name,
    string memory symbol,
    address minter,
    uint256 maxSupply
  )
    ERC721(name, symbol)
  {
    // Set vars defined in ERC721iEnumerable.sol
    _maxSupply = maxSupply;
    _preMintReceiver = minter;
  }

  /**
    * @dev Pre-mint the max-supply of token IDs to the minter account.
    * Token IDs are in base-1 sequential order.
    */
  function _preMint() internal {
    // Update balance for initial owner, defined in ERC721.sol
    _balances[_preMintReceiver] = _maxSupply;

    // Emit the Consecutive Transfer Event
    emit ConsecutiveTransfer(1, _maxSupply, address(0), _preMintReceiver);
  }
}