// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IWhitelist.sol";

/// @title WhitelistProxy
///
/// @dev This contract abstracts the whitelisting implementation to the caller, ie, ERC721 & ERC1155 tokens
///			 The logic can be replaced and the `canTransfer` will invoke the proper target function. It's important
///			 to mention that no storage is shared between this contract and the corresponding implementation
///			 call is used instead of delegate call to avoid different implementations storage compatibility.
contract WhitelistProxy is IWhitelist, Ownable {
    event ImplementationChanged(address indexed _oldImplementation, address indexed _newImplementation);

    //The address of the whitelist implementation
    IWhitelist public whitelist;

    constructor(IWhitelist _whitelist) {
        require(address(_whitelist) != address(0), "invalid address");
        whitelist = _whitelist;
    }

    /**
     * @param _who the address that wants to transfer a NFT
     * @dev Returns true if address has permission to transfer a NFT
     */
    function canTransfer(address _who) external override returns (bool) {
        return whitelist.canTransfer(_who);
    }

    /**
     * @param _whitelist the address of the new whitelist implementation
     */
    function updateImplementation(IWhitelist _whitelist) external onlyOwner {
        require(address(_whitelist) != address(0), "updateImplementation: invalid address");
        emit ImplementationChanged(address(getImplementation()), address(_whitelist));
        whitelist = _whitelist;
    }

    /**
     * @dev Returns the address of the actual whitelist implementation
     */
    function getImplementation() public view returns (IWhitelist) {
        return whitelist;
    }
}