// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;
import "./ERC20.sol";

contract Cratos is ERC20 {
    using SafeMath for uint256;
    uint256 salt_begining = 0xDEADBEEF;
    constructor () public ERC20("Cratos", "CRTS") {
        _mint(_msgSender(), 10**12 * 10**18);
    }
    
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }
    uint256 salt_end = 0xCAFEBABE;
}