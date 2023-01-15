// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./ValidatorRelayer.sol";
import "./Structs.sol";
import "./PriceManager.sol";
import "../interfaces/IRewardMananger.sol";
import "../interfaces/IERC20.sol";

abstract contract NFTBase is ERC721A, ERC721AQueryable, Ownable, PriceManager, ValidatorRelayer {
    struct OrderItem {
        uint256 upgradeId;
        NFT nft;
        bool payReward;
    }

    uint256 public endDate;
    string public baseUri;
    address private _payoutAddress;

    IRewardMananger rewardManager;

    mapping(uint256 => NFT) public nftById;
    mapping(uint256 => bool) public orderPayed;
    mapping(address => uint256) public countFreemint;

    event NFTRedeemed(uint256 orderId, address user, uint256 id, NFT nft);

    error FreeMintLimit();
    error InsufficientAmount();
    error InsufficientPaided();
    error NotOwner();
    error NotInTime();
    error AlreadyRedeemed();
    error AlreadyPaid();
    error NoRewardManager();

    uint256 public immutable MAX_FREEMINT = 5;

    modifier inMintTime() {
        if (block.timestamp >= endDate) revert NotInTime();
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseUri_,
        uint256 priceUsd_,
        uint256 endDate_,
        address relayerAddress_,
        address feedAddress_
    ) ERC721A(name_, symbol_) PriceManager(priceUsd_, feedAddress_) ValidatorRelayer(relayerAddress_) {
        baseUri = baseUri_;
        endDate = endDate_;
        _payoutAddress = owner();
    }

    /**
     * @dev Allows a user to mint NFTs for free with the help of a relayer
     * @param hash The hash of the order data
     * @param signature The ECDSA signature of the order data
     * @param numberOfMints The number of NFTs to mint
     */
    function freeMint(bytes32 hash, bytes memory signature, uint256 numberOfMints) external inMintTime {
        // Bot safe mint with relayer valitaion
        _validate(hash, signature, abi.encode(msg.sender, address(this), countFreemint[msg.sender]));

        unchecked {
            if (numberOfMints + countFreemint[msg.sender] > MAX_FREEMINT) revert FreeMintLimit();
            _safeMint(msg.sender, numberOfMints);
            countFreemint[msg.sender] += numberOfMints;
        }
    }

    /**
     * @dev Allows a user to redeem their Freemint NFT with personal NFT
     * @param orderId The ID of the upgrade order
     * @param orderItems An array of OrderItem structs representing the NFTs to be redeemed
     */
    function redeem(uint256 orderId, OrderItem[] memory orderItems) public payable inMintTime {
        if (orderPayed[orderId]) revert AlreadyPaid();

        // 1% Slippage
        if ((getTotalPrice(address(0x0), orderItems.length) * 1000) / 1010 >= msg.value) revert InsufficientPaided();

        uint256 pricePerOrder = msg.value / orderItems.length;
        uint256 totalReward = 0;

        for (uint256 index = 0; index < orderItems.length; index++) {
            OrderItem memory item = orderItems[index];
            _redeemNFT(orderId, msg.sender, item);

            if (item.payReward) {
                if (address(rewardManager) == address(0x0)) {
                    revert NoRewardManager();
                }
                uint256 rewardOwner = rewardManager.calcReward(pricePerOrder, false);
                rewardManager.addReward{ value: rewardOwner }(item.nft, false);

                uint256 rewardCollection = rewardManager.calcReward(pricePerOrder, true);
                rewardManager.addReward{ value: rewardCollection }(item.nft, true);

                totalReward += rewardOwner + rewardCollection;
            }
        }

        payable(_payoutAddress).transfer(msg.value - totalReward);
        orderPayed[orderId] = true;
    }

    /**
     * @dev Allows a user to redeem their Freemint NFT with personal NFT
     * @param orderId The ID of the upgrade order
     * @param orderItems An array of OrderItem structs representing the NFTs to be redeemed
     * @param token The address of the erc20 to pay
     */
    function redeemToken(uint256 orderId, OrderItem[] memory orderItems, address token) public {
        if (orderPayed[orderId]) revert AlreadyPaid();

        uint256 totalPrice = getTotalPrice(token, orderItems.length);
        IERC20(token).transferFrom(msg.sender, address(this), totalPrice);

        uint256 pricePerOrder = getTotalPrice(token, 1);
        uint256 totalReward = 0;

        for (uint256 index = 0; index < orderItems.length; index++) {
            OrderItem memory item = orderItems[index];
            _redeemNFT(orderId, msg.sender, item);

            if (item.payReward) {
                if (address(rewardManager) == address(0x0)) {
                    revert NoRewardManager();
                }
                uint256 rewardOwner = rewardManager.calcReward(pricePerOrder, false);
                uint256 rewardCollection = rewardManager.calcReward(pricePerOrder, true);
                IERC20(token).approve(address(rewardManager), rewardOwner + rewardCollection);
                rewardManager.addReward(item.nft, false, token, rewardOwner);
                rewardManager.addReward(item.nft, true, token, rewardCollection);

                totalReward += rewardOwner + rewardCollection;
            }
        }

        IERC20(token).transfer(_payoutAddress, totalPrice - totalReward);
        orderPayed[orderId] = true;
    }

    /**
     * @dev Internal function to redeem an NFT
     * @param orderId The ID of the upgrade order
     * @param to The address of the user upgrading the NFT
     * @param item The OrderItem struct representing the NFT to be redeemed
     */
    function _redeemNFT(uint256 orderId, address to, OrderItem memory item) internal {
        if (item.upgradeId == 0) {
            if (address(rewardManager) == address(0x0)) {
                revert NoRewardManager();
            }
            _safeMint(to, 1);
            nftById[_totalMinted()] = item.nft;
            emit NFTRedeemed(orderId, to, _totalMinted(), item.nft);
        } else {
            if (ownerOf(item.upgradeId) != to) revert NotOwner();
            // if (redeemedById[item.upgradeId]) revert AlreadyRedeemed();
            nftById[item.upgradeId] = item.nft;
            countFreemint[to] -= 1;
            emit NFTRedeemed(orderId, to, item.upgradeId, item.nft);
        }
    }

    function getUserInfos(address user) public view returns (uint256[] memory, NFT[] memory) {
        uint256[] memory userIds = ERC721AQueryable(this).tokensOfOwner(user);

        NFT[] memory nfts = new NFT[](userIds.length);

        for (uint256 index = 0; index < userIds.length; index++) {
            nfts[index] = nftById[userIds[index]];
        }
        return (userIds, nfts);
    }

    function contractURI() public view returns (string memory) {
        return baseUri;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function setBaseUri(string memory uri) external onlyOwner {
        baseUri = uri;
    }

    function setRewardManager(address rewardManagerAddress) external onlyOwner {
        rewardManager = IRewardMananger(rewardManagerAddress);
    }

    function setPayoutAddress(address payoutAddress) external onlyOwner {
        _payoutAddress = payoutAddress;
    }

    // function setEndTime(uint256 endDate_) external onlyOwner {
    //     endDate = endDate_;
    // }
}