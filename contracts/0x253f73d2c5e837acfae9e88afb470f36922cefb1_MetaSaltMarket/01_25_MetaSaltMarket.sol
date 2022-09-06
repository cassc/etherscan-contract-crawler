// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;
import "./MarketCore.sol";
import "./TransferManager.sol";

contract MetaSaltMarket is MarketCore {
    function __MetaSaltMarket_init(
        uint newProtocolFee,
        address newDefaultFeeReceiver,
        address transferERC721Proxy,
        address transferERC1155Proxy        
    ) external initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();                
        __OrderValidator_init_unchained();
        __TransferManager_init_unchained(newProtocolFee, newDefaultFeeReceiver, transferERC721Proxy, transferERC1155Proxy);
    }
}