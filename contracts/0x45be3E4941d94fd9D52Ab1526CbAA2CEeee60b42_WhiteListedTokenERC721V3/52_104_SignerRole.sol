pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/access/AccessControl.sol";

contract SignerRole is AccessControl {
    
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

    modifier onlyAdmin() {
        require(isAdmin(_msgSender()), "Ownable: caller is not the admin");
        _;
    }

    modifier onlySigner() {
        require(isSigner(_msgSender()), "Ownable: caller is not the signer");
        _;
    }

    constructor() public {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function addAdmin(address _accont) internal onlyAdmin {
        grantRole(DEFAULT_ADMIN_ROLE , _accont);
    }

    function removeAdmin(address _accont) internal onlyAdmin {
        revokeRole(DEFAULT_ADMIN_ROLE , _accont);
    }

    function addSigner(address _account) public onlyAdmin {
        grantRole(SIGNER_ROLE, _account);
    }

    function removeSigner(address _account) public onlyAdmin {
        revokeRole(SIGNER_ROLE, _account);
    }

    function isSigner(address _account) public virtual view returns(bool) {
        return hasRole(SIGNER_ROLE, _account);
    }

    function isAdmin(address _account) internal virtual view returns(bool) {
        return hasRole(DEFAULT_ADMIN_ROLE , _account);
    }
}