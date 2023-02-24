// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ITaxable {
    error Taxable__TaxDisabled();
    error Taxable__AlreadyEnabled();
    error Taxable__InvalidArguments();

    event TaxEnabled(
        address indexed operator,
        uint256 indexed start,
        uint256 indexed stop
    );

    event TaxBeneficiarySet(
        address indexed operator,
        address indexed oldBeneficiary,
        address indexed newBeneficiary
    );

    function toggleTax() external;

    function setTaxBeneficiary(address taxBeneficiary_) external;

    function tax(
        address token_,
        uint256 amount_
    ) external view returns (uint256);

    function taxFraction(address token_) external pure returns (uint256);

    function percentageFraction() external pure returns (uint256);

    function isTaxEnabled() external view returns (bool);

    function taxEnabledDuration() external pure returns (uint256);
}