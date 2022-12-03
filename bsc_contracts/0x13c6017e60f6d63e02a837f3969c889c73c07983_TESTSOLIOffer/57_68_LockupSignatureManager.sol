// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

import "hardhat/console.sol";
import "../TokenTransfer.sol";
import "../../../base/ISignatureManager.sol";

/**
 * @dev LockupSignatureManager locks all token transfers until the token is signed
 */
contract LockupSignatureManager is TokenTransfer {
    // A reference to the contract that signs
    ISignatureManager internal signatureManager;

    /**
     * @dev
     */
    constructor(
        address _signatureManagerContract,
        address _issuer,
        uint256 _totalTokens,
        string memory _tokenName,
        string memory _tokenSymbol
    ) public TokenTransfer(_issuer, _totalTokens, _tokenName, _tokenSymbol) {
        require(_issuer != address(0), "Issuer is empty");

        // convert the address to the interface
        signatureManager = ISignatureManager(_signatureManagerContract);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (signatureManager != ISignatureManager(0x0)) {
            require(
                signatureManager.isSigned(address(this)),
                "Token is not signed"
            );
        }

        super._beforeTokenTransfer(from, to, amount);
    }
}