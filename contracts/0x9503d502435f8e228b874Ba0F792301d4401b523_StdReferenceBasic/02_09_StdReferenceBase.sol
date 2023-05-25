// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

import {IStdReference} from "IStdReference.sol";

abstract contract StdReferenceBase is IStdReference {
    function getReferenceData(string memory _base, string memory _quote) public view virtual override returns (ReferenceData memory);

    function getReferenceDataBulk(string[] memory _bases, string[] memory _quotes) public view override returns (ReferenceData[] memory) {
        require(_bases.length == _quotes.length, "BAD_INPUT_LENGTH");
        uint256 len = _bases.length;
        ReferenceData[] memory results = new ReferenceData[](len);
        for (uint256 idx = 0; idx < len; idx++) {
            results[idx] = getReferenceData(_bases[idx], _quotes[idx]);
        }
        return results;
    }
}