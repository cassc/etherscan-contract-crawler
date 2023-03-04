// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Module, Enum} from "@gnosis.pm/zodiac/contracts/core/Module.sol";
import {SailHelper} from "szns/lib/SailHelper.sol";
import {IBuyEvents} from "szns/interfaces/IBuyEvents.sol";
import {IBuyActions} from "szns/interfaces/IBuyActions.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ConsiderationInterface} from "seaport/interfaces/ConsiderationInterface.sol";
import {Order, ItemType, ConsiderationItem} from "seaport/lib/ConsiderationStructs.sol";

contract BuyModule is Module, IBuyEvents, IBuyActions {
    SailHelper private immutable sailHelper;

    error NFTAlreadyOwn();
    error NFTNotOwn();
    error NFTNotAllowed();
    error NotNativeToken();
    error ZeroAddressBuyModule();

    mapping(address => bool) public nfts;
    bool public enforceBuyRestrictions;

    constructor(
        address _sailHelper // Seaport Address
    ) {
        if (_sailHelper == address(0)) revert ZeroAddressBuyModule();
        sailHelper = SailHelper(_sailHelper);
    }

    /**
     * @dev Initialize function, will be triggered when a new proxy is deployed
     * @param initializeParams Parameters of initialization encoded
     * @notice This function will initialize the contract, including setting the avatar, target, and allowed NFTs.
     * @notice This function will also transfer ownership of the contract to the provided avatar address.
     */
    function setUp(
        bytes memory initializeParams
    ) public virtual override initializer {
        __Ownable_init();
        (address _avatar, address _target, address[] memory _nfts) = abi.decode(
            initializeParams,
            (address, address, address[])
        );

        _setNFTs(_nfts);

        setAvatar(_avatar);
        setTarget(_target);
        transferOwnership(_avatar);
    }

    /**
     * @dev This function sets up the NFTs that can be bought using the smart contract.
     * @param _nfts An array of addresses representing the NFTs that can be bought.
     */
    function _setNFTs(address[] memory _nfts) internal {
        uint256 length = _nfts.length;
        for (uint256 i = 0; i < length; ) {
            nfts[_nfts[i]] = true;
            unchecked {
                ++i;
            }
        }
    }

    function _setEnforceBuyRestrictions(bool _enforceBuyRestrictions) internal {
        enforceBuyRestrictions = _enforceBuyRestrictions;
    }

    /**
     * @dev This function allows a user to buy an NFT from an exchange, like OpenSea.
     * @param seaportOrder The order object containing the details of the NFT being bought.
     * @notice Revert if the NFT is not allowed to be bought, if the NFT is already owned by the contract, or if the purchase is unsuccessful.
     * @notice Emit NFTBought event on successful purchase.
     */
    function buy(Order calldata seaportOrder) public virtual {
        address nftContract = seaportOrder.parameters.offer[0].token;
        uint256 tokenID = seaportOrder.parameters.offer[0].identifierOrCriteria;

        if (seaportOrder.parameters.offer.length != 1) {
            revert NFTNotAllowed();
        }

        // By default listings made through opensea have 2 considerations:
        // (1) the offerer consideration and (2) opensea fee, another thing may be royalties to collection creator
        uint256 value = 0;
        unchecked {
            for (
                uint256 i = 0;
                i < seaportOrder.parameters.consideration.length;
                i++
            ) {
                ConsiderationItem memory consideration = seaportOrder
                    .parameters
                    .consideration[i];

                //Check consideration was set to ETH
                if (
                    consideration.token != address(0) ||
                    consideration.itemType != ItemType.NATIVE
                ) {
                    revert NotNativeToken();
                }
                value += seaportOrder.parameters.consideration[i].startAmount;
            }
        }

        if (!nfts[nftContract] && enforceBuyRestrictions) {
            revert NFTNotAllowed();
        }

        if (IERC721(nftContract).ownerOf(tokenID) == address(avatar)) {
            revert NFTAlreadyOwn();
        }

        bytes memory callData = abi.encodeCall(
            ConsiderationInterface(sailHelper.seaport()).fulfillOrder,
            (seaportOrder, bytes32(0))
        );

        (bool _success, bytes memory _returnData) = execAndReturnData(
            sailHelper.seaport(),
            value,
            callData,
            Enum.Operation.Call
        );

        require(_success, string(_returnData));

        if (IERC721(nftContract).ownerOf(tokenID) != address(avatar)) {
            revert NFTNotOwn();
        }

        emit NFTBought(block.timestamp, value, nftContract, tokenID);
    }
}