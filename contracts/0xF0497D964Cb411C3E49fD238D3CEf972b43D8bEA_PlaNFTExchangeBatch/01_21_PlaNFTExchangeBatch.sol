//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./ExchangeBatch.sol";

contract PlaNFTExchangeBatch is ExchangeBatch {
    string public constant codename = "Lambton Worm";

    /**
     * @dev Initialize a PlaNFTExchange instance
     * @param registryAddress Address of the registry instance which this Exchange instance will use
     * @param tokenAddress Address of the token used for protocol fees
     */
    constructor(
        ProxyRegistry registryAddress,
        TokenTransferProxy tokenTransferProxyAddress,
        ERC20 tokenAddress,
        address protocolFeeAddress,
        address rewardFeeRecipient
    ) {
        registry = registryAddress;
        tokenTransferProxy = tokenTransferProxyAddress;
        exchangeToken = tokenAddress;
        protocolFeeRecipient = protocolFeeAddress;
        _rewardFeeRecipient = rewardFeeRecipient;
    }
}