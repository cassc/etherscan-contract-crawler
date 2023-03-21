/* Attestation decode and validation */
/* AlphaWallet 2021 - 2022 */
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC5169.sol";

abstract contract ERC5169 is IERC5169 {

    string[] private _scriptURI;
    function scriptURI() external view override returns(string[] memory) {
        return _scriptURI;
    }

    function setScriptURI(string[] memory newScriptURI) external override {
        _authorizeSetScripts(newScriptURI);

        _scriptURI = newScriptURI;

        emit ScriptUpdate(newScriptURI);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC5169).interfaceId;
    }

     /**
     * @dev Function that should revert when `msg.sender` is not authorized to set script URI. Called by
     * {setScriptURI}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeSetScripts(string[] memory) internal override onlyOwner {}
     * ```
     */
    function _authorizeSetScripts(string[] memory newScriptURI) internal virtual;
}