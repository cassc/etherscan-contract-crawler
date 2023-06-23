//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PianoKingWhitelist is Ownable, ReentrancyGuard {
  using Address for address payable;

  // Address => amount of tokens allowed for white listed address
  mapping(address => uint256) private whiteListAmount;
  address[] private whiteListedAddresses;
  // Supply left to be distributed
  uint256 private supplyLeft = 1000;
  uint256 private constant MAX_TOKEN_PER_ADDRESS = 25;
  // In wei
  uint256 private constant PRICE_PER_TOKEN = 100000000000000000;
  // Address authorized to withdraw the funds
  address private pianoKingWallet = 0xA263f5e0A44Cb4e22AfB21E957dE825027A1e586;
  // Indicate if the sale is open
  bool private saleOpen = true;

  event AddressWhitelisted(
    address indexed addr,
    uint256 amountOfToken,
    uint256 fundsDeposited
  );

  /**
   * @dev White list an address for a given amount of tokens
   */
  function whiteListSender() external payable nonReentrant {
    // Check that the sale is still open
    require(saleOpen, "Sale not open");
    // We check the value is at least greater or equal to that of
    // one token
    require(msg.value >= PRICE_PER_TOKEN, "Not enough funds");
    // We get the amount of tokens according to the value passed
    // by the sender. Since Solidity only supports integer numbers
    // the division will be an integer whose value is floored
    // (i.e. 15.9 => 15 and not 16)
    uint256 amountOfToken = msg.value / PRICE_PER_TOKEN;
    // We check there is enough supply left
    require(supplyLeft >= amountOfToken, "Not enough tokens left");
    // Check that the amount desired by the sender is below or
    // equal to the maximum per address
    require(
      amountOfToken + whiteListAmount[msg.sender] <= MAX_TOKEN_PER_ADDRESS,
      "Above maximum"
    );
    // If the amount is set to zero then the sender
    // is not yet whitelisted so we add it to the list
    // of whitelisted addresses
    if (whiteListAmount[msg.sender] == 0) {
      whiteListedAddresses.push(msg.sender);
    }
    // Assign the number of token to the sender
    whiteListAmount[msg.sender] += amountOfToken;

    // Remove the assigned tokens from the supply left
    supplyLeft -= amountOfToken;

    // Some events for easy to access info
    emit AddressWhitelisted(msg.sender, amountOfToken, msg.value);
  }

  /**
   * @dev Set the address of the Piano King Wallet
   */
  function setPianoKingWallet(address addr) external onlyOwner {
    require(addr != address(0), "Invalid address");
    pianoKingWallet = addr;
  }

  /**
    @dev Set the status of the sale
    @param open Whether the sale is open
   */
  function setSaleStatus(bool open) external onlyOwner {
    saleOpen = open;
  }

  /**
   * @dev Get the supply left
   */
  function getSupplyLeft() external view returns (uint256) {
    return supplyLeft;
  }

  /**
   * @dev Get the amount of tokens the address has been whitelisted for
   * If the value is equal to 0 then the address is not whitelisted
   * @param adr The address to check
   */
  function getWhitelistAllowance(address adr) public view returns (uint256) {
    return whiteListAmount[adr];
  }

  /**
   * @dev Get the list of all whitelisted addresses
   */
  function getWhitelistedAddresses() public view returns (address[] memory) {
    return whiteListedAddresses;
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
}