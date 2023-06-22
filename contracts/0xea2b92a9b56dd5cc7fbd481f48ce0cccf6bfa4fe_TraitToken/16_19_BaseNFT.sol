// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/AccessControlEnumerable.sol';
import '@openzeppelin/contracts/interfaces/IERC2981.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

import '../interfaces/INFTPriceResolver.sol';
import '../interfaces/IOperatorFilter.sol';
import './ERC721FU.sol';

/**
 * @notice Uniswap IQuoter interface snippet taken from uniswap v3 periphery library.
 */
interface IQuoter {
  function quoteExactInputSingle(
    address tokenIn,
    address tokenOut,
    uint24 fee,
    uint256 amountIn,
    uint160 sqrtPriceLimitX96
  ) external returns (uint256 amountOut);
}

abstract contract BaseNFT is ERC721FU, AccessControlEnumerable, ReentrancyGuard {
  using Strings for uint256;

  bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
  bytes32 public constant REVEALER_ROLE = keccak256('REVEALER_ROLE');

  address public constant WETH9 = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
  address public constant DAI = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);

  /**
   * @notice NFT provenance hash reassignment prohibited.
   */
  error PROVENANCE_REASSIGNMENT();

  /**
   * @notice Base URI assignment along with the "revealed" flag can only be done once.
   */
  error ALREADY_REVEALED();

  /**
   * @notice User mint allowance exhausted.
   */
  error ALLOWANCE_EXHAUSTED();

  /**
   * @notice mint() function received an incorrect payment, expected payment returned as argument.
   */
  error INCORRECT_PAYMENT(uint256);

  /**
   * @notice Token supply exhausted, all tokens have been minted.
   */
  error SUPPLY_EXHAUSTED();

  /**
   * @notice Various payment failures caused by incorrect contract condiguration.
   */
  error PAYMENT_FAILURE();

  error MINT_NOT_STARTED();
  error MINT_CONCLUDED();

  error INVALID_TOKEN();

  error INVALID_RATE();

  error MINTING_PAUSED();

  error CALLER_BLOCKED();

  /**
   * @notice Prevents minting outside of the mint period if set. Can be set only to have a start or only and end date.
   */
  modifier onlyDuringMintPeriod() {
    uint256 start = mintPeriod >> 128;
    if (start != 0) {
      if (start > block.timestamp) {
        revert MINT_NOT_STARTED();
      }
    }

    uint256 end = uint128(mintPeriod);
    if (end != 0) {
      if (end < block.timestamp) {
        revert MINT_CONCLUDED();
      }
    }

    _;
  }
  /**
   * @notice Prevents minting by blocked addresses and contracts hashes.
   */
  modifier callerNotBlocked(address account) {
    if (address(operatorFilter) != address(0)) {
      if (!operatorFilter.mayTransfer(account)) {
        revert CALLER_BLOCKED();
      }
    }

    _;
  }

  IQuoter public constant uniswapQuoter = IQuoter(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6);

  uint256 public maxSupply;
  uint256 public unitPrice;
  uint256 public mintAllowance;
  uint256 public mintPeriod;
  uint256 public totalSupply;

  string public baseUri;
  string public contractUri;
  string public provenanceHash;

  /**
   * @notice Revealed flag.
   *
   * @dev changes the way tokenUri(uint256) works.
   */
  bool public isRevealed;

  /**
   * @notice Pause minting flag
   */
  bool public isPaused;

  /**
   * @notice If set, token ids will not be sequential, but instead based on minting account, current blockNumber, and optionally, price of eth.
   */
  bool public randomizedMint;

  /**
   * @notice Address that receives payments from mint operations.
   */
  address payable public payoutReceiver;

  /**
   * @notice Address that receives payments from secondary sales.
   */
  address payable public royaltyReceiver;

  /**
   * @notice Royalty rate expressed in bps.
   */
  uint256 public royaltyRate;

  INFTPriceResolver public priceResolver;
  IOperatorFilter public operatorFilter;

  //*********************************************************************//
  // ----------------------------- ERC721 ------------------------------ //
  //*********************************************************************//

  /**
   * @dev Override to apply callerNotBlocked modifier in case there is an OperatorFilter set
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _id
  ) public virtual override callerNotBlocked(msg.sender) {
    super.transferFrom(_from, _to, _id);
  }

  /**
   * @dev Override to apply callerNotBlocked modifier in case there is an OperatorFilter set
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _id
  ) public virtual override callerNotBlocked(msg.sender) {
    super.safeTransferFrom(_from, _to, _id);
  }

  /**
   * @dev Override to apply callerNotBlocked modifier in case there is an OperatorFilter set
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _id,
    bytes calldata _data
  ) public virtual override callerNotBlocked(msg.sender) {
    super.safeTransferFrom(_from, _to, _id, _data);
  }

  //*********************************************************************//
  // ------------------------- external views -------------------------- //
  //*********************************************************************//

  /**
   * @notice Get contract metadata to make OpenSea happy.
   */
  function contractURI() public view returns (string memory) {
    return contractUri;
  }

  /**
   * @dev If the token has been set as "revealed", returned uri will append the token id
   */
  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory uri) {
    if (_ownerOf[_tokenId] == address(0)) {
      uri = '';
    } else {
      uri = !isRevealed ? baseUri : string(abi.encodePacked(baseUri, _tokenId.toString()));
    }
  }

  /**
   * @notice EIP2981 implementation for royalty distribution.
   *
   * @param _tokenId Token id.
   * @param _salePrice NFT sale price to derive royalty amount from.
   */
  function royaltyInfo(
    uint256 _tokenId,
    uint256 _salePrice
  ) external view virtual returns (address receiver, uint256 royaltyAmount) {
    if (_salePrice == 0 || _ownerOf[_tokenId] != address(0)) {
      receiver = address(0);
      royaltyAmount = 0;
    } else {
      receiver = royaltyReceiver == address(0) ? address(this) : royaltyReceiver;
      royaltyAmount = (_salePrice * royaltyRate) / 10_000;
    }
  }

  /**
   * @dev rari-capital version of ERC721 reverts when owner is address(0), usually that means it's not minted, this is problematic for several workflows. This function simply returns an address.
   */
  function ownerOf(uint256 _tokenId) public view override returns (address owner) {
    owner = _ownerOf[_tokenId];
  }

  function mintPeriodStart() external view returns (uint256 start) {
    start = mintPeriod >> 128;
  }

  function mintPeriodEnd() external view returns (uint256 end) {
    end = uint256(uint128(mintPeriod));
  }

  function getMintPrice(address _minter) external view virtual returns (uint256 expectedPrice) {
    if (address(priceResolver) == address(0)) {
      return unitPrice + feeExtras(unitPrice);
    }

    expectedPrice = priceResolver.getPriceWithParams(address(this), _minter, totalSupply + 1, '');
    return expectedPrice + feeExtras(expectedPrice);
  }

  //*********************************************************************//
  // ---------------------- external transactions ---------------------- //
  //*********************************************************************//

  /**
   * @notice Mints a token to the calling account. Must be paid in Ether if price is non-zero.
   *
   * @dev Proceeds are forwarded to the default Juicebox terminal for the project id set in the constructor. Payment will fail if the terminal is not set in the jbx directory.
   */
  function mint()
    external
    payable
    virtual
    nonReentrant
    onlyDuringMintPeriod
    callerNotBlocked(msg.sender)
    returns (uint256 tokenId)
  {
    tokenId = mintActual(msg.sender);
  }

  /**
   * @notice Mints a token to the provided account rather than the caller. Must be paid in Ether if price is non-zero.
   *
   * @dev Proceeds are forwarded to the default Juicebox terminal for the project id set in the constructor. Payment will fail if the terminal is not set in the jbx directory.
   */
  function mint(
    address _account
  )
    external
    payable
    virtual
    nonReentrant
    onlyDuringMintPeriod
    callerNotBlocked(msg.sender)
    returns (uint256 tokenId)
  {
    tokenId = mintActual(_account);
  }

  /**
   * @notice Accepts Ether payment and forwards it to the appropriate jbx terminal during the mint phase.
   *
   * @dev This version of the NFT does not directly accept Ether and will fail to process mint payment if there is no payoutReceiver set.
   *
   * @dev In case of multi-mint where the amount passed to the transaction is greater than the cost of a single mint, it would be up to the caller of this function to refund the difference. Here we'll take only the required amount to mint the tokens we're allowed to.
   */
  function processPayment() internal virtual returns (uint256 balance, uint256 refund) {
    uint256 accountBalance = _balanceOf[msg.sender];
    if (accountBalance == mintAllowance) {
      revert ALLOWANCE_EXHAUSTED();
    }

    uint256 expectedPrice = unitPrice;
    if (address(priceResolver) != address(0)) {
      expectedPrice = priceResolver.getPrice(address(this), msg.sender, 0);
    }

    expectedPrice += feeExtras(expectedPrice);

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

        if (accountBalance + balance > mintAllowance) {
          // reduce to mint allowance; since we're here, final balance shouuld be >= 1
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

  //*********************************************************************//
  // --------------------- privileged transactions --------------------- //
  //*********************************************************************//

  /**
   * @notice Privileged operation callable by accounts with MINTER_ROLE permission to mint the next NFT id to the provided address.
   */
  function mintFor(
    address _account
  ) external virtual onlyRole(MINTER_ROLE) returns (uint256 tokenId) {
    if (totalSupply == maxSupply) {
      revert SUPPLY_EXHAUSTED();
    }

    unchecked {
      ++totalSupply;
    }
    tokenId = generateTokenId(_account, 0);
    _mint(_account, tokenId);
  }

  function setPause(bool pause) external onlyRole(DEFAULT_ADMIN_ROLE) {
    isPaused = pause;
  }

  function addMinter(address _account) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _grantRole(MINTER_ROLE, _account);
  }

  function removeMinter(address _account) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _revokeRole(MINTER_ROLE, _account);
  }

  function addRevealer(address _account) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _grantRole(REVEALER_ROLE, _account);
  }

  function removeRevealer(address _account) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _revokeRole(REVEALER_ROLE, _account);
  }

  /**
   * @notice Set provenance hash.
   *
   * @dev This operation can only be executed once.
   */
  function setProvenanceHash(string memory _provenanceHash) external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (bytes(provenanceHash).length != 0) {
      revert PROVENANCE_REASSIGNMENT();
    }
    provenanceHash = _provenanceHash;
  }

  /**
    @notice Metadata URI for token details in OpenSea format.
   */
  function setContractURI(string memory _contractUri) external onlyRole(DEFAULT_ADMIN_ROLE) {
    contractUri = _contractUri;
  }

  /**
   * @notice Allows adjustment of minting period.
   *
   * @param _mintPeriodStart New minting period start.
   * @param _mintPeriodEnd New minting period end.
   */
  function updateMintPeriod(
    uint256 _mintPeriodStart,
    uint256 _mintPeriodEnd
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    mintPeriod = (_mintPeriodStart << 128) | _mintPeriodEnd;
  }

  function updateUnitPrice(uint256 _unitPrice) external onlyRole(DEFAULT_ADMIN_ROLE) {
    unitPrice = _unitPrice;
  }

  function updatePriceResolver(
    INFTPriceResolver _priceResolver
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    priceResolver = _priceResolver;
  }

  function updateOperatorFilter(
    IOperatorFilter _operatorFilter
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    operatorFilter = _operatorFilter;
  }

  function setRandomizedMint(bool _randomizedMint) external onlyRole(DEFAULT_ADMIN_ROLE) {
    randomizedMint = _randomizedMint;
  }

  /**
   * @notice Set NFT metadata base URI.
   *
   * @dev URI must include the trailing slash.
   */
  function setBaseURI(string memory _baseUri, bool _reveal) external onlyRole(REVEALER_ROLE) {
    if (isRevealed && !_reveal) {
      revert ALREADY_REVEALED();
    }

    baseUri = _baseUri;
    isRevealed = _reveal;
  }

  /**
   * @notice Allows owner to transfer ERC20 balances.
   */
  function transferTokenBalance(
    IERC20 token,
    address to,
    uint256 amount
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    token.transfer(to, amount);
  }

  function setPayoutReceiver(
    address payable _payoutReceiver
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    payoutReceiver = _payoutReceiver;
  }

  /**
   * @notice Sets royalty info
   *
   * @param _royaltyReceiver Payable royalties receiver.
   * @param _royaltyRate Rate expressed in bps, can only be set once.
   */
  function setRoyalties(
    address _royaltyReceiver,
    uint16 _royaltyRate
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    royaltyReceiver = payable(_royaltyReceiver);

    if (_royaltyRate > 10_000) {
      revert INVALID_RATE();
    }

    if (royaltyRate == 0) {
      royaltyRate = _royaltyRate;
    }
  }

  /**
   * @notice Function to consolidate functionality for external mint calls.
   *
   * @dev External calls should be validated by modifiers like `onlyDuringMintPeriod` and `callerNotBlocked`.
   *
   * @param _account Address to assign the new token to.
   */
  function mintActual(address _account) internal virtual returns (uint256 tokenId) {
    if (totalSupply == maxSupply) {
      revert SUPPLY_EXHAUSTED();
    }

    if (isPaused) {
      revert MINTING_PAUSED();
    }

    (uint256 balance, uint256 refund) = processPayment();

    for (; balance != 0; ) {
      unchecked {
        ++totalSupply;
      }
      tokenId = generateTokenId(_account, msg.value); // NOTE: this call requires totalSupply to be incremented by 1
      _mint(_account, tokenId);
      unchecked {
        --balance;
      }
    }

    if (refund != 0) {
      _account.call{value: refund}('');
    }
  }

  function feeExtras(uint256) internal view virtual returns (uint256 fee) {
    fee = 0;
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(AccessControlEnumerable, ERC721FU) returns (bool) {
    return
      interfaceId == type(IERC2981).interfaceId || // 0x2a55205a
      AccessControlEnumerable.supportsInterface(interfaceId) ||
      ERC721FU.supportsInterface(interfaceId);
  }

  /**
   * @notice Generates a token id based on provided parameters. Id range is 1...(maxSupply + 1), 0 is considered invalid and never returned.
   *
   * @dev If randomizedMint is set token id will be based on account value, current price of eth for the amount provided (via Uniswap), current block number. Collisions are resolved via increment.
   */
  function generateTokenId(
    address _account,
    uint256 _amount
  ) internal virtual returns (uint256 tokenId) {
    if (!randomizedMint) {
      tokenId = totalSupply;
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

      tokenId =
        uint256(keccak256(abi.encodePacked(_account, block.number, ethPrice))) %
        (maxSupply + 1);

      // resolve token id collisions
      while (tokenId == 0 || _ownerOf[tokenId] != address(0)) {
        tokenId = ++tokenId % (maxSupply + 1);
      }
    }
  }
}