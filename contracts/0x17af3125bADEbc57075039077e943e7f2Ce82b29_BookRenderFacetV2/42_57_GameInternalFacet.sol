//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "hardhat/console.sol";

import "./LibStorage.sol";

import {AccessControlInternal} from "@solidstate/contracts/access/access_control/AccessControlInternal.sol";

contract GameInternalFacet is WithStorage, AccessControlInternal {
    error TokenNotFound(string slug);
    
    bytes32 constant ADMIN = keccak256("admin");
    
    modifier onlyRoleStr(string memory role) {
        if (!_hasRole(ADMIN, msg.sender)) {
            _checkRole(_strToRole(role));
        }
        _;
    }
    
    function _grantRoleStr(string memory role, address account) internal {
        _grantRole(_strToRole(role), account);
    }
    
    function _setRoleAdminStr(string memory role, string memory adminRole) internal {
        _setRoleAdmin(_strToRole(role), _strToRole(adminRole));
    }
    
    function _strToRole(string memory role) internal pure returns (bytes32) {
        return keccak256(bytes(role));
    }
    
    function slugToTokenId(string memory slug) internal pure returns (uint) {
        bytes32 hashed = keccak256(bytes(slug));
        return uint(hashed);
    }
    
    function slugToTokenInfo(string memory slug) internal view returns (GameItemTokenInfo storage) {
        uint tokenId = slugToTokenId(slug);
        return gs().tokenIdToTokenInfo[tokenId];
    }
    
    function findIdBySlugOrRevert(string memory slug) internal view returns (uint) {
        GameItemTokenInfo storage tokenInfo = slugToTokenInfo(slug);
        if (bytes(tokenInfo.slug).length == 0) revert TokenNotFound({slug: slug});
        
        return slugToTokenId(slug);
    }
}