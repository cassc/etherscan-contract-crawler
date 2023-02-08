// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ExchangeWrapperCore.sol";

contract ExchangeWrapper is ExchangeWrapperCore {
    function __ExchangeWrapper_init(
        address _exchangeV2,
        address _rarible,
        address _wyvern,
        address _seaport,
        address _x2y2,
        address _looksrare,
        address _sudoswap
    ) external initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ExchangeWrapper_init_unchained(
            _exchangeV2,
            _rarible,
            _wyvern,
            _seaport,
            _x2y2,
            _looksrare,
            _sudoswap
        );
    }
}