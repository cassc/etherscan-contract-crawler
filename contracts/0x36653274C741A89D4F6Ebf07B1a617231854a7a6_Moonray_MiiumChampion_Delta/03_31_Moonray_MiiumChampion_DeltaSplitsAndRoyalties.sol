// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import '@openzeppelin/contracts/token/common/ERC2981.sol';

contract Moonray_MiiumChampion_DeltaSplitsAndRoyalties is ERC2981 {
    address[] internal addresses = [0x40966a835a9a8993BeD9aE541e2a3F00c7734c0D];

    uint256[] internal splits = [100];

    uint96 private constant DEFAULT_ROYALTY_BASIS_POINTS = 750;

    constructor() {
        // Default royalty information to be this contract, so that no potential
        // royalty payments are missed by marketplaces that support ERC2981.
        _setDefaultRoyalty(address(this), DEFAULT_ROYALTY_BASIS_POINTS);
    }
}