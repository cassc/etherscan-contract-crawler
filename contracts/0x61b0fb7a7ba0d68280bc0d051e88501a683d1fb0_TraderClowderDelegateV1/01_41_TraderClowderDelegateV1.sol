// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.13;

import {ClowderMain} from "../../ClowderMain.sol";
import {SellOrderV1, SellOrderV1Functions} from "./passiveorders/SellOrderV1.sol";
import {TransferOrderV1, TransferOrderV1Functions, AssetType} from "../common/passiveorders/TransferOrderV1.sol";
import {SeaportUtil} from "./interactionutils/SeaportUtil.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ReservoirOracle} from "./external/reservoiroracle/ReservoirOracle.sol";
import {LiquidSplit} from "./external/liquidsplit/LiquidSplit.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeTransferLib} from "solady/src/utils/SafeTransferLib.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {ITraderClowderDelegateV1} from "./ITraderClowderDelegateV1.sol";

contract TraderClowderDelegateV1 is
    ReentrancyGuard,
    ReservoirOracle,
    LiquidSplit,
    ERC20,
    Initializable,
    ITraderClowderDelegateV1
{
    /* constants */
    uint256 public constant PERCENTAGE_SCALE_FOR_0XSPLITS = 1e6;
    uint256 public constant minConsensusForSellingOverFairPrice = 5_000; // out of 10_000
    uint256 public constant minConsensusForSellingUnderOrEqualFairPrice =
        10_000; // out of 10_000
    uint256 public constant minConsensusForAssetTransfer = 10_000; // out of 10_000
    uint32 public constant protocolFeeFractionFromSelling = 1e4; // out of PERCENTAGE_SCALE_FOR_0XSPLITS
    string public constant _name = "Clowder Delegate Shares";
    string public constant _symbol = "CDS";

    /* immutable variables */
    ClowderMain public immutable clowderMain;
    address public immutable reservoirOracleAddress;

    /* storage variables */

    bytes32 public EIP712_DOMAIN_SEPARATOR;

    // user => nonce => isUsableSellNonce
    mapping(address => mapping(uint256 => bool)) public isUsableSellNonce;

    // user => nonce => isUsableTransferlNonce
    mapping(address => mapping(uint256 => bool)) public isUsableTransferlNonce;


    /* libraries */
    using SafeTransferLib for address;

    constructor(
        address _clowderMain,
        address _reservoirOracleAddress,
        address _splitMain
    ) LiquidSplit(_splitMain) 
        ERC20("", "") // we don't set anything here as we don't use these values
        // because they are saved in storage and storage will be cleaned up on proxy clones (right?)
     {
        clowderMain = ClowderMain(_clowderMain);
        reservoirOracleAddress = _reservoirOracleAddress;
    }

    function createNewClone(
        address[] memory accounts,
        uint256[] memory contributions,
        uint256 totalContributions) public initializer returns (address) {

		EIP712_DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ), // EIP712 domain typehash
                keccak256("TraderClowderDelegate"), // name
                keccak256(bytes("0.1")), // version
                block.chainid,
                address(this)
            )
        );

        // mint ERC20 tokens to each owner
        uint256 accumulatedScaledToken = 0;
        for (uint256 i = 0; i < accounts.length; i++) {
            if (i != accounts.length - 1) {
                // the total supply must be
                // PERCENTAGE_SCALE_FOR_0XSPLITS
                uint256 scaledToken = (contributions[i] * PERCENTAGE_SCALE_FOR_0XSPLITS) /
                    totalContributions;
                accumulatedScaledToken += scaledToken;
                _mint(
                    accounts[i],
                    scaledToken
                );
            } else {
                // last one
                _mint(
                    accounts[i],
                    PERCENTAGE_SCALE_FOR_0XSPLITS - accumulatedScaledToken
                );
            }
        }

        _createSplit();

        return address(this);
	}

    // To be able to receive NFTs
    // Note: parameters must stay as it is a standard
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    // to be able to receive eth
    receive() external payable {}

    function cancelSellOrders(uint256[] calldata sellOrderNonces) external {
        require(
            sellOrderNonces.length > 0,
            "Cancel: Must provide at least one nonce"
        );

        for (uint256 i = 0; i < sellOrderNonces.length; i++) {
            isUsableSellNonce[msg.sender][sellOrderNonces[i]] = true; // cancelled
        }
    }

    function cancellTransferOrders(uint256[] calldata transferOrderNonces)
        external
    {
        require(
            transferOrderNonces.length > 0,
            "Cancel: Must provide at least one nonce"
        );

        for (uint256 i = 0; i < transferOrderNonces.length; i++) {
            isUsableTransferlNonce[msg.sender][transferOrderNonces[i]] = true; // cancelled
        }
    }

    function listOnSeaport(
        SellOrderV1[] calldata orders,
        Message calldata message
    ) external nonReentrant {
        require(
            orders.length > 0,
            "ListOnMarketplace: Must have at least one order"
        );

        /* Validations */

        uint256 fairPrice = verifyReservoirPrice(orders[0].collection, message);
        // TODO: ratify by Clowder oracle

        (
            uint256 minExpirationTime,
            uint256 maxOfMinProceeds,
            uint256 realContributionOnBoard
        ) = SellOrderV1Functions.validateSellOrdersParameters(
                isUsableSellNonce,
                this,
                orders
            );

        validatePriceConsensus(
            fairPrice,
            maxOfMinProceeds,
            realContributionOnBoard
        );

        // Includes interaction with
        // other contracts
        SellOrderV1Functions.validateSignatures(
            orders,
            EIP712_DOMAIN_SEPARATOR
        );

        SeaportUtil.approveConduitForERC721(
            orders[0].conduitController,
            orders[0].conduitKey,
            orders[0].collection,
            orders[0].tokenId
        );

        SeaportUtil.listERC721(orders[0], minExpirationTime, maxOfMinProceeds);
    }

    function transferAsset(
        TransferOrderV1[] calldata orders
    ) external nonReentrant {
        require(
            orders.length > 0,
            "Transfer: Must have at least one order"
        );

        /* Validations */
        (
            uint256 realContributionOnBoard
        ) = TransferOrderV1Functions.validateTransferOrdersParameters(
                isUsableTransferlNonce,
                this,
                orders
        );

        // validate consensus
        require(
            realContributionOnBoard * 10_000 >=
                totalSupply() * minConsensusForAssetTransfer,
            "Transfer: consensus not reached"
        );

        // Includes interaction with
        // other contracts
        TransferOrderV1Functions.validateSignatures(
            orders,
            EIP712_DOMAIN_SEPARATOR
        );

        // transfer the asset
        if (orders[0].assetType == AssetType.NATIVE) {
            orders[0].recipient.safeTransferETH(address(this).balance);

        } else if (orders[0].assetType == AssetType.ERC20) {
            orders[0].token.safeTransfer(
                orders[0].recipient,
                ERC20(orders[0].token).balanceOf(address(this))
            );

        } else if (orders[0].assetType == AssetType.ERC721) {
            IERC721(orders[0].token).safeTransferFrom(
                address(this),
                orders[0].recipient,
                orders[0].tokenId);

        } else if (orders[0].assetType == AssetType.ERC1155) {
            IERC1155(orders[0].token).safeTransferFrom(
                address(this),
                orders[0].recipient,
                orders[0].tokenId,
                IERC1155(orders[0].token).balanceOf(address(this), orders[0].tokenId),
                ""
                );
                
        } else {
            revert("Transfer: asset type not supported");
        }
    }

    function validatePriceConsensus(
        uint256 fairPrice,
        uint256 maxOfMinProceeds,
        uint256 realContributionOnBoard
    ) internal view {

        // Validating price consensus
        if (maxOfMinProceeds > fairPrice) {
            if (minConsensusForSellingOverFairPrice == 10_000) {
                // we need 10_000 out of 10_000 consensus
                require(
                    realContributionOnBoard == totalSupply(),
                    "Selling over fairPrice: consensus not reached"
                );
            } else {
                // we need more than N out of 10_000 consensus
                require(
                    realContributionOnBoard * 10_000 >
                        totalSupply() * minConsensusForSellingOverFairPrice,
                    "Selling over fairPrice: consensus not reached"
                );
            }
        } else {
            // we need a different consensus ratio
            require(
                realContributionOnBoard * 10_000 >=
                    totalSupply() * minConsensusForSellingUnderOrEqualFairPrice,
                "Selling u/e fairPrice: consensus not reached"
            );
        }
    }

    function verifyReservoirPrice(
        address collection,
        Message calldata message
    ) internal view returns (uint256) {
        // Construct the message id using EIP-712 structured-data hashing
        bytes32 id = keccak256(
            abi.encode(
                keccak256(
                    // from: https://github.com/reservoirprotocol/indexer/blob/main/packages/indexer/src/api/endpoints/oracle/get-collection-floor-ask/v6.ts
                    // If you change the version don't forget to change backend too
                    "ContractWideCollectionPrice(uint8 kind,uint256 twapSeconds,address contract,bool onlyNonFlaggedTokens)"
                ),
                PriceKind.TWAP,
                24 hours,
                collection,
                false
            )
        );

        // Validate the message
        uint256 maxMessageAge = 5 minutes;
        if (
            !_verifyMessage(id, maxMessageAge, message, reservoirOracleAddress)
        ) {
            revert InvalidMessage();
        }

        (address messageCurrency, uint256 price) = abi.decode(
            message.payload,
            (address, uint256)
        );
        require(
            0x0000000000000000000000000000000000000000 == messageCurrency,
            "Wrong currency"
        );

        return price;
    }

    function distributorFee() public pure override returns (uint32) {
        return protocolFeeFractionFromSelling;
    }

    function distributorAddress() public view override returns (address) {
        return clowderMain.protocolFeeReceiver();
    }

    function scaledPercentBalanceOf(
        address account
    ) public view override returns (uint32) {
        return uint32(balanceOf(account));
    }

    function decimals() public pure override returns (uint8) {
        return 4;
    }
    function name() public pure override returns (string memory) {
        return _name;
    }
    function symbol() public pure override returns (string memory) {
        return _symbol;
    }
}