// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../misc/PlatformFeeDistributor.sol";

contract VeFeeGateway is Ownable {
  using SafeERC20 for IERC20;

  /// @notice Emitted when a new mapping is added.
  /// @param _token The address of reward token added.
  /// @param _distributor The address of distributor added.
  event AddDistributor(address _token, address _distributor);

  /// @notice Emitted when a new mapping is removed.
  /// @param _token The address of reward token removed.
  /// @param _distributor The address of distributor removed.
  event RemoveDistributor(address _token, address _distributor);

  /// @notice The address of PlatformFeeDistributor contract
  address public immutable platform;

  /// @notice Mapping from reward token address to ve fee distributor contract.
  mapping(address => address) public token2distributor;

  /// @notice Mapping from ve fee distributor contract to reward token address.
  mapping(address => address) public distributor2token;

  constructor(address _platform) {
    platform = _platform;
  }

  /// @notice Distribute platform rewards to ve fee distributors.
  /// @param _distributors The address list of ve fee distributors.
  function distribute(address[] memory _distributors) external {
    // claim rewards to this contract.
    if (platform != address(0)) {
      PlatformFeeDistributor(platform).claim();
    }

    for (uint256 i = 0; i < _distributors.length; i++) {
      address _token = distributor2token[_distributors[i]];
      require(_token != address(0), "invalid distributor");
      uint256 _balance = IERC20(_token).balanceOf(address(this));
      if (_balance > 0) {
        IERC20(_token).safeTransfer(_distributors[i], _balance);
      }
    }
  }

  /// @dev add a mapping to contract.
  /// @param _token The address of reward token to add.
  /// @param _distributor The address of distributor to add.
  function add(address _token, address _distributor) external onlyOwner {
    require(token2distributor[_token] == address(0), "token mapping exists");
    require(distributor2token[_distributor] == address(0), "distributor mapping exists");

    token2distributor[_token] = _distributor;
    distributor2token[_distributor] = _token;

    emit AddDistributor(_token, _distributor);
  }

  /// @dev remote a mapping from contract.
  /// @param _distributor The address of distributor to remove.
  function remove(address _distributor) external onlyOwner {
    address _token = distributor2token[_distributor];

    distributor2token[_distributor] = address(0);
    token2distributor[_token] = address(0);

    emit RemoveDistributor(_token, _distributor);
  }
}