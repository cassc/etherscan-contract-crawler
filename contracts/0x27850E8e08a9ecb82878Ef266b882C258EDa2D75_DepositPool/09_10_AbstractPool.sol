// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]

    maintainers:
    - [email protected]
    - [email protected]
    - [email protected]
    - [email protected]

    contributors:
    - [email protected]

**************************************/

// OpenZeppelin imports
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Local imports
import { IPool } from "../interfaces/IPool.sol";

/**************************************
    
    Pool abstract contract

**************************************/

abstract contract AbstractPool is IPool {
    using SafeERC20 for IERC20;

    // storage
    IERC20 public immutable erc20;
    address public immutable keeper;

    // modifiers
    modifier onlyKeeper() {

        // check if sender is keeper
        if (msg.sender != keeper) {

            // revert
            revert InvalidSender(msg.sender, keeper);

        }

        // enter function
        _;

    }

    /**************************************
    
        Constructor

     **************************************/

    constructor(address _erc20, address _keeper) {
        erc20 = IERC20(_erc20);
        keeper = _keeper;
    }

    /**************************************

        Pool balance

     **************************************/

    function poolInfo() external override view
    returns (uint256) {
        return erc20.balanceOf(address(this));
    }

    /**************************************

        Withdraw

     **************************************/

    function withdraw(address _receiver, uint256 _amount) public override
    onlyKeeper {
        erc20.safeTransfer(_receiver, _amount);
        emit Withdraw(_receiver, _amount);
    }

}