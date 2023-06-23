// CRAT utility token
// Website: https://cryptorat.army
// Medium: https://medium.com/@CryptoRATnews
// By Igor Rekun, Andrey Kiselev and Dimitry Lesnevsky

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract CryptoRat is Context, ERC20, Ownable {
    constructor() ERC20("Cryptorat.army", "CRAT") {
        _mint(_msgSender(), 200_000_000_000 * (10 ** decimals()));
        renounceOwnership();
    }
}