// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../security/Administered.sol";
import "../Interfaces/INFTCollection.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract ClaimFactory is Administered {
    /// @dev Collection struct
    struct StructClaim {
        address wallet;
        address addrNft;
        uint256 amountNft;
        uint256 timestamp;
        bool withdrawal;
    }

    /// @dev reserve
    uint public reserveNFt = 0;

    /// @dev mapping
    mapping(string => StructClaim) public _claim;

    /// @dev create a new land
    function createCodeLand(
        string memory _code,
        address _addrNft,
        uint256 _amount
    ) external onlyUser returns (bool) {
        /// @dev check if the land is already created
        require(
            !_claim[_code].withdrawal,
            "CreateCodeLand: Land already created"
        );

        /// @dev create a new land
        _claim[_code] = StructClaim(address(0), _addrNft, _amount, 0, true);

        /// @dev add the amount of nft to the reserve
        reserveNFt = reserveNFt + _amount;

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