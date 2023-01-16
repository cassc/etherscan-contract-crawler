// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {Authorizable} from "./lib/Authorizable.sol";
import {IUniswapV2Router02} from "./interfaces/IUniswapV2Router02.sol";
import {ICollection} from "./interfaces/ICollection.sol";

/*
 * @dev Contract that represents a collection of ERC721 tokens.
 * The collection is managed by admins, who can control various parameters
 * such as whether new tokens can be minted, maximum supply of tokens, and valid payment options.
 * Only the owner can withdraw funds (paid in QUINT tokens or stable coins) from minting sales.
 */
contract Collection is ICollection, ERC721, ERC721Enumerable, ERC721Burnable, Authorizable {
  using Address for address;
  using Strings for uint256;

  uint256 public nextId = 1;
  IUniswapV2Router02 private immutable uniswapV2Router;

  // Minting options
  IERC20 public immutable QUINT;
  IERC20 public immutable STABLE;

  // Minting restrictions
  bool public isMintingEnabled;
  bool public isMintingLimitEnabled;
  mapping(address => bool) public isExcludedFromMintingLimit;
  mapping(address => uint256) public mintedAmountPerAccount;
  uint256 public maxMintPerAccount;
  uint256 public maxSupply;

  // Minting price
  uint256 public price;

  // Metadata prefix
  string public baseURI;

  /**
   * @dev Modifier to check if minting is enabled and total supply does not exceed maximum supply.
   * @param amount -> The amount of tokens to mint.
   */
  modifier isValidMint(address account, uint256 amount) {
    require(isMintingEnabled, "Collection: Minting must be enabled");

    require(totalSupply() + amount <= maxSupply, "Collection: Total supply exceeds maximum supply");

    if (isMintingLimitEnabled) {
      uint256 minted = mintedAmountPerAccount[account];

      // Check if the account is excluded from minting limits,
      // This is relevant only if the minting limit is enabled.
      if (!isExcludedFromMintingLimit[account]) {
        require(
          minted + amount <= maxMintPerAccount,
          "Collection: Amount exceeds maximum mint per account"
        );
      }
    }
    _;
  }

  /**
   * @dev Modifier to check if the account calling the function is an EOA/wallet.
   * @param account -> The address of the account calling the function.
   */
  modifier isValidAccount(address account) {
    require(
      account == tx.origin && !account.isContract(),
      "Collection: Account must be a EOA/wallet"
    );
    _;
  }

  /**
   * @dev Modifier to check if the payment is in valid option.
   * @param token -> The address of the payment token.
   */
  modifier isValidPayment(address token) {
    require(
      token == address(QUINT) || token == address(STABLE),
      "Collection: Unrecognized payment option"
    );
    _;
  }

  /**
   * @dev Constructor for the Collection contract.
   * Initializes the contract with the name, symbol, maximum supply, mint price, and maximum mint per account.
   *
   * @param _name -> representing the name of the collection.
   * @param _symbol -> representing the symbol of the collection.
   * @param newBaseURI -> representing the metadata endpoint of the collection.
   * @param routerEndpoint -> representing the router for fetching price conversion.
   * @param newMaxSupply -> representing the maximum supply of tokens in the collection.
   * @param quint -> representing the quint token address as payment option for minting the collection.
   * @param stable -> representing the stable coin address as payment option for minting the collection.
   * @param newMintPrice -> representing the price at which new tokens can be minted.
   * @param newMaxMintPerAccount -> representing the maximum number of tokens that can be
   * minted by each account, if minting limits are enabled.
   */
  constructor(
    string memory _name,
    string memory _symbol,
    string memory newBaseURI,
    address routerEndpoint, // 0x10ED43C718714eb63d5aA57B78B54704E256024E testnet
    uint256 newMaxSupply,
    address quint,
    address stable,
    uint256 newMintPrice,
    uint256 newMaxMintPerAccount
  ) ERC721(_name, _symbol) {
    QUINT = IERC20(quint);
    STABLE = IERC20(stable);
    price = newMintPrice;
    maxSupply = newMaxSupply;
    maxMintPerAccount = newMaxMintPerAccount;
    baseURI = newBaseURI;
    uniswapV2Router = IUniswapV2Router02(routerEndpoint);
  }

  /**
   * @dev Set the minting state for the collection.
   * @param isEnabled -> representing the new minting state.
   * @return whether the minting state was set successfully.
   * -------------------------------------------------------------
   * @notice Only authorized users can set the minting state.
   */
  function setMintingState(bool isEnabled) external onlyAuthorized returns (bool) {
    require(isMintingEnabled != isEnabled, "Collection: Minting state not unique");

    isMintingEnabled = isEnabled;
    emit MintStateChanged(msg.sender, isEnabled);
    return true;
  }

  /**
   * @dev Set the minting limit state for the collection.
   * @param isEnabled -> representing the new minting limit state.
   * @return whether the minting limit state was set successfully.
   * -------------------------------------------------------------
   * @notice Only authorized users can set the minting limit state.
   */
  function setMintingLimitState(bool isEnabled) external onlyAuthorized returns (bool) {
    require(isMintingLimitEnabled != isEnabled, "Collection: Minting limit state not unique");

    isMintingLimitEnabled = isEnabled;
    emit MintLimitStateChanged(msg.sender, isEnabled);
    return true;
  }

  /**
   * @dev Set the maximum supply of tokens for the collection.
   * @param newMaxSupply -> representing the new maximum supply of tokens.
   * @return whether the maximum supply was set successfully.
   * -------------------------------------------------------------
   * @notice Only authorized users can set the maximum supply.
   */
  function setMaxSupply(uint256 newMaxSupply) external onlyAuthorized returns (bool) {
    require(maxSupply != newMaxSupply, "Collection: Max supply not unique");

    maxSupply = newMaxSupply;
    emit MaxSupplyChanged(msg.sender, newMaxSupply);
    return true;
  }

  /**
   * @dev Set the price per mint of the collection.
   * @param newPrice -> representing the new price per mint.
   * @return whether the price per mint was set successfully.
   * -------------------------------------------------------------
   * @notice Only authorized users can set the price per mint.
   */
  function setPrice(uint256 newPrice) external onlyAuthorized returns (bool) {
    require(price != newPrice, "Collection: Price not unique");

    price = newPrice;
    emit PriceChanged(msg.sender, newPrice);
    return true;
  }

  /**
   * @dev Set the maximum number of tokens that can be minted by each account.
   * @param newMaxMintPerAccount -> representing the new maximum number of tokens that can be minted by each account.
   * @return whether the maximum number of tokens that can be minted by each account was set successfully.
   * -------------------------------------------------------------
   * @notice Only authorized users can set the maximum number of tokens that can be minted by each account.
   */
  function setMaxMintPerAccount(uint256 newMaxMintPerAccount)
    external
    onlyAuthorized
    returns (bool)
  {
    require(
      maxMintPerAccount != newMaxMintPerAccount,
      "Collection: Max mint per account not unique"
    );

    maxMintPerAccount = newMaxMintPerAccount;
    emit MintLimitChanged(msg.sender, newMaxMintPerAccount);
    return true;
  }

  /**
   * @dev Set an account to be excluded from minting limits.
   * @param account -> representing the account that is excluded from minting limits.
   * @param isExcluded -> representing whether an account is excluded from minting limits.
   * @return whether the account was excluded successfully.
   * -------------------------------------------------------------
   * @notice Only authorized users can exclude accounts from minting limits.
   */
  function setAccountExcludedFromMintingLimit(address account, bool isExcluded)
    external
    onlyAuthorized
    returns (bool)
  {
    require(
      isExcludedFromMintingLimit[account] != isExcluded,
      "Collection: Excluded account state not unique"
    );

    isExcludedFromMintingLimit[account] = isExcluded;
    emit ExcludedFromMintingLimit(msg.sender, account, isExcluded);
    return true;
  }

  /**
   * @dev Set the base URI for the collection.
   * @param newBaseURI -> representing the new base URI for the collection.
   * @return whether the base URI was set successfully.
   * -------------------------------------------------------------
   * @notice Only authorized users can set the base URI.
   */
  function setBaseURI(string memory newBaseURI) external onlyAuthorized returns (bool) {
    baseURI = newBaseURI;
    emit BaseURIChanged(msg.sender, newBaseURI);
    return true;
  }

  /**
   * @dev Withdraw funds from the contract.
   * @param token -> representing the token to be withdrawn.
   * @param recipient -> the recipient to receive the withdrawn funds.
   * @return whether the funds were withdrawn successfully.
   * -------------------------------------------------------------
   * @notice Only the owner can withdraw funds.
   */
  function withdrawFunds(address token, address recipient) external onlyOwner returns (bool) {
    uint256 balance = IERC20(token).balanceOf(address(this));
    IERC20(token).transfer(recipient, balance);
    emit FundsWithdrawn(msg.sender, recipient, balance);
    return true;
  }

  /**
   * @dev Airdrop tokens and sends them to a given recipient.
   * @param amount -> representing the number of tokens to be minted.
   * @param recipient -> representing the receiver of the minted token(s).
   * @return whether the airdrop was successful.
   */
  function airdrop(uint256 amount, address recipient) external onlyAuthorized returns (bool) {
    require(totalSupply() + amount <= maxSupply, "Collection: Total supply exceeds maximum supply");

    // Track/counter ids.
    uint256 index = nextId;
    nextId = index + amount;
    // Mint the purchased tokens.
    for (uint256 i; i < amount; i++) {
      _mint(recipient, index + i);
    }

    emit Airdropped(msg.sender, recipient, amount);
    return true;
  }

  /**
   * @dev Mint new tokens for the collection,
   * @param token -> representing the token payment option.
   * @param amount -> representing the number of tokens to be minted.
   * @return whether the minting was successful.
   * -------------------------------------------------------------
   * @notice (i) The minting must be enabled.
   *        (ii) The sender must be an externally owned account.
   *       (iii) The payment option must be valid.
   *
   * If minting limits are enabled:
   *           The amount of tokens minted by the account must not exceed the maximum mint per account.
   *           The total supply of tokens must not exceed the maximum supply.
   *
   * @notice Minting is only supporting payments in QUINT and desired STABLE token.
   * The payment token must be approved and transferred to the contract before minting can take place.
   */
  function mint(address token, uint256 amount)
    external
    isValidMint(msg.sender, amount)
    isValidAccount(msg.sender)
    isValidPayment(token)
    returns (bool)
  {
    // Check the payment option and calculate the cost based on amount.
    // Process the payment, and store the funds in the contract.
    require(processPayment(msg.sender, token, amount), "Collection: Payment for mint failed");

    // Track/counter ids.
    uint256 index = nextId;
    nextId = index + amount;
    // Mint the purchased tokens.
    for (uint256 i; i < amount; i++) {
      _mint(msg.sender, index + i);
    }

    // Track minted amount per account,
    // for cases where the minting limit is enabled.
    mintedAmountPerAccount[msg.sender] += amount;
    return true;
  }

  /**
   * @dev Proxy to mint new tokens for the collection.
   * @param token -> representing the token payment option.
   * @param amount -> representing the number of tokens to be minted.
   * @param recipient -> representing the receiver of the minted token(s).
   * @return whether the minting was successful.
   * -------------------------------------------------------------
   * @notice (i) The minting must be enabled.
   *        (ii) The sender must be an externally owned account.
   *       (iii) The payment option must be valid.
   *
   * If minting limits are enabled:
   *           The amount of tokens minted by the account must not exceed the maximum mint per account.
   *           The total supply of tokens must not exceed the maximum supply.
   *
   * @notice Minting is only supporting payments in QUINT and desired STABLE token.
   * The payment token must be approved and transferred to the contract before minting can take place.
   */
  function mintProxy(
    address token,
    uint256 amount,
    address recipient
  )
    external
    isValidMint(recipient, amount)
    isValidAccount(msg.sender)
    isValidPayment(token)
    returns (bool)
  {
    // Check the payment option and calculate the cost based on amount.
    // Process the payment, and store the funds in the contract.
    require(processPayment(msg.sender, token, amount), "Collection: Payment for mint failed");

    // Track/counter ids.
    uint256 index = nextId;
    nextId = index + amount;
    // Mint the purchased tokens.
    for (uint256 i; i < amount; i++) {
      _mint(recipient, index + i);
    }

    // Track minted amount per account,
    // for cases where the minting limit is enabled.
    mintedAmountPerAccount[recipient] += amount;
    return true;
  }

  /**
   * @dev Get the amount of withdrawable funds from minting sales.
   * @return AvailableQuint -> the amount of withdrawable funds of the token type 'quint'.
   * @return availableStable -> the amount of withdrawable funds of the token type 'stable'.
   */
  function getWithdrawableFunds()
    external
    view
    returns (uint256 AvailableQuint, uint256 availableStable)
  {
    return (QUINT.balanceOf(address(this)), STABLE.balanceOf(address(this)));
  }

  /**
   * @dev Get the remaining supply of tokens in the collection.
   * @return the remaining supply of tokens in the collection.
   */
  function getRemainingSupply() external view returns (uint256) {
    return maxSupply - totalSupply();
  }

  /**
   * @dev Retrieves the price per mint for the QUINT token
   * based on the current price. The function uses pancakeswap router to
   * calculate the amount of QUINT tokens that can be received for a given
   * amount of tokens in the path.
   *
   * @return The price per mint when the payment option is QUINT.
   *
   */
  function getPricePerMintWithQUINT() public view returns (uint256) {
    // Define the path of tokens to convert through
    // - STABLE
    // - WBNB
    // - QUINT
    address[] memory path = new address[](3);
    path[0] = address(STABLE);
    path[1] = uniswapV2Router.WETH();
    path[2] = address(QUINT);

    // Get the amount of QUINT tokens that can be received from the input amount
    uint256[] memory amountOutMins = IUniswapV2Router02(uniswapV2Router).getAmountsOut(price, path);
    // Return the amount of QUINT tokens received
    return amountOutMins[path.length - 1];
  }

  /**
   * @dev Get the URI for a token in the collection.
   * @param tokenId -> representing the ID of the token for which the URI is to be retrieved.
   * @return the URI of the token.
   * -------------------------------------------------------------
   * @notice The token must exist in the collection.
   */
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
  }

  /**
   * @dev Check if the contract supports a given interface.
   * @param interfaceId -> representing the ID of the interface to be checked.
   * @return whether the contract supports the given interface.
   * -------------------------------------------------------------
   * @notice This function overrides the default implementation in ERC721 and ERC721Enumerable.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  /**
   * @dev Check internally logic before a token transfer takes place.
   * @param from -> the account transferring the token.
   * @param to -> the account receiving the token.
   * @param tokenId -> representing the ID of the token being transferred.
   * -------------------------------------------------------------
   * @notice This function overrides the default implementation in ERC721 and ERC721Enumerable.
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  /**
   * @dev Process payment internally for minting tokens.
   * @param account -> representing the account making the payment.
   * @param token -> representing the token being used for payment.
   * @param amount -> representing the number of tokens being minted.
   */
  function processPayment(
    address account,
    address token,
    uint256 amount
  ) private returns (bool) {
    if (token == address(QUINT)) {
      // Calculate the cost per mint in quint tokens based
      // On a constant value that is denominated in USD.
      uint256 cost = getPricePerMintWithQUINT() * amount;
      SafeERC20.safeTransferFrom(QUINT, account, address(this), cost);
    } else {
      // The cost per mint in stable tokens based
      // On a constant price denominated in USD.
      uint256 cost = price * amount;
      SafeERC20.safeTransferFrom(STABLE, account, address(this), cost);
    }
    return true;
  }
}