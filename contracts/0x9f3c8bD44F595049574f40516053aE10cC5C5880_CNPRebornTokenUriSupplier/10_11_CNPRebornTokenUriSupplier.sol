// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "./ITokenUriSupplier.sol";
import "../ICNPReborn.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CNPRebornTokenUriSupplier is
    ITokenUriSupplier,
    AccessControl,
    Ownable
{
    using Strings for uint256;

    // ==================================================================
    // Constants
    // ==================================================================
    bytes32 public constant ADMIN = "ADMIN";

    // ==================================================================
    // Variables
    // ==================================================================
    ICNPReborn private _reborn;

    string public baseURI = "";
    string public baseExtension = ".json";

    // ==================================================================
    // Conctructor
    // ==================================================================
    constructor() {
        grantRole(ADMIN, msg.sender);
    }

    // ==================================================================
    // Functions
    // ==================================================================
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        string memory stage = _reborn.isAdult(tokenId)
            ? "adult"
            : _reborn.isChild(tokenId)
            ? "child"
            : "egg";
        string memory lock = _reborn.isLocked(tokenId) ? "_lock" : "";
        string memory ct = _reborn.inCoolDownTime(tokenId) ? "_ct" : "";
        
        return
            string(
                abi.encodePacked(
                    baseURI,
                    tokenId.toString(),
                    "/",
                    stage,
                    lock,
                    ct,
                    baseExtension
                )
            );
    }

    function setBaseURI(string memory _value) external onlyRole(ADMIN) {
        baseURI = _value;
    }

    function setBaseExtension(string memory _value) external onlyRole(ADMIN) {
        baseExtension = _value;
    }

    function setReborn(address value) external onlyRole(ADMIN){
        _reborn = ICNPReborn(value);
    }

    // ==================================================================
    // operations
    // ==================================================================
    function grantRole(bytes32 role, address account)
        public
        override
        onlyOwner
    {
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account)
        public
        override
        onlyOwner
    {
        _revokeRole(role, account);
    }
}