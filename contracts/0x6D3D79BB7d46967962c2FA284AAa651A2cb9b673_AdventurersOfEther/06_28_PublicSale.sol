//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../AdventurersStorage.sol";

/**
 * @notice Public sale stage of Adventurers Token workflow
 */
abstract contract PublicSale is AdventurersStorage {

    /// @notice PublicSaleConfig struct.
    /// @param price The PublicSale price.
    /// @param tokensPerTransaction The amount of tokens per tx.
    struct PublicSaleConfig {
        uint128 price;
        uint32 tokensPerTransaction;
    }

    /// @notice Returns the publicSaleConfig.
    PublicSaleConfig public publicSaleConfig = PublicSaleConfig({
        price: 0.02 ether,
        tokensPerTransaction: 0 // 10 + extra 1 for <
    });

    /// @notice Used to mint in the public mint phase.
    /// @param _count The amount of tokens to mint.
    function mintPublic(uint256 _count) external payable {
        PublicSaleConfig memory _cfg = publicSaleConfig;
        require(_cfg.tokensPerTransaction > 0, "publicsale: disabled");
        require(msg.value == _cfg.price * _count, "publicsale: payment amount");
        require(_count < _cfg.tokensPerTransaction, "publicsale: invalid count");
        
        _mint(msg.sender, _count);
    }

    /// @notice Used to adjust the publicsale config values.
    /// @dev Restricted with onlyOwner modifier.
    /// @param _price The publicSale mint price.
    /// @param _tokensPerTransaction The amount of tokens allowed per tx.
    function setPublicSaleConfig(uint128 _price, uint32 _tokensPerTransaction) external onlyOwner {
        uint32 _perTx = _tokensPerTransaction += 1;

        publicSaleConfig = PublicSaleConfig({
            price: _price,
            tokensPerTransaction: _perTx
        });
    }
}