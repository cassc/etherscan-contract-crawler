// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "../external/council/libraries/Authorizable.sol";

interface IVotingVaultView {
    function queryVotePowerView(address user, uint256 blockNumber) external view returns (uint256);
}

contract BalanceQuery is Authorizable, IVotingVaultView {
    // stores approved voting vaults
    IVotingVaultView[] public vaults;

    /**
     * @notice Constructs this contract and stores needed data. Sets the deployer as the owner
     *         and authorizes the _vaultManager to be able to add/remove vaults.
     *
     * @param _vaultManager         User authorized to add/remove vaults
     * @param votingVaults          An array of the vaults to query balances from
     */
    constructor(address _vaultManager, address[] memory votingVaults) {
        // create a new array of voting vaults
        vaults = new IVotingVaultView[](votingVaults.length);
        // populate array with each vault passed into constructor
        for (uint256 i = 0; i < votingVaults.length; i++) {
            vaults[i] = IVotingVaultView(votingVaults[i]);
        }

        // authorize the _vaultManager to be able to add/remove vaults
        _authorize(_vaultManager);
    }

    /**
     * @notice Queries and adds together the vault balances for specified user
     *
     * @param user                  The user to query balances for
     *
     * @return The                  Total voting power for the user
     */
    function balanceOf(address user) public view returns (uint256) {
        uint256 votingPower = 0;
        // query voting power from each vault and add to total
        for (uint256 i = 0; i < vaults.length; i++) {
            try vaults[i].queryVotePowerView(user, block.number - 1) returns (uint v) {
                votingPower = votingPower + v;
            } catch {}
        }
        // return that balance
        return votingPower;
    }

    /**
     * @notice Updates the storage variable for vaults to query
     *
     * @param _vaults               An array of the new vaults to store
     */
    function updateVaults(address[] memory _vaults) external onlyAuthorized {
        // reset our array in storage
        vaults = new IVotingVaultView[](_vaults.length);

        // populate with each vault passed into the method
        for (uint256 i = 0; i < _vaults.length; i++) {
            vaults[i] = IVotingVaultView(_vaults[i]);
        }
    }

    /**
     * @notice Attempts to load the voting power of a user
     *
     * @param user                   The address we want to load the voting power of
     * @param blockNumber            The block number we want the user's voting power at
     *
     * @return userVotingPower       The number of votes
     */
    function queryVotePowerView(
        address user,
        uint256 blockNumber
    ) external view override returns (uint256 userVotingPower) {
        // return that balance
        return userVotingPower;
    }
}