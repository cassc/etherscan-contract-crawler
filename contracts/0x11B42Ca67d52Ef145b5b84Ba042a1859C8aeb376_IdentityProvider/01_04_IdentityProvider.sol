// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IProvider.sol";

contract IdentityProvider is Ownable, IProvider {
    mapping(address => bool) private verifiers;
    mapping(address => bool) private wallets;

    string public url;

    event Register(address indexed wallet, bool asVerifier);
    event Revoke(address indexed wallet, bool asVerifier);

    constructor(string memory _url) {
        url = _url;
    }

    function setUrl(string calldata _url) public onlyOwner {
        url = _url;
    }

    function registerVerifier(address _addr) public onlyOwner {
        verifiers[_addr] = true;
        emit Register(_addr, true);
    }

    function revokeVerifier(address _addr) public onlyOwner {
        require(verifiers[_addr], "address is not a verifier");
        delete verifiers[_addr];
        emit Revoke(_addr, true);
    }

    function isVerifier(address _addr) external view returns (bool) {
        return verifiers[_addr];
    }


    function register(address _addr) public onlyOwner {
        wallets[_addr] = true;
        emit Register(_addr, false);
    }

    function revoke(address _addr) public onlyOwner {
        require(wallets[_addr], "address is not registered");
        delete wallets[_addr];
        emit Revoke(_addr, false);
    }

    function isKnown(address _addr) external view returns (bool) {
        return wallets[_addr];
    }
}