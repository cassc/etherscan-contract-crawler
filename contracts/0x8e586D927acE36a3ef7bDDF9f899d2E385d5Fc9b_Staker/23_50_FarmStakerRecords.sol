// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./Token.sol";
import "./Staker.sol";

/**
  @title A basic smart contract for tracking the ownership of SuperFarm Stakers.
  @author Tim Clancy

  This is the governing registry of all SuperFarm Staker assets.
*/
contract FarmStakerRecords is Ownable, ReentrancyGuard {

  /// A struct used to specify token and pool strengths for adding a pool.
  struct PoolData {
    IERC20 poolToken;
    uint256 tokenStrength;
    uint256 pointStrength;
  }

  /// A version number for this record contract's interface.
  uint256 public version = 1;

  /// A mapping for an array of all Stakers deployed by a particular address.
  mapping (address => address[]) public farmRecords;

  /// An event for tracking the creation of a new Staker.
  event FarmCreated(address indexed farmAddress, address indexed creator);

  /**
    Create a Staker on behalf of the owner calling this function. The Staker
    supports immediate specification of the emission schedule and pool strength.

    @param _name The name of the Staker to create.
    @param _token The Token to reward stakers in the Staker with.
    @param _tokenSchedule An array of EmissionPoints defining the token schedule.
    @param _pointSchedule An array of EmissionPoints defining the point schedule.
    @param _initialPools An array of pools to initially add to the new Staker.
  */
  function createFarm(string calldata _name, IERC20 _token, Staker.EmissionPoint[] memory _tokenSchedule, Staker.EmissionPoint[] memory _pointSchedule, PoolData[] calldata _initialPools) nonReentrant external returns (Staker) {
    Staker newStaker = new Staker(_name, _token);

    // Establish the emissions schedule and add the token pools.
    newStaker.setEmissions(_tokenSchedule, _pointSchedule);
    for (uint256 i = 0; i < _initialPools.length; i++) {
      newStaker.addPool(_initialPools[i].poolToken, _initialPools[i].tokenStrength, _initialPools[i].pointStrength);
    }

    // Transfer ownership of the new Staker to the user then store a reference.
    newStaker.transferOwnership(msg.sender);
    address stakerAddress = address(newStaker);
    farmRecords[msg.sender].push(stakerAddress);
    emit FarmCreated(stakerAddress, msg.sender);
    return newStaker;
  }

  /**
    Allow a user to add an existing Staker contract to the registry.

    @param _farmAddress The address of the Staker contract to add for this user.
  */
  function addFarm(address _farmAddress) external {
    farmRecords[msg.sender].push(_farmAddress);
  }

  /**
    Get the number of entries in the Staker records mapping for the given user.

    @return The number of Stakers added for a given address.
  */
  function getFarmCount(address _user) external view returns (uint256) {
    return farmRecords[_user].length;
  }
}