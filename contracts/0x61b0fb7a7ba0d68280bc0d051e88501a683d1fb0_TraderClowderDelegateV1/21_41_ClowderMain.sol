// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.13;

// _________ .__                   .___
// \_   ___ \|  |   ______  _  ____| _/___________
// /    \  \/|  |  /  _ \ \/ \/ / __ |/ __ \_  __ \
// \     \___|  |_(  <_> )     / /_/ \  ___/|  | \/
//  \______  /____/\____/ \/\_/\____ |\___  >__|
//         \/                       \/    \/

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {BuyOrderV1, BuyOrderV1Functions} from "./libraries/passiveorders/BuyOrderV1.sol";
import {Execution} from "./libraries/execution/Execution.sol";
import {SafeERC20Transfer} from "./libraries/assettransfer/SafeERC20Transfer.sol";
import {SignatureUtil} from "./libraries/SignatureUtil.sol";
// import {OpenSeaUtil} from "./libraries/externalmarketplaces/OpenSeaUtil.sol";
// import {LooksRareUtil} from "./libraries/externalmarketplaces/LooksRareUtil.sol";
import {NftCollectionFunctions} from "./libraries/NftCollection.sol";
import {IClowderCallee} from "./interfaces/IClowderCallee.sol";
import {IClowderMain} from "./interfaces/IClowderMain.sol";

import {ITraderClowderDelegateV1} from "./delegates/trader/ITraderClowderDelegateV1.sol";


contract ClowderMainOwnable is Ownable {
    address public protocolFeeReceiver;
    uint256 public protocolFeeFraction = 100; // out of 10_000

    /**
     * @notice [onlyOwner] Change the protocol fee receiver
     * @param _protocolFeeReceiver new receiver
     */
    function changeProtocolFeeReceiver(
        address _protocolFeeReceiver
    ) external onlyOwner {
        protocolFeeReceiver = _protocolFeeReceiver;
    }

    /**
     * @notice [onlyOwner] Change the protocol fee fraction
     * @param _protocolFeeFraction new fee fraction (out of 10_000)
     */
    function changeProtocolFeeFraction(
        uint256 _protocolFeeFraction
    ) external onlyOwner {
        protocolFeeFraction = _protocolFeeFraction;
    }
}

contract ClowderMain is ClowderMainOwnable, ReentrancyGuard, IClowderMain {
    address public immutable WETH;
    bytes32 public immutable EIP712_DOMAIN_SEPARATOR;
    // TODO: remove when implementing delegate factory recognition;
    address public immutable delegateFactory;

    // user => nonce => isUsedBuyNonce
    mapping(address => mapping(uint256 => bool)) public isUsedBuyNonce;
    // buyer => executionId => real contribution
    // Returns to zero when the owner is given their part of the
    // sale proceeds (claimProceeds).
    mapping(address => mapping(uint256 => uint256)) public realContributions;
    // executionId => Execution
    mapping(uint256 => Execution) public executions;

    constructor(address _WETH, address _protocolFeeReceiver, address _delegateFactory) {
        WETH = _WETH;
        protocolFeeReceiver = _protocolFeeReceiver;
        delegateFactory = _delegateFactory;

        EIP712_DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ), // EIP712 domain typehash
                keccak256("Clowder"), // name
                keccak256(bytes("0.2")), // version
                block.chainid,
                address(this)
            )
        );
    }

    function cancelBuyOrders(uint256[] calldata buyOrderNonces) external {
        require(
            buyOrderNonces.length > 0,
            "Cancel: Must provide at least one nonce"
        );

        for (uint256 i = 0; i < buyOrderNonces.length; i++) {
            // if (!isUsedBuyNonce[msg.sender][buyOrderNonces[i]]) {
            isUsedBuyNonce[msg.sender][buyOrderNonces[i]] = true; // used
            // }
        }
    }

    /**
     * @notice Executes on an array of passive buy orders
     */
    function executeOnPassiveBuyOrders(
        BuyOrderV1[] calldata buyOrders,
        uint256 executorPrice,
        uint256 tokenId,
        bytes calldata data
    ) external nonReentrant {
        require(buyOrders.length > 0, "Execute: Must have at least one order");

        uint256 protocolFee = (protocolFeeFraction * executorPrice) / 10_000;
        uint256 price = executorPrice + protocolFee;

        require(
            executions[buyOrders[0].executionId].collection == address(0),
            "Execute: Id already executed"
        );
        // creating the execution object immediately (extra measure to prevent reentrancy)
        executions[buyOrders[0].executionId] = Execution({
            collection: buyOrders[0].collection,
            buyPrice: price,
            tokenId: tokenId
        });

        uint256 protocolFeeTransferred = 0;
        uint256 executorPriceTransferred = 0;

        // TODO: maybe save gas by tranferring weth only once per owner (signer)
        // Possibly receive the data grouped from outside blockchain to
        // save gas on the grouping?

        address[] memory owners = new address[](buyOrders.length);
        uint256[] memory contributions = new uint256[](buyOrders.length);
        uint256 ownersLength = 0;

        // validate and process all the buy orders
        for (uint256 i = 0; i < buyOrders.length; i++) {
            BuyOrderV1 calldata order = buyOrders[i];
            // Validate order nonce usability
            require(
                !isUsedBuyNonce[order.signer][order.buyNonce],
                "Order nonce is unusable"
            );
            // Invalidating order nonce immediately (to avoid reentrancy
            // or even reusing the signature in this loop)
            // DO NOT separate from the above check, otherwise the order
            // nonce could be reused. If you need separation
            // probably you can check the signer/nonces before "i".
            isUsedBuyNonce[order.signer][order.buyNonce] = true;
            // Validate order signature
            require(
                SignatureUtil.verify(
                    order.hash(),
                    order.signer,
                    order.v,
                    order.r,
                    order.s,
                    EIP712_DOMAIN_SEPARATOR
                ),
                "Signature: Invalid"
            );
            // Validate the order is not expired
            require(order.buyPriceEndTime >= block.timestamp, "Order expired");

            // Validate the order can accept the price
            require(order.canAcceptBuyPrice(price), "Order can't accept price");
            // Validate collection
            require(
                order.collection == buyOrders[0].collection,
                "Order collection mismatch"
            );
            // Validate executionId
            require(
                order.executionId == buyOrders[0].executionId,
                "Order executionId mismatch"
            );
            // Validate delegate
            require(
                order.delegate == buyOrders[0].delegate,
                "Order delegate mismatch"
            );

            uint256 contribution = order.contribution;

            // transferring the protocol fee
            uint256 protocolWethAmount = Math.min(
                protocolFee - protocolFeeTransferred,
                contribution
            );
            protocolFeeTransferred += protocolWethAmount;
            _safeTransferWETH(
                order.signer,
                protocolFeeReceiver,
                protocolWethAmount
            );

            // transferring the protocol executor price
            uint256 executorPriceAmount = Math.min(
                executorPrice - executorPriceTransferred,
                contribution - protocolWethAmount
            );
            executorPriceTransferred += executorPriceAmount;
            _safeTransferWETH(order.signer, msg.sender, executorPriceAmount);

            // adding to the real contribution of the signer
            uint256 realContribution = protocolWethAmount +
                executorPriceAmount;
            // check if exists on the owners array
            bool exists = false;
            for (uint256 j = 0; j < ownersLength; j++) {
                if (owners[j] == order.signer) {
                    contributions[j] += realContribution;
                    exists = true;
                    break;
                }
            }
            if (!exists) {
                owners[ownersLength] = order.signer;
                contributions[ownersLength] = realContribution;
                ownersLength++;
            }
        } // ends the orders for loop

        // filter out the owners with zero contributions
        uint256[] memory _contributions = new uint256[](ownersLength);
        address[] memory _owners = new address[](ownersLength);
        for (uint256 i = 0; i < ownersLength; i++) {
            _owners[i] = owners[i];
            _contributions[i] = contributions[i];
        }

        // validating that we transferred the correct amounts of WETH
        require(
            protocolFeeTransferred == protocolFee,
            "Protocol fee not transferred correctly"
        );
        require(
            executorPriceTransferred == executorPrice,
            "Executor price not transferred correctly"
        );

        // getting the actual delegate
        address actualDelegate = buyOrders[0].delegate;
        // TODO: factory recognition, I mean, check if delegate is a clowder delegate factory
        if (actualDelegate == address(0)) {

            // instantiate the trader clowder delegate here
            actualDelegate = ITraderClowderDelegateV1(
                // TODO: when factory recognition is ready just use buyOrders[0].delegate
                delegateFactory
            ).createNewClone(
                _owners,
                _contributions,
                price
            );
        } else {
            // otherwise we store the contributions in realContributions here
            for (uint256 i = 0; i < _owners.length; i++) {
                realContributions[_owners[i]][buyOrders[0].executionId] = _contributions[i];
            }
        }

        if (data.length > 0) {

            IClowderCallee(msg.sender).clowderCall(data);

            // make sure the delegate is the owner of the NFT
            require(
                NftCollectionFunctions.ownerOf(
                    buyOrders[0].collection,
                    tokenId
                ) == actualDelegate,
                "Delegate is not the owner of the NFT"
            );
        } else {
            // transferring the NFT
            NftCollectionFunctions.transferNft(
                buyOrders[0].collection,
                msg.sender,
                actualDelegate,
                tokenId
            );
        }
    }

    function _safeTransferWETH(
        address from,
        address to,
        uint256 amount
    ) internal {
        SafeERC20Transfer.safeERC20Transfer(WETH, from, to, amount);
    }
}