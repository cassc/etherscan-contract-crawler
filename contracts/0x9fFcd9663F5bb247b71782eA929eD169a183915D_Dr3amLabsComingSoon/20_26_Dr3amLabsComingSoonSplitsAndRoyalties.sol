// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import '@openzeppelin/contracts/token/common/ERC2981.sol';

contract Dr3amLabsComingSoonSplitsAndRoyalties is ERC2981 {
    address[] internal addresses = [
        0x7A9c785541Fe23c297c499fc902eB24739290E18
    ];

    uint256[] internal splits = [100];

    uint96 private constant DEFAULT_ROYALTY_BASIS_POINTS = 750;

    constructor() {
        // Default royalty information to be this contract, so that no potential
        // royalty payments are missed by marketplaces that support ERC2981.
        _setDefaultRoyalty(address(this), DEFAULT_ROYALTY_BASIS_POINTS);
    }
}