// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "@openzeppelin/contracts/token/common/ERC2981.sol";

abstract contract Royalties is ERC2981 {
    address beneficiary;
    uint96 bips;

    constructor(address _beneficiary, uint96 _bips) {
        if (_beneficiary != address(0x0))
            _setDefaultRoyalty(_beneficiary, _bips);
    }
}