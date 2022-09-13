// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;
import { Owned } from "../../dependencies/solmate/Owned.sol";
import { Initializable } from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";

import { ITreasury } from "../../interfaces/ITreasury.sol";

import { Constants } from "../../libraries/Constants.sol";

/**
 * @title Treasury
 * @author CyberConnect
 * @notice This contract is used for treasury.
 */
contract Treasury is Initializable, Owned, ITreasury {
    /*//////////////////////////////////////////////////////////////
                                STATES
    //////////////////////////////////////////////////////////////*/

    address internal _treasuryAddress;
    uint16 internal _treasuryFee;
    mapping(address => bool) internal _allowedCurrencyList;

    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        address owner,
        address treasuryAddress,
        uint16 treasuryFee
    ) initializer {
        require(treasuryAddress != address(0), "ZERO_TREASURY_ADDRESS");
        require(owner != address(0), "ZERO_OWNER_ADDRESS");
        require(treasuryFee <= Constants._MAX_BPS, "INVALID_TREASURY_FEE");

        Owned.__Owned_Init(owner);
        _treasuryAddress = treasuryAddress;
        _treasuryFee = treasuryFee;
    }

    /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets the treasury address.
     *
     * @param treasuryAddress The treasury address to set.
     * @dev This function is only available to the owner.
     */
    function setTreasuryAddress(address treasuryAddress) external onlyOwner {
        require(treasuryAddress != address(0), "ZERO_ADDRESS");
        address preTreasuryAddress = _treasuryAddress;
        _treasuryAddress = treasuryAddress;
        emit SetTreasuryAddress(preTreasuryAddress, treasuryAddress);
    }

    /**
     * @notice Sets the treasury fee.
     *
     * @param treasuryFee The treasury fee to set.
     * @dev This function is only available to the owner.
     */
    function setTreasuryFee(uint16 treasuryFee) external onlyOwner {
        require(treasuryFee <= Constants._MAX_BPS, "INVALID_TREASURY_FEE");
        uint16 preTreasuryFee = _treasuryFee;
        _treasuryFee = treasuryFee;
        emit SetTreasuryFee(preTreasuryFee, treasuryFee);
    }

    /**
     * @notice Allows a currency that will be used in a transaction.
     *
     * @param currency The ERC20 token contract address.
     * @dev This function is only available to the owner.
     */
    function allowCurrency(address currency, bool allowed) external onlyOwner {
        bool preAllowed = _allowedCurrencyList[currency];
        _allowedCurrencyList[currency] = allowed;
        emit AllowCurrency(currency, preAllowed, allowed);
    }

    /*//////////////////////////////////////////////////////////////
                         EXTERNAL VIEW
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ITreasury
    function getTreasuryAddress() external view override returns (address) {
        return _treasuryAddress;
    }

    /// @inheritdoc ITreasury
    function getTreasuryFee() external view override returns (uint256) {
        return _treasuryFee;
    }

    /// @inheritdoc ITreasury
    function isCurrencyAllowed(address currency)
        external
        view
        override
        returns (bool)
    {
        return _allowedCurrencyList[currency];
    }
}