// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../base/BlockContext.sol";
import "./interfaces/IWrappedToken.sol";
import "./interfaces/IETHBridge.sol";

abstract contract ETHBridgeStorage {
    // --------- IMMUTABLE ---------
    address internal _bridgeAdmin;
    mapping(uint256 => bool) internal _nonces;
}

contract ETHBridge is
    IETHBridge,
    BlockContext,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    ETHBridgeStorage
{
    //
    function initialize() external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        //
        _bridgeAdmin = _msgSender();
    }

    modifier onlyBridgeAdmin() {
        require(_bridgeAdmin == _msgSender(), "ETHB: caller is not the admin");
        _;
    }

    function getBridgeAdmin() public view returns (address) {
        return _bridgeAdmin;
    }

    function setBridgeAdmin(address newAdmin) public onlyOwner {
        require(newAdmin != address(0), "ETHB: new admin is the zero address");
        _bridgeAdmin = newAdmin;
    }

    function isNonceUsed(uint256 nonce) public view returns (bool) {
        return _nonces[nonce];
    }

    function mint(
        uint256[] calldata nonces,
        IWrappedToken[] calldata tokens,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external onlyBridgeAdmin nonReentrant {
        require(
            nonces.length == tokens.length &&
                tokens.length == recipients.length &&
                recipients.length == amounts.length,
            "ETHB: invalid input data"
        );
        for (uint i = 0; i < recipients.length; i++) {
            require(!_nonces[nonces[i]], "ETHB: nonce is used");
            _nonces[nonces[i]] = true;
            tokens[i].mint(recipients[i], amounts[i]);
        }
        emit Mint(nonces, tokens, recipients, amounts);
    }

    function burn(
        IWrappedToken token,
        address recipient,
        uint256 amount
    ) external {
        token.permitBurnFrom(_msgSender(), amount);
        emit Burn(token, _msgSender(), recipient, amount);
    }
}