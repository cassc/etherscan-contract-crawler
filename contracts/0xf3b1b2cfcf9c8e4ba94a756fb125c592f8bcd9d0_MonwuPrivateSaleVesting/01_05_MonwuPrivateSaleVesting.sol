// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./MonwuPrivateSaleWhitelist.sol";

interface MonwuTokenERC20 is IERC20 {
  function burn(uint256 amount) external;
  function decimals() external view returns(uint8);
}

contract MonwuPrivateSaleVesting is Ownable {

  struct PrivateInvestor {
    address investor; 
    uint256 allocation;
    uint256 released;
    uint256 start;
    uint256 cliffEnd;
    uint256 vestingEnd;
  }

  MonwuTokenERC20 public monwuToken;
  MonwuPrivateSaleWhitelist public monwuPrivateSaleWhitelist;

  uint256 public privateSaleAllocation;
  uint256 public privateSoldTokens;

  uint256 public burnDeadline;

  uint256 public constant cliffDuration = 52 weeks;
  uint256 public constant vestingDuration = 52 weeks;
  uint256 public constant releaseDuration = 91 days;
  uint8 public constant numberOfUnlocks = 5;

  mapping(address => PrivateInvestor) public addressToPrivateInvestor;


  event OwnerWithdrawEther(uint256 indexed amount);
  event InvestorPaidAllocation(address indexed investor, uint256 indexed startTimestamp);
  event InvestorReleaseTokens(address indexed investor, uint256 indexed amount);


  constructor(address monwuTokenAddress, address whitelistAddress) {
    monwuPrivateSaleWhitelist = MonwuPrivateSaleWhitelist(whitelistAddress);
    monwuToken = MonwuTokenERC20(monwuTokenAddress);

    privateSaleAllocation = 150_000_000 * (10 ** monwuToken.decimals());

    burnDeadline = block.timestamp + (52 weeks * 3);

    transferOwnership(0xB1E6B6A058CB64987D51f99ced8f1B08a8297E03);
  }


  // ====================================================================================
  //                                  OWNER INTERFACE
  // ====================================================================================

  function withdrawEther(uint256 amount) external onlyOwner {
    require(amount <= address(this).balance, "Not enough ether");

    (bool success,) = owner().call{ value: amount }("");
    require(success, "Transfer failed");

    emit OwnerWithdrawEther(amount);
  }

  function burnLeftovers() external onlyOwner onlyAfterBurnDeadline {
    uint256 tokenBalance = monwuToken.balanceOf(address(this));
    monwuToken.burn(tokenBalance);
  }
  // ====================================================================================



  // ====================================================================================
  //                               INVESTORS INTERFACE
  // ====================================================================================

  function buyPrivateSaleMonwu() external payable onlyWhitelisted {

    (address investor, uint256 allocation, uint256 amountToPay) = monwuPrivateSaleWhitelist.getWhitelistedAddressData(msg.sender);

    require(msg.value >= amountToPay, "Not enough ether");
    require(addressToPrivateInvestor[investor].investor == address(0), "Already added");
    require(privateSoldTokens + allocation <= privateSaleAllocation, "Private allocation exceeded");

    uint256 startCliff = block.timestamp;
    uint256 endCliff = startCliff + cliffDuration;
    uint256 endVesting = endCliff + vestingDuration;

    PrivateInvestor memory privateInvestor = PrivateInvestor(
      investor, 
      allocation, 
      0,
      startCliff,
      endCliff,
      endVesting
    );

    addressToPrivateInvestor[investor] = privateInvestor;
    privateSoldTokens += allocation;

    emit InvestorPaidAllocation(msg.sender, startCliff);
  }

  function investorRelease(uint256 amount) external onlyInvestor cantReleaseMoreThanAllocation(amount) {

    uint256 releasableAmount = computeReleasableAmount();
    require(releasableAmount >= amount, "Can't withdraw more than is released");

    addressToPrivateInvestor[msg.sender].released += amount;
    monwuToken.transfer(msg.sender, amount);

    emit InvestorReleaseTokens(msg.sender, amount);
  }
  // ====================================================================================



  // ====================================================================================
  //                                     HELPERS
  // ====================================================================================

  function computeReleasableAmount() internal view returns(uint256) {

    uint256 releasableAmount;
    uint256 totalReleasedTokens;

    PrivateInvestor memory privateInvestor = addressToPrivateInvestor[msg.sender];

    // if cliff duration didn't end yet, releasable amount is zero.
    if(block.timestamp < privateInvestor.cliffEnd) return 0;

    // if cliff and vesting ended, rest tokens are claimable
    if(block.timestamp >= privateInvestor.vestingEnd) return privateInvestor.allocation - privateInvestor.released;

    totalReleasedTokens = (((block.timestamp - privateInvestor.cliffEnd) / releaseDuration) + 1) * (privateInvestor.allocation / numberOfUnlocks);
    releasableAmount = totalReleasedTokens - privateInvestor.released;

    return releasableAmount;
  }
  // ====================================================================================



  // ====================================================================================
  //                                     MODIFIERS
  // ====================================================================================

  modifier onlyInvestor() {
    require(addressToPrivateInvestor[msg.sender].investor == msg.sender, "Not an investor");
    _;
  }

  modifier onlyWhitelisted() {
    (address investor, , ) = monwuPrivateSaleWhitelist.getWhitelistedAddressData(msg.sender);
    require(investor == msg.sender, "Address not whitelisted");
    _;
  }

  modifier onlyAfterBurnDeadline() {
    require(block.timestamp > burnDeadline, "Burning deadline not reached yet");
    _;
  }

  modifier cantReleaseMoreThanAllocation(uint256 amount) {
    require(addressToPrivateInvestor[msg.sender].released + amount <= addressToPrivateInvestor[msg.sender].allocation, "Release exceeds allocation");
    _;
  }
}