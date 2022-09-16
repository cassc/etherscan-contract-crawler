// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

import "../PhutureIndex.sol";

contract IndexLogicV2Test is PhutureIndex {
    function mint(address _recipient) external {
        _mint(_recipient, 1);
    }

    function burn(address _recipient) external {
        _burn(_recipient, 1);
    }
}