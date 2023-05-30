// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.0 < 0.9.0;
/*************************************************
⠀⠀⢀⣠⠤⠶⠖⠒⠒⠶⠦⠤⣄⠀⠀⠀⣀⡤⠤⠤⠤⠤⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⣴⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⣦⠞⠁⠀⠀⠀⠀⠀⠀⠉⠳⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⡾⠁⠀⠀⠀⠀⠀⠀⣀⣀⣀⣀⣀⣀⣘⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⣆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⢀⡴⠚⠉⠁⠀⠀⠀⠀⠈⠉⠙⠲⣄⣤⠤⠶⠒⠒⠲⠦⢤⣜⣧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠳⡄⠀⠀⠀⠀⠀⠀⠀⠉⠳⢄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⠹⣆⠀⠀⠀⠀⠀⠀⣀⣀⣀⣹⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⣠⠞⣉⣡⠤⠴⠿⠗⠳⠶⣬⣙⠓⢦⡈⠙⢿⡀⠀⠀⢀⣼⣿⣿⣿⣿⣿⡿⣷⣤⡀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⣾⣡⠞⣁⣀⣀⣀⣠⣤⣤⣤⣄⣭⣷⣦⣽⣦⡀⢻⡄⠰⢟⣥⣾⣿⣏⣉⡙⠓⢦⣻⠃⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠉⠉⠙⠻⢤⣄⣼⣿⣽⣿⠟⠻⣿⠄⠀⠀⢻⡝⢿⡇⣠⣿⣿⣻⣿⠿⣿⡉⠓⠮⣿⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠙⢦⡈⠛⠿⣾⣿⣶⣾⡿⠀⠀⠀⢀⣳⣘⢻⣇⣿⣿⣽⣿⣶⣾⠃⣀⡴⣿⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠙⠲⠤⢄⣈⣉⣙⣓⣒⣒⣚⣉⣥⠟⠀⢯⣉⡉⠉⠉⠛⢉⣉⣡⡾⠁⠀⠀⠀⠀⠀⠀⠀
⠀⠀⣠⣤⡤⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢈⡿⠋⠀⠀⠀⠀⠈⠻⣍⠉⠀⠺⠿⠋⠙⣦⠀⠀⠀⠀⠀⠀⠀
⠀⣀⣥⣤⠴⠆⠀⠀⠀⠀⠀⠀⠀⣀⣠⠤⠖⠋⠀⠀⠀⠀⠀⠀⠀⠀⠈⠳⠀⠀⠀⠀⠀⢸⣧⠀⠀⠀⠀⠀⠀
⠸⢫⡟⠙⣛⠲⠤⣄⣀⣀⠀⠈⠋⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⠏⣨⠇⠀⠀⠀⠀⠀
⠀⠀⠻⢦⣈⠓⠶⠤⣄⣉⠉⠉⠛⠒⠲⠦⠤⠤⣤⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣠⠴⢋⡴⠋⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠉⠓⠦⣄⡀⠈⠙⠓⠒⠶⠶⠶⠶⠤⣤⣀⣀⣀⣀⣀⣉⣉⣉⣉⣉⣀⣠⠴⠋⣿⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠉⠓⠦⣄⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡼⠁⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠉⠙⠛⠒⠒⠒⠒⠒⠤⠤⠤⠒⠒⠒⠒⠒⠒⠚⢉⡇⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⠴⠚⠛⠳⣤⠞⠁⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣤⠚⠁⠀⠀⠀⠀⠘⠲⣄⡀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣴⠋⠙⢷⡋⢙⡇⢀⡴⢒⡿⢶⣄⡴⠀⠙⠳⣄⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢦⡀⠈⠛⢻⠛⢉⡴⣋⡴⠟⠁⠀⠀⠀⠀⠈⢧⡀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⡄⠀⠘⣶⢋⡞⠁⠀⠀⢀⡴⠂⠀⠀⠀⠀⠹⣄⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡇⠀⠀⠈⠻⢦⡀⠀⣰⠏⠀⠀⢀⡴⠃⢀⡄⠙⣆⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⡾⢷⡄⠀⠀⠀⠀⠉⠙⠯⠀⠀⡴⠋⠀⢠⠟⠀⠀⢹⡄
 ____    ____    ____    ____             ______  ____    _____   ____       
/\  _`\ /\  _`\ /\  _`\ /\  _`\   /'\_/`\/\__  _\/\  _`\ /\  __`\/\  _`\     
\ \ \L\ \ \ \L\_\ \ \L\ \ \ \L\_\/\      \/_/\ \/\ \ \L\_\ \ \/\ \ \,\L\_\   
 \ \ ,__/\ \  _\L\ \ ,__/\ \  _\L\ \ \__\ \ \ \ \ \ \ \L_L\ \ \ \ \/_\__ \   
  \ \ \/  \ \ \L\ \ \ \/  \ \ \L\ \ \ \_/\ \ \_\ \_\ \ \/, \ \ \_\ \/\ \L\ \ 
   \ \_\   \ \____/\ \_\   \ \____/\ \_\\ \_\/\_____\ \____/\ \_____\ `\____\
    \/_/    \/___/  \/_/    \/___/  \/_/ \/_/\/_____/\/___/  \/_____/\/_____/
**************************************************/
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import '@openzeppelin/contracts/utils/Strings.sol';

/**
  * @notice error declaration
*/
error decreaseNotAllowed(uint256 quantity, uint256 maxSupply);
error notEnoughFunds(uint256 payableValue, uint256 required);
error maxSupplyExceeded(uint256 quantity, uint256 maxSupply);
error notWhitelisted(address minter, bytes32 root);
error whitelistSupplyExceeded(uint256 quantity, uint256 maxWhitelistSupply);
error transferFailed(address from, address to, uint256 quantity);
error maxPerTxExceeded(uint256 quantity, uint256 maxPerTx);
error maxPerWalletExceeded(uint256 quantity, uint256 maxPerWallet);
error nonExistentToken(uint256 tokenId);
error mintNotStartedYet();
error notTokenOwner();
error noTokensFound(address sender);
error notEnoughPepesBurned(address sender, uint256 currentCount, uint256 requiredCount);
error burnIsDisabled();

contract Pepemigos is DefaultOperatorFilterer, ERC721AQueryable, Ownable, ReentrancyGuard {
  
  event BurnedSingle(address burner, uint256 tokenId, uint256 timestamp);
  event BurnedMultiple(address burner, uint256[] tokenIds, uint256 timestamp);
  event BtcAddressSet(address setter, string btcAddr, uint256 timestamp);

  using Strings for uint256;
  /**
    * @notice Token and sale related variables.
  */
  uint256 public maxSupply = 6969;
  uint256 public maxWhitelistSupply = 2000;
  uint256 public whitelistSupply;
  uint256 public publicPrice = 0.0036 ether;
  uint256 public whitelistPrice = 0 ether;

  bool public publicSaleActive = false;
  bool public whitelistSaleActive = false;

  bytes32 public merkleRoot;

  string public baseURI = "";
  string public hiddenURI = "ipfs://QmQ2XMRdxNDFZMUtChmp6oCDLfcU1tE4GioC1fbMMYoN5R/";
  string public uriSuffix = ".json";
  bool public revealed = false;
  bool public burnActive = true;

  uint256 public publicMaxPerTx = 3;
  uint256 public whitelistMaxPerTx = 1;
  uint256 public publicMaxPerWallet = 3;
  uint256 public whitelistMaxPerWallet = 1;
  uint256 public pepesForBTCRequired = 4;

  struct userToken {
    uint256 id;
    string uri;
  }

  struct HolderClaim {
    uint256 publicClaimed;
    uint256 whitelistClaimed;
  }

  struct holderBTC {
    uint256 recordedIndex;
    string BTCAddress;
  }

  struct burnEntry {
    address burner;
    uint256 count;
    string btcAddress;
  }

  struct btcEntry {
    address claimedBy;
    string btcAddress;
  }

  uint256 public burnerAddressCount;
  uint256 public btcAddressCount;
  mapping(address => holderBTC) public holderBTCAddress;
  mapping(uint256 => address) public btcClaimedIndex;

  mapping(address => HolderClaim) public holderClaimed;
  mapping(uint256 => address) public getBurnerAddress;

  /**
    * @notice Validates the minting process by ensuring that the buyer has enough funds, 
    *         the max supply is not exceeded, and the user's maximum per-transaction and 
    *         per-wallet limits are not exceeded.
    * @param maxPerTx     The maximum quantity of tokens that can be purchased in a single transaction.
    * @param maxPerWallet The maximum quantity of tokens that a user can hold.
    * @param quantity     The quantity of tokens being purchased.
    * @param price        The price of a single token.
    * @param userClaimed  The total quantity of tokens that the user has already claimed.
  */
  modifier validateMint(uint256 maxPerTx, uint256 maxPerWallet, uint256 quantity, uint256 price, uint256 userClaimed) {
    uint256 priceCalculated = price * quantity;
    uint256 userSupplyCalculated = totalSupply() + balanceOf(msg.sender) + quantity;
    uint256 userWalletCalculated = userClaimed + quantity;
    if (msg.value < priceCalculated) {
      revert notEnoughFunds(msg.value, priceCalculated);
    }
    if (userSupplyCalculated > maxSupply) {
      revert maxSupplyExceeded(userSupplyCalculated, maxSupply);
    }
    if (quantity > maxPerTx) {
      revert maxPerTxExceeded(quantity, maxPerTx);
    }
    if (userWalletCalculated > maxPerWallet) {
      revert maxPerWalletExceeded(userWalletCalculated, maxPerWallet);
    }
    _;
  }

  constructor() ERC721A("Pepemigos", "PPMGS") {
    /**
      @dev Team mint 69 tokens
    */
    mintOwner(msg.sender, 69);
  }


  /**
    * @notice Mint new tokens to the caller's address.
    * @param quantity The amount of tokens to mint.
  */
  function mintPublic(uint256 quantity)
    public
    payable
    validateMint(
      publicMaxPerTx, 
      publicMaxPerWallet, 
      quantity, 
      publicPrice, 
      holderClaimed[msg.sender].publicClaimed
    ) 
  {
    if (!publicSaleActive) {
      revert mintNotStartedYet();
    }
    _mint(msg.sender, quantity);
    unchecked {
      holderClaimed[msg.sender].publicClaimed += quantity;
    }
  }

  /**
    * @notice Mint new tokens to the caller's address, but only if they are whitelisted.
    * @param quantity The amount of tokens to mint.
    * @param proof The Merkle proof that verifies the caller's address is whitelisted.
  */
  function mintWhitelist(uint256 quantity, bytes32[] calldata proof)
    public
    payable
    validateMint(
      whitelistMaxPerTx, 
      whitelistMaxPerWallet, 
      quantity, 
      whitelistPrice, 
      holderClaimed[msg.sender].whitelistClaimed
    )
  {
    if (!whitelistSaleActive) {
      revert mintNotStartedYet();
    }
    uint256 whitelistCalculated = whitelistSupply + quantity;
    if (whitelistCalculated > maxWhitelistSupply) {
      revert whitelistSupplyExceeded(whitelistCalculated, maxWhitelistSupply);
    }
    (bool verify) = MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender)));
    if (!verify) {
      revert notWhitelisted(msg.sender, merkleRoot);
    }
    _mint(msg.sender, quantity);
    unchecked {
      whitelistSupply += quantity;
      holderClaimed[msg.sender].whitelistClaimed += quantity;
    }
  }

  /**
    * @notice Mint new tokens to the specified address, but only the contract owner can call this function.
    * @param to The address to mint the tokens to.
    * @param quantity The amount of tokens to mint.
  */
  function mintOwner(address to, uint256 quantity) public onlyOwner {
    _mint(to, quantity);
  }

  function burn(uint256 tokenId) public {
    if (!burnActive) {
      revert burnIsDisabled();
    }
    if (ownerOf(tokenId) != msg.sender) {
      revert notTokenOwner();
    }
    if (getBurnedCount(msg.sender) == 0) {
      burnerAddressCount++;
      getBurnerAddress[burnerAddressCount] = msg.sender;
    }

    _burn(tokenId, true);
    emit BurnedSingle(msg.sender, tokenId, block.timestamp);
  }

  function burnMultiple(uint256[] memory tokenIds) public {
    if (!burnActive) {
      revert burnIsDisabled();
    }
    if (getBurnedCount(msg.sender) == 0) {
      burnerAddressCount++;
      getBurnerAddress[burnerAddressCount] = msg.sender;
    }

    for (uint256 index = 0; index < tokenIds.length; index++) {
      if (ownerOf(tokenIds[index]) != msg.sender) {
        revert notTokenOwner();
      }
      _burn(tokenIds[index], true);
    }
    emit BurnedMultiple(msg.sender, tokenIds, block.timestamp);
  }

  function burnedSupply() public view returns (uint256) {
    return _totalBurned();
  }

  function getBurnedCount(address ownerAddress) public view returns (uint256) {
    return _numberBurned(ownerAddress);
  }

  function setBTCAddress(string memory btcAddr) public {
    uint256 count = getBurnedCount(msg.sender);
    if (count >= pepesForBTCRequired) {
      lockInAddress(msg.sender, btcAddr);
      emit BtcAddressSet(msg.sender, btcAddr, block.timestamp);
    } else {
      revert notEnoughPepesBurned(msg.sender, count, pepesForBTCRequired);
    }
  }

  function lockInAddress(address to, string memory addr) internal {
      if (holderBTCAddress[to].recordedIndex > 0) {
        btcClaimedIndex[holderBTCAddress[to].recordedIndex] = to;
        holderBTCAddress[to].BTCAddress = addr;
      } else {
        btcAddressCount++;
        btcClaimedIndex[btcAddressCount] = to;
        holderBTCAddress[to] = holderBTC({ recordedIndex: btcAddressCount, BTCAddress: addr });
      }
  }

  /**
    * @notice Returns the URI for a given token. This function is an override of the tokenURI function in ERC721A.
    * @param tokenId The token ID to retrieve the URI for.
    * @return string A string representing the URI for the given token.
  */
  function tokenURI(uint256 tokenId) public view override(IERC721A, ERC721A) returns (string memory) {
    if (!_exists(tokenId)) {
      revert nonExistentToken(tokenId);
    }

    return revealed ? bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), uriSuffix)) : '' : hiddenURI;
  }

  /**
    * @notice Gets an array of all the tokens and tokenURIs owned by a given address. Suitable for off chain calls.
    * @param ownerAddress The address of the owner to query
    * @return tokens An array of userToken structs representing each token owned by the given address
    * Each userToken struct contains the following fields:
    * id:   The unique identifier of the token
    * uri:  The URI for the token metadata
  */
  function getUserTokens(address ownerAddress) external view virtual returns (userToken[] memory) {
    unchecked {
      uint256 tokenIdsIdx;
      address currOwnershipAddr;
      uint256 tokenIdsLength = balanceOf(ownerAddress);
      userToken[] memory tokens = new userToken[](tokenIdsLength);
      TokenOwnership memory ownership;
      for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
        ownership = _ownershipAt(i);
        if (ownership.burned) {
          continue;
        }
        if (ownership.addr != address(0)) {
          currOwnershipAddr = ownership.addr;
        }
        if (currOwnershipAddr == ownerAddress) {
          tokens[tokenIdsIdx] = userToken({ id: i, uri: tokenURI(i) });
          tokenIdsIdx++;
        }
      }
      return tokens;
    }
  }

  function getBurners() external view virtual returns (burnEntry[] memory) {
    unchecked {
      uint256 burnAddrId;
      burnEntry[] memory burnBoard = new burnEntry[](burnerAddressCount);
      for (uint256 i = 1; i <= burnerAddressCount; ++i) {
        address burnerAddress = getBurnerAddress[i];
        burnBoard[burnAddrId] = burnEntry({ burner: burnerAddress, count: getBurnedCount(burnerAddress), btcAddress: holderBTCAddress[burnerAddress].BTCAddress });
        burnAddrId++;
      }
      return burnBoard;
    }
  }

  function getBTCAddresses() external view virtual returns (btcEntry[] memory) {
    unchecked {
      uint256 burnAddrId;
      btcEntry[] memory btcBoard = new btcEntry[](btcAddressCount);
      for (uint256 i = 1; i <= btcAddressCount; ++i) {
        address btcAddressOwner = btcClaimedIndex[i];
        btcBoard[burnAddrId] = btcEntry({ claimedBy: btcAddressOwner, btcAddress: holderBTCAddress[btcAddressOwner].BTCAddress });
        burnAddrId++;
      }
      return btcBoard;
    }
  }

  /**
    * @notice Set the maximum supply of tokens that can be minted.
    *         The function can only increase max supply.
    * @param supply The new maximum supply.
  */
  function setMaxSupply(uint256 supply) public onlyOwner {
    if (supply < maxSupply) {
      revert decreaseNotAllowed(supply, maxSupply);
    }
    maxSupply = supply;
  }

  /**
    * @notice Set the maximum supply of tokens that can be minted through the whitelist.
    * @param supply The new maximum whitelist supply.
  */
  function setMaxWhitelistSupply(uint256 supply) public onlyOwner {
    maxWhitelistSupply = supply;
  }

  /**
    * @notice Enable or disable the public sale of tokens.
    * @param status true to enable the public sale, false to disable it.
  */
  function setPublicSale(bool status) public onlyOwner {
    publicSaleActive = status;
  }

  /**
    * @notice Enable or disable the whitelist sale of tokens.
    * @param status true to enable the whitelist sale, false to disable it.
  */
  function setWhitelistSale(bool status) public onlyOwner {
    whitelistSaleActive = status;
  }

  function setBothSales(bool _whitelist, bool _public) public onlyOwner {
    whitelistSaleActive = _whitelist;
    publicSaleActive = _public;
  }

  /**
    * @notice Set the Merkle root used to verify if an address is whitelisted.
    * @param root The new Merkle root.
  */
  function setMerkleRoot(bytes32 root) public onlyOwner {
    merkleRoot = root;
  }

  /**
    * @notice Set whether or not the token's metadata has been revealed.
    * @param isRevealed True if the metadata has been revealed, false otherwise.
  */
  function setRevealed(bool isRevealed) public onlyOwner {
    revealed = isRevealed;
  }

  /**
    * @notice Set the base URI used to construct the token's URI.
    * @param uri The new base metadata URI. Should end with slash at the end ( e.g. ipfs://some_cid/ )
  */
  function setBaseURI(string memory uri) public onlyOwner {
    baseURI = uri;
  }

  /**
    * @notice Set the hidden URI used to point at unrevealed token's metadata json.
    * @param uri The new hidden metadata URI.
  */
  function setHiddenURI(string memory uri) public onlyOwner {
    hiddenURI = uri;
  }

  /**
    * @notice Set the suffix used to construct the token's URI.
    * @param suffix The new suffix.
  */
  function setURISuffix(string memory suffix) public onlyOwner {
    uriSuffix = suffix;
  }

  /**
    * @notice Sets the public price for the contract.
    * @param price The new public price to be set (in WEI format).
  */
  function setPublicPrice(uint256 price) public onlyOwner {
    publicPrice = price;
  }

  /**
    * @notice Sets the whitelist price for the contract.
    * @param price The new whitelist price to be set (in WEI format).
  */
  function setWhitelistPrice(uint256 price) public onlyOwner {
    whitelistPrice = price;
  }

  /**
    * @notice Sets the maximum number of tokens that can be minted per transaction for the public sale
    * @param maxPerTx The maximum number of tokens that can be minted per transaction for the public sale
  */
  function setPublicPerTx(uint256 maxPerTx) public onlyOwner {
    publicMaxPerTx = maxPerTx;
  }

  /**
    * @notice Sets the maximum number of tokens that can be minted per transaction for the whitelist sale
    * @param maxPerTx The maximum number of tokens that can be minted per transaction for the whitelist sale
  */
  function setWhitelistPerTx(uint256 maxPerTx) public onlyOwner {
    whitelistMaxPerTx = maxPerTx;
  }

  /**
    * @notice Sets the maximum number of tokens that can be minted per wallet for the public sale
    * @param maxPerWallet The maximum number of tokens that can be minted per wallet for the public sale
  */
  function setPublicPerWallet(uint256 maxPerWallet) public onlyOwner {
    publicMaxPerWallet = maxPerWallet;
  }

  /**
    * @notice Sets the maximum number of tokens that can be minted per wallet for the whitelist sale
    * @param maxPerWallet The maximum number of tokens that can be minted per wallet for the whitelist sale
  */
  function setWhitelistPerWallet(uint256 maxPerWallet) public onlyOwner {
    whitelistMaxPerWallet = maxPerWallet;
  }

  function setPepesRequiredForBTC(uint256 amount) public onlyOwner {
    pepesForBTCRequired = amount;
  }

  function setBurnState(bool state) public onlyOwner {
    burnActive = state;
  }

  function revealCollection(string memory _uri) public onlyOwner {
    baseURI = _uri;
    revealed = true;
  }

  /**
    * @notice Allows the contract owner to withdraw all the ether held in the contract.
    *         The function can only be called by the contract owner and is protected against reentrancy attacks.
  */
  function withdraw() public onlyOwner nonReentrant {
    address ownerAddress = owner();
    (bool transfer, ) = payable(ownerAddress).call{ value: address(this).balance }('');
    if (!transfer) {
      revert transferFailed(address(this), ownerAddress, address(this).balance);
    }
  }

  /**
    * @notice Returns the starting token ID for this contract, which is always 1.
    *         This function overrides the _startTokenId function in the ERC721A contract.
    * @return uint256 The starting token ID.
  */
  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  /**
    * @notice OpenSea enforced overrides for the ERC721A transfer and approval methods
    *         start
  */
  function setApprovalForAll(address operator, bool approved) public override(IERC721A, ERC721A) onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public payable override(IERC721A, ERC721A) onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }
  /**
    * @notice OpenSea enforced overrides for the ERC721A transfer and approval methods
    *         end
  */
}