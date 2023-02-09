// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./STOTokenDividendUpgradeable.sol";

/// @title STOTokenConfiscateUpgradeable Confiscate Methods for Confiscating STO Tokens in case of failure or lost of STO Token
/// @custom:security-contact [email protected]
abstract contract STOTokenConfiscateUpgradeable is STOTokenDividendUpgradeable {
    /// confiscation feature is enabled by default
    bool public confiscation;
    /// flag to disable forever confiscation feature
    bool public confiscationFeatureDisabled;

    /// @dev Event to signal that STO Tokens have been confiscated
    /// @param from  Array of addresses from where STO tokens are lost
    /// @param to Address where STO tokens are being sent
    /// @param amount Array of amounts of STO tokens to be confiscated
    event STOTokensConfiscated(
        address[] from, 
        address to, 
        uint[] amount 
    );

    /// @dev Event to signal that STO Tokens have been confiscated
    /// @param confiscation previews status of the STO Tokens confiscation
    /// @param status changed status of the STO Tokens confiscation 
    event STOTokenConfiscationStatusChanged(bool confiscation, bool status);

    /// @dev Event to signal that STO Token has Confiscation feature disabled
    event STOTokenConfiscationDisabled();

    /// @dev Init Confiscation Feature
    function __STOTokenConfiscate_init(
        address stoToken,
        address paymentToken,
        string memory name,
        string memory symbol
    ) internal onlyInitializing {
        confiscation = true;
        confiscationFeatureDisabled = confiscationFeatureDisabled
            ? true
            : false;
        __STOTokenDividend_init(stoToken, paymentToken, name, symbol);
    }

    /// @dev Method to confiscate STO Tokens in case of failure or lost of STO Token
    /// @dev This method is only available to the owner of the contract
    /// @param from Array of Addresses of where STO tokens are lost
    /// @param amount Array of Amounts of STO tokens to be confiscated
    /// @param to Address of where STO tokens to be sent
    function confiscate(
        address[] memory from,
        uint[] memory amount,
        address to
    ) external onlyOwner {
        if (confiscationFeatureDisabled || !confiscation)
            revert ConfiscationDisabled();
        for (uint256 i = 0; i < from.length; i++) {
            _transfer(from[i], to, amount[i]);
        }
        emit STOTokensConfiscated(from, to, amount);
    }

    /// @dev Method to enable/disable Confiscation Feature
    /// @dev This method is only available to the owner of the contract
    function changeConfiscation(bool status) external onlyOwner {
        if (confiscationFeatureDisabled) revert ConfiscationDisabled();
        confiscation = status;
        emit STOTokenConfiscationStatusChanged(confiscation, status);
    }

    /// @dev Method to disable Confiscation Feature forever
    /// @dev This method is only available to the owner of the contract
    function disableConfiscationFeature() external onlyOwner {
        confiscationFeatureDisabled = true;
        confiscation = false;
        emit STOTokenConfiscationDisabled();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}