// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./IGetRoyalties.sol";

contract FeeProvider is Ownable {
    /**
     * @dev Emitted when changing `MarketplaceFee` for a `collection`.
     */
    event MarketplaceFeeChanged(
        address indexed colection,
        uint16 buyerFee,
        uint16 sellerFee
    );

    /**
     * @dev Emitted when changing `customCollectionRoyalties` for a `collection`.
     */
    event CollectionRoyaltiesChanged(address indexed colection);

    struct MarketplaceFee {
        bool customFee;
        uint16 buyerFee;
        uint16 sellerFee;
    }

    struct CollectionRoyalties {
        address payable[] recipients;
        uint16[] fees;
    }

    bytes4 private INTERFACE_ID_FEES = 0xb7799584;
    address private feesBeneficiary;

    mapping(address => MarketplaceFee) private marketplaceCollectionFee;
    mapping(address => CollectionRoyalties) private customCollectionRoyalties;

    constructor() {
        feesBeneficiary = _msgSender();
        marketplaceCollectionFee[address(0)] = MarketplaceFee(true, 0, 250);
    }

    /**
     * @dev external function that returns fees beneficiary address
     */
    function getFeesBeneficiary() external view returns (address) {
        return _getFeesBeneficiary();
    }

    /**
     * @dev internal function that returns fees beneficiary address
     */
    function _getFeesBeneficiary() internal view returns (address) {
        return feesBeneficiary;
    }

    /**
     * @dev external function that returns marketplace fee for a collection
     *
     * @param collection  address of a collection to check
     */
    function getMarketplaceFee(
        address collection
    ) external view returns (MarketplaceFee memory) {
        return _getMarketplaceFee(collection);
    }

    /**
     * @dev internal function that returns marketplace fee for a collection
     *
     * @param collection  address of a collection to check
     */
    function _getMarketplaceFee(
        address collection
    ) internal view returns (MarketplaceFee memory) {
        if (marketplaceCollectionFee[collection].customFee) {
            return marketplaceCollectionFee[collection];
        }
        return marketplaceCollectionFee[address(0)];
    }

    /**
     * @dev external function that returns royalties for a token
     *
     * @param collection  address of a collection of a token
     * @param id          id of token
     */
    function getRoyalties(
        address collection,
        uint256 id
    )
        external
        view
        returns (address payable[] memory recipients, uint16[] memory fees)
    {
        return _getRoyalties(collection, id);
    }

    /**
     * @dev internal function that returns royalties for a token
     *
     * @param collection  address of a collection of a token
     * @param id          id of token
     */
    function _getRoyalties(
        address collection,
        uint256 id
    )
        internal
        view
        returns (address payable[] memory recipients, uint16[] memory fees)
    {
        if (IERC165(collection).supportsInterface(INTERFACE_ID_FEES)) {
            IGetRoyalties collection = IGetRoyalties(collection);
            return (collection.getFeeRecipients(id), collection.getFeeBps(id));
        }
        return (
            customCollectionRoyalties[collection].recipients,
            customCollectionRoyalties[collection].fees
        );
    }

    /**
     * @dev external function that returns custom royalties for a collection
     *
     * @param collection  address of a collection
     */
    function getCustomRoyalties(
        address collection
    ) external view returns (CollectionRoyalties memory) {
        return customCollectionRoyalties[collection];
    }

    /**
     * @dev change fees beneficiary
     */
    function changeFeesBeneficiary(
        address newFeesBeneficiary
    ) external onlyOwner {
        feesBeneficiary = newFeesBeneficiary;
    }

    /**
     * @dev change collection fees
     */
    function changeMarketplaceCollectionFee(
        address collection,
        uint16 buyerFee,
        uint16 sellerFee
    ) external onlyOwner {
        require(
            sellerFee < 10000 && buyerFee < 10000,
            "FeeProvider: wrong fee amount"
        );

        delete marketplaceCollectionFee[collection];
        if (buyerFee + sellerFee > 0) {
            marketplaceCollectionFee[collection] = MarketplaceFee(
                true,
                buyerFee,
                sellerFee
            );
        }
        emit MarketplaceFeeChanged(collection, buyerFee, sellerFee);
    }

    /**
     * @dev change custom collection royalties
     */
    function changeCollectionRoyalties(
        address collection,
        address payable[] calldata recipients,
        uint16[] calldata amounts
    ) external onlyOwner {
        require(collection != address(0), "FeeProvider: wrong collection");
        require(
            recipients.length == amounts.length,
            "FeeProvider: wrong params length"
        );

        delete customCollectionRoyalties[collection];
        if (amounts.length > 0) {
            customCollectionRoyalties[collection] = CollectionRoyalties(
                recipients,
                amounts
            );
        }

        emit CollectionRoyaltiesChanged(collection);
    }

    /**
     * @dev used to calculate royalty fees and marketplace fees
     */
    function calculateFee(
        uint256 _amount,
        uint16 _fee
    ) internal pure returns (uint256) {
        return (_amount * _fee) / 10000;
    }
}