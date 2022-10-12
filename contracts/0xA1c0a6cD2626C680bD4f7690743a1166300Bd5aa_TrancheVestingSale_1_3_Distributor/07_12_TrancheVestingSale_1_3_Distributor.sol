// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import { Distributor } from "./abstract/Distributor.sol";
import { TrancheVesting } from "./abstract/TrancheVesting.sol";
import { MerkleSet } from "./abstract/MerkleSet.sol";
import { ISaleManager_v_1_3 } from "../sale/v1.3/ISaleManager.sol";

abstract contract IERC20WithDecimals is IERC20 {
  function decimals() public view virtual returns (uint8);
}

contract TrancheVestingSale_1_3_Distributor is
  Distributor,
  TrancheVesting,
  ReentrancyGuard
{
  ISaleManager_v_1_3 public immutable saleManager;
  bytes32 public immutable saleId;

  modifier validSaleParticipant(address beneficiary) {
    require(saleManager.getSpent(saleId, beneficiary) != 0, "no purchases found");

    _;
  }

  constructor(
    ISaleManager_v_1_3 _saleManager, // where the purchase occurred
    bytes32 _saleId, // the sale id
    IERC20 _token, // the purchased token to distribute
    Tranche[] memory tranches, // vesting tranches
    uint256 voteWeightBips, // the factor for voting power (e.g. 15000 means users have a 50% voting bonus for unclaimed tokens)
    string memory uri // information on the sale (e.g. merkle proofs)
  )
    TrancheVesting(tranches)
    // initialize the distributor with the total purchased quantity from the sale
    Distributor(_token, _saleManager.spentToBought(_saleId, _saleManager.getTotalSpent(_saleId)), voteWeightBips, uri)
  {
    require(address(_saleManager) != address(0), "TVS_1_3_D: sale is address(0)");
    require(_saleId != bytes32(0), "TVS_1_3_D: sale id is bytes(0)");

    // if the ERC20 token provides decimals, ensure they match 
    int decimals = tryDecimals(_token);
    require(decimals == -1 || decimals == int(_saleManager.getDecimals(_saleId)), "token decimals do not match sale");
    require(_saleManager.isOver(_saleId), "TVS_1_3_D: sale not over");

    saleManager = _saleManager;
    saleId = _saleId;
  }

  function NAME() external override virtual pure returns (string memory) {
    return 'TrancheVestingSale_1_3_Distributor';
  }
  
  // File specific version - starts at 1, increments on every solidity diff
  function VERSION() external override virtual pure returns (uint) {
    return 3;
  }

  function tryDecimals(IERC20 _token) internal view returns (int) {
      try IERC20WithDecimals(address(_token)).decimals() returns (uint8 decimals) {
        return int(uint(decimals));
      } catch {
        return -1;
      }
  }

  function getPurchasedAmount(address buyer) public view returns (uint256) {
    /**
    Get the purchased token quantity from the sale
  
    Example: if a user buys $1.11 of a FOO token worth $0.50 each, the purchased amount will be 2.22 FOO
    Returns purchased amount: 2220000 (2.22 with 6 decimals)
    */
    return saleManager.getBought(saleId, buyer);
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