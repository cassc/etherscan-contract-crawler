// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./ExchangeDomain.sol";

contract ExchangeOrdersHolder is Initializable, OwnableUpgradeable {

    mapping(bytes32 => OrderParams) internal orders;

    struct OrderParams {
        /* how much has owner (in wei, or UINT256_MAX if ERC-721) */
        uint selling;
        /* how much wants owner (in wei, or UINT256_MAX if ERC-721) */
        uint buying;

        /* fee for selling */
        uint sellerFee;
    }
	
	function initialize() public virtual initializer {
		__Ownable_init();
    }

    function add(ExchangeDomain.Order calldata order) external {
        require(msg.sender == order.key.owner, "order could be added by owner only");
        bytes32 key = prepareKey(order);
        orders[key] = OrderParams(order.selling, order.buying, order.sellerFee);
    }

    function exists(ExchangeDomain.Order calldata order) external view returns (bool) {
        bytes32 key = prepareKey(order);
        OrderParams memory params = orders[key];
        return params.buying == order.buying && params.selling == order.selling && params.sellerFee == order.sellerFee;
    }

    function prepareKey(ExchangeDomain.Order memory order) public pure returns (bytes32) {
        return keccak256(abi.encode(
                order.key.sellAsset.token,
                order.key.sellAsset.tokenId,
                order.key.owner,
                order.key.buyAsset.token,
                order.key.buyAsset.tokenId,
                order.key.salt
            ));
    }
}