// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./NeverGibUpFren.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";


/// @title Crowdsale for "NeverGibUpFren"
/// @notice No eth can be drained whether by stakers nor by the creatooor. No date or max. eth restricitions for finalizing.
contract NGUFCrowdsale {
  IUniswapV2Router02 private constant routooor =
    IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
  IUniswapV2Factory private constant factooory =
    IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

  address public creatooor;

  NeverGibUpFren public tokeen;
  address public pair;

  uint256 public start;
  uint256 public end;
  bool public finalized;

  struct Participant {
    uint256 at;
    uint256 stake;
  }

  mapping(address => Participant) private participants;
  address[] public participantAddresses;
  
  uint256 public staked;

  mapping(address => bool) public claimed;


  /// @notice Sets the creatooor and starts the crowdsale
  constructor() {
    creatooor = msg.sender;
    start = block.timestamp;
  }

  /// @notice Returns all stakes from the particicipants
  /// @return uint256 array of all stakes
  function allStakes() external view returns (uint256[] memory) {
    uint256[] memory all = new uint256[](participantAddresses.length);
    for (uint256 i = 0; i < participantAddresses.length; i++) {
      all[i] = participants[participantAddresses[i]].stake;
    }
    return all;
  }

  /// @notice Returns the participant entry of the caller
  /// @return Participant entry
  function stakeOf(address participant) external view returns (Participant memory) {
    return participants[participant];
  }

  /// @notice Increases the stake of the sender by the transaction value
  function increaseStake() external payable {
    require(!finalized, "crowdsale finished");
    require(msg.value >= 0.01 ether, "min. 0.01 eth");

    if (participants[msg.sender].at == 0) {
      // add participant with stake
      participantAddresses.push(msg.sender);
      participants[msg.sender] = Participant({ at: block.timestamp, stake: msg.value });
    } else {
      // increase participant's stake
      participants[msg.sender].stake += msg.value;
    }

    staked += msg.value;
  }

  /// @notice Finalizes the crowdsale, deploys the tokeen, and creates a uniwsap pair
  /// @notice Only callable by the creatooor 
  function finalizeCrowdsale() external {
    require(msg.sender == creatooor, "not the creatooor");
    require(!finalized, "crowdsale already finalized");

    // deploy the tokeen
    tokeen = new NeverGibUpFren();

    // a k for the sendooor
    tokeen.transfer(msg.sender, 1000 * 10 ** 18);

    // calculate tokeen amounts
    uint256 supply = (100000 - 2000) * 10 ** 18;
    uint256 crowdsalePortion = (10000) * 10 ** 18;
    uint256 liquidity = supply - crowdsalePortion;

    // approve router to spend liquidity
    tokeen.approve(address(routooor), liquidity);

    // create uniswap token pair, burn lp tokens
    routooor.addLiquidityETH{value: staked}(
      address(tokeen),
      liquidity,
      liquidity - 1,
      staked - 1,
      address(0),
      block.timestamp + 10 hours
    );

    pair = factooory.getPair(address(tokeen), routooor.WETH());

    // signal the tokeen that the pair creation is done
    tokeen.finishDeployment();

    // finish the crowdsale
    finalized = true;
    end = block.timestamp;
  }

  /// @notice Claims tokeens proportional to the senders eth stake
  function claimTokeens() external {
    require(finalized, "crowdsale not finalized");
    require(!claimed[msg.sender], "already claimed");

    Participant memory p = participants[msg.sender];

    require(p.stake > 0, "No tokeens claimable");
    require(
      block.timestamp >= ((end + 3 days) + (p.at - start)),
      "Not claimable yet"
    );

    uint256 percentage = (p.stake * 100000) / staked;
    uint256 claimable = ((10000 * 10 ** 18) / 100000) * percentage;

    claimed[msg.sender] = true;

    tokeen.transfer(msg.sender, claimable);
  }
}