// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./openzeppelin-contracts-4.7.3-ERC20.sol";
import "./openzeppelin-contracts-4.7.3-Ownable.sol";
import "./IBEP20.sol";

contract BEP20EtalonToken is ERC20, Ownable, IBEP20 {
    constructor() ERC20("Etalon", "ETAL") {
        _mint(msg.sender, 5000000 * 10 ** decimals());
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address) {
        return owner();
    }
}
