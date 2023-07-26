pragma solidity 0.8.18;
// SPDX-License-Identifier: AGPL-3.0
// Tomcat (core/TcMav.sol)

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { OFT } from "@layerzerolabs/solidity-examples/contracts/token/oft/OFT.sol";
import { ITcMav } from "contracts/interfaces/core/ITcMav.sol";

/**
 * @title tcMAV - Tomcat Finance liquid veMAV
 * 
 * @notice tcMAV is a LayerZero Omnichain Fungible Token (OFT) and ERC20, a liquid/transferrable receipt token for
 * MAV that is staked into Tomcat Finance.
 */
contract TcMav is Ownable, OFT, ITcMav {
    /**
     * @notice A set of Tomcat addresses which are approved to mint/burn
     * the tcMAV token
     */
    mapping(address => bool) public override minters;

    constructor(address _layerZeroEndpoint)
        Ownable()
        OFT("Tomcat tcMAV", "tcMAV", _layerZeroEndpoint)
    // solhint-disable-next-line no-empty-blocks
    {}

    /**
     * @notice Set whether an account can mint/burn this tcMAV token
     */
    function setMinter(address account, bool canMint) external override onlyOwner {
        if (account == address(0)) revert InvalidAddress();
        minters[account] = canMint;
        emit MinterSet(account, canMint);
    }

    /**
     * @notice Creates `amount` of tcMAV tokens and assigns them to `account`, increasing
     * the total supply.
     */
    function mint(address recipient, uint256 amount) external override onlyMinters {
        _mint(recipient, amount);
    }

    /**
     * @notice Destroys `amount` of tcMAV tokens from `account`, reducing the
     * total supply.
     */
    function burn(address from, uint256 amount) external override onlyMinters {
        _burn(from, amount);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyMinters() {
        if (!minters[msg.sender]) revert NotMinter();
        _;
    }
}