pragma solidity <0.6 >=0.4.24;

import "./IERC20.sol";

contract IMintableToken is IERC20 {
    function mint(address, uint) external returns (bool);
    function burn(uint) external returns (bool);

    event Minted(address indexed to, uint256 amount);
    event Burned(address indexed from, uint256 amount);
    event MinterAdded(address indexed minter);
    event MinterRemoved(address indexed minter);
}