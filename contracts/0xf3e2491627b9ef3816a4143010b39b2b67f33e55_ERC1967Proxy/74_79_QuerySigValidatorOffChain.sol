// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import "./QueryValidatorOffChain.sol";

contract QuerySigValidatorOffChain is QueryValidatorOffChain {
    string public constant CIRCUIT_ID = "credentialAtomicQuerySigV2";

    function getCircuitId() external view virtual override returns (string memory id) {
        return CIRCUIT_ID;
    }

    function _getInputValidationParameters(
        uint256[] calldata inputs_
    ) internal pure override returns (ValidationParams memory) {
        return
            ValidationParams(
                inputs_[4], // issuerID
                inputs_[2], // issuerClaimState
                inputs_[6], // issuerClaimNonRevState
                inputs_[5] == 1 // isRevocationChecked
            );
    }
}