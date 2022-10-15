/*************************************************************************************
 * 
 * Autor & Owner: BotPlanet
 *
 * 446576656c6f7065723a20416e746f6e20506f6c656e79616b61 *****************************/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IVesting {

    struct BeneficiaryData {
        address account;
        uint256 periodAmount;
        uint256 lastTransferTimestamp;
        uint256 nextTransferTimestamp;
    }

    // Events

    event BeneficiaryAdded(address indexed account, uint256 periodAmount);
    event BeneficiaryUpdated(address indexed account, uint256 periodAmount);
    event BeneficiaryRemoved(address indexed account);
    event BeneficiaryRestartedTransfers(address indexed account);
    event ReleasedTokens(uint256 releasedTokens);    
    event OwnerChanged(address oldOwner, address newOwner);
    event StateChanged(bool isPausedContract);

    // Methods: General

    function GetTokensBalance() external view returns(uint256);
    function GetBNBBalance() external view returns(uint256);
    // Interrumpt any functions in the contract
    function Pause() external;
    // Allow paused functions in the contract
    function Unpause() external;
    // Check state of contract if is paused or not
    function IsPaused() external view returns(bool);

    // Methods: Owner

    function OwnerSet(address newOwner) external;
    function OwnerGet() external returns(address);

    // Methods: Beneficiary

    // Add Beneficiary with default first date
    function BeneficiaryAdd(address account_, uint256 periodAmount_) external;
    function BeneficiaryAddExtended(address account_, uint256 periodAmount_, uint256 nextTransferTimestamp) external;
    function BeneficiaryUpdate(address account_, uint256 periodAmount_, uint256 nextTransferTimestamp) external;
    function BeneficiaryRemove(address account_) external;
    function BeneficiaryRestartTransfers(address account_) external;
    function BeneficiaryGetInfo(address account_) external view returns(BeneficiaryData memory);

    // Methods: Distribution

    function ReleaseTokens() external;
}