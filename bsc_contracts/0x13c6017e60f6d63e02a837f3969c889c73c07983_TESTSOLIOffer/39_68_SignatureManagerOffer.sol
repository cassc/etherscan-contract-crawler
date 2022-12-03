/* SPDX-License-Identifier: UNLICENSED */
pragma solidity ^0.6.12;

import "hardhat/console.sol";
import "../../../base/BaseOfferSale.sol";
import "../../../base/BaseOfferToken.sol";
import "../../../SignatureManager.sol";

/**
 * @dev SignatureManagerOffer
 * @notice Módulo de oferta que necessita ser assinado por um SignatureManager para ser inicializado.
 */
contract SignatureManagerOffer is BaseOfferSale {
    // A reference to the contract that signs
    SignatureManager internal signatureManager;

    constructor(address _signatureManagerContract) public BaseOfferSale() {
        // convert the address to the interface
        signatureManager = SignatureManager(_signatureManagerContract);
    }

    function _initialize() internal override {
        // only initialize if our contract is signed
        require(signatureManager.isSigned(address(this)), "Contract is not signed");
    }
}