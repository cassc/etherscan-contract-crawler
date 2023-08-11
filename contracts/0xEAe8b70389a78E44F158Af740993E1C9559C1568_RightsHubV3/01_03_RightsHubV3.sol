// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract RightsHubV3 is Ownable {
    /**
     * @dev Emitted when rights are registered
     */
    event RightsRegistration(
        address indexed registrar,
        string rightsManifestUri
    );

    // Indicates if allow list is active or not
    bool private _useAllowlist;

    // List of contract addresses that can call this contract
    mapping(address => bool) _allowlist;

    constructor() {
        _useAllowlist = true;
    }

    /*
     * Returns a boolean indicating if allow list is enabled
     */
    function useAllowlist() public view returns (bool) {
        return _useAllowlist;
    }

    /*
     * Disable allow list
     */
    function disableAllowlist() public onlyOwner {
        _useAllowlist = false;
    }

    /*
     * Enable allowlist
     */
    function enableAllowlist() public onlyOwner {
        _useAllowlist = true;
    }

    /*
     * Add address to allowed list
     */
    function addAllowed(address addr) public onlyOwner {
        _allowlist[addr] = true;
    }

    /*
     * Remove address from allowed list
     */
    function removeAllowed(address addr) public onlyOwner {
        _allowlist[addr] = false;
    }

    /*
     * Throws error if caller is not in the allowed list
     */
    modifier onlyAllowed() {
        if (_useAllowlist) {
            require(
                _allowlist[msg.sender] == true || _allowlist[tx.origin] == true,
                "RightsHub: caller is not in allow list"
            );
        }
        _;
    }

    /*
     * Register rights
     */
    function registerRights(
        string calldata rightsManifestUri
    ) public onlyAllowed {
        require(
            tx.origin != msg.sender,
            "RightsHub: registerRights() can only be called by Smart Contracts"
        );
        require(
            bytes(rightsManifestUri).length > 0,
            "RightsHub: Rights Manifest URI can not be empty"
        );

        // Emit event
        emit RightsRegistration(msg.sender, rightsManifestUri);
    }
}