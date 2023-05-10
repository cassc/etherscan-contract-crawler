// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/utils/auth/ImmutableALCB.sol";
import "contracts/interfaces/IUtilityToken.sol";
import "contracts/utils/MagicEthTransfer.sol";

contract ReentrantLoopDistributionMock is MagicEthTransfer, ImmutableFactory, ImmutableALCB {
    uint256 internal _counter;

    constructor() ImmutableFactory(msg.sender) ImmutableALCB() {}

    receive() external payable {
        _internalLoop();
    }

    function depositEth(uint8 magic_) public payable checkMagic(magic_) {
        _internalLoop();
    }

    function _internalLoop() internal {
        _counter++;
        if (_counter <= 3) {
            IUtilityToken(_alcbAddress()).distribute();
        }
    }
}