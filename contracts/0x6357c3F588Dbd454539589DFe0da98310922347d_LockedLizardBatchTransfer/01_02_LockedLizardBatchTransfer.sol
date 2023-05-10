// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "./interfaces/ILizardLounge.sol";

contract LockedLizardBatchTransfer {
    ILizardLounge public immutable LizardLounge;

    constructor(ILizardLounge lizardLoungeAddress) {
        LizardLounge = lizardLoungeAddress;
    }

    function batchTransferFrom(address _from, address _to, uint256[] calldata _tokenIds) external {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            LizardLounge.transferFrom(_from, _to, _tokenIds[i]);
        }
    }
}