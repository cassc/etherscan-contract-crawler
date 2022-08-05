// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "GenericVault.sol";

contract AuraBalVault is GenericUnionVault {
    bool public isHarvestPermissioned = false;
    mapping(address => bool) public authorizedHarvesters;

    constructor(address _token) GenericUnionVault(_token) {}

    /// @notice Sets whether only whitelisted addresses can harvest
    /// @param _status Whether or not harvests are permissioned
    function setHarvestPermissions(bool _status) external onlyOwner {
        isHarvestPermissioned = _status;
    }

    /// @notice Adds or remove an address from the harvesters' whitelist
    /// @param _harvester address of the authorized harvester
    /// @param _authorized Whether to add or remove harvester
    function updateAuthorizedHarvesters(address _harvester, bool _authorized)
        external
        onlyOwner
    {
        authorizedHarvesters[_harvester] = _authorized;
    }

    /// @notice Claim rewards and swaps them to auraBAL for restaking
    /// @param _minAmountOut - min amount of BPT to receive for harvest
    /// @dev Can be called by anyone against an incentive in BPT
    /// @dev Harvest logic in the strategy contract
    /// @dev Harvest can be called even if permissioned when last staker is
    ///      withdrawing from the vault.
    function harvest(uint256 _minAmountOut) public {
        require(
            !isHarvestPermissioned ||
                authorizedHarvesters[msg.sender] ||
                totalSupply() == 0,
            "permissioned harvest"
        );
        uint256 _harvested = IStrategy(strategy).harvest(
            msg.sender,
            _minAmountOut
        );
        emit Harvest(msg.sender, _harvested);
    }

    /// @notice Claim rewards and swaps them to auraBAL for restaking
    /// @dev Can be called by anyone against an incentive in BPT
    /// @dev Harvest logic in the strategy contract
    /// @dev Harvest can be called even if permissioned when last staker is
    ///      withdrawing from the vault.
    function harvest() public override {
        harvest(0);
    }
}