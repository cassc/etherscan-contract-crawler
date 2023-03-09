// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "./IBEP20.sol";

interface IFundToken is IBEP20 {
    /**
     * @dev Set & Disable minter
     */
    function setMinter(address, bool) external;

    /**
     * @dev Mint token function
     */
    function mint(address, uint256) external;

    /**
     * @dev Burn token function
     */
    function burn(address, uint256) external;

    /**
     * @dev called once by the factory at time of deployment
     */
    function initialize(string memory name_, string memory symbol_) external;
}