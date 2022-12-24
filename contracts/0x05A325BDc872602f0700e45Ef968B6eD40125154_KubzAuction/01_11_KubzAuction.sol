// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/IBKZOpaqueAuctionInfo.sol";

contract KubzAuction is
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    IBKZOpaqueAuctionInfo
{
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public MIN_BID_AMOUNT; // = 0.1ether;
    uint256 public BID_ITEMS_COUNT; // 3000
    uint256 public FOR_SALE_ITEMS_COUNT; // 5000

    uint256 public finalPrice;
    uint8 public auctionState;
    address public signer;

    // public bid, 1-3 items per address
    // items count are hidden, as this is an opaque auction
    address[] public bidders;
    uint256 public totalDepositedETH;
    mapping(address => uint256) public userBidETH; // address => bid price/deposited in wei
    mapping(address => bool) public isUserRefunded; // address => user has refunded, whether as winner or loser

    // wonBiddedItems + wlAirdropUsers.count() <= FOR_SALE_ITEMS_COUNT
    uint256 public wonBiddedItems; // bid winner items count, <= BID_ITEMS_COUNT
    EnumerableSet.AddressSet wlAirdropUsers; // WL enter airdrop, 1 item per address

    uint256 public withdrawed;

    event UserEnteredBid(
        address indexed user,
        uint256 bidAmount,
        bool indexed newUser
    );

    event UserEnteredWLAirdrop(address indexed user);

    event UserRefunded(
        address indexed user,
        uint256 bidAmount,
        uint256 indexed wonItemsCount
    );

    function initialize(address _signer) public initializer {
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        OwnableUpgradeable.__Ownable_init();
        MIN_BID_AMOUNT = 0.069 ether;
        BID_ITEMS_COUNT = 3000;
        FOR_SALE_ITEMS_COUNT = 5000;
        signer = _signer;
    }

    function checkValidity(bytes calldata signature, string memory action)
        public
        view
        returns (bool)
    {
        require(
            ECDSA.recover(
                ECDSA.toEthSignedMessageHash(
                    keccak256(abi.encodePacked(msg.sender, action))
                ),
                signature
            ) == signer,
            "invalid signature"
        );
        return true;
    }

    function addBid() external payable {
        require(auctionState == 1, "Auction not in bidding state");
        require(msg.value > 0, "msg.value must > 0");
        uint256 newAmount = userBidETH[msg.sender] + msg.value;
        require(
            newAmount >= MIN_BID_AMOUNT,
            "Total deposited ETH amount has to be >= MIN_BID_AMOUNT"
        );
        if (userBidETH[msg.sender] == 0) {
            bidders.push(msg.sender);
            emit UserEnteredBid(msg.sender, newAmount, true);
        } else {
            emit UserEnteredBid(msg.sender, newAmount, false);
        }
        totalDepositedETH += msg.value;
        userBidETH[msg.sender] = newAmount;
    }

    function wlEnterAirdrop(bytes calldata signature) external payable {
        require(auctionState == 2, "Not opened to enter airdrop");
        require(finalPrice > 0, "finalPrice not yet set");
        require(msg.value == finalPrice, "msg.value does not match finalPrice");
        checkValidity(signature, "bkz:auction:wl-airdrop");
        require(
            !wlAirdropUsers.contains(msg.sender),
            "Already in airdrop list"
        );
        wlAirdropUsers.add(msg.sender);
        emit UserEnteredWLAirdrop(msg.sender);
    }

    function refund(bytes calldata signature, uint256 wonItemsCount)
        external
        nonReentrant
    {
        require(auctionState >= 2, "Auction not started or still ongoing");
        require(userBidETH[msg.sender] > 0, "No bid record");
        require(!isUserRefunded[msg.sender], "Already refunded");
        require(wonItemsCount <= 3, "Too many won items");
        checkValidity(
            signature,
            string.concat(
                "bkz:auction:refund:won-items:",
                Strings.toString(wonItemsCount)
            )
        );

        uint256 refundAmount = userBidETH[msg.sender] -
            (finalPrice * wonItemsCount);
        require(refundAmount <= userBidETH[msg.sender], "underflow");
        require(refundAmount > 0, "No refund needed");

        isUserRefunded[msg.sender] = true;
        emit UserRefunded(msg.sender, refundAmount, wonItemsCount);
        _withdraw(msg.sender, refundAmount);
    }

    // =============== Stats ===============
    function getWLAirdropLength() external view returns (uint256) {
        return wlAirdropUsers.length();
    }

    function getBiddersLength() external view returns (uint256) {
        return bidders.length;
    }

    function getBidders(uint256 fromIdx, uint256 toIdx)
        external
        view
        returns (address[] memory)
    {
        toIdx = Math.min(toIdx, bidders.length);
        address[] memory part = new address[](toIdx - fromIdx);
        for (uint256 i = 0; i < toIdx - fromIdx; i++) {
            part[i] = bidders[i + fromIdx];
        }
        return part;
    }

    function getBiddersAll() external view returns (address[] memory) {
        return bidders;
    }

    function getWLAirdropUsers(uint256 fromIdx, uint256 toIdx)
        external
        view
        returns (address[] memory)
    {
        toIdx = Math.min(toIdx, wlAirdropUsers.length());
        address[] memory part = new address[](toIdx - fromIdx);
        for (uint256 i = 0; i < toIdx - fromIdx; i++) {
            part[i] = wlAirdropUsers.at(i + fromIdx);
        }
        return part;
    }

    function getWLAirdropUsersAll() external view returns (address[] memory) {
        return wlAirdropUsers.values();
    }

    // =============== Admin ===============
    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function withdrawSales() public onlyOwner {
        require(
            auctionState == 2 || auctionState == 3,
            "Auction not in concluding or finished state"
        );
        require(wonBiddedItems > 0, "wonBiddedItems not set");
        require(finalPrice > 0, "finalPrice not set");
        uint256 sales = (wonBiddedItems + wlAirdropUsers.length()) * finalPrice;
        uint256 available = sales - withdrawed;
        withdrawed = sales;

        require(available > 0, "No balance to withdraw");
        _withdraw(owner(), available);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "cant withdraw");
    }

    function changeMinBidAmount(uint256 amount) external onlyOwner {
        require(auctionState == 0, "Auction already started");
        MIN_BID_AMOUNT = amount;
    }

    function changeBidItemsCount(uint256 count) external onlyOwner {
        require(auctionState == 0, "Auction already started");
        BID_ITEMS_COUNT = count;
    }

    function changeForSaleItemsCount(uint256 count) external onlyOwner {
        require(auctionState == 0, "Auction already started");
        FOR_SALE_ITEMS_COUNT = count;
    }

    function setWonBiddedItems(uint256 items) external onlyOwner {
        require(items <= BID_ITEMS_COUNT, "Too many won items");
        wonBiddedItems = items;
    }

    function setFinalPrice(uint256 price) external onlyOwner {
        finalPrice = price;
    }

    // 0 = not started
    // 1 = started, bidding
    // 2 = finalPrice announced | wl airdrop starts | auction refund opens |
    //     wled users can pay finalPrice to enter airdrop list |
    //     users can pay finalPrice to enter waitlist, stop when 0 vac
    // 3 = wl airdrop end | waitlist losers can refund
    function setAuctionState(uint8 state) external onlyOwner {
        auctionState = state;
    }

    // =============== IBKZBlindAuctionInfo ===============
    function getAirdroppingItemsCount() external view returns (uint256) {
        return wonBiddedItems + wlAirdropUsers.length();
    }

    function getForSaleItemsCount() external view returns (uint256) {
        return FOR_SALE_ITEMS_COUNT;
    }

    function getFinalPrice() external view returns (uint256) {
        return finalPrice;
    }

    function getAuctionState() external view returns (uint8) {
        return auctionState;
    }

    function getSigner() external view returns (address) {
        return signer;
    }
}