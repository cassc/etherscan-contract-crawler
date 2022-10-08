// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.17;

import "@gnosis.pm/zodiac/contracts/guard/BaseGuard.sol";
import "@gnosis.pm/zodiac/contracts/factory/FactoryFriendly.sol";

contract OwnerGuard is FactoryFriendly, BaseGuard {
    event SetAccountBricked(address account, bool bricked);
    event OwnerGuardSetup(address indexed initiator, address indexed owner);

    constructor(address _owner) {
      bytes memory initializeParams = abi.encode(_owner);
      setUp(initializeParams);
    }

    /// @dev Initialize function, will be triggered when a new proxy is deployed
    /// @param initializeParams Parameters of initialization encoded
    function setUp(bytes memory initializeParams) public override {
      __Ownable_init();
      address _owner = abi.decode(initializeParams, (address));
      transferOwnership(_owner);
      emit OwnerGuardSetup(msg.sender, _owner);
    }

    mapping(address => bool) public bricked;

    /// @dev Set whether or not calls can be made from an address.
    /// @notice Only callable by owner.
    /// @param account Address to be bricked.
    /// @param brick Bool to brick (true) or not to brick (false) the owner.
    function setAccountBricked(address account, bool brick) public onlyOwner {
      require(address(this) != account, "Cannot brick the guard account");
      require(owner() != account, "Cannot brick the owner acount");
      bricked[account] = brick;
      emit SetAccountBricked(account, bricked[account]);
    }

    /// @dev Returns bool to indicate if an address is bricked or not.
    /// @param account Address to check.
    function isAccountBricked(address account) public view returns (bool) {
      return (bricked[account]);
    }

    // solhint-disallow-next-line payable-fallback
    fallback() external {
      // We don't revert on fallback to avoid issues in case of a Safe upgrade
      // E.g. The expected check method might change and then the Safe would be locked.
    }

    function checkTransaction(
      address,
      uint256,
      bytes memory,
      Enum.Operation,
      uint256,
      uint256,
      uint256,
      address,
      // solhint-disallow-next-line no-unused-vars
      address payable,
      bytes memory,
      address sender
    ) external view override {
      require((bricked[sender] == false), "Account has been bricked, and cannot perform transactions");
    }

    function checkAfterExecution(bytes32, bool) external view override {}
}