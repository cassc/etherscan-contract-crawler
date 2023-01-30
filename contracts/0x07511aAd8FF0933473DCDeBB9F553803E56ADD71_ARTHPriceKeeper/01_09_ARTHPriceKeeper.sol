// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { KeeperCompatibleInterface } from "./interfaces/KeeperCompatibleInterface.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IGMUOracle } from "./interfaces/IGMUOracle.sol";
import { IRegistry } from "./interfaces/IRegistry.sol";

/**
 * @dev This keeper contract rewards the caller with a certain amount of MAHA based on their
 * contribution to keeping the oracle up-to-date
 */
contract ARTHPriceKeeper is Ownable, KeeperCompatibleInterface {
  IGMUOracle public gmuOracle;
  IRegistry public registry;
  uint256 public mahaRewardPerEpoch;

  constructor(
    IGMUOracle _gmuOracle,
    IRegistry _registry,
    uint256 _mahaRewardPerEpoch,
    address _governance
  ) {
    gmuOracle = _gmuOracle;
    mahaRewardPerEpoch = _mahaRewardPerEpoch;
    registry = _registry;

    _transferOwnership(_governance);
  }

  function updateMahaReward(uint256 reward) external onlyOwner {
    mahaRewardPerEpoch = reward;
  }

  function nextUpkeepTime() external view returns (uint256) {
    return gmuOracle.nextEpochPoint();
  }

  function checkUpkeep(bytes calldata)
    external
    view
    override
    returns (bool, bytes memory)
  {
    return (gmuOracle.callable(), "");
  }

  function performUpkeep(bytes calldata performData) external override {
    gmuOracle.updatePrice();

    // if the keeper wants a maha reward, we provide it with one; usually
    // non-chainlink keepers would ask for a MAHA reward
    if (performData.length > 0) {
      uint256 flag = abi.decode(performData, (uint256));
      if (flag >= 1) {
        require(
          IERC20(registry.maha()).balanceOf(address(this)) >=
            mahaRewardPerEpoch,
          "not enough maha for rewards"
        );
        IERC20(registry.maha()).transfer(msg.sender, mahaRewardPerEpoch);
      }
    }

    emit PerformUpkeep(msg.sender, performData);
  }

  function refund(IERC20 token) external onlyOwner {
    token.transfer(msg.sender, token.balanceOf(address(this)));
  }
}