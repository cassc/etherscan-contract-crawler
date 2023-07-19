// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./utils/ExclusionList.sol";

abstract contract CirculatingSupplyBase is OwnableUpgradeable, ExclusionList {
    event TokenSet(address indexed newToken);

    address public token;

    function setUp(bytes memory initializeParams) public {
        (address _owner, address _token, address[] memory _exclusions) = abi
            .decode(initializeParams, (address, address, address[]));
        __Ownable_init();
        transferOwnership(_owner);
        setupExclusions();
        token = _token;
        for (uint256 i = 0; i < _exclusions.length; i++) {
            _excludeAddress(_exclusions[i]);
        }
    }

    /// @dev Sets the token to calculate circulating supply of
    /// @param _token token to calculate circulating supply of
    /// @notice This can only be called by the owner
    function setToken(address _token) public onlyOwner {
        token = _token;
        emit TokenSet(_token);
    }

    /// @dev Removes an excluded address
    /// @param prevExclusion Exclusion that pointed to the exclusion to be removed in the linked list
    /// @param exclusion Exclusion to be removed
    /// @notice This can only be called by the owner
    function removeExclusion(address prevExclusion, address exclusion)
        public
        onlyOwner
    {
        _removeExclusion(prevExclusion, exclusion);
    }

    /// @dev Enables the balance of an address from the circulatingSupply calculation
    /// @param exclusion Address to be excluded
    /// @notice This can only be called by the owner
    function exclude(address exclusion) public onlyOwner {
        _excludeAddress(exclusion);
    }

    function get() public view virtual returns (uint256 circulatingSupply);
}