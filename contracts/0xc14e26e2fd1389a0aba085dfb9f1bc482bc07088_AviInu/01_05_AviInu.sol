pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AviInu is ERC20 {
    constructor() ERC20("Avraham Inu", "AVI") {
        _mint(msg.sender, 198000000 ether);
        _mint(0xADBaB4F38Ff9DCD71886f43B148bcad4A3081fB9, 2000000 ether);
    }
}