// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import { Distributor } from "./abstract/Distributor.sol";
import { TrancheVesting } from "./abstract/TrancheVesting.sol";
import { MerkleSet } from "./abstract/MerkleSet.sol";
import { FlatPriceSale } from "../sale/v2/FlatPriceSale.sol";

contract TrancheVestingSale_2_0_Distributor is
  Distributor,
  TrancheVesting,
  ReentrancyGuard
{
  FlatPriceSale public immutable sale;
  uint256 public immutable price;
  uint8 public immutable decimals;

  modifier validSaleParticipant(address beneficiary) {
    require(sale.buyerTotal(beneficiary) != 0, "no purchases found");

    _;
  }

  constructor(
    FlatPriceSale _sale, // where the purchase occurred
    IERC20 _token, // the purchased token
    uint8 _decimals, // the number of decimals used by the purchased token
    // the price of the purchased token denominated in the sale's base currency with 8 decimals
    // e.g. if the sale was selling $FOO at $0.55 per token, price = 55000000
    uint256 _price, 
    Tranche[] memory tranches, // vesting tranches
    uint256 voteWeightBips, // the factor for voting power (e.g. 15000 means users have a 50% voting bonus for unclaimed tokens)
    string memory uri // information on the sale (e.g. merkle proofs)
  )
    TrancheVesting(tranches)
    // TODO: get the right quantity to the distributor constructor
    Distributor(_token, _sale.total() * 10 ** _decimals / _price, voteWeightBips, uri)
  {
    require(address(_sale) != address(0), "TVS_2_0_D: sale is address(0)");
    
    // previously deployed v2.0 sales did not implement the isOver() method
    (,,,,,,uint endTime,,) = _sale.config();
    require(endTime < block.timestamp, "TVS_2_0_D: sale not over yet");
    require(_price != 0, "TVS_2_0_D: price is 0");

    sale = _sale;
    decimals = _decimals;
    price = _price;
  }

  function NAME() external override virtual pure returns (string memory) {
    return 'TrancheVestingSale_2_0_Distributor';
  }
  
  // File specific version - starts at 1, increments on every solidity diff
  function VERSION() external override virtual pure returns (uint) {
    return 3;
  }

  function getPurchasedAmount(address buyer) public view returns (uint256) {
    /**
    Get the quantity purchased from the sale and convert it to native tokens
  
    Example: if a user buys $1.11 of a FOO token worth $0.50 each, the purchased amount will be 2.22 FOO
    - buyer total: 111000000 ($1.11 with 8 decimals)
    - decimals: 6 (the token being purchased has 6 decimals)
    - price: 50000000 ($0.50 with 8 decimals)

    Calculation: 111000000 * 1000000 / 50000000

    Returns purchased amount: 2220000 (2.22 with 6 decimals)
    */
    return sale.buyerTotal(buyer) * (10 ** decimals) / price;
  }

  function initializeDistributionRecord(
    address beneficiary // the address that will receive tokens
  ) validSaleParticipant(beneficiary) external {
    _initializeDistributionRecord(beneficiary, getPurchasedAmount(beneficiary));
  }

  function claim(
    address beneficiary // the address that will receive tokens
  ) external validSaleParticipant(beneficiary) nonReentrant {
    uint256 amount = getClaimableAmount(beneficiary);

    if (!records[beneficiary].initialized) {
      _initializeDistributionRecord(beneficiary, getPurchasedAmount(beneficiary));
    }

    super._executeClaim(beneficiary, amount);
  }

  function getDistributionRecord(address beneficiary) external override view returns (DistributionRecord memory) {
    DistributionRecord memory record = records[beneficiary];

  // workaround prior to initialization
    if (!record.initialized) {
      record.total = uint120(getPurchasedAmount(beneficiary));
    }
    return record;
  }

  // get the number of tokens currently claimable by a specific user
  function getClaimableAmount(address beneficiary) public override view returns (uint256) {
    if (records[beneficiary].initialized) return super.getClaimableAmount(beneficiary);

    // we can get the claimable amount prior to initialization
    return getPurchasedAmount(beneficiary) * _getVestedBips(beneficiary, block.timestamp) / 10000;
  }
}