//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./Exchange.sol";

contract PlaNFTExchange is Exchange {
    string public constant codename = "Lambton Worm";

    /**
     * @dev Initialize a PlaNFTExchange instance
     * @param registryAddress Address of the registry instance which this Exchange instance will use
     * @param tokenAddress Address of the token used for protocol fees
     */
    constructor (
        string memory name,
        string memory version,
        uint256 chainId,
        bytes32 salt,
        ProxyRegistry registryAddress,
        TokenTransferProxy tokenTransferProxyAddress,
        ERC20 tokenAddress,
        address protocolFeeAddress,
        address rewardFeeRecipient
    ) Exchange(name, version, chainId, salt) {
        registry = registryAddress;
        tokenTransferProxy = tokenTransferProxyAddress;
        exchangeToken = tokenAddress;
        protocolFeeRecipient = protocolFeeAddress;
        _rewardFeeRecipient = rewardFeeRecipient;
    }
}