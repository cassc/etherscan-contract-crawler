// SPDX-License-Identifier: MIT

pragma solidity =0.6.12;
import "./ERC20.sol";

contract KCT is ERC20 {
    using SafeMath for uint256;

    constructor () public ERC20("KazonCollective Token", "KCT") {
        _mint(_msgSender(), 1000000000000 * 10 ** 18);
    }
    
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }
}