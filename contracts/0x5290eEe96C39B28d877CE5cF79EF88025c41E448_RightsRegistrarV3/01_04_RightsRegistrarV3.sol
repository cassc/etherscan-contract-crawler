// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./RightsHubV3.sol";

contract RightsRegistrarV3 is Ownable {
    // Address of Rights Hub v3 contract
    address internal _hub;

    // Indicates if allow list is active or not
    bool private _useAllowlist;

    // List of addresses that can register rights using this contract
    mapping(address => bool) _allowlist;

    /*
     * Constructor
     */
    constructor(address hub_) {
        _hub = hub_;
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
     * Enable allow list
     */
    function enableAllowlist() public onlyOwner {
        _useAllowlist = true;
    }

    /*
     * Add address to the allow list
     */
    function addAllowed(address addr) public onlyOwner {
        _allowlist[addr] = true;
    }

    /*
     * Remove address from the allow list
     */
    function removeAllowed(address addr) public onlyOwner {
        _allowlist[addr] = false;
    }

    /*
     * Throws error if initiator of transaction (`tx.origin`) is not in the allow list
     */
    modifier onlyAllowed() {
        if (_useAllowlist) {
            require(
                _allowlist[tx.origin] == true,
                "RightsRegistrar: caller is not in allow list"
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
        RightsHubV3(_hub).registerRights(rightsManifestUri);
    }
}