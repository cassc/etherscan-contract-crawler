pragma solidity 0.8.18;
// SPDX-License-Identifier: AGPL-3.0
// Tomcat (interfaces/core/ITcMav.sol)

import { IOFT } from "@layerzerolabs/solidity-examples/contracts/token/oft/IOFT.sol";

/**
 * @title tcMAV - Tomcat Finance liquid veMAV
 * 
 * @notice tcMAV is a LayerZero Omnichain Fungible Token (OFT) and ERC20, a liquid/transferrable receipt token for
 * MAV that is staked into Tomcat Finance.
 */
interface ITcMav is IOFT {
    event MinterSet(address indexed account, bool canMint);

    error NotMinter();
    error InvalidAddress();

    /**
     * @notice A set of Tomcat addresses which are approved to mint/burn
     * the tcMAV token
     */
    function minters(address account) external view returns (bool canMint);

    /**
     * @notice Set whether an account can mint/burn this tcMAV token
     */
    function setMinter(address account, bool canMint) external;

    /**
     * @notice Creates `amount` of tcMAV tokens and assigns them to `account`, increasing
     * the total supply.
     */
    function mint(address recipient, uint256 amount) external;

    /**
     * @notice Destroys `amount` of tcMAV tokens from `account`, reducing the
     * total supply.
     */
    function burn(address from, uint256 amount) external;
}