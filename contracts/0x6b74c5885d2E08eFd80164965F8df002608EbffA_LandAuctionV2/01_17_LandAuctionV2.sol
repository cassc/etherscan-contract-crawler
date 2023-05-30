// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./interfaces/IWETH.sol";
import "./interfaces/ILockShiboshi.sol";
import "./interfaces/ILockLeash.sol";
import "./interfaces/ILandRegistry.sol";
import "./interfaces/ILandAuction.sol";

import "./LandAuction.sol";

contract LandAuctionV2 is ILandAuction, AccessControl, ReentrancyGuard {
    using ECDSA for bytes32;

    uint32 constant clearLow = 0xffff0000;
    uint32 constant clearHigh = 0x0000ffff;
    uint32 constant factor = 0x10000;

    /*
        xLow, yHigh gets mapped to 1,1
        transform: x + 97, 100 - y

        y_mapped = 100 - y
        x_mapped = 97 + x
    */

    int16 public constant xLow = -96;
    int16 public constant yLow = -99;
    int16 public constant xHigh = 96;
    int16 public constant yHigh = 99;

    enum Stage {
        Default,
        Inactive,
        PrivateSale,
        PublicSale
    }

    struct Bid {
        uint256 amount;
        address bidder;
    }

    LandAuction public auctionV1;
    ILandRegistry public landRegistry;
    ILockLeash public lockLeash;
    ILockShiboshi public lockShiboshi;
    bool public multiMintEnabled;

    address public signerAddress;
    Stage public currentStage;

    mapping(int16 => mapping(int16 => Bid)) public getCurrentBid;
    mapping(address => uint256) private _winningsBidsOf;

    mapping(address => uint32[]) private _mintedBy;
    mapping(address => uint32[]) private _allBidsOf;
    mapping(address => mapping(uint32 => uint8)) private _statusOfBidsOf;

    event StageSet(uint256 stage);
    event SignerSet(address signer);
    event multiMintToggled(bool newValue);
    event LandBought(
        address indexed user,
        uint32 indexed encXY,
        int16 x,
        int16 y,
        uint256 price,
        uint256 time,
        Stage saleStage
    );

    constructor(
        LandAuction _auctionV1,
        ILandRegistry _landRegistry,
        ILockLeash _lockLeash,
        ILockShiboshi _lockShiboshi
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        auctionV1 = _auctionV1;
        landRegistry = _landRegistry;
        lockLeash = _lockLeash;
        lockShiboshi = _lockShiboshi;

        signerAddress = msg.sender;
    }

    modifier onlyValid(int16 x, int16 y) {
        require(xLow <= x && x <= xHigh, "ERR_X_OUT_OF_RANGE");
        require(yLow <= y && y <= yHigh, "ERR_Y_OUT_OF_RANGE");
        _;
    }

    modifier onlyStage(Stage s) {
        require(currentStage == s, "ERR_THIS_STAGE_NOT_LIVE_YET");
        _;
    }

    function weightToCapacity(uint256 weightLeash, uint256 weightShiboshi)
        public
        pure
        returns (uint256)
    {
        uint256[10] memory QRangeLeash = [
            uint256(9),
            uint256(30),
            uint256(60),
            uint256(100),
            uint256(130),
            uint256(180),
            uint256(220),
            uint256(300),
            uint256(370),
            uint256(419)
        ];
        uint256[10] memory QRangeShiboshi = [
            uint256(45),
            uint256(89),
            uint256(150),
            uint256(250),
            uint256(350),
            uint256(480),
            uint256(600),
            uint256(700),
            uint256(800),
            uint256(850)
        ];
        uint256[10] memory buckets = [
            uint256(1),
            uint256(5),
            uint256(10),
            uint256(20),
            uint256(50),
            uint256(80),
            uint256(100),
            uint256(140),
            uint256(180),
            uint256(200)
        ];
        uint256 capacity;

        if (weightLeash > 0) {
            for (uint256 i = 9; i >= 0; i = _uncheckedDec(i)) {
                if (weightLeash > QRangeLeash[i] * 1e18) {
                    capacity += buckets[i];
                    break;
                }
            }
        }

        if (weightShiboshi > 0) {
            for (uint256 i = 9; i >= 0; i = _uncheckedDec(i)) {
                if (weightShiboshi > QRangeShiboshi[i]) {
                    capacity += buckets[i];
                    break;
                }
            }
        }

        return capacity;
    }

    function getOutbidPrice(uint256 bidPrice) public pure returns (uint256) {
        // 5% more than the current price
        return (bidPrice * 21) / 20;
    }

    function winningsBidsOf(address user) public view returns (uint256) {
        return _winningsBidsOf[user] + auctionV1.winningsBidsOf(user);
    }

    function availableCapacityOf(address user) public view returns (uint256) {
        uint256 weightLeash = lockLeash.weightOf(user);
        uint256 weightShiboshi = lockShiboshi.weightOf(user);

        return
            weightToCapacity(weightLeash, weightShiboshi) -
            winningsBidsOf(user);
    }

    function getReservePrice(int16 x, int16 y) public view returns (uint256) {
        return auctionV1.getReservePrice(x, y);
    }

    function getPriceOf(int16 x, int16 y) public view returns (uint256) {
        Bid storage currentBid = getCurrentBid[x][y];
        if (currentBid.amount == 0) {
            // no bids on this contract
            return auctionV1.getPriceOf(x, y);
        } else {
            // attempt to outbid a bid placed here
            return getOutbidPrice(currentBid.amount);
        }
    }

    function priceOfCategory(int8 category) external view returns (uint256) {
        return auctionV1.priceOfCategory(category);
    }

    function getCategory(int16 x, int16 y) public view returns (int8) {
        return auctionV1.getCategory(x, y);
    }

    function isShiboshiZone(int16 x, int16 y) public pure returns (bool) {
        /*
            (12,99) to (48, 65)
            (49, 99) to (77, 78)
            (76, 77) to (77, 50)
            (65, 50) to (75, 50)
        */

        if (x >= 12 && x <= 48 && y <= 99 && y >= 65) {
            return true;
        }
        if (x >= 49 && x <= 77 && y <= 99 && y >= 78) {
            return true;
        }
        if (x >= 76 && x <= 77 && y <= 77 && y >= 50) {
            return true;
        }
        if (x >= 65 && x <= 75 && y == 50) {
            return true;
        }
        return false;
    }

    // List of currently winning bids of this user
    function bidInfoOf(address user)
        external
        view
        returns (int16[] memory, int16[] memory)
    {
        (int16[] memory xsV1, int16[] memory ysV1) = auctionV1.bidInfoOf(user);
        uint256 lengthV1 = xsV1.length;

        uint256 bidCount = _winningsBidsOf[user];
        int16[] memory xs = new int16[](bidCount + lengthV1);
        int16[] memory ys = new int16[](bidCount + lengthV1);

        for (uint256 i = 0; i < lengthV1; i = _uncheckedInc(i)) {
            xs[i] = xsV1[i];
            ys[i] = ysV1[i];
        }

        uint256 ptr = lengthV1;
        uint32[] storage allBids = _allBidsOf[user];
        uint256 length = allBids.length;

        for (uint256 i = 0; i < length; i = _uncheckedInc(i)) {
            if (_statusOfBidsOf[user][allBids[i]] == 1) {
                (int16 x, int16 y) = _decodeXY(allBids[i]);
                xs[ptr] = x;
                ys[ptr] = y;
                ptr = _uncheckedInc(ptr);
            }
        }

        return (xs, ys);
    }

    // List of all bids, ever done by this user
    function allBidInfoOf(address user)
        external
        view
        returns (int16[] memory, int16[] memory)
    {
        (int16[] memory xsV1, int16[] memory ysV1) = auctionV1.allBidInfoOf(
            user
        );
        uint256 lengthV1 = xsV1.length;

        uint32[] storage allBids = _allBidsOf[user];
        uint256 bidCount = allBids.length;
        int16[] memory xs = new int16[](bidCount + lengthV1);
        int16[] memory ys = new int16[](bidCount + lengthV1);

        for (uint256 i = 0; i < lengthV1; i = _uncheckedInc(i)) {
            xs[i] = xsV1[i];
            ys[i] = ysV1[i];
        }

        for (
            uint256 i = lengthV1;
            i < lengthV1 + bidCount;
            i = _uncheckedInc(i)
        ) {
            (int16 x, int16 y) = _decodeXY(allBids[i - lengthV1]);
            xs[i] = x;
            ys[i] = y;
        }

        return (xs, ys);
    }

    function mintedBy(address user) external
        view
        returns (int16[] memory, int16[] memory) {

            uint32[] storage allMints = _mintedBy[user];
            uint256 mintCount = allMints.length;
            int16[] memory xs = new int16[](mintCount);
            int16[] memory ys = new int16[](mintCount);

            for (uint256 i = 0; i < mintCount; i = _uncheckedInc(i)) {
                (int16 x, int16 y) = _decodeXY(allMints[i]);
                xs[i] = x;
                ys[i] = y;
            }

            return (xs, ys);
        }


    function setStage(uint256 stage) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (stage >= 2) {
            require(
                uint256(auctionV1.currentStage()) == 0,
                "ERR_AUCTION_V1_IS_NOT_DISABLED"
            );
        }
        currentStage = Stage(stage);
        emit StageSet(stage);
    }

    function setSignerAddress(address signer)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(signer != address(0), "ERR_CANNOT_BE_ZERO_ADDRESS");
        signerAddress = signer;
        emit SignerSet(signer);
    }

    function setLandRegistry(address _landRegistry)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        landRegistry = ILandRegistry(_landRegistry);
    }

    function setLockLeash(address _lockLeash)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        lockLeash = ILockLeash(_lockLeash);
    }

    function setLockShiboshi(address _lockShiboshi)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        lockShiboshi = ILockShiboshi(_lockShiboshi);
    }

    function setAuctionV1(LandAuction _auctionV1)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        auctionV1 = _auctionV1;
    }

    function setMultiMint(bool desiredValue)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(multiMintEnabled != desiredValue, "ERR_ALREADY_DESIRED_VALUE");
        multiMintEnabled = desiredValue;

        emit multiMintToggled(desiredValue);
    }

    function withdraw(address to, uint256 amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        payable(to).transfer(amount);
    }

    function mintWinningBid(int16[] calldata xs, int16[] calldata ys) external {
        require(
            currentStage == Stage.PublicSale ||
                currentStage == Stage.PrivateSale,
            "ERR_MUST_WAIT_FOR_BIDDING_TO_END"
        );

        uint256 length = xs.length;
        require(length == ys.length, "ERR_INPUT_LENGTH_MISMATCH");

        for (uint256 i = 0; i < length; i = _uncheckedInc(i)) {
            int16 x = xs[i];
            int16 y = ys[i];
            require(xLow <= x && x <= xHigh, "ERR_X_OUT_OF_RANGE");
            require(yLow <= y && y <= yHigh, "ERR_Y_OUT_OF_RANGE");

            (, address user) = auctionV1.getCurrentBid(x, y);
            require(user != address(0), "ERR_NO_BID_FOUND");
            landRegistry.mint(user, x, y);
            _mintedBy[user].push(_encodeXY(x, y));
        }
    }

    function mintPrivate(int16 x, int16 y)
        external
        payable
        onlyStage(Stage.PrivateSale)
        nonReentrant
    {
        require(availableCapacityOf(msg.sender) != 0, "ERR_NO_BIDS_REMAINING");
        require(!isShiboshiZone(x, y), "ERR_NO_MINT_IN_SHIBOSHI_ZONE");
        _mintPublicOrPrivate(msg.sender, x, y, msg.value);
        emit LandBought(
            msg.sender,
            _encodeXY(x, y),
            x,
            y,
            msg.value,
            block.timestamp,
            Stage.PrivateSale
        );
    }

    function mintPrivateMulti(
        int16[] calldata xs,
        int16[] calldata ys,
        uint256[] calldata prices
    ) external payable onlyStage(Stage.PrivateSale) nonReentrant {
        require(multiMintEnabled, "ERR_MULTI_BID_DISABLED");

        uint256 length = xs.length;
        require(length != 0, "ERR_NO_INPUT");
        require(length == ys.length, "ERR_INPUT_LENGTH_MISMATCH");
        require(length == prices.length, "ERR_INPUT_LENGTH_MISMATCH");

        address user = msg.sender;
        require(
            availableCapacityOf(user) >= length,
            "ERR_INSUFFICIENT_BIDS_REMAINING"
        );

        uint256 total;
        for (uint256 i = 0; i < length; i = _uncheckedInc(i)) {
            total += prices[i];
        }
        require(msg.value == total, "ERR_INSUFFICIENT_AMOUNT_SENT");

        for (uint256 i = 0; i < length; i = _uncheckedInc(i)) {
            int16 x = xs[i];
            int16 y = ys[i];
            require(!isShiboshiZone(x, y), "ERR_NO_MINT_IN_SHIBOSHI_ZONE");
            _mintPublicOrPrivate(user, x, y, prices[i]);
            emit LandBought(
                user,
                _encodeXY(x, y),
                x,
                y,
                prices[i],
                block.timestamp,
                Stage.PrivateSale
            );
        }
    }

    function mintPrivateShiboshiZone(
        int16 x,
        int16 y,
        bytes calldata signature
    ) external payable onlyStage(Stage.PrivateSale) nonReentrant {
        require(
            _verifySigner(_hashMessage(msg.sender), signature),
            "ERR_SIGNATURE_INVALID"
        );
        require(isShiboshiZone(x, y), "ERR_NOT_IN_SHIBOSHI_ZONE");
        _mintPublicOrPrivate(msg.sender, x, y, msg.value);
        emit LandBought(
            msg.sender,
            _encodeXY(x, y),
            x,
            y,
            msg.value,
            block.timestamp,
            Stage.PrivateSale
        );
    }

    function mintPrivateShiboshiZoneMulti(
        int16[] calldata xs,
        int16[] calldata ys,
        uint256[] calldata prices,
        bytes calldata signature
    ) external payable onlyStage(Stage.PrivateSale) nonReentrant {
        require(multiMintEnabled, "ERR_MULTI_BID_DISABLED");

        address user = msg.sender;
        require(
            _verifySigner(_hashMessage(user), signature),
            "ERR_SIGNATURE_INVALID"
        );

        uint256 length = xs.length;
        require(length != 0, "ERR_NO_INPUT");
        require(length == ys.length, "ERR_INPUT_LENGTH_MISMATCH");
        require(length == prices.length, "ERR_INPUT_LENGTH_MISMATCH");

        uint256 total;
        for (uint256 i = 0; i < length; i = _uncheckedInc(i)) {
            total += prices[i];
        }
        require(msg.value == total, "ERR_INSUFFICIENT_AMOUNT_SENT");

        for (uint256 i = 0; i < length; i = _uncheckedInc(i)) {
            int16 x = xs[i];
            int16 y = ys[i];
            require(isShiboshiZone(x, y), "ERR_NOT_IN_SHIBOSHI_ZONE");
            _mintPublicOrPrivate(user, x, y, prices[i]);
            emit LandBought(
                user,
                _encodeXY(x, y),
                x,
                y,
                prices[i],
                block.timestamp,
                Stage.PrivateSale
            );
        }
    }

    function mintPublic(int16 x, int16 y)
        external
        payable
        onlyStage(Stage.PublicSale)
        nonReentrant
    {
        _mintPublicOrPrivate(msg.sender, x, y, msg.value);
        emit LandBought(
            msg.sender,
            _encodeXY(x, y),
            x,
            y,
            msg.value,
            block.timestamp,
            Stage.PublicSale
        );
    }

    function mintPublicMulti(
        int16[] calldata xs,
        int16[] calldata ys,
        uint256[] calldata prices
    ) external payable onlyStage(Stage.PublicSale) nonReentrant {
        require(multiMintEnabled, "ERR_MULTI_BID_DISABLED");

        uint256 length = xs.length;
        require(length != 0, "ERR_NO_INPUT");
        require(length == ys.length, "ERR_INPUT_LENGTH_MISMATCH");
        require(length == prices.length, "ERR_INPUT_LENGTH_MISMATCH");

        uint256 total;
        for (uint256 i = 0; i < length; i = _uncheckedInc(i)) {
            total += prices[i];
        }
        require(msg.value == total, "ERR_INSUFFICIENT_AMOUNT_SENT");

        address user = msg.sender;
        for (uint256 i = 0; i < length; i = _uncheckedInc(i)) {
            int16 x = xs[i];
            int16 y = ys[i];
            _mintPublicOrPrivate(user, x, y, prices[i]);
            emit LandBought(
                user,
                _encodeXY(x, y),
                x,
                y,
                prices[i],
                block.timestamp,
                Stage.PublicSale
            );
        }
    }

    // transform: +97, +100
    function _transformXY(int16 x, int16 y)
        internal
        pure
        onlyValid(x, y)
        returns (uint16, uint16)
    {
        return (uint16(x + 97), uint16(100 - y));
    }

    function _mintPublicOrPrivate(
        address user,
        int16 x,
        int16 y,
        uint256 price
    ) internal onlyValid(x, y) {
        Bid storage currentBid = getCurrentBid[x][y];
        require(currentBid.amount == 0, "ERR_NOT_UP_FOR_SALE");
        require(price == getReservePrice(x, y), "ERR_INSUFFICIENT_AMOUNT_SENT");

        currentBid.bidder = user;
        currentBid.amount = price;
        _winningsBidsOf[user] += 1;

        uint32 encXY = _encodeXY(x, y);
        _allBidsOf[user].push(encXY);
        _statusOfBidsOf[user][encXY] = 1;

        landRegistry.mint(user, x, y);
    }

    function _hashMessage(address sender) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(sender));
    }

    function _verifySigner(bytes32 messageHash, bytes memory signature)
        private
        view
        returns (bool)
    {
        return
            signerAddress ==
            messageHash.toEthSignedMessageHash().recover(signature);
    }

    function _uncheckedInc(uint256 i) internal pure returns (uint256) {
        unchecked {
            return i + 1;
        }
    }

    function _uncheckedDec(uint256 i) internal pure returns (uint256) {
        unchecked {
            return i - 1;
        }
    }

    function _encodeXY(int16 x, int16 y) internal pure returns (uint32) {
        return
            ((uint32(uint16(x)) * factor) & clearLow) |
            (uint32(uint16(y)) & clearHigh);
    }

    function _decodeXY(uint32 value) internal pure returns (int16 x, int16 y) {
        x = _expandNegative16BitCast((value & clearLow) >> 16);
        y = _expandNegative16BitCast(value & clearHigh);
    }

    function _expandNegative16BitCast(uint32 value)
        internal
        pure
        returns (int16)
    {
        if (value & (1 << 15) != 0) {
            return int16(int32(value | clearLow));
        }
        return int16(int32(value));
    }
}