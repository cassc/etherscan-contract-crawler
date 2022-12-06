// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;
import {DataTypes} from "../libraries/DataTypes.sol";

interface IBendApeStaking {
    event OffersMatched(DataTypes.ApeOffer apeOffer, DataTypes.BakcOffer backOffer, DataTypes.CoinOffer coinOffer);

    event OffersCanceled(address indexed user, uint256[] offerNonces);

    function cancelOffers(uint256[] calldata offerNonces) external;

    function isCancelled(address user, uint256 offerNonce) external view returns (bool);

    function matchWithBakcAndCoin(
        DataTypes.ApeOffer calldata apeOffer,
        DataTypes.BakcOffer calldata bakcOffer,
        DataTypes.CoinOffer calldata coinOffer
    ) external;

    function matchWithCoin(DataTypes.ApeOffer calldata apeOffer, DataTypes.CoinOffer calldata coinOffer) external;

    function matchWithBakc(DataTypes.ApeOffer calldata apeOffer, DataTypes.BakcOffer calldata backOffer) external;

    function stakeSelf(
        address apeAddress,
        uint256 apeTokenId,
        uint256 backTokenId,
        uint256 apeCoinAmount
    ) external;
}