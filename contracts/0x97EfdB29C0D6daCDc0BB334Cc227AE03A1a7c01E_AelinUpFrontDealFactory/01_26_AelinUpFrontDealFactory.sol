// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./MinimalProxyFactory.sol";
import "./AelinUpFrontDeal.sol";
import "./libraries/AelinNftGating.sol";
import "./libraries/AelinAllowList.sol";
import {IAelinUpFrontDeal} from "./interfaces/IAelinUpFrontDeal.sol";

contract AelinUpFrontDealFactory is MinimalProxyFactory, IAelinUpFrontDeal {
    using SafeERC20 for IERC20;

    address public immutable UP_FRONT_DEAL_LOGIC;
    address public immutable AELIN_ESCROW_LOGIC;
    address public immutable AELIN_TREASURY;

    constructor(
        address _aelinUpFrontDeal,
        address _aelinEscrow,
        address _aelinTreasury
    ) {
        require(_aelinUpFrontDeal != address(0), "cant pass null deal address");
        require(_aelinTreasury != address(0), "cant pass null treasury address");
        require(_aelinEscrow != address(0), "cant pass null escrow address");
        UP_FRONT_DEAL_LOGIC = _aelinUpFrontDeal;
        AELIN_ESCROW_LOGIC = _aelinEscrow;
        AELIN_TREASURY = _aelinTreasury;
    }

    function createUpFrontDeal(
        UpFrontDealData calldata _dealData,
        UpFrontDealConfig calldata _dealConfig,
        AelinNftGating.NftCollectionRules[] calldata _nftCollectionRules,
        AelinAllowList.InitData calldata _allowListInit
    ) external returns (address upFrontDealAddress) {
        require(_dealData.sponsor == msg.sender, "sponsor must be msg.sender");
        upFrontDealAddress = _cloneAsMinimalProxy(UP_FRONT_DEAL_LOGIC, "Could not create new deal");

        AelinUpFrontDeal(upFrontDealAddress).initialize(
            _dealData,
            _dealConfig,
            _nftCollectionRules,
            _allowListInit,
            AELIN_TREASURY,
            AELIN_ESCROW_LOGIC
        );

        emit CreateUpFrontDeal(
            upFrontDealAddress,
            string(abi.encodePacked("aeUpFrontDeal-", _dealData.name)),
            string(abi.encodePacked("aeUD-", _dealData.symbol)),
            _dealData.purchaseToken,
            _dealData.underlyingDealToken,
            _dealData.holder,
            _dealData.sponsor,
            _dealData.sponsorFee,
            _dealData.merkleRoot,
            _dealData.ipfsHash
        );

        emit CreateUpFrontDealConfig(
            upFrontDealAddress,
            _dealConfig.underlyingDealTokenTotal,
            _dealConfig.purchaseTokenPerDealToken,
            _dealConfig.purchaseRaiseMinimum,
            _dealConfig.purchaseDuration,
            _dealConfig.vestingPeriod,
            _dealConfig.vestingCliffPeriod,
            _dealConfig.allowDeallocation
        );
    }
}