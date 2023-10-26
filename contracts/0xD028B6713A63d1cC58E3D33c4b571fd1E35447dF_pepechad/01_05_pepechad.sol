pragma solidity ^0.8.21;

   import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

   contract pepechad is ERC20 {
       constructor() ERC20("PEPE CHAD COIN", "PEPE") {
           _mint(msg.sender, 1000000000000 * 10 ** decimals());
       }
   }