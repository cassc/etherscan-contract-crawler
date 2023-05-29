// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "../zone/tlds/Ape.sol";
import "./Inviteable.sol";

// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract ApeRegistrar is Inviteable {
  event DomainPurchased(string label, uint256 invite, uint8 generation);
  event DepositWithdrawn(uint256 amount, address to);

  using SafeMath for uint8;
  using SafeMath for uint256;

  AggregatorV3Interface internal priceFeed;
  ApeZone private _zoneContract;
  string public baseURI;
  string public contractURI;

  constructor(
    ApeZone zoneContract,
    string memory name,
    string memory symbol
  ) Inviteable(name, symbol, 3, 5, 256, 0) {
    _zoneContract = zoneContract;

    // ETH / USD (Chainlink)
    priceFeed = AggregatorV3Interface(
      0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
    );
  }

  function redeem(
    address to,
    uint256 invite,
    string memory label,
    bytes32 parent
  ) public payable {
    require(_isApprovedOrOwner(msg.sender, invite), "must own invite");
    require(!redeemed[invite], "invite must be open");
    require(
      generation[invite] <= getRedeemableGeneration(),
      "generation must be redeemable"
    );

    uint256 price = getPrice(label);

    require(msg.value >= price, "not enough ether");
    deposit(msg.value);

    if (msg.value > price) {
      // refund the difference
      (bool success, ) = payable(msg.sender).call{value: (msg.value - price)}(
        ""
      );
      require(success, "refund failed");
    }

    if (generation[invite] > 0) {
      // refund half the eth to owner of parent invite
      payable(ownerOf(parentInvite[invite])).transfer(price / 2);
    }

    // register zone
    _zoneContract.register(to, parent, label);

    // redeem invite & create child invites
    redeemInvite(invite);

    emit DomainPurchased(label, invite, generation[invite]);
  }

  function withdraw(address payable to) public onlyOwner {
    uint256 balance = address(this).balance;
    to.transfer(address(this).balance);
    emit DepositWithdrawn(balance, to);
  }

  function deposit(uint256 amount) public payable {}

  function getBalance() public view returns (uint256) {
    return address(this).balance;
  }

  function getPrice(string memory label) public view returns (uint256 value) {
    uint256 letters = bytes(label).length;

    require(letters > 0, "must have label");

    (, int256 ethValue, , , ) = priceFeed.latestRoundData();

    uint256 half = 50;

    if (letters < 8) {
      half = half * (2**(8 - letters));
    }

    half *= 1e26;
    half = half / uint256(ethValue);

    value = half * 2;
  }

  function setBaseURI(string memory base) public onlyOwner {
    _setBaseURI(base);
  }

  function setContractURI(string memory uri) public onlyOwner {
    contractURI = uri;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function _setBaseURI(string memory base) internal virtual {
    baseURI = base;
  }
}