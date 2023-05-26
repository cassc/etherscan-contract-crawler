/**
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡠⠔⠒⠂⠀⠒⠢⢄⡀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠔⠁⠀⠀⠀⠀⠀⠀⠀⠀⠈⠢⡀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠎⠀⠀⠀⠀⠀⢀⣴⠢⠄⠀⠀⠀⠘⢆⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡌⡆⠀⠀⠀⠀⠀⠈⠀⣀⠀⠀⠀⠀⠀⠘⡄⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡇⢡⠀⠀⠀⠀⠀⠀⠊⠀⠇⠀⠀⠐⠒⢲⡇⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢡⠈⢆⠀⠀⠀⠀⠸⣿⢀⠆⠀⢀⠔⢲⢠⠃⠀⠀
⠀⠀⠀⠀⠀⠀⢀⠀⠀⢀⣀⣀⣀⠀⢣⠈⠢⡀⠀⠀⠈⠉⠋⠀⡆⣾⡠⡮⠃⠀⠀⠀
⠠⣀⠀⠀⠀⠐⢘⡁⠸⠁⠀⠀⠀⠉⠒⢧⠠⠱⡀⠀⢰⣇⠀⠀⠘⠈⡎⢀⡠⠄⢠⠀
⠀⠱⡙⢤⡀⠈⠁⠘⠄⢠⡂⠀⣤⠀⢄⠀⢣⠃⠃⠀⠰⠹⠷⠖⠂⢀⠏⠠⡀⡠⢇⠀
⠀⠀⠘⡄⠘⠲⠤⢀⣈⠁⠥⠚⠁⢣⠟⠀⡜⡠⠃⠐⠒⠒⠒⠒⠒⠁⢀⠔⠳⣑⣝⡆
⠀⠀⠀⠈⢦⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣂⡀⠤⠔⠊⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠑⢥⡂⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⡠⠔⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠈⠑⠂⠤⠤⠤⠤⠤⠀⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀

CasperShitbuster (CASPY)
 **/

pragma solidity ^0.8.18;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract CasperShitbuster is ERC20, Ownable {
    uint256 constant initialSupply = 1000000000 * (10**18);

    constructor() ERC20("CasperShitbuster", "CASPY") {
        _mint(msg.sender, initialSupply);
    }
}