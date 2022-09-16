// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

import "../libraries/ValidatorLibrary.sol";

contract TestValidatorLibrary {
    using ValidatorLibrary for ValidatorLibrary.Sign;

    function verify(
        ValidatorLibrary.Sign calldata sign,
        bytes memory _data,
        uint _nonce
    ) external view returns (bool) {
        return sign.verify(_data, _nonce);
    }
}