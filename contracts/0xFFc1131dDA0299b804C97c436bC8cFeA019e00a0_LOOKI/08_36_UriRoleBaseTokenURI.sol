// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/access/AccessControlEnumerable.sol';

/**
@notice ERC721 extension that overrides the OpenZeppelin _baseURI() function to
return a prefix that can be set by the contract owner.
 */
abstract contract UriRoleBaseTokenURI is AccessControlEnumerable {
    bytes32 public constant SET_BASE_TOKEN_URI_ROLE = keccak256('SET_BASE_TOKEN_URI_ROLE');
    /// @notice Base token URI used as a prefix by tokenURI().
    string public baseTokenURI;

    constructor(string memory _baseTokenURI) {
        _grantRole(SET_BASE_TOKEN_URI_ROLE, _msgSender());
        setBaseTokenURI(_baseTokenURI);
    }

    /// @notice Sets the base token URI prefix.
    function setBaseTokenURI(string memory _baseTokenURI) public onlyRole(SET_BASE_TOKEN_URI_ROLE) {
        baseTokenURI = _baseTokenURI;
    }

    /**
    @notice Concatenates and returns the base token URI and the token ID without
    any additional characters (e.g. a slash).
    @dev This requires that an inheriting contract that also inherits from OZ's
    ERC721 will have to override both contracts; although we could simply
    require that users implement their own _baseURI() as here, this can easily
    be forgotten and the current approach guides them with compiler errors. This
    favours the latter half of "APIs should be easy to use and hard to misuse"
    from https://www.infoq.com/articles/API-Design-Joshua-Bloch/.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return baseTokenURI;
    }
}