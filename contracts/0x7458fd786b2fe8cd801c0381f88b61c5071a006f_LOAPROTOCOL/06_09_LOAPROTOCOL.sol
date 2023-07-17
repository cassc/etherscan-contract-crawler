pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./ERC20Burnable.sol";
import "./TokenTimelock.sol";
/**
 * @title LOAPROTOCOL

 */
contract LOAPROTOCOL is ERC20, ERC20Detailed,ERC20Burnable {


    constructor () public ERC20Detailed("LOAPROTOCOL", "LOA", 18) {
        _mint(msg.sender, 2000000000 * (10 ** uint256(decimals())));
    }
}
