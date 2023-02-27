// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC20Snapshot} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import {AccessControl} from "../../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
import {ERC20Permit} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import {ERC20Votes} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {Passport} from "../Passport/Passport.sol";

contract Rep is ERC20, ERC20Snapshot, AccessControl, ERC20Permit, ERC20Votes {
    error Disabled();

    bytes32 public constant SNAPSHOT_ROLE = keccak256("SNAPSHOT_ROLE");
    bytes32 public constant MINTER_BURNER_ROLE = keccak256("MINTER_BURNER_ROLE");

    Passport public immutable passport;
    mapping(uint256 => address) private passportToAddress;

    modifier updateAddress(uint256 passportId) {
        updateOwner(passportId);
        _;
    }

    constructor(address owner, address passport_, string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
        ERC20Permit(name_)
    {
        passport = Passport(passport_);
        // check that the owner is an admin of the passport
        require(passport.hasRole(passport.DEFAULT_ADMIN_ROLE(), owner), "Rep: initial owner must be passport admin");
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(SNAPSHOT_ROLE, owner);
        _grantRole(MINTER_BURNER_ROLE, owner);
    }

    function updateOwner(uint256 passportId) public {
        address passportOwner = passport.ownerOf(passportId); // reverts if does not exist
        address currentOwner = passportToAddress[passportId];
        if (currentOwner == address(0)) {
            // its the first time we see this passport
            passportToAddress[passportId] = passportOwner;
        } else if (currentOwner != passportOwner) {
            // the passport has moved
            _transfer(currentOwner, passportOwner, balanceOf(currentOwner));
            passportToAddress[passportId] = passportOwner;
        }
    }

    function snapshot() public onlyRole(SNAPSHOT_ROLE) {
        _snapshot();
    }

    function mint(uint256 toPassportId, uint256 amount)
        public
        onlyRole(MINTER_BURNER_ROLE)
        updateAddress(toPassportId)
    {
        _mint(passport.ownerOf(toPassportId), amount);
    }

    function balanceOf(uint256 passportId) public view returns (uint256) {
        return balanceOf(passport.ownerOf(passportId));
    }

    function transfer(
        address,
        /* to */
        uint256 /* amount */
    ) public pure override returns (bool) {
        revert Disabled();
    }

    function transferFrom(
        address,
        /* from */
        address,
        /* to */
        uint256 /* amount */
    ) public virtual override returns (bool) {
        revert Disabled();
    }

    function increaseAllowance(
        address,
        /* spender */
        uint256 /* addedValue */
    ) public pure override returns (bool) {
        revert Disabled();
    }

    function decreaseAllowance(
        address,
        /* spender */
        uint256 /* subtractedValue */
    ) public pure override returns (bool) {
        revert Disabled();
    }

    function allowance(
        address,
        /* owner */
        address /* spender */
    ) public pure override returns (uint256) {
        return 0;
    }

    function approve(
        address,
        /* spender */
        uint256 /* amount */
    ) public pure override returns (bool) {
        revert Disabled();
    }

    function burnFrom(uint256 passportId, uint256 amount)
        public
        onlyRole(MINTER_BURNER_ROLE)
        updateAddress(passportId)
    {
        _burn(passport.ownerOf(passportId), amount);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override (ERC20, ERC20Snapshot) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount) internal override (ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal override (ERC20, ERC20Votes) {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override (ERC20, ERC20Votes)
        onlyRole(MINTER_BURNER_ROLE)
    {
        super._burn(account, amount);
    }
}