// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./lib/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./PianoKingWhitelist.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./interfaces/IPianoKingRNConsumer.sol";

/**
 * @dev The contract of Piano King NFTs.
 */
contract PianoKing is ERC721, Ownable, IERC2981 {
  using Address for address payable;
  using Strings for uint256;

  uint256 private constant MAX_TOKEN_PER_ADDRESS = 25;
  // The amount in Wei (0.2 ETH by default) required to give to this contract
  // in order to premint an NFT for the 7000 tokens following the 1000 in presale
  uint256 public constant MIN_PRICE = 200000000000000000;
  // The royalties taken on each sale. Can range from 0 to 10000
  // 500 => 5%
  uint16 internal constant ROYALTIES = 500;
  // The current minted supply
  uint256 public totalSupply;
  // The base url for the metadata of each token
  string public baseURI =
    "ipfs://QmX1wiZB72EnXdTxQCeZhRxtmT9GkBuWpD7TtDrfAcSio4/";
  // The supply left before next batch mint
  // Start at 0 as there is no premint for presale
  uint256 public supplyLeft = 0;

  // Address => how many tokens this address will receive on the next batch mint
  mapping(address => uint256) public preMintAllowance;

  // Addresses that have paid to get a token in the next batch mint
  address[] public preMintAddresses;

  // The random number used as a seed for the random sequence for batch mint
  uint256 internal randomSeed;
  // The random number used as the base for the incrementor in the sequence
  uint256 internal randomIncrementor;
  // Indicate if the random number is ready to be used
  bool internal canUseRandomNumber;
  // Allow to keep track of iterations through multiple consecutives
  // transactions for batch mints
  uint16 internal lastBatchIndex;

  IPianoKingRNConsumer public pianoKingRNConsumer;
  PianoKingWhitelist public pianoKingWhitelist;
  // Address authorized to withdraw the funds
  address public pianoKingWallet = 0xA263f5e0A44Cb4e22AfB21E957dE825027A1e586;
  // Address where the royalties should be sent to
  address public pianoKingFunds;

  // Doesn't have to be defined straight away, can be defined later
  // at least before phase 2
  address public pianoKingDutchAuction;

  constructor(
    address _pianoKingWhitelistAddress,
    address _pianoKingRNConsumer,
    address _pianoKingFunds
  ) ERC721("Piano King NFT", "PK") {
    require(_pianoKingWhitelistAddress != address(0), "Invalid address");
    require(_pianoKingRNConsumer != address(0), "Invalid address");
    require(_pianoKingFunds != address(0), "Invalid address");
    pianoKingWhitelist = PianoKingWhitelist(_pianoKingWhitelistAddress);
    pianoKingRNConsumer = IPianoKingRNConsumer(_pianoKingRNConsumer);
    pianoKingFunds = _pianoKingFunds;
  }

  /**
   * @dev Let anyone premint a random token as long as they send at least
   * the min price required to do so
   * The actual minting will happen later in a batch to reduce the fees
   * of random number request to off-chain oracles
   */
  function preMint() external payable {
    // The sender must send at least the min price to mint
    // and acquire the NFT
    preMintFor(msg.sender);
  }

  /**
   * @dev Premint a token for a given address.
   * Meant to be used by the Dutch Auction contract or anyone wishing to
   * offer a token to someone else or simply paying the gas fee for that person
   */
  function preMintFor(address addr) public payable {
    require(addr != address(0), "Invalid address");
    // The presale mint has to be completed before this function can be called
    require(totalSupply >= 1000, "Presale mint not completed");
    bool isDutchAuction = totalSupply >= 8000;
    // After the first phase only the Piano King Dutch Auction contract
    // can mint
    if (isDutchAuction) {
      require(msg.sender == pianoKingDutchAuction, "Only through auction");
    }
    uint256 amountOfToken = isDutchAuction ? 1 : msg.value / MIN_PRICE;
    // If the result is 0 then not enough funds was sent
    require(amountOfToken > 0, "Not enough funds");

    // We check there is enough supply left
    require(supplyLeft >= amountOfToken, "Not enough tokens left");
    // Check that the amount desired by the sender is below or
    // equal to the maximum per address
    require(
      amountOfToken + preMintAllowance[addr] <= MAX_TOKEN_PER_ADDRESS,
      "Above maximum"
    );

    // Add the address to the list if it's not in there yet
    if (preMintAllowance[addr] == 0) {
      preMintAddresses.push(addr);
    }
    // Assign the number of token to the sender
    preMintAllowance[addr] += amountOfToken;

    // Remove the newly acquired tokens from the supply left before next batch mint
    supplyLeft -= amountOfToken;
  }

  /**
   * @dev Do a batch mint for the tokens after the first 1000 of presale
   * This function is meant to be called multiple times in row to loop
   * through consecutive ranges of the array to spread gas costs as doing it
   * in one single transaction may cost more than a block gas limit
   * @param count How many addresses to loop through
   */
  function batchMint(uint256 count) external onlyOwner {
    _batchMint(preMintAddresses, count);
  }

  /**
   * @dev Mint all the token pre-purchased during the presale
   * @param count How many addresses to loop through
   */
  function presaleMint(uint256 count) external onlyOwner {
    _batchMint(pianoKingWhitelist.getWhitelistedAddresses(), count);
  }

  /**
   * @dev Fetch the random numbers from RNConsumer contract
   */
  function fetchRandomNumbers() internal {
    // Will revert if the numbers are not ready
    (uint256 seed, uint256 incrementor) = pianoKingRNConsumer
      .getRandomNumbers();
    // By checking this we enforce the use of a different random number for
    // each batch mint
    // There is still the case in which two subsequent random number requests
    // return the same random number. However since it's a true random number
    // using the full range of a uint128 this has an extremely low chance of occuring.
    // And if it does we can still request another number.
    // We can't use the randomSeed for comparison as it changes during the batch mint
    require(incrementor != randomIncrementor, "Cannot use old random numbers");
    randomIncrementor = incrementor;
    randomSeed = seed;
    canUseRandomNumber = true;
  }

  /**
   * @dev Generic batch mint
   * We don't use neither the _mint nor the _safeMint function
   * to optimize the process as much as possible in terms of gas
   * @param addrs Addresses meant to receive tokens
   * @param count How many addresses to loop through in this call
   */
  function _batchMint(address[] memory addrs, uint256 count) internal {
    // To mint a batch all of its tokens need to have been preminted
    require(supplyLeft == 0, "Batch not yet sold out");
    if (!canUseRandomNumber) {
      // Will revert the transaction if the random numbers are not ready
      fetchRandomNumbers();
    }
    // Get the ending index from the start index and the number of
    // addresses to loop through
    uint256 end = lastBatchIndex + count;
    // Check that the end is not longer than the addrs array
    require(end <= addrs.length, "Out of bounds");
    // Get the bounds of the current phase/slot
    (uint256 lowerBound, uint256 upperBound) = getBounds();
    // Set the token id to the value of the random number variable
    // If it's the start, then it will be the random number returned
    // by Chainlink VRF. If not it will be the last token id generated
    // in the batch needed to continue the sequence
    uint256 tokenId = randomSeed;
    uint256 incrementor = randomIncrementor;
    for (uint256 i = lastBatchIndex; i < end; i++) {
      address addr = addrs[i];
      uint256 allowance = getAllowance(addr);
      for (uint256 j = 0; j < allowance; j++) {
        // Generate a number from the random number for the given
        // address and this given token to be minted
        tokenId = generateTokenId(tokenId, lowerBound, upperBound, incrementor);
        _owners[tokenId] = addr;
        emit Transfer(address(0), addr, tokenId);
      }
      // Update the balance of the address
      _balances[addr] += allowance;
      if (lowerBound >= 1000) {
        // We clear the mapping at this address as it's no longer needed
        delete preMintAllowance[addr];
      }
    }
    if (end == addrs.length) {
      // We've minted all the tokens of this batch, so this random number
      // cannot be used anymore
      canUseRandomNumber = false;
      if (lowerBound >= 1000) {
        // And we can clear the preMintAddresses array to free it for next batch
        // It's always nice to free unused storage anyway
        delete preMintAddresses;
      }
      // Add the supply at the end to minimize interactions with storage
      // It's not critical to know the actual current evolving supply
      // during the batch mint so we can do that here
      totalSupply += upperBound - lowerBound;
      // Get the bounds of the next range now that this batch mint is completed
      (lowerBound, upperBound) = getBounds();
      // Assign the supply available to premint for the next batch
      supplyLeft = upperBound - lowerBound;
      // Set the index back to 0 so that next batch mint can start at the beginning
      lastBatchIndex = 0;
    } else {
      // Save the token id in the random number variable to continue the sequence
      // on next call
      randomSeed = tokenId;
      // Save the index to set as start of next call
      lastBatchIndex = uint16(end);
    }
  }

  /**
   * @dev Get the allowance of an address depending of the current supply
   * @param addr Address to get the allowance of
   */
  function getAllowance(address addr) internal view virtual returns (uint256) {
    // If the supply is below a 1000 then we're getting the white list allowance
    // otherwise it's the premint allowance
    return
      totalSupply < 1000
        ? pianoKingWhitelist.getWhitelistAllowance(addr)
        : preMintAllowance[addr];
  }

  /**
   * @dev Generate a number from a random number for the tokenId that is guarranteed
   * not to repeat within one cycle (defined by the size of the modulo) if we call
   * this function many times in a row.
   * We use the properties of prime numbers to prevent collisions naturally without
   * manual checks that would be expensive since they would require writing the
   * storage or the memory.
   * @param randomNumber True random number which has been previously provided by oracles
   * or previous tokenId that was generated from it. Since we're generating a sequence
   * of numbers defined by recurrence we need the previous number as the base for the next.
   * @param lowerBound Lower bound of current batch
   * @param upperBound Upper bound of current batch
   * @param incrementor Random incrementor based on the random number provided by oracles
   */
  function generateTokenId(
    uint256 randomNumber,
    uint256 lowerBound,
    uint256 upperBound,
    uint256 incrementor
  ) internal pure returns (uint256 tokenId) {
    if (lowerBound < 8000) {
      // For the presale of 1000 tokens and the 7 batches of
      // 1000 after  that
      tokenId = getTokenIdInRange(
        randomNumber,
        1009,
        incrementor,
        lowerBound,
        upperBound
      );
    } else {
      // Dutch auction mints of 200 tokens
      tokenId = getTokenIdInRange(
        randomNumber,
        211,
        incrementor,
        lowerBound,
        upperBound
      );
    }
  }

  /**
   * @dev Get a token id in a given range
   * @param randomNumber True random number which has been previously provided by oracles
   * or previous tokenId that was generated from it. Since we're generating a sequence
   * of numbers defined by recurrence we need the previous number as the base for the next.
   * @param lowerBound Lower bound of current batch
   * @param upperBound Upper bound of current batch
   * @param incrementor Random incrementor based on the random number provided by oracles
   */
  function getTokenIdInRange(
    uint256 randomNumber,
    uint256 modulo,
    uint256 incrementor,
    uint256 lowerBound,
    uint256 upperBound
  ) internal pure returns (uint256 tokenId) {
    // Special case in which the incrementor would be equivalent to 0
    // so we need to add 1 to it.
    if (incrementor % modulo == modulo - 1 - (lowerBound % modulo)) {
      incrementor += 1;
    }
    tokenId = lowerBound + ((randomNumber + incrementor) % modulo) + 1;
    // Shouldn't trigger too many iterations
    while (tokenId > upperBound) {
      tokenId = lowerBound + ((tokenId + incrementor) % modulo) + 1;
    }
  }

  /**
   * @dev Get the bounds of the range to generate the ids in
   * @return lowerBound The starting position from which the tokenId will be randomly picked
   * @return upperBound The ending position until which the tokenId will be randomly picked
   */
  function getBounds()
    internal
    view
    returns (uint256 lowerBound, uint256 upperBound)
  {
    if (totalSupply < 8000) {
      // For 8 batch mints of 1000 tokens including the presale
      lowerBound = (totalSupply / 1000) * 1000;
      upperBound = lowerBound + 1000;
    } else if (totalSupply < 10000) {
      // To get the 200 tokens slots to be distributed by Dutch auctions
      lowerBound = 8000 + ((totalSupply - 8000) / 200) * 200;
      upperBound = lowerBound + 200;
    } else {
      // Set both at zero to mark that we reached the end of the max supply
      lowerBound = 0;
      upperBound = 0;
    }
  }

  /**
   * @dev Set the address of the Piano King Wallet
   */
  function setPianoKingWallet(address addr) external onlyOwner {
    require(addr != address(0), "Invalid address");
    pianoKingWallet = addr;
  }

  /**
   * @dev Set the address of the Piano King Whitelist
   */
  function setWhitelist(address addr) external onlyOwner {
    require(addr != address(0), "Invalid address");
    pianoKingWhitelist = PianoKingWhitelist(addr);
  }

  /**
   * @dev Set the address of the contract authorized to do Dutch Auction
   * of the tokens of this contract
   */
  function setDutchAuction(address addr) external onlyOwner {
    require(addr != address(0), "Invalid address");
    pianoKingDutchAuction = addr;
  }

  /**
   * @dev Set the address of the contract meant to hold the royalties
   */
  function setFundsContract(address addr) external onlyOwner {
    require(addr != address(0), "Invalid address");
    pianoKingFunds = addr;
  }

  /**
   * @dev Set the address of the contract meant to request the
   * random number
   */
  function setRNConsumerContract(address addr) external onlyOwner {
    require(addr != address(0), "Invalid address");
    pianoKingRNConsumer = IPianoKingRNConsumer(addr);
  }

  /**
   * @dev Set the base URI of every token URI
   */
  function setBaseURI(string memory uri) external onlyOwner {
    baseURI = uri;
  }

  /**
   * @dev Set addresses directly in the list as if they preminted for free
   * like for giveaway.
   */
  function setPreApprovedAddresses(
    address[] memory addrs,
    uint256[] memory amounts
  ) external onlyOwner {
    require(addrs.length <= 10, "Too many addresses");
    require(addrs.length == amounts.length, "Arrays length do not match");
    for (uint256 i = 0; i < addrs.length; i++) {
      address addr = addrs[i];
      require(addr != address(0), "Invalid address");
      uint256 amount = amounts[i];
      require(amount > 0, "Amount too low");
      require(
        amount + preMintAllowance[addr] <= MAX_TOKEN_PER_ADDRESS,
        "Above maximum"
      );
      if (preMintAllowance[addr] == 0) {
        preMintAddresses.push(addr);
      }
      preMintAllowance[addr] = amount;
    }
  }

  /**
   * @dev Retrieve the funds of the sale
   */
  function retrieveFunds() external {
    // Only the Piano King Wallet or the owner can withraw the funds
    require(
      msg.sender == pianoKingWallet || msg.sender == owner(),
      "Not allowed"
    );
    payable(pianoKingWallet).sendValue(address(this).balance);
  }

  // The following functions are overrides required by Solidity.

  /**
   * @dev Override of an OpenZeppelin hook called on before any token transfer
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override {
    // This will prevent anyone from burning a token if he or she tries
    // to send it to the zero address
    require(to != address(0), "Burning not allowed");
    super._beforeTokenTransfer(from, to, tokenId);
  }

  /**
   * @dev Get the URI for a given token
   */
  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    require(_exists(tokenId), "URI query for nonexistent token");
    // Concatenate the baseURI and the tokenId as the tokenId should
    // just be appended at the end to access the token metadata
    return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
  }

  // View and pure functions

  /**
   * @dev Get the address of the Piano King wallet
   */
  function getPianoKingWallet() external view returns (address) {
    return pianoKingWallet;
  }

  /**
   * @dev Get the addresses that preminted
   */
  function getPremintAddresses() external view returns (address[] memory) {
    return preMintAddresses;
  }

  /**
   * @dev Called with the sale price to determine how much royalty is owed and to whom.
   * @param tokenId - the NFT asset queried for royalty information
   * @param salePrice - the sale price of the NFT asset specified by `tokenId`
   * @return receiver - address of who should be sent the royalty payment
   * @return royaltyAmount - the royalty payment amount for `salePrice`
   */
  function royaltyInfo(uint256 tokenId, uint256 salePrice)
    external
    view
    override
    returns (address receiver, uint256 royaltyAmount)
  {
    // The funds should be sent to the funds contract
    receiver = pianoKingFunds;
    // We divide it by 10000 as the royalties can change from
    // 0 to 10000 representing percents with 2 decimals
    royaltyAmount = (salePrice * ROYALTIES) / 10000;
  }
}