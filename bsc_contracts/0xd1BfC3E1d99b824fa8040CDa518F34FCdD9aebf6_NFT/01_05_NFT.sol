pragma solidity >=0.6.0 <0.8.0;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

contract NFT is ERC20 {
    constructor(uint256 initialSupply) ERC20("nullfox", "NFT") {
        _mint(msg.sender, initialSupply);
    }
}