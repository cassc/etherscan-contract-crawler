// Steady Stack Fantom: An AI LLM powered Fantom app and token
// Website: https://steadystackfantom.com
// Steady Stack Fantom is a product and token created by the Steady Stack Team.

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract Fantom is Context, ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("SteadyStackFantom.com", "FANTOM") {
        _mint(_msgSender(), 1_000_000_000 * (10 ** decimals()));
    }
}