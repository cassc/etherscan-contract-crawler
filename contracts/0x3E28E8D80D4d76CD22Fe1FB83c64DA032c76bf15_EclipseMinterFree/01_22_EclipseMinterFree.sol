// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import {Eclipse} from "../app/Eclipse.sol";
import {IEclipseERC721} from "../interface/IEclipseERC721.sol";
import {IEclipseMintGate} from "../interface/IEclipseMintGate.sol";
import {IEclipsePaymentSplitter} from "../interface/IEclipsePaymentSplitter.sol";
import {EclipseMinterBase, GateParams} from "./EclipseMinterBase.sol";

/**
 * @dev Eclipse Free Minter
 * Admin for collections deployed on {Eclipse}
 */

contract EclipseMinterFree is EclipseMinterBase {
    struct FreeParams {
        address artist;
        uint48 startTime;
        uint48 endTime;
        uint24 maxSupply;
        GateParams gate;
    }

    event PricingSet(
        address collection,
        CollectionMintParams mint,
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
        FreeParams memory params = abi.decode(data, (FreeParams));
        CollectionMintParams[] storage col = collections[collection];
        address artist = params.artist;
        uint48 startTime = params.startTime;
        uint48 endTime = params.endTime;
        uint24 maxSupply = params.maxSupply;
        uint8 index = uint8(col.length);
        uint8 gateType = params.gate.gateType;
        address gateAddress = Eclipse(eclipse).gateTypes(gateType);

        checkParams(artist, sender, startTime, endTime, maxSupply);

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
        emit PricingSet(collection, mintParams, index);
    }

    function checkParams(
        address artist,
        address sender,
        uint48 startTime,
        uint48 endTime,
        uint24 maxSupply
    ) internal view {
        require(sender == artist, "invalid collection");
        require(startTime > block.timestamp, "startTime too early");
        if (endTime != 0) {
            require(endTime > startTime, "endTime must be greater startTime");
        }
        require(maxSupply > 0, "maxSupply must be greater 0");
    }

    /**
     * @dev Get price for collection
     */
    function getPrice(address, uint8) public pure override returns (uint256) {
        return 0;
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
    }

    /**
     * @dev Get collection pricing object
     */
    function getCollectionPricing(address) external pure returns (uint256) {
        return 0;
    }
}