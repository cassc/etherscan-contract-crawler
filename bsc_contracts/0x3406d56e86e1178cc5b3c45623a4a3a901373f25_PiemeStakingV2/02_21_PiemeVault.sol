// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface IPiemeVault {
    function withdraw(address to, uint256 amount) external;

    event Withdrawn(address, uint256);
}

contract PiemeVault is Ownable, IPiemeVault {
    IERC20 public token;
    address public secondary_owner;

    constructor(address token_, address owner_) {
        token = IERC20(token_);
        secondary_owner = owner_;
    }

    /**
     * @dev Withdraws funds.
     *
     * @param to Transfer funds to address
     * @param amount Transfer amount
     * Emits a {Withdrawn} event.
     */
    function withdraw(address to, uint256 amount) public virtual override {
        require(
            _msgSender() == owner() || _msgSender() == secondary_owner,
            "!owner"
        );
        require(token.transfer(to, amount), "!transfer");
        emit Withdrawn(to, amount);
    }
}