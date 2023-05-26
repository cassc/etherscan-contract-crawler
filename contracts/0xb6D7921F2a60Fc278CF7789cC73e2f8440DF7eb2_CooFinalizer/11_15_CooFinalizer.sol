// SPDX-License-Identifier: Alt-Research-License-1.0
// Copyright Alt Research Ltd. 2023. All rights reserved.
//
// You acknowledge and agree that Alt Research Ltd. ("Alt Research") (or Alt
// Research's licensors) own all legal rights, titles and interests in and to the
// work, software, application, source code, documentation and any other documents

pragma solidity =0.8.18;

import {Finalizer} from "./rollup/Finalizer.sol";
import {KeyValuePair} from "./rollup/Types.sol";

interface ICoo {
    function mintL2(address recipient, uint256 tokenId) external;
}

contract CooFinalizer is Finalizer {
    function executeFinalization(
        address target,
        uint64 nonce,
        bytes32[] calldata proof,
        bytes calldata data
    ) external override {
        _executeFinalization(target, nonce, proof, data);
        ICoo coo = ICoo(target);
        // Interactions
        KeyValuePair[] memory pairs = abi.decode(data, (KeyValuePair[]));
        for (uint256 i = 0; i < pairs.length; ) {
            uint256 tokenId = uint256(pairs[i].key);
            address to = abi.decode(pairs[i].value, (address));
            coo.mintL2(to, tokenId);
            unchecked {
                ++i;
            }
        }
    }
}