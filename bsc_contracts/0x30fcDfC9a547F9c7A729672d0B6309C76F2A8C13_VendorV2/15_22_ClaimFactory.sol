// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../security/Administered.sol";
import "../Interfaces/INFTCollection.sol";

contract ClaimFactory is Administered {
    /// @dev Collection struct
    struct StructClaim {
        address wallet;
        address addressNft;
        uint256 amountNft;
        uint256 timestamp;
        bool withdrawal;
    }

    /// @dev mapping
    mapping(string => StructClaim) public _claim;

    /// @dev create a new land
    function createCodeLand(
        string memory _code,
        uint256 _amount,
        address _addressNft
    ) external onlyUser returns (bool) {
        /// @dev check if the land is already created
        require(
            !_claim[_code].withdrawal,
            "CreateCodeLand: Land already created"
        );

        /// @dev mint the NFT
        INFTCollection(_addressNft).mintReserved(address(this), _amount);

        /// @dev create a new land
        _claim[_code] = StructClaim(address(0), _addressNft, _amount, 0, true);

        return true;
    }

    function removeCodeLand(
        string memory _code
    ) external onlyUser returns (bool) {
        /// @dev remove a land
        _claim[_code] = StructClaim(address(0), address(0), 0, 0, false);
        return true;
    }
}