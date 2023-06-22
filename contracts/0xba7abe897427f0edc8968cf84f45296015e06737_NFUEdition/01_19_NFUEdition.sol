// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Strings.sol';

import './components/BaseNFT.sol';

/**
 * @notice This is a pseudo ERC1155 contract presented as an ERC721.
 */
contract NFUEdition is BaseNFT {
  using Strings for uint256;

  event RegisterEdition(uint256 editionId, uint256 supply, uint256 price);

  error INVALID_OPERATION();

  /**
   * @dev Lists edition (array-index) supply caps (value).
   */
  uint256[] public editions;

  /**
   * @dev Lists edition (array-index) prices in wei (value).
   */
  uint256[] public editionPrices;

  /**
   * @dev Tracks last minted edition (array-index) token id (value).
   */
  uint256[] public mintedEditions;

  //*********************************************************************//
  // -------------------------- initializer ---------------------------- //
  //*********************************************************************//

  /**
   * @dev This contract is meant to be deployed via the `Deployer` which makes `Clone`s. The `Deployer` itself has a reference to a known-good copy. When the platform admin is deploying the `Deployer` and the source `NFUEdition` the constructor will lock that contract to the platform admin. When the deployer is making copies of it the source storage isn't taken so the Deployer will call `initialize` to set the admin to the correct account.
   */
  constructor() {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(MINTER_ROLE, msg.sender);
  }

  /**
   * @notice Initializes token state. Used by the Deployer contract to set NFT parameters and contract ownership.
   *
   * @dev _unitPrice (after _maxSupply, before _mintAllowance) parameter is ignored as token prices are dictated by edition definition.
   *
   * @dev While this contract inherits from BaseNFT, it doesn't allow base URI modification and is automatically revealed.
   *
   * @param _owner Token admin.
   * @param _name Token name.
   * @param _symbol Token symbol.
   * @param _baseUri Base URI.
   * @param _contractUri OpenSea-style contract metadata URI.
   * @param _maxSupply Max NFT supply.
   * @param _mintAllowance Per-user mint cap.
   * @param _mintPeriodStart Start of the minting period in seconds.
   * @param _mintPeriodEnd End of the minting period in seconds.
   */
  function initialize(
    address _owner,
    string memory _name,
    string memory _symbol,
    string memory _baseUri,
    string memory _contractUri,
    uint256 _maxSupply,
    uint256,
    uint256 _mintAllowance,
    uint256 _mintPeriodStart,
    uint256 _mintPeriodEnd
  ) public {
    if (bytes(name).length != 0) {
      revert INVALID_OPERATION();
    }

    if (getRoleMemberCount(DEFAULT_ADMIN_ROLE) != 0) {
      if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
        revert INVALID_OPERATION();
      }
    } else {
      _grantRole(DEFAULT_ADMIN_ROLE, _owner);
      _grantRole(MINTER_ROLE, _owner);
    }

    name = _name;
    symbol = _symbol;

    baseUri = _baseUri;
    contractUri = _contractUri;
    maxSupply = _maxSupply;
    mintAllowance = _mintAllowance;
    mintPeriod = (_mintPeriodStart << 128) | _mintPeriodEnd;
    isRevealed = true;

    payoutReceiver = payable(_owner);
    royaltyReceiver = payable(_owner);

    _grantRole(DEFAULT_ADMIN_ROLE, _owner);
    _grantRole(MINTER_ROLE, _owner);
  }

  //*********************************************************************//
  // ------------------------- mint operations ------------------------- //
  //*********************************************************************//

  /**
   * @notice Mints a token for a given edition provided that price validation logic is satisfied. Subject to maxSupply constraints set in the `initialize` function and edition limits set with `registerEdition`.
   *
   * @param _edition Edition index.
   */
  function mint(
    uint256 _edition
  )
    external
    payable
    virtual
    nonReentrant
    onlyDuringMintPeriod
    callerNotBlocked(msg.sender)
    supplyAvailable(_edition)
    returns (uint256 tokenId)
  {
    tokenId = mintActual(_edition, msg.sender);
  }

  function mint(
    uint256 _edition,
    address _account
  )
    external
    payable
    virtual
    nonReentrant
    onlyDuringMintPeriod
    callerNotBlocked(msg.sender)
    supplyAvailable(_edition)
    returns (uint256 tokenId)
  {
    tokenId = mintActual(_edition, _account);
  }

  //*********************************************************************//
  // --------------------- privileged transactions --------------------- //
  //*********************************************************************//

  /**
   * @notice Privileged operation to mint an edition to an address. Does not accept payment, ignores paused flag, mint period and block list.
   */
  function mintEditionFor(
    uint256 _edition,
    address _account
  ) external virtual onlyRole(MINTER_ROLE) supplyAvailable(_edition) returns (uint256 tokenId) {
    unchecked {
      ++totalSupply;
      ++mintedEditions[_edition];
    }
    tokenId = generateTokenId(_account, 0, _edition);
    _mint(_account, tokenId);
  }

  /**
   * @notice Appends an edition to the current list. Editions must be in acending order price-wise and this operation will fail if the edition being added is priced below the last one.
   */
  function registerEdition(
    uint256 _maxSupply,
    uint256 _price
  ) external virtual onlyRole(MINTER_ROLE) returns (uint256 editionId) {
    editions.push(_maxSupply);
    editionPrices.push(_price);
    mintedEditions.push(0);
    editionId = editions.length - 1;

    emit RegisterEdition(editionId, _maxSupply, _price);
  }

  //*********************************************************************//
  // ------------------------ parent overrides ------------------------- //
  //*********************************************************************//
  /**
   * @notice Provides a token URI based on edition index encoded in the bottom 16 bits of the token id.
   */
  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory uri) {
    if (ownerOf(_tokenId) == address(0)) {
      uri = '';
    } else {
      uri = string(abi.encodePacked(baseUri, uint256(uint16(_tokenId)).toString()));
    }
  }

  /**
   * @dev Prevent mint without edition param.
   */
  function mint() external payable override returns (uint256) {
    revert INVALID_OPERATION();
  }

  /**
   * @dev Prevent mint without edition param.
   */
  function mintFor(address) external override returns (uint256) {
    revert INVALID_OPERATION();
  }

  /**
   * @dev Prevent mint without edition param.
   */
  function generateTokenId(address, uint256) internal virtual override returns (uint256 tokenId) {
    revert INVALID_OPERATION();
  }

  /**
   * @notice Function to consolidate functionality for external mint calls.
   *
   * @dev External calls should be validated by modifiers like `onlyDuringMintPeriod`, `callerNotBlocked` and `supplyAvailable`.
   *
   * @param _edition Edition id to mint.
   * @param _account Address to assign the new token to.
   */
  function mintActual(
    uint256 _edition,
    address _account
  ) internal virtual returns (uint256 tokenId) {
    if (isPaused) {
      revert MINTING_PAUSED();
    }

    (uint256 balance, uint256 refund) = processPayment(_edition); // validates price

    for (; balance != 0; ) {
      unchecked {
        ++totalSupply;
        ++mintedEditions[_edition];
      }
      tokenId = generateTokenId(_account, msg.value, _edition);
      _mint(_account, tokenId);
      unchecked {
        --balance;
      }
    }

    if (refund != 0) {
      _account.call{value: refund}('');
    }
  }

  /**
   * @dev Prevent calls to processPayment without edition id parameter.
   */
  function processPayment() internal override returns (uint256, uint256) {
    revert INVALID_OPERATION();
  }

  /**
   * @notice Accepts Ether payment and forwards it to the appropriate jbx terminal during the mint phase.
   *
   * @dev This version of the NFT does not directly accept Ether and will fail to process mint payment if there is no payoutReceiver set.
   *
   * @dev In case of multi-mint where the amount passed to the transaction is greater than the cost of a single mint, it would be up to the caller of this function to refund the difference. Here we'll take only the required amount to mint the tokens we're allowed to.
   *
   * @param _edition Edition id being minted.
   */
  function processPayment(
    uint256 _edition
  ) internal virtual returns (uint256 balance, uint256 refund) {
    uint256 accountBalance = _balanceOf[msg.sender];
    if (accountBalance == mintAllowance) {
      revert ALLOWANCE_EXHAUSTED();
    }

    uint256 expectedPrice = editionPrices[_edition];
    if (address(priceResolver) != address(0)) {
      expectedPrice = priceResolver.getPrice(address(this), msg.sender, 0);
    }

    if (msg.value < expectedPrice) {
      revert INCORRECT_PAYMENT(expectedPrice);
    }

    if (msg.value == 0 || msg.value == expectedPrice) {
      balance = 1;
      refund = 0;
    } else if (msg.value > expectedPrice) {
      if (address(priceResolver) != address(0)) {
        // TODO: pending changes to INFTPriceResolver
        balance = 1;
        refund = msg.value - expectedPrice;
      } else {
        balance = msg.value / expectedPrice;

        if (totalSupply + balance > maxSupply) {
          // reduce to max supply
          balance -= totalSupply + balance - maxSupply;
        }

        if (mintedEditions[_edition] + balance > editions[_edition]) {
          balance -= mintedEditions[_edition] + balance - editions[_edition];
        }

        if (accountBalance + balance > mintAllowance) {
          // reduce to mint allowance; since we're here, final balance should be >= 1
          balance -= accountBalance + balance - mintAllowance;
        }

        refund = msg.value - (balance * expectedPrice);
      }
    }

    if (payoutReceiver != address(0)) {
      (bool success, ) = payoutReceiver.call{value: msg.value - refund}('');
      if (!success) {
        revert PAYMENT_FAILURE();
      }
    } else {
      revert PAYMENT_FAILURE();
    }
  }

  /**
   * @notice Returns a token id for the given parameters, edition is encoded in the bottom (right) 16 bits.
   *
   * @dev If randomizedMint is set token id will be based on account value, current price of eth for the amount provided (via Uniswap), current block number. Collisions are resolved via increment.
   *
   * @param _account Account which will recieve the token.
   * @param _amount Price being paid for this token, in wei.
   * @param _edition Edition index.
   */
  function generateTokenId(
    address _account,
    uint256 _amount,
    uint256 _edition
  ) internal virtual returns (uint256 tokenId) {
    if (!randomizedMint) {
      tokenId = _edition | (uint240(mintedEditions[_edition] + 1) << 16);
    } else {
      uint256 ethPrice;
      if (_amount != 0) {
        ethPrice = uniswapQuoter.quoteExactInputSingle(
          WETH9,
          DAI,
          3000, // fee
          _amount,
          0 // sqrtPriceLimitX96
        );
      }

      uint256 editionSupply = editions[_edition] + 1; // +1 because we consider 0 to be an invalid token id
      uint256 tokenIdRoot = uint256(keccak256(abi.encodePacked(_account, block.number, ethPrice))) %
        editionSupply;

      tokenId = _edition | (uint240(tokenIdRoot) << 16);

      // resolve token id collisions
      while (tokenId == 0 || _ownerOf[tokenId] != address(0)) {
        tokenId = _edition | (uint240(++tokenIdRoot % editionSupply) << 16);
      }
    }
  }

  modifier supplyAvailable(uint256 _edition) {
    uint256 l = editions.length;
    if (l == 0) {
      revert INVALID_OPERATION();
    }

    if (_edition > l - 1) {
      revert INVALID_OPERATION();
    }

    if (totalSupply == maxSupply) {
      revert SUPPLY_EXHAUSTED();
    }

    if (mintedEditions[_edition] == editions[_edition]) {
      revert SUPPLY_EXHAUSTED();
    }

    _;
  }
}