// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ServiceLocator.sol";
import "./utils/GLPFunctions.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


contract GPOReserve is Ownable, AccessControl {
    bytes32 public constant AUTHORIZED_BUYX  =
        keccak256("CAN_BUY_GPO_FREEPRICE");
    modifier authorizedBuyx() {
        require(hasRole(AUTHORIZED_BUYX, _msgSender()));
        _;
    }

    constructor(address _svcLoc) {
        $ = ServiceLocator(_svcLoc);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    ServiceLocator private $;
    using GLPFunctions for ServiceLocator;

    uint256 public gpoTotalSupply;

    function buyGPOx(
        address buyer,
        uint256 gpoAmount,
        uint256 usdcAmount
    ) public authorizedBuyx {
        require(
            gpoAmount <= $.balance(CryptoToken.GPO, address(this)),
            "GR: not enough GPO"
        );

        $.transferFrom(CryptoToken.USDC, buyer, $.usdcReserve(), usdcAmount);
        $.transfer(CryptoToken.GPO, buyer, gpoAmount);
        gpoTotalSupply += gpoAmount;
    }

    function transferRemainingTokens() public onlyOwner {
        $.transfer(CryptoToken.GPO, owner(), $.balance(CryptoToken.GPO, address(this)));
    }
    
}