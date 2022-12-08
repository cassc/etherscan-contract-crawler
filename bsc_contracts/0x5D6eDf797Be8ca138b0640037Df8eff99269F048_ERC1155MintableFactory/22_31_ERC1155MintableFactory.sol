// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/IFactory.sol";
import "../helpers/MogulERC1155Mintable.sol";
import "../libraries/structs.sol";

contract ERC1155MintableFactory is AccessControl, IERC1155Factory {
    bytes32 public constant ROLE_ADMIN = keccak256("ROLE_ADMIN");
    address public tokenImplementation;

    error AdminOnly();
    // Besides our generic ERC1155 Created event, we emit a specific event personalized to our ecosystem
    event ERC1155Created(address contractAddress, address owner);
    event Mogul1155Created(address contractAddress, address owner);

    constructor() {
        tokenImplementation = address(new MogulERC1155Mintable());
        _setupRole(ROLE_ADMIN, msg.sender);
        _setRoleAdmin(ROLE_ADMIN, ROLE_ADMIN);
    }

    function setTokenImplementation(address _tokenImplementation) external {
        if (!hasRole(ROLE_ADMIN, msg.sender)) revert AdminOnly();
        tokenImplementation = _tokenImplementation;
    }

    // This will create new mintable NFts
    function createERC1155(
        address owner,
        string calldata name,
        string calldata symbol,
        ERC1155Config calldata configuration,
        PriceRule[] calldata rules
    ) external override {
        address clone = Clones.clone(tokenImplementation);
        IInitializableERC1155(clone).init(
            owner,
            name,
            symbol,
            configuration.globalSupplyConfigs
        );

        IInitializableERC1155(clone).setInitialPricingConfig(
            configuration.strategy,
            configuration.acceptedPaymentTokens,
            configuration.paymentTokensPricing,
            rules
        );

        emit ERC1155Created(clone, owner);
        emit Mogul1155Created(clone, owner);
    }
}