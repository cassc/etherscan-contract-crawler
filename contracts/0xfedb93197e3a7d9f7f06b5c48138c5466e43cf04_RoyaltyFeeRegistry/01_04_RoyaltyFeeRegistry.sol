// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IRoyaltyFeeRegistry} from "../interfaces/IRoyaltyFeeRegistry.sol";

/**
 * @title RoyaltyFeeRegistry
 * @notice It is a royalty fee registry for the CryptoAvatars exchange.
 */
contract RoyaltyFeeRegistry is IRoyaltyFeeRegistry, Ownable {
    struct FeeInfo {
        address setter;
        address receiver;
        uint256 fee;
    }

    // Limit (if enforced for fee royalty in percentage (10,000 = 100%)
    uint256 public royaltyFeeLimit;
    uint256 public royaltyRemixCreator;
    uint256 public royaltyRemixOwner;

    mapping(address => FeeInfo) private _royaltyFeeInfoCollection;

    event NewRoyaltyFeeLimit(uint256 royaltyFeeLimit);
    event NewRoyaltyRemixCreator(uint256 royaltyRemixCreator);
    event NewRoyaltyRemixOwner(uint256 royaltyRemixOwner);
    event RoyaltyFeeUpdate(address indexed collection, address indexed setter, address indexed receiver, uint256 fee);

    /**
     * @notice Constructor
     * @param _royaltyFeeLimit new royalty fee limit (500 = 5%, 1,000 = 10%)
     */
    constructor(uint256 _royaltyFeeLimit) {
        require(_royaltyFeeLimit <= 9500, "Owner: Royalty fee limit too high");
        royaltyFeeLimit = _royaltyFeeLimit;
    }

    /**
     * @notice Update royalty info for the creator of the parent avatar remix 
     * @param _royalty new royalty fee limit (500 = 5%, 1,000 = 10%)
     */
    function updateRoyaltyRemixCreator(uint256 _royalty) external override onlyOwner {
        require(_royalty <= 9500, "Owner: Royalty fee limit too high");
        royaltyRemixCreator = _royalty;
        emit NewRoyaltyRemixCreator(_royalty);
    }

    /**
     * @notice Update royalty info for the owner of the parent avatar remix 
     * @param _royalty new royalty fee limit (500 = 5%, 1,000 = 10%)
     */
    function updateRoyaltyRemixOwner(uint256 _royalty) external override onlyOwner {
        require(_royalty <= 9500, "Owner: Royalty fee limit too high");
        royaltyRemixOwner = _royalty;
        emit NewRoyaltyRemixOwner(_royalty);
    }

    /**
     * @notice Update royalty info for collection
     * @param _royaltyFeeLimit new royalty fee limit (500 = 5%, 1,000 = 10%)
     */
    function updateRoyaltyFeeLimit(uint256 _royaltyFeeLimit) external override onlyOwner {
        require(_royaltyFeeLimit <= 9500, "Owner: Royalty fee limit too high");
        royaltyFeeLimit = _royaltyFeeLimit;

        emit NewRoyaltyFeeLimit(_royaltyFeeLimit);
    }

    /**
     * @notice Update royalty info for collection
     * @param collection address of the NFT contract
     * @param setter address that sets the receiver
     * @param receiver receiver for the royalty fee
     * @param fee fee (500 = 5%, 1,000 = 10%)
     */
    function updateRoyaltyInfoForCollection(
        address collection,
        address setter,
        address receiver,
        uint256 fee
    ) external override onlyOwner {
        require(fee <= royaltyFeeLimit, "Registry: Royalty fee too high");
        _royaltyFeeInfoCollection[collection] = FeeInfo({setter: setter, receiver: receiver, fee: fee});

        emit RoyaltyFeeUpdate(collection, setter, receiver, fee);
    }

    /**
     * @notice Calculate royalty info for a collection address and a sale gross amount
     * @param collection collection address
     * @param amount amount
     * @return receiver address and amount received by royalty recipient
     */
    function royaltyInfo(address collection, uint256 amount) external view override returns (address, uint256) {
        return (
            _royaltyFeeInfoCollection[collection].receiver,
            (amount * _royaltyFeeInfoCollection[collection].fee) / 10000
        );
    }

     /**
     * @notice Get remix creator royalty info
     */    function getRemixCreatorRoyaltyFee() external view override returns(uint256){
        return royaltyRemixCreator;
    }

    /**
     * @notice Get remix owner royalty info
     */    function getRemixOwnerRoyaltyFee() external view override returns(uint256){
        return royaltyRemixOwner;
    }



    /**
     * @notice View royalty info for a collection address
     * @param collection collection address
     */
    function royaltyFeeInfoCollection(address collection)
        external
        view
        override
        returns (
            address,
            address,
            uint256
        )
    {
        return (
            _royaltyFeeInfoCollection[collection].setter,
            _royaltyFeeInfoCollection[collection].receiver,
            _royaltyFeeInfoCollection[collection].fee
        );
    }
}