/*
                                                                     ██████ ██████   ██████   ██████ ███████
                                                                    ██      ██   ██ ██    ██ ██      ██
                                                                    ██      ██████  ██    ██ ██      ███████
                                                                    ██      ██   ██ ██    ██ ██           ██
                                                                     ██████ ██   ██  ██████   ██████ ███████

                                                                          Utility token for StockCroc

                                                                             http://stockcroc.xyz

                                                                            [email protected]
*/

pragma solidity ^0.8.0;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";

/**
 * @dev Establishes an initial supply of 100M to be sent to a gnosis
 * safe for crowdsales IDO distribution.
 */
contract StockCrocCROC is ERC20 {
    constructor() ERC20("Croc", "CROC") {
        /// Total Supply of 100,000,000
        _mint(0x253b8b193AD7AEc38152A1f05112e4c6FAe2ae9A, 100000000 * 10 ** decimals());
    }
}