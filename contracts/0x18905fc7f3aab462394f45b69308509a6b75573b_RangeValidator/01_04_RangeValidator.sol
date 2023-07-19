// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import "src/interfaces/validators/IBaseOfferValidator.sol";

contract RangeValidator is IBaseOfferValidator {
    error TokenIdOutOfRangeError(uint256 min, uint256 max);

    function validateOffer(
        IBaseLoan.LoanOffer calldata,
        uint256 _tokenId,
        bytes calldata _validatorData
    ) external pure {
        (uint256 min_value, uint256 max_value) = abi.decode(
            _validatorData,
            (uint256, uint256)
        );
        if (_tokenId < min_value || _tokenId > max_value) {
            revert TokenIdOutOfRangeError(min_value, max_value);
        }
    }
}