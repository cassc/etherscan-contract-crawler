// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import { ConsiderationInterface } from "./seaport/interfaces/ConsiderationInterface.sol";

import "./interfaces/IEscrowBuyer.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev For basic orders involving ETH / native / ERC20 <=> ERC721 / ERC1155
 *      matching, a group of six functions may be called that only requires a
 *      subset of the usual order arguments. Note the use of a "basicOrderType"
 *      enum; this represents both the usual order type as well as the "route"
 *      of the basic order (a simple derivation function for the basic order
 *      type is `basicOrderType = orderType + (4 * basicOrderRoute)`.)
 */
/*struct BasicOrderParameters {
    // calldata offset
    address considerationToken; // 0x24  ether
    uint256 considerationIdentifier; // 0x44
    uint256 considerationAmount; // 0x64
    address payable offerer; // 0x84
    address zone; // 0xa4
    address offerToken; // 0xc4   nft 
    uint256 offerIdentifier; // 0xe4
    uint256 offerAmount; // 0x104
    BasicOrderType basicOrderType; // 0x124
    uint256 startTime; // 0x144
    uint256 endTime; // 0x164
    bytes32 zoneHash; // 0x184
    uint256 salt; // 0x1a4
    bytes32 offererConduitKey; // 0x1c4
    bytes32 fulfillerConduitKey; // 0x1e4
    uint256 totalOriginalAdditionalRecipients; // 0x204
    AdditionalRecipient[] additionalRecipients; // 0x224
    bytes signature; // 0x244
    // Total length, excluding dynamic array data: 0x264 (580)
}
*/

import { BasicOrderParameters } from "./seaport/lib/ConsiderationStructs.sol";

contract SeaportEscrowBuyer is
    Initializable,
    OwnableUpgradeable,
    IERC721ReceiverUpgradeable,
    IEscrowBuyer
{
    address public immutable EXCHANGE;

    AssetReceiptRegister public assetReceiptRegister; // a mutex

    struct AssetReceiptRegister {
        address assetContractAddress;
        uint256 assetTokenId;
        uint256 quantity;
    }

    constructor(address _exchange) {
        EXCHANGE = _exchange;
    }

    function initialize() external initializer {
        __Ownable_init();
    }

    /**
     * @notice Purchase an NFT and escrow it in this contract.
     * @param parameters Seaport Protocol order parameters.
     */
    function fulfillBasicOrderWithEth(BasicOrderParameters calldata parameters)
        public
        payable
        onlyOwner
        returns (bool)
    {
        resetAssetReceiptRegister();

        return
            ConsiderationInterface(EXCHANGE).fulfillBasicOrder{
                value: msg.value
            }(parameters);
    }

     function fulfillBasicOrderWithToken(BasicOrderParameters calldata parameters, uint256 totalPurchasePrice)
        public
        onlyOwner
        returns (bool)
    {
        resetAssetReceiptRegister();

        address paymentToken = parameters.considerationToken;

        IERC20(paymentToken).approve(EXCHANGE,totalPurchasePrice);

        return
            ConsiderationInterface(EXCHANGE).fulfillBasicOrder(parameters);
    }

    /**
     * @notice Transfer the NFT from escrow to a users wallet.
     * @param tokenAddress The NFT contract address.
     * @param tokenId The NFT token ID.
     * @param tokenType The type of NFT asset
     * @param amount The amount of NFT asset quantity (1 if not 1155)
     * @param recipient The address that will receive the NFT.
     */
    function claimNFT(
        address tokenAddress,
        uint256 tokenId,
        IBNPLMarket.TokenType tokenType,
        uint256 amount,
        address recipient
    ) external onlyOwner returns (bool) {
        if (tokenType == IBNPLMarket.TokenType.ERC1155) {
            bytes memory data;

            IERC1155Upgradeable(tokenAddress).safeTransferFrom(
                address(this),
                recipient,
                tokenId,
                amount,
                data
            );
            return true;
        } else {
            IERC721Upgradeable(tokenAddress).safeTransferFrom(
                address(this),
                recipient,
                tokenId
            );
            return true;
        }
    }

    /**
     * @notice A read-only method to validate that an NFT is escrowed in this contract
     * @param assetContractAddress The NFT contract address.
     * @param assetTokenId The NFT token ID.
     * @param quantity The amount of NFT asset quantity (1 if not 1155).
     * @param tokenType The type of NFT asset.
     */
    function hasOwnershipOfAsset(
        address assetContractAddress,
        uint256 assetTokenId,
        uint256 quantity,
        IBNPLMarket.TokenType tokenType
    ) public view returns (bool) {
        if (tokenType == IBNPLMarket.TokenType.ERC721) {
            address currentOwner = IERC721Upgradeable(assetContractAddress)
                .ownerOf(assetTokenId);

            return address(this) == currentOwner;
        } else {
            //require asset handshake registry values and reset them for 1155
            bool valid = _validateAssetReceiptRegister(
                assetContractAddress,
                assetTokenId,
                quantity
            );

            return valid;
        }
    }

    //Asset Receipt Registers

    /**
     * @notice Sets a temporary mutex for tracking receipt of an NFT asset.
     * @param _assetContractAddress The contract address for the NFT asset.
     * @param _assetTokenId The token id for the NFT asset.
     * @param _quantity The quantity of the NFT asset. Always 1 for ERC721.
     */
    function setAssetReceiptRegister(
        address _assetContractAddress,
        uint256 _assetTokenId,
        uint256 _quantity
    ) internal {
        assetReceiptRegister = AssetReceiptRegister({
            assetContractAddress: _assetContractAddress,
            assetTokenId: _assetTokenId,
            quantity: _quantity
        });
    }

    /**
     * @notice Reset the temporary mutex for tracking receipt of an NFT asset.
     */
    function resetAssetReceiptRegister() internal {
        delete assetReceiptRegister;
    }

    /**
     * @notice Verifies the state of the a temporary mutex for tracking receipt of an NFT asset.
     * @param _assetContractAddress The contract address for the NFT asset.
     * @param _assetTokenId The token id for the NFT asset.
     * @param _quantity The quantity of the NFT asset. Always 1 for ERC721.
     */
    function _validateAssetReceiptRegister(
        address _assetContractAddress,
        uint256 _assetTokenId,
        uint256 _quantity
    ) internal view returns (bool) {
        return
            (assetReceiptRegister.assetContractAddress ==
                _assetContractAddress) &&
            (assetReceiptRegister.assetTokenId == _assetTokenId &&
                assetReceiptRegister.quantity == _quantity);
    }

    //On NFT Recieved handlers

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    function onERC1155Received(
        address,
        address,
        uint256 id,
        uint256 value,
        bytes calldata
    ) external returns (bytes4) {
        setAssetReceiptRegister(msg.sender, id, value);

        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata
    ) external returns (bytes4) {
        require(
            _ids.length == 1,
            "Only allowed one asset batch transfer per transaction."
        );

        setAssetReceiptRegister(msg.sender, _ids[0], _values[0]);

        return
            bytes4(
                keccak256(
                    "onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"
                )
            );
    }
}