// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./SoftAdministered.sol";

contract ClaimFactory is SoftAdministered {
    /// @dev Collection struct
    struct StructClaim {
        address wallet;
        uint256 amountNft;
        uint256 timestamp;
        bool withdrawal;
    }

    /// @dev mapping
    mapping(string => StructClaim) public _claim;

    /**
     * @dev Create a new code
     */
    function createCode(
        string memory _code,
        uint256 _amount
    ) external onlyUser returns (bool) {
        /// @dev check if the land is already created
        require(
            !_claim[_code].withdrawal,
            "CreateCodeLand: Land already created"
        );

        /// @dev create a new land
        _claim[_code] = StructClaim(address(0), _amount, 0, true);

        return true;
    }

    /**
     *  remove code
     */
    function removeCodeLand(
        string memory _code
    ) external onlyUser returns (bool) {
        /// @dev remove a land
        _claim[_code] = StructClaim(address(0), 0, 0, false);
        return true;
    }
}