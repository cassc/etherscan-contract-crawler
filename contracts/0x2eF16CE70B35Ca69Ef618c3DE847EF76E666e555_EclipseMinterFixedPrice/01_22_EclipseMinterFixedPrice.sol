// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import {Eclipse} from "../app/Eclipse.sol";
import {IEclipseERC721} from "../interface/IEclipseERC721.sol";
import {IEclipseMintGate} from "../interface/IEclipseMintGate.sol";
import {IEclipsePaymentSplitter} from "../interface/IEclipsePaymentSplitter.sol";
import {EclipseMinterBase, GateParams} from "./EclipseMinterBase.sol";

/**
 * @dev Eclipse Fixed Price Minter
 * Admin for collections deployed on {Eclipse}
 */

contract EclipseMinterFixedPrice is EclipseMinterBase {
    struct FixedPriceParams {
        address artist;
        uint48 startTime;
        uint48 endTime;
        uint256 price;
        uint24 maxSupply;
        GateParams gate;
    }
    mapping(address => uint256[]) public prices;
    event PricingSet(
        address collection,
        CollectionMintParams mint,
        uint256 price,
        uint8 index
    );

    constructor(address eclipse_) EclipseMinterBase(eclipse_) {}

    /**
     * @dev Set pricing for collection
     * @param collection contract address of the collection
     * @param data `FixedPriceParams` struct
     */
    function setPricing(
        address collection,
        address sender,
        bytes memory data
    ) external override onlyAdmin {
        FixedPriceParams memory params = abi.decode(data, (FixedPriceParams));
        CollectionMintParams[] storage col = collections[collection];
        address artist = params.artist;
        uint48 startTime = params.startTime;
        uint48 endTime = params.endTime;
        uint256 price = params.price;
        uint24 maxSupply = params.maxSupply;
        uint8 index = uint8(col.length);
        uint8 gateType = params.gate.gateType;
        address gateAddress = Eclipse(eclipse).gateTypes(gateType);

        checkParams(
            collection,
            artist,
            sender,
            startTime,
            endTime,
            maxSupply,
            price
        );

        IEclipseMintGate(gateAddress).addGateForCollection(
            collection,
            address(this),
            index,
            params.gate.gateCalldata
        );
        CollectionMintParams memory mintParams = CollectionMintParams(
            artist,
            startTime,
            endTime,
            maxSupply,
            gateAddress,
            gateType
        );
        col.push(mintParams);
        emit PricingSet(collection, mintParams, price, index);
    }

    function checkParams(
        address collection,
        address artist,
        address sender,
        uint256 startTime,
        uint256 endTime,
        uint256 maxSupply,
        uint256 price
    ) internal {
        require(sender == artist, "invalid collection");
        require(startTime > block.timestamp, "startTime too early");
        if (endTime != 0) {
            require(endTime > startTime, "endTime must be greater startTime");
        }
        require(maxSupply > 0, "maxSupply must be greater 0");
        require(price > 0, "price must be greater 0");
        prices[collection].push(price);
    }

    /**
     * @dev Mint a token
     * @param collection contract address of the collection
     */
    function mintOne(
        address collection,
        uint8 index
    ) external payable override {
        _checkState(collection, index);
        address user = _msgSender();
        address minter = address(this);
        address gate = collections[collection][index].gateAddress;
        _getAllowedMintsAndUpdate(collection, index, minter, gate, user, 1);
        IEclipseERC721(collection).mintOne(user);
        _splitPayment(collection, index, user, 1, msg.value);
    }

    /**
     * @dev Mint a token
     * @param collection contract address of the collection
     * @param amount amount of tokens to mint
     */
    function mint(
        address collection,
        uint8 index,
        uint24 amount
    ) external payable override {
        _checkState(collection, index);
        address user = _msgSender();
        address minter = address(this);
        address gate = collections[collection][index].gateAddress;
        uint24 allowedMints = _getAllowedMintsAndUpdate(
            collection,
            index,
            minter,
            gate,
            user,
            amount
        );
        IEclipseERC721(collection).mint(user, allowedMints);

        _splitPayment(
            collection,
            index,
            user,
            amount,
            (msg.value / amount) * allowedMints
        );
    }

    /**
     * @dev Internal function to forward funds to a {EclipsePaymentSplitter}
     */
    function _splitPayment(
        address collection,
        uint8 index,
        address sender,
        uint24 amount,
        uint256 value
    ) internal {
        uint256 msgValue = msg.value;
        require(
            msgValue >= getPrice(collection, index) * amount,
            "wrong amount sent"
        );
        address paymentSplitter = eclipse
            .store()
            .getPaymentSplitterForCollection(collection);
        IEclipsePaymentSplitter(paymentSplitter).splitPayment{value: value}();
        if (value != msgValue) {
            payable(sender).transfer(msgValue - value);
        }
    }

    /**
     * @dev Get collection pricing object
     * @param collection contract address of the collection
     */
    function getCollectionPricing(
        address collection
    ) external view returns (uint256[] memory) {
        return prices[collection];
    }

    /**
     * @dev Get price for collection
     * @param collection contract address of the collection
     */
    function getPrice(
        address collection,
        uint8 index
    ) public view override returns (uint256) {
        return prices[collection][index];
    }
}