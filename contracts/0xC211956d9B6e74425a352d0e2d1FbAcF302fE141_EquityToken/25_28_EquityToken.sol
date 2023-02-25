// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {ERC20, ERC20Votes, ERC20Permit} from "openzeppelin/token/ERC20/extensions/ERC20Votes.sol";

import {Captable} from "./Captable.sol";
import {IMPL_INIT_NOOP_ADDR} from "../bases/FirmBase.sol";

/*
THE TRANSFER OF THE SECURITIES REFERENCED HEREIN IS SUBJECT TO CERTAIN TRANSFER
RESTRICTIONS SET FORTH IN THE COMPANY’S BYLAWS, WHICH MAY BE OBTAINED UPON
WRITTEN REQUEST TO THE COMPANY AT ITS DESIGNATED ELECTRONIC ADDRESS.
THE COMPANY SHALL NOT REGISTER OR OTHERWISE RECOGNIZE OR GIVE EFFECT TO ANY
PURPORTED TRANSFER OF SECURITIES THAT DOES NOT COMPLY WITH SUCH TRANSFER RESTRICTIONS.*/

/**
 * @title Equity token
 * @author Firm ([email protected])
 * @notice ERC20 with vote delegation controlled by a Captable contract
 */
contract EquityToken is ERC20Votes {
    Captable public captable;
    uint32 public classId;

    error AlreadyInitialized();
    error UnauthorizedNotCaptable();

    modifier onlyCaptable() {
        // We use msg.sender directly here because Captable will never do meta-txs into this contract
        if (msg.sender != address(captable)) {
            revert UnauthorizedNotCaptable();
        }

        _;
    }

    constructor() ERC20("", "") ERC20Permit("") {
        initialize(Captable(IMPL_INIT_NOOP_ADDR), 0);
    }

    function initialize(Captable captable_, uint32 classId_) public {
        if (address(captable) != address(0)) {
            revert AlreadyInitialized();
        }

        captable = captable_;
        classId = classId_;
    }

    function mint(address account, uint256 amount) external onlyCaptable {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyCaptable {
        _burn(account, amount);
    }

    function forcedTransfer(address from, address to, uint256 amount) external onlyCaptable {
        _transfer(from, to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        // Transfers triggered by Captable are always allowed and not checked
        if (msg.sender != address(captable)) {
            captable.ensureTransferIsAllowed(from, to, classId, amount);
        }

        super._beforeTokenTransfer(from, to, amount);
    }

    function name() public view override returns (string memory) {
        return captable.nameFor(classId);
    }

    function symbol() public view override returns (string memory) {
        return captable.tickerFor(classId);
    }
}