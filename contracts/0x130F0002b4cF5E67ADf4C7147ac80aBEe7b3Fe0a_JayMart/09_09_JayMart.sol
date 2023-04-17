//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IJAY {
    function sell(uint256 value) external;

    function buy(address reciever) external payable;

    function burnFrom(address account, uint256 amount) external;

    function ETHtoJAY(uint256 value) external view returns (uint256);
}

contract JayMart is Ownable, ReentrancyGuard {
    // Define our price feed interface
    AggregatorV3Interface internal priceFeed;

    // Create variable to hold the team wallet address
    address payable private TEAM_WALLET;

    // Create variable to hold contract address
    address payable private immutable JAY_ADDRESS;

    // Define new IJAY interface
    IJAY private immutable JAY;

    // Define some constant variables
    uint256 private constant SELL_NFT_PAYOUT = 2;
    uint256 private constant SELL_NFT_FEE_VAULT = 4;
    uint256 private constant SELL_NFT_FEE_TEAM = 4;

    uint256 private constant BUY_NFT_FEE_TEAM = 2;
    uint256 private constant USD_PRICE_SELL = 2 * 10 ** 18;
    uint256 private constant USD_PRICE_BUY = 10 * 10 ** 18;

    // Define variables for amount of NFTs bought/sold
    uint256 private nftsBought;
    uint256 private nftsSold;

    // Create variables for gas fee calculation
    uint256 private buyNftFeeEth = 0.01 * 10 ** 18;
    uint256 private buyNftFeeJay = 10 * 10 ** 18;
    uint256 private sellNftFeeEth = 0.001 * 10 ** 18;

    // Create variable to hold when the next fee update can occur
    uint256 private nextFeeUpdate = block.timestamp + (7 days);

    // Constructor
    constructor(address _jayAddress) {
        JAY = IJAY(_jayAddress);
        JAY_ADDRESS = payable(_jayAddress);
        setTEAMWallet(0x985B6B9064212091B4b325F68746B77262801BcB);
        priceFeed = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        ); //main
    }

    function setTEAMWallet(address _address) public onlyOwner {
        TEAM_WALLET = payable(_address);
    }

    /*
     * Name: sendEth
     * Purpose: Tranfer ETH tokens
     * Parameters:
     *    - @param 1: Address
     *    - @param 2: Value
     * Return: n/a
     */
    function sendEth(address _address, uint256 _value) private {
        (bool success, ) = _address.call{value: _value}("");
        require(success, "ETH Transfer failed.");
    }

    /*
     * Name: buyNFTs
     * Purpose: Purchase NFTs with ETH
     * Parameters:
     *    - @param 1: ERC721 Token Address
     *    - @param 2: ERC721 IDs
     *    - @param 3: ERC1155 Token Address
     *    - @param 4: ERC1155 IDs
     *    - @param 5: ERC1155 Amounts
     * Return: n/a
     */
    function buyNFTs(
        address[] calldata erc721TokenAddress,
        uint256[] calldata erc721Ids,
        address[] calldata erc1155TokenAddress,
        uint256[] calldata erc1155Ids,
        uint256[] calldata erc1155Amounts
    ) external payable nonReentrant {
        // Calculate total
        require(
            erc721TokenAddress.length + erc1155TokenAddress.length <= 500,
            "Max is 500"
        );
        uint256 total = erc721TokenAddress.length;

        // Transfer ERC721 NFTs
        buyERC721(erc721TokenAddress, erc721Ids);

        // Transfer ERC1155 NFTs
        total += buyERC1155(erc1155TokenAddress, erc1155Ids, erc1155Amounts);

        // Increase NFTs bought
        nftsBought += total;

        // Calculate Jay fee
        uint256 _fee = total * (buyNftFeeEth);

        // Make sure enough ETH is present
        require(msg.value >= _fee, "You need to pay more ETH.");

        // Send fees to designated wallets
        sendEth(TEAM_WALLET, msg.value / (BUY_NFT_FEE_TEAM));
        sendEth(JAY_ADDRESS, address(this).balance);

        // Initiate burn method
        JAY.burnFrom(msg.sender, total * (buyNftFeeJay));
    }

    /*
     * Name: buyJay
     * Purpose: Purchase JAY tokens by selling NFTs
     * Parameters:
     *    - @param 1: ERC721 Token Address
     *    - @param 2: ERC721 IDs
     *    - @param 3: ERC1155 Token Address
     *    - @param 4: ERC1155 IDs
     *    - @param 5: ERC1155 Amounts
     * Return: n/a
     */
    function buyJay(
        address[] calldata erc721TokenAddress,
        uint256[] calldata erc721Ids,
        address[] calldata erc1155TokenAddress,
        uint256[] calldata erc1155Ids,
        uint256[] calldata erc1155Amounts
    ) external payable nonReentrant {
        require(
            erc721TokenAddress.length + erc1155TokenAddress.length <= 500,
            "Max is 500"
        );
        uint256 teamFee = msg.value / (SELL_NFT_FEE_TEAM);
        uint256 jayFee = msg.value / (SELL_NFT_FEE_VAULT);
        uint256 userValue = msg.value / (SELL_NFT_PAYOUT);

        uint256 total = erc721TokenAddress.length;

        // Transfer ERC721 NFTs
        buyJayWithERC721(erc721TokenAddress, erc721Ids);

        // Transfer ERC1155 NFTs
        total += buyJayWithERC1155(
            erc1155TokenAddress,
            erc1155Ids,
            erc1155Amounts
        );

        // Increase nftsSold variable

        nftsSold += total;

        // Calculate fee
        uint256 _fee = total >= 100
            ? ((total) * (sellNftFeeEth)) / (2)
            : (total) * (sellNftFeeEth);

        // Make sure enough ETH is present
        require(msg.value >= _fee, "You need to pay more ETH.");

        // Send fees to their designated wallets
        sendEth(TEAM_WALLET, teamFee);
        sendEth(JAY_ADDRESS, jayFee);

        // buy JAY
        JAY.buy{value: userValue}(msg.sender);
    }

    /*
     * Name: buyERC721
     * Purpose: Transfer ERC721 NFTs
     * Parameters:
     *    - @param 1: ERC721 Token Address
     *    - @param 2: ERC721 IDs
     * Return: n/a
     */
    function buyERC721(
        address[] calldata _tokenAddress,
        uint256[] calldata ids
    ) internal {
        for (uint256 id = 0; id < ids.length; id++) {
            IERC721(_tokenAddress[id]).safeTransferFrom(
                address(this),
                msg.sender,
                ids[id]
            );
        }
    }

    /*
     * Name: buyERC1155
     * Purpose: Transfer ERC1155 NFTs
     * Parameters:
     *    - @param 1: ERC1155 Token Address
     *    - @param 2: ERC1155 IDs
     *    - @param 3: ERC1155 Amounts
     * Return: Amount of NFTs bought
     */
    function buyERC1155(
        address[] calldata _tokenAddress,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) internal returns (uint256) {
        uint256 amount = 0;
        for (uint256 id = 0; id < ids.length; id++) {
            amount = amount + (amounts[id]);
            IERC1155(_tokenAddress[id]).safeTransferFrom(
                address(this),
                msg.sender,
                ids[id],
                amounts[id],
                ""
            );
        }
        return amount;
    }

    /*
     * Name: buyJayWithERC721
     * Purpose: Buy JAY from selling ERC721 NFTs
     * Parameters:
     *    - @param 1: ERC721 Token Address
     *    - @param 2: ERC721 IDs
     *
     * Return: n/a
     */
    function buyJayWithERC721(
        address[] calldata _tokenAddress,
        uint256[] calldata ids
    ) internal {
        for (uint256 id = 0; id < ids.length; id++) {
            IERC721(_tokenAddress[id]).safeTransferFrom(
                msg.sender,
                address(this),
                ids[id]
            );
        }
    }

    /*
     * Name: buyJayWithERC1155
     * Purpose: Buy JAY from selling ERC1155 NFTs
     * Parameters:
     *    - @param 1: ERC1155 Token Address
     *    - @param 2: ERC1155 IDs
     *    - @param 3: ERC1155 Amounts
     *
     * Return: Number of NFTs sold
     */
    function buyJayWithERC1155(
        address[] calldata _tokenAddress,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) internal returns (uint256) {
        uint256 amount = 0;
        for (uint256 id = 0; id < ids.length; id++) {
            amount = amount + (amounts[id]);
            IERC1155(_tokenAddress[id]).safeTransferFrom(
                msg.sender,
                address(this),
                ids[id],
                amounts[id],
                ""
            );
        }
        return amount;
    }

    function getPriceSell(uint256 total) public view returns (uint256) {
        return total * sellNftFeeEth;
    }

    function getPriceBuy(uint256 total) public view returns (uint256) {
        return total * buyNftFeeEth;
    }

    function getFees()
        public
        view
        returns (uint256, uint256, uint256, uint256)
    {
        return (sellNftFeeEth, buyNftFeeEth, buyNftFeeJay, nextFeeUpdate);
    }

    function getTotals() public view returns (uint256, uint256) {
        return (nftsBought, nftsSold);
    }

    /*
     * Name: updateFees
     * Purpose: Update the NFT sales fees
     * Parameters: n/a
     * Return: Array of uint256: NFT Sell Fee (ETH), NFT Buy Fee (ETH), NFT Buy Fee (JAY), time of next update
     */
    function updateFees()
        external
        nonReentrant
        returns (uint256, uint256, uint256, uint256)
    {
        // Get latest price feed
        (
            uint80 roundID,
            int256 price,
            ,
            uint256 timestamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();

        require(price > 0, "Chainlink price <= 0");
        require(answeredInRound >= roundID, "Stale price");
        require(timestamp != 0, "Round not complete");

        uint256 _price = uint256(price) * (1 * 10 ** 10);
        require(timestamp > nextFeeUpdate, "Fee update every 24 hrs");

        uint256 _sellNftFeeEth;
        if (_price > USD_PRICE_SELL) {
            uint256 _p = _price / (USD_PRICE_SELL);
            _sellNftFeeEth = uint256(1 * 10 ** 18) / (_p);
        } else {
            _sellNftFeeEth = USD_PRICE_SELL / (_price);
        }

        require(
            owner() == msg.sender ||
                (sellNftFeeEth / (2) < _sellNftFeeEth &&
                    sellNftFeeEth * (150) > _sellNftFeeEth),
            "Fee swing too high"
        );

        sellNftFeeEth = _sellNftFeeEth;

        if (_price > USD_PRICE_BUY) {
            uint256 _p = _price / (USD_PRICE_BUY);
            buyNftFeeEth = uint256(1 * 10 ** 18) / (_p);
        } else {
            buyNftFeeEth = USD_PRICE_BUY / (_price);
        }
        buyNftFeeJay = JAY.ETHtoJAY(buyNftFeeEth);

        nextFeeUpdate = timestamp + (24 hours);
        return (sellNftFeeEth, buyNftFeeEth, buyNftFeeJay, nextFeeUpdate);
    }

    function getLatestPrice() public view returns (int256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }

    receive() external payable {}

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
}