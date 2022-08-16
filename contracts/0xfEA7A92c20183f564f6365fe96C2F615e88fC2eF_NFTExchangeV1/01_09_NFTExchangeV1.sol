// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NFTExchange.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/INFTify1155.sol";
import "../interfaces/INFTify721.sol";

contract NFTExchangeV1 is NFTExchange {
    using SafeERC20 for IERC20;

    uint256 private constant ERC_721 = 1;
    uint256 private constant ERC_1155 = 0;

    /**
     * @dev Buy from primary sale
     * data: [0] tokenID, [1] quantity, [2] sellOrderSupply, [3] sellOrderPrice, [4] enableMakeOffer
     * ------[5] buyingAmount, [6] tokenType, [7] partnerType, [8] partnerFee, [9] transactionType,
     * ------[10] storeFeeRatio, [11-...] payoutRatios
     * addr: [0] creator == artist, [1] tokenAddress, [2] collectionAddress, [3] signer, [4] storeAddress,
     * ------[5] receiver, [6---] payoutAddress
     * strs: [0] internalTxId
     * signatures: [0] nftBuyRequestSignture, [1] sellOrderSignature, [2] payoutSignature
     */
    function buyNowNative(
        uint256[] memory, /*data*/
        address[] memory, /*addr*/
        string[] memory, /*strs*/
        bytes[] memory /*signatures*/
    ) public payable reentrancyGuard {
        _delegatecall(buyHandler);
    }

    /**
     * @dev Accept offer
     * data: [0] tokenID, [1] quantity, [2] sellOrderSupply, [3] enableMakeOffer, [4] sellOrderPrice
     * ------[5] offerAmount, [6] offerPrice, [7] listingTime, [8] expirationTime, [9] tokenType,
     * ------[10] partnerType, [11] partnerFee, [12] storeFeeRatio, [13-...] payoutRatio
     * addr: [0] creator == artist, [1] contractAddress, [2] tokenAddress, [3] receiver, [4] signer,
     * ------[5] storeAddress, [6-...] payoutAddress
     * strs: [0] internalTxId
     * signatures: [0] nftAcceptOfferSignature, [1] sellOrderSignature, [2] makeOfferSignature, [3] payoutSignature
     */
    function acceptOffer(
        uint256[] memory, /*data*/
        address[] memory, /*addr*/
        string[] memory, /*strs*/
        bytes[] memory /*signatures*/
    ) public reentrancyGuard {
        _delegatecall(offerHandler);
    }

    /**
     * @dev Buy from secondary sale
     * data: [0] tokenID, [1] royaltyRatio, [2] sellOrderSupply, [3] sellOrderPrice, [4] enableMakeOffer,
     * ------[5] amount, [6] tokenType, [7] partnerType, [8] partnerFee, [9] transactionType,
     * ------[10] storeFeeRatio, [11-...] payoutRatios
     * addr: [0] creator == artist, [1] contractAddress, [2] tokenAddress, [3] seller, [4] signer,
     * ------[5] storeAddress, [6] receiver, [7---] payoutAddress
     * strs: [0] internalTxId
     * signatures: [0] nftResellSignature, [1] sellOrderSignature, [2] payoutSignature
     */
    function sellNowNative(
        uint256[] memory, /*data*/
        address[] memory, /*addr*/
        string[] memory, /*strs*/
        bytes[] memory /*signatures*/
    ) public payable reentrancyGuard {
        _delegatecall(sellHandler);
    }

    /**
     * @dev Cancel sale order
     * data: [0] saleOrderID, [1] saleOrderSupply, [2] type
     * addr: [0] signer
     * strs: [...] internalTxId
     * signatures: [0-...] saleOrderSignatures, cancelBatchSignature
     */
    function cancelSaleOrder(
        uint256[] memory, /*data*/
        address[] memory, /*addr*/
        string[] memory, /*strs*/
        bytes[] memory /*signatures*/
    ) public reentrancyGuard {
        _delegatecall(cancelHandler);
    }

    /**
     * @dev Cancel offer
     * data: [0] makeOfferID, [1] type
     * addr: [0] signer
     * strs: [0] internalTxId
     * signatures: [0] makeOfferSignature
     */
    function cancelOffer(
        uint256[] memory, /*data*/
        address[] memory, /*addr*/
        string[] memory, /*strs*/
        bytes[] memory /*signatures*/
    ) public reentrancyGuard {
        _delegatecall(cancelHandler);
    }

    function withdraw(
        address _to,
        address tokenAddress,
        uint256 _amount
    ) public onlyAdmins {
        require(tokenAddress != address(0), "Token address is zero");
        IERC20(tokenAddress).safeTransfer(_to, _amount);
    }

    function transferNFT(
        address collection,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        uint256 tokenType,
        bytes memory data
    ) public reentrancyGuard {
        require(msg.sender == address(this), "NFTify: only proxy contract");

        if (tokenType == ERC_721) {
            INFTify721(collection).safeTransferFrom(from, to, id, data);
        } else if (tokenType == ERC_1155) {
            INFTify1155(collection).safeTransferFrom(
                from,
                to,
                id,
                amount,
                data
            );
        }
    }

    /**
     * @dev Open box
     * data [0] box id, [1-...] token ids
     * addr [0] owner, [1] signer, [2] box's collection, [3-...] token's collection
     * strs [0] internalTxId
     * signatures [0] openBoxSignature, [1-...] boxSignatures
     */
    function openBox(
        uint256[] memory,
        address[] memory,
        string[] memory,
        bytes[] memory
    ) public reentrancyGuard {
        _delegatecall(boxUtils);
    }

    /**
     * @dev Execute meta transaction
     */
    function executeMetaTransaction(
        uint256[] memory, /* data */
        address[] memory, /* addrs */
        bytes[] memory, /* signatures */
        bytes32, /* requestType */
        uint8, /* v */
        bytes32, /* r */
        bytes32 /* s */
    ) public reentrancyGuard {
        _delegatecall(metaHandler);
    }

    /**
     * @dev Claim airdrop
     */
    function claimAirdrop(
        uint256[] memory,
        address[] memory,
        string[] memory,
        bytes[] memory
    ) public reentrancyGuard {
        _delegatecall(airdropHandler);
    }

    /**
     * @dev Cancel airdrop event
     */
    function cancelAirdropEvent(
        uint256[] memory,
        address[] memory,
        string[] memory,
        bytes[] memory
    ) public reentrancyGuard {
        _delegatecall(cancelHandler);
    }
}