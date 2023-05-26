// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.10;

import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";
import {Controlled} from "../utils/Controlled.sol";

/// @notice Nation3 ERC20 token.
/// @author Nation3 (https://github.com/nation3/app/blob/master/contracts/contracts/tokens/NATION.sol).
/// @dev Mintable by controller.
contract NATION is ERC20, Controlled {
    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() ERC20("Nation3", "NATION", 18) {}

    /*//////////////////////////////////////////////////////////////
                            CONTROLLER ACTIONS
    //////////////////////////////////////////////////////////////*/

    function mint(address to, uint256 amount) external onlyController {
        _mint(to, amount);
    }
}