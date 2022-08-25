pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract CRYPTO is ERC20,Ownable {
    uint256 MAX = 100000000 * 1e18;

    constructor() public ERC20('New Crypto Space', 'CRYPTO'){
        _mint(msg.sender, MAX);
    }
}