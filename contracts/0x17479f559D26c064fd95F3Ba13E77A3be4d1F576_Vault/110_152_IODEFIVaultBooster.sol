// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

//  libraries
import { DataTypes } from "../../protocol/earn-protocol-configuration/contracts/libraries/types/DataTypes.sol";

/**
 * @title Interface for ODEFIVaultBooster Contract
 * @author Opty.fi inspired by Compound.finance
 * @notice Interface for managing the ODEFI rewards
 */
interface IODEFIVaultBooster {
    /**
     * @notice Claim all the ODEFI accrued by holder in all markets
     * @param _holder User's address to claim ODEFI
     * @return Total No. of ODEFI tokens accrued by holder in all markets
     */
    function claimODEFI(address _holder) external returns (uint256);

    /**
     * @notice Claim all the ODEFI accrued by holder in the specified markets
     * @param _holder User's address to claim ODEFI
     * @param _odefiVaults The list of ODEFI vaults to claim ODEFI
     * @return Total No. of ODEFI tokens accrued by holder in specified odefiVaults
     */
    function claimODEFI(address _holder, address[] memory _odefiVaults) external returns (uint256);

    /**
     * @notice Claim all ODEFI accrued by the holders
     * @param _holders The addresses to claim ODEFI for
     * @param _odefiVaults The list of vaults to claim ODEFI in
     * @return Total No. of ODEFI tokens accrued by holders in specified odefiVaults
     */
    function claimODEFI(address[] memory _holders, address[] memory _odefiVaults) external returns (uint256);

    /**
     * @notice Calculate additional accrued ODEFI for a contributor since last accrual
     * @dev Update user rewards acc. to user state and ODEFI vault index in the ODEFI vault
     * @param _odefiVault ODEFI Vault's address to update ODEFI reward token
     * @param _user User address to calculate contributor rewards
     */
    function updateUserRewards(address _odefiVault, address _user) external;

    /**
     * @notice Update the user's state in ODEFI vault contract
     * @dev Updates the last ODEFI vault index and timestamp
     * @param _odefiVault ODEFI Vault's address
     * @param _user User address to update his last ODEFI index and timestamp
     */
    function updateUserStateInVault(address _odefiVault, address _user) external;

    /**
     * @notice Set the ODEFI rate for a specific pool
     * @dev Set the ODEFI rate in ODEFI per second per vault token for a specific pool
     * @param _odefiVault ODEFI Vault's address
     * @return Returns a boolean whether the operation succeeded or not
     */
    function updateOdefiVaultRatePerSecondAndVaultToken(address _odefiVault) external returns (bool);

    /**
     * @notice Updates the vault's state
     * @dev Stores the last ODEFI vault rate as well as timestamp
     * @param _odefiVault ODEFI Vault's address
     * @return Returns the ODEFI vault index
     */
    function updateOdefiVaultIndex(address _odefiVault) external returns (uint224);

    /**
     * @notice Set the ODEFI rate for a specific pool
     * @dev Sets the rate in reward tokens per second
     * @param _odefiVault ODEFI Vault's address
     * @param _rate Rate to be set for ODEFI token
     * @return Returns a boolean whether opertaion succeeded or not
     */
    function setOdefiVaultRate(address _odefiVault, uint256 _rate) external returns (bool);

    /**
     * @notice Adding new ODEFI vault address
     * @param _odefiVault ODEFI Vault's address
     * @return Returns a boolean whether opertaion is succeeded or not
     */
    function addOdefiVault(address _odefiVault) external returns (bool);

    /**
     * @notice Enabling the ODEFI vault
     * @param _odefiVault ODEFI Vault's address
     * @param _enable ODEFI vault is enabled or not
     * @return Returns a boolean whether opertaion is succeeded or not
     */
    function setOdefiVault(address _odefiVault, bool _enable) external returns (bool);

    /**
     * @notice Claim all the ODEFI accrued by holder in all markets
     * @param _holder The address to claim ODEFI for
     * @return Returns the no. of claimable ODEFI tokens
     */
    function claimableODEFI(address _holder) external view returns (uint256);

    /**
     * @notice Claim all the ODEFI accrued by holder in the specified markets
     * @param _holder The address to claim ODEFI for
     * @param _odefiVaults The list of vaults to claim ODEFI in
     * @return Returns the no. of claimable ODEFI tokens
     */
    function claimableODEFI(address _holder, address[] memory _odefiVaults) external view returns (uint256);

    /**
     * @notice Get the index of the specified ODEFI vault
     * @param _odefiVault The list of vaults to claim ODEFI in
     * @return Returns the index of ODEFI vault
     */
    function currentOdefiVaultIndex(address _odefiVault) external view returns (uint256);

    /**
     * @notice Get the no. of ODEFI tokens balance in the Vault booster contract
     * @return Returns the no. of ODEFI tokens in the Vault booster contract
     */
    function balance() external view returns (uint256);

    /**
     * @notice Get the no. of seconds until the ODEFI distribution has ended
     * @dev Divides the ODEFI tokens balance by the sum of all the ODEFI rates per second in all the vaults
     * @return Returns the no. of seconds until ODEFI distribution has ended
     */
    function rewardDepletionSeconds() external view returns (uint256);

    /**
     * @notice Get the ODEFI token address
     * @return Returns the address of ODEFI token
     */
    function getOdefiAddress() external view returns (address);
}