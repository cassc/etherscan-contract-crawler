pragma solidity ^0.6.0;

import "ERC20.sol";

contract FOToken is ERC20 {
    constructor() public ERC20("FIBOS", "FO") {
        _mint(address(0x8cbd6dFDD2Cc917793746613A648c600AFB020b1), 1000000000000000);
        _setupDecimals(4);
    }
}