// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./Interfaces/ICrowdsale.sol";
import "./Whitelist.sol";
import "./LisaCrowdsaleBase.sol";

/**
 * @title Crowdsale
 * @notice Crowdsale is a contract for managing a token crowdsale for selling ArtToken (AT) tokens
 * for BaseToken (BT). USDC can be used as a base token. Deployer can specify start and end dates of the crowdsale,
 * along with the limits of purchase amount per transaction and total purchase amount per buyer.
 */
contract LisaCrowdsaleProportional is Initializable, LisaCrowdsaleBase {
    using SafeERC20 for IERC20;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bool private sellerProceedsClaimed = false;

    uint256 public presaleStartTimestamp;

    /*
     * @notice Initializes the crowdsale contract. Grants roles to the creator as a seller and whitelisters.
     */
    function initialize(
        CrowdsaleProportionalInitParams calldata params
    ) external initializer {
        require(params.rate > 0, "Crowdsale: rate is 0");
        require(
            params.sellerAddress != address(0),
            "Crowdsale: wallet is the zero address"
        );
        require(
            address(params.at) != address(0),
            "Crowdsale: at is the zero address"
        );
        require(
            address(params.bt) != address(0),
            "Crowdsale: bt is the zero address"
        );
        require(
            params.presaleStartDate <= params.startDate,
            "Crowdsale: presaleStartDate should be before startDate"
        );
        require(
            params.startDate < params.endDate,
            "Crowdsale: startDate should be before endDate"
        );
        require(
            params.sellerRetainedAmount <= params.crowdsaleAmount,
            "sellerRetainedAmount should be less than crowdsaleAmount"
        );
        rate = params.rate;
        totalPriceBT = costBT(params.crowdsaleAmount);
        targetSaleProceedsBT =
            totalPriceBT -
            costBT(params.sellerRetainedAmount);
        amountLeftAT = params.crowdsaleAmount - params.sellerRetainedAmount;
        require(
            maxPurchaseBT < targetSaleProceedsBT,
            "maxPurchaseBT should be less than targetSaleProceedsBT"
        );

        seller = params.sellerAddress;
        tokenAT = params.at;
        tokenBT = params.bt;
        presaleStartTimestamp = params.presaleStartDate;
        startTimestamp = params.startDate;
        endTimestamp = params.endDate;
        allocationsBT[params.sellerAddress] = costBT(
            params.sellerRetainedAmount
        );
        totalForSaleAT = params.crowdsaleAmount;
        settings = params.lisaSettings;
        protocolFeeAmount = params.protocolFeeAmount;
        minPurchaseBT = params.minParticipationBT;
        maxPurchaseBT = params.maxParticipationBT;
        if (params.sellerRetainedAmount > 0) {
            emit TokensReserved(params.sellerAddress, params.sellerRetainedAmount);
        }

        _grantRole(WHITELISTER_ROLE, _msgSender());
        _grantRole(SELLER_ROLE, params.sellerAddress);
        _grantRole(WHITELISTER_ROLE, params.sellerAddress);
    }

    /**
     * @dev This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     * @param amountBT amount of purchase in base tokens
     */
    function buyTokens(
        uint256 amountBT
    ) external nonReentrant onlyRole(PARTICIPANT_ROLE) {
        if (block.timestamp >= startTimestamp) {
            amountBT = amountBT + collectedBT > targetSaleProceedsBT
                ? targetSaleProceedsBT - collectedBT
                : amountBT;
        }
        _preValidatePurchase(_msgSender(), amountBT);

        uint256 amountATSimple = amountBT * rate;

        _updatePurchasingState(_msgSender(), amountATSimple, amountBT);

        _processPurchase(_msgSender(), amountBT);
        emit TokensReserved(_msgSender(), amountATSimple);

        _postValidatePurchase(_msgSender(), amountBT);
    }

    /**
     * @notice  Claim the sale proceeds. Can only be called once by the seller when the crowdsale is successful.
     * Transfers the sale proceeds BT tokens to the caller.
     */
    function claimSaleProceeds()
        public
        override
        nonReentrant
        returns (uint256)
    {
        require(
            seller == _msgSender(),
            "Can only claim from the seller() wallet"
        );
        require(
            status() == CrowdsaleStatus.SUCCESSFUL,
            "Crowdsale should be successful to claim sale proceeds"
        );
        require(
            sellerProceedsClaimed == false,
            "Crowdsale: already claimed sale proceeds"
        );
        uint256 amountBT = targetSaleProceedsBT;
        sellerProceedsClaimed = true;
        IERC20(tokenBT).safeTransfer(seller, amountBT);
        return amountBT;
    }

    /**
     * @notice  Claim the AT tokens. Can only be called by a participant or a seller.
     * Transfers the AT tokens to the caller and returns change in BT.
     */
    function claimTokens() public override nonReentrant returns (uint256) {
        require(
            status() == CrowdsaleStatus.SUCCESSFUL,
            "Crowdsale should be successful to claim tokens"
        );

        uint256 allocationAT = getAllocationFor(_msgSender());
        if (allocationAT == 0) {
            return 0;
        }
        if (_msgSender() == seller) {
            allocationsBT[_msgSender()] = 0;
            emit TokensClaimed(_msgSender(), allocationAT);
            tokenAT.safeTransfer(_msgSender(), allocationAT);
            return allocationAT;
        }
        uint256 allocationCostBT = (targetSaleProceedsBT *
            allocationsBT[_msgSender()]) / collectedBT;
        uint256 refundBT = allocationsBT[_msgSender()] - allocationCostBT;
        allocationsBT[_msgSender()] = 0;
        emit TokensClaimed(_msgSender(), allocationAT);
        tokenAT.safeTransfer(_msgSender(), allocationAT);
        if (refundBT > 0) {
            IERC20(tokenBT).safeTransfer(_msgSender(), refundBT);
            emit TokensRefunded(_msgSender(), refundBT);
        }
        return allocationAT;
    }

    // -------------------  INTERNAL, MUTATING  -------------------
    /**
     * @dev Updates token balances of crowdsale participants and the amount of tokens sold.
     * @param buyer Address receiving the tokens
     * @param amountBT Purchase amount in BaseTokens
     */
    function _updatePurchasingState(
        address buyer,
        uint256 amountAT,
        uint256 amountBT
    ) internal override {
        if (amountLeftAT >= amountAT) {
            amountLeftAT = amountLeftAT - amountAT;
        } else {
            amountLeftAT = 0;
        }
        collectedBT = collectedBT + amountBT;
        allocationsBT[buyer] += amountBT;
    }

    // -------------------  EXTERNAL, VIEW  -------------------

    /**
     * @notice  Returns the name of the crowdsale contract.
     * @return  byte32  Name of the crowdsale contract.
     */
    function name() public pure override returns (string memory) {
        return "LisaCrowdsaleProportional";
    }

    /**
     * @notice  Returns the crowdsale status at the moment of the call.
     * @dev     Uses current timestamp to compare against startTimestamp and endTimestamp.
     * @return  CrowdsaleStatus enum value.
     */
    function status() public view override returns (CrowdsaleStatus) {
        if (block.timestamp < presaleStartTimestamp) {
            return CrowdsaleStatus.NOT_STARTED;
        } else if (
            block.timestamp >= presaleStartTimestamp &&
            block.timestamp < startTimestamp
        ) {
            return CrowdsaleStatus.IN_PROGRESS;
        } else if (
            block.timestamp >= startTimestamp && block.timestamp <= endTimestamp
        ) {
            if (amountLeftAT > 0) {
                return CrowdsaleStatus.IN_PROGRESS;
            } else {
                return CrowdsaleStatus.SUCCESSFUL;
            }
        } else if (amountLeftAT > 0) {
            return CrowdsaleStatus.UNSUCCESSFUL;
        } else {
            return CrowdsaleStatus.SUCCESSFUL;
        }
    }

    /**
     * @notice  Returns AT allocation for a given buyer distributing tokens proportionally.
     * The seller gets full allocation (sellerRetainedAmount) even if the crowdsale is oversubscribed.
     * @param   buyer Buyer's address that participated in this crowdsale.
     * @return  uint256 Amount of AT tokens allocated for a given buyer.
     */
    function getAllocationFor(
        address buyer
    ) public view override returns (uint256) {
        if (buyer == seller) {
            return getTokenAmount(allocationsBT[buyer]);
        } else if (collectedBT > targetSaleProceedsBT) {
            uint256 totalAT = getTokenAmount(targetSaleProceedsBT);
            return (totalAT * allocationsBT[buyer]) / collectedBT;
        }
        return getTokenAmount(allocationsBT[buyer]);
    }

    /**
     * @notice  The amount of AT tokens available for a given buyer, taking into account their current allocation.
     * @dev     Does not take into account the total amount of AT tokens available for sale.
     * @param   buyer  Address of the buyer.
     * @return  uint256  Amount of AT tokens available for a given buyer.
     */
    function remainingToBuyAT(
        address buyer
    ) public view override returns (uint256) {
        return getTokenAmount(maxPurchaseBT - allocationsBT[buyer]);
    }

    // -------------------  INTERNAL, VIEW  -------------------
    /**
     * @dev Validation of an incoming purchase
     * @param buyer Address performing the token purchase
     * @param amountBT Amount of base tokens sent for purchase
     */
    function _preValidatePurchase(
        address buyer,
        uint256 amountBT
    ) internal view {
        require(
            allocationsBT[buyer] > 0 || amountBT >= minPurchaseBT,
            "Crowdsale: purchase amount is below the threshold"
        );
        require(
            allocationsBT[buyer] + amountBT <= maxPurchaseBT,
            "Crowdsale: purchase amount is above the threshold"
        );
        require(
            block.timestamp >= presaleStartTimestamp,
            "Crowdsale: participation before presale start date"
        );
        require(
            block.timestamp <= endTimestamp,
            "Crowdsale: participation after end date"
        );
        if (block.timestamp >= startTimestamp) {
            require(
                amountBT > 0 && collectedBT + amountBT <= targetSaleProceedsBT,
                "Crowdsale: no tokens left for sale"
            );
        }
    }

    /**
     * @dev Validation of an executed purchase.
     * @param buyer Address performing the token purchase
     * @param amountBT Total value of purchase in BT
     */
    function _postValidatePurchase(
        address buyer,
        uint256 amountBT
    ) internal view {
        assert(
            costBT(totalForSaleAT - amountLeftAT - getAllocationFor(seller)) <=
                collectedBT
        );
        assert(amountBT <= allocationsBT[buyer]);
        assert(getAllocationFor(buyer) <= getTokenAmount(maxPurchaseBT));
        assert(collectedBT <= IERC20(tokenBT).balanceOf(address(this)));
    }
}