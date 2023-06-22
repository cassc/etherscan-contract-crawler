// SPDX-License-Identifier: MIT
pragma solidity >=0.8.16;

import "openzeppelin/access/IAccessControl.sol";

interface IManagedTokenTaxProvider is IAccessControl {
    function MANAGE_EXEMPTIONS_ROLE() external returns (bytes32);
    function MANAGE_TAX_ROLE() external returns (bytes32);

    function getTax(address from, address to, uint256 amount) external returns (uint256);
    function setTax(uint16 buyBips, uint16 sellBips) external;
    function freezeTax() external;

    function setMaxTxAmount(uint256 amount) external;
    function freezeMaxTxAmount() external;

    function addExemptions(address account) external;
    function removeExemptions(address account) external;

    function addDex(address account) external;
    function removeDex(address account) external;
}