// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract PropToken is ERC20, Pausable, AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    address private owner;

    mapping(address => bool) public whitelist;
    mapping(address => bool) public blocklist;

    event WhitelistChanged(address Address, bool Status);

    event BlocklistChanged(address Address, bool Status);

    event OwnershipTransfered(address OldOwner, address NewOwner);

    constructor(uint256 _initialSupply) ERC20("PROP TOKEN", "PROP") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);

        _mint(msg.sender, _initialSupply);
        owner = msg.sender;
    }

    function pause() public onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    function changeWhitelist(address _user, bool _status)
        public
        onlyRole(ADMIN_ROLE)
    {
        whitelist[_user] = _status;
        emit WhitelistChanged(_user, _status);
    }

    function changeBlocklist(address _user, bool _status)
        public
        onlyRole(ADMIN_ROLE)
    {
        blocklist[_user] = _status;
        emit BlocklistChanged(_user, _status);
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal override {
        require(
            !blocklist[_from] && !blocklist[_to],
            "Address in the blocklisted."
        );
        if (paused()) {
            require(whitelist[msg.sender], "Token on pause.");
        }
        super._beforeTokenTransfer(_from, _to, _amount);
    }

    function setNewOwner(address _newOwner) external {
        require(
            owner == _msgSender(),
            "This function can only be called by the current owner."
        );
        emit OwnershipTransfered(owner, _newOwner);
        owner = _newOwner;
    }

    function decimals() public view virtual override(ERC20) returns (uint8) {
        return 8;
    }

    function getOwner() public view returns (address) {
        return owner;
    }
}