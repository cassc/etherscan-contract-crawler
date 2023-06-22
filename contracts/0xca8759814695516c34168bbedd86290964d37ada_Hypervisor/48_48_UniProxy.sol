/// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma abicoder v2;

import "./interfaces/IHypervisor.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IClearing {

	function clearDeposit(
    uint256 deposit0,
    uint256 deposit1,
    address from,
    address to,
    address pos,
    uint256[4] memory minIn
  ) external view returns (bool cleared);

	function clearShares(
    address pos,
    uint256 shares
  ) external view returns (bool cleared);

  function getDepositAmount(
    address pos,
    address token,
    uint256 _deposit
  ) external view returns (uint256 amountStart, uint256 amountEnd);
}

/// @title UniProxy v1.2.3
/// @notice Proxy contract for hypervisor positions management
contract UniProxy is ReentrancyGuard {

	IClearing public clearance;
  address public owner;

  constructor(address _clearance) {
    owner = msg.sender;
		clearance = IClearing(_clearance);	
  }

  /// @notice Deposit into the given position
  /// @param deposit0 Amount of token0 to deposit
  /// @param deposit1 Amount of token1 to deposit
  /// @param to Address to receive liquidity tokens
  /// @param pos Hypervisor Address
  /// @param minIn min assets to expect in position during a direct deposit 
  /// @return shares Amount of liquidity tokens received
  function deposit(
    uint256 deposit0,
    uint256 deposit1,
    address to,
    address pos,
    uint256[4] memory minIn
  ) nonReentrant external returns (uint256 shares) {
    require(to != address(0), "to should be non-zero");
		require(clearance.clearDeposit(deposit0, deposit1, msg.sender, to, pos, minIn), "deposit not cleared");

		/// transfer assets from msg.sender and mint lp tokens to provided address 
		shares = IHypervisor(pos).deposit(deposit0, deposit1, to, msg.sender, minIn);
		require(clearance.clearShares(pos, shares), "shares not cleared");
  }

  /// @notice Get the amount of token to deposit for the given amount of pair token
  /// @param pos Hypervisor Address
  /// @param token Address of token to deposit
  /// @param _deposit Amount of token to deposit
  /// @return amountStart Minimum amounts of the pair token to deposit
  /// @return amountEnd Maximum amounts of the pair token to deposit
  function getDepositAmount(
    address pos,
    address token,
    uint256 _deposit
  ) public view returns (uint256 amountStart, uint256 amountEnd) {
		return clearance.getDepositAmount(pos, token, _deposit);
	}

	function transferClearance(address newClearance) external onlyOwner {
    require(newClearance != address(0), "newClearance should be non-zero");
		clearance = IClearing(newClearance);
	}

  function transferOwnership(address newOwner) external onlyOwner {
    require(newOwner != address(0), "newOwner should be non-zero");
    owner = newOwner;
  }

  modifier onlyOwner {
    require(msg.sender == owner, "only owner");
    _;
  }
}