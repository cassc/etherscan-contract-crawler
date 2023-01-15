// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import '@openzeppelin/contracts/access/Ownable.sol';
import "./packages/ERC721WithOperatorFilter.sol";

contract CryptoNinjaMosaic is ERC721WithOperatorFilter {

    constructor(address[] memory _administrators)
        ERC721("CryptoNinjaMosaic", "CNM")
    {
        _setRoleAdmin(CONTRACT_ADMIN, CONTRACT_ADMIN);
        setDefaultRoyalty(payable(0x52A76a606AC925f7113B4CC8605Fe6bCad431EbB), 1000);

        for (uint256 i = 0; i < _administrators.length; i++) {
            _setupRole(CONTRACT_ADMIN, _administrators[i]);
        }
    }

}