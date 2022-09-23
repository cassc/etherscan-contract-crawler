// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "./extensions/SecureToken.sol";

contract XJoyToken is SecureToken {
    /**
     * Flag indicating if contract is guarding transfers from blacklisted sources and sniper attacks
     */
    bool public guarding;

    event Guarding(bool _status);

    /**
     * Tokens constructor
     *
     * @param _whitelist - Initial list of whitelisted receivers
     * @param _blacklist - Initial list of blacklisted addresses
     * @param _admins - Initial list of all administrators of the token
     * @param _guarding - If SecureToken is guarding the transfers from the constructor moment
     */
    constructor(
        address[] memory _whitelist,
        address[] memory _blacklist,
        address[] memory _admins,
        bool _guarding,
        uint256 _initialSupply
    )
        SecureToken(
            _whitelist,
            _blacklist,
            _admins,
            "xJOY Token",
            "xJOY"
        )
    {
        guarding = _guarding;
        mint(_msgSender(), _initialSupply);
    }

    /**
     * Turning on or off guarding mechanism of the contract
     *
     * @param _guard - Flag if guarding mechanism should be turned on or off
     */
    function setGuard(bool _guard) external onlyAdmin {
        if (guarding != _guard) {
            guarding = _guard;
            emit Guarding(_guard);
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256
    ) internal virtual override {
        if (guarding) {
            require(!blacklisted[from] || whitelisted[to], "SecureToken: This address is forbidden from making any transfers");
        }
    }
    
}