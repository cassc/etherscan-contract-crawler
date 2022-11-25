// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "WitnetRequestMalleableBase.sol";

contract WitnetRequestRandomness is WitnetRequestMalleableBase {
    bytes internal constant _WITNET_RANDOMNESS_BYTECODE_TEMPLATE = hex"0a0f120508021a01801a0210022202100b";

    constructor() {
        initialize(bytes(""));
    }

    function initialize(bytes memory)
        public
        virtual override
    {
        super.initialize(_WITNET_RANDOMNESS_BYTECODE_TEMPLATE);
    }
}