// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../../market/liquidator/ILiquidator.sol";

abstract contract LiquidatorBase is OwnableUpgradeable, ILiquidator {
    /// @dev list of already approved liquidators.
    mapping(address => bool) public whitelistLiquidators;

    /// @dev list of all approved liquidator addresses. Stores the key for mapping approvedLiquidators
    address[] public whitelistedLiquidators;

    /// @dev mapping for storing the plaform Fee and unearned APY Fee at the time of payback or liquidation
    // add the value in the mapping like that
    // [TokenMarket][stableCoinAddress] += platformFee OR Unearned APY Fee
    mapping(address => mapping(address => uint256))
        public stableCoinWithdrawable;

    /// @dev mapping to add the collateral token amount when autosell off
    // remaining tokens will be added to the collateralsWithdrawable mapping
    // [TokenMarket][collateralToken] += exceedaltcoins;  // liquidated collateral on autsell off
    mapping(address => mapping(address => uint256))
        public collateralsWithdrawable;

    event NewLiquidatorApproved(
        address indexed _newLiquidator,
        bool _liquidatorAccess
    );
    event AutoSellONLiquidated(
        uint256 _loanId,
        TokenLoanData.LoanStatus loanStatus
    );
    event AutoSellOFFLiquidated(
        uint256 _loanId,
        TokenLoanData.LoanStatus loanStatus
    );
    event FullTokensLoanPaybacked(uint256, address, address, uint256, uint256);
    event PartialTokensLoanPaybacked(uint256, address, address, uint256);

    /**
    @dev function to check if address have liquidate role option
     */
    function isLiquidateAccess(address liquidator)
        external
        view
        override
        returns (bool)
    {
        return whitelistLiquidators[liquidator];
    }

    /**
     * @dev makes _newLiquidator an approved liquidator and emits the event
     * @param _newLiquidator Address of the new liquidator
     * @param _liquidatorAccess access variables for _newLiquidator
     */
    function _makeDefaultApproved(
        address _newLiquidator,
        bool _liquidatorAccess
    ) internal {
        whitelistLiquidators[_newLiquidator] = _liquidatorAccess;
        whitelistedLiquidators.push(_newLiquidator);
        emit NewLiquidatorApproved(_newLiquidator, _liquidatorAccess);
    }
}