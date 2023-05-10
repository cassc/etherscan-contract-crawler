// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/errors/BridgePoolFactoryErrors.sol";
import "contracts/libraries/factory/BridgePoolFactoryBase.sol";

/// @custom:salt BridgePoolFactory
/// @custom:deploy-type deployUpgradeable
contract BridgePoolFactory is BridgePoolFactoryBase {
    constructor() BridgePoolFactoryBase() {}

    /**
     * @notice Deploys a new bridge to pass tokens to our chain from the specified ERC contract.
     * The pools are created as thin proxies (EIP1167) routing to versioned implementations identified by corresponding salt.
     * @param tokenType_ type of token (1=ERC20, 2=ERC721)
     * @param ercContract_ address of ERC20 source token contract
     * @param implementationVersion_ version of BridgePool implementation to use
     */
    function deployNewNativePool(
        uint8 tokenType_,
        address ercContract_,
        uint16 implementationVersion_
    ) public onlyFactoryOrPublicEnabled {
        _deployNewNativePool(tokenType_, ercContract_, implementationVersion_);
    }

    /**
     * @notice deploys logic for bridge pools and stores it in a logicAddresses mapping
     * @param tokenType_ type of token (1=ERC20, 2=ERC721)
     * @param chainId_ address of ERC20 source token contract
     * @param value_ amount of eth to send to the contract on creation
     * @param deployCode_ logic contract deployment bytecode
     */
    function deployPoolLogic(
        uint8 tokenType_,
        uint256 chainId_,
        uint256 value_,
        bytes calldata deployCode_
    ) public onlyFactory returns (address) {
        return _deployPoolLogic(tokenType_, chainId_, value_, deployCode_);
    }

    /**
     * @dev enables or disables public pool deployment
     **/
    function togglePublicPoolDeployment() public onlyFactory {
        _togglePublicPoolDeployment();
    }

    /**
     * @notice calculates bridge pool address with associated bytes32 salt
     * @param bridgePoolSalt_ bytes32 salt associated with the pool, calculated with getBridgePoolSalt
     * @return poolAddress calculated calculated bridgePool Address
     */
    function lookupBridgePoolAddress(
        bytes32 bridgePoolSalt_
    ) public view returns (address poolAddress) {
        poolAddress = BridgePoolAddressUtil.getBridgePoolAddress(bridgePoolSalt_, address(this));
    }

    /**
     * @notice calculates salt for a BridgePool contract based on ERC contract's address, tokenType, chainID and version_
     * @param tokenContractAddr_ address of ERC Token contract
     * @param tokenType_ type of token (1=ERC20, 2=ERC721)
     * @param version_ version of the implementation
     * @param chainID_ chain ID
     * @return calculated calculated salt
     */
    function getBridgePoolSalt(
        address tokenContractAddr_,
        uint8 tokenType_,
        uint256 chainID_,
        uint16 version_
    ) public pure returns (bytes32) {
        return
            BridgePoolAddressUtil.getBridgePoolSalt(
                tokenContractAddr_,
                tokenType_,
                chainID_,
                version_
            );
    }
}