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

contract LandAuction is ILandAuction, AccessControl, ReentrancyGuard {
    using ECDSA for bytes32;

    bytes32 public constant GRID_SETTER_ROLE = keccak256("GRID_SETTER_ROLE");

    uint32 constant clearLow = 0xffff0000;
    uint32 constant clearHigh = 0x0000ffff;
    uint32 constant factor = 0x10000;

    uint16 public constant N = 194; // xHigh + 97 + 1
    uint16 public constant M = 200; // yHigh + 100 + 1

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
        Bidding,
        PrivateSale,
        PublicSale
    }

    struct Bid {
        uint256 amount;
        address bidder;
    }

    address public immutable weth;
    ILandRegistry public landRegistry;
    ILockLeash public lockLeash;
    ILockShiboshi public lockShiboshi;
    bool public multiBidEnabled;

    address public signerAddress;
    Stage public currentStage;

    int8[N + 10][M + 10] private _categoryBIT;

    mapping(int16 => mapping(int16 => Bid)) public getCurrentBid;
    mapping(int8 => uint256) public priceOfCategory;
    mapping(address => uint256) public winningsBidsOf;

    mapping(address => uint32[]) private _allBidsOf;
    mapping(address => mapping(uint32 => uint8)) private _statusOfBidsOf;

    event CategoryPriceSet(int8 category, uint256 price);
    event StageSet(uint256 stage);
    event SignerSet(address signer);
    event multiBidToggled(bool newValue);
    event BidCreated(
        address indexed user,
        uint32 indexed encXY,
        int16 x,
        int16 y,
        uint256 price,
        uint256 time
    );
    event LandBought(
        address indexed user,
        uint32 indexed encXY,
        int16 x,
        int16 y,
        uint256 price,
        Stage saleStage
    );

    constructor(
        address _weth,
        ILandRegistry _landRegistry,
        ILockLeash _lockLeash,
        ILockShiboshi _lockShiboshi
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(GRID_SETTER_ROLE, msg.sender);

        weth = _weth;
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

    function availableCapacityOf(address user) public view returns (uint256) {
        uint256 weightLeash = lockLeash.weightOf(user);
        uint256 weightShiboshi = lockShiboshi.weightOf(user);

        return
            weightToCapacity(weightLeash, weightShiboshi) -
            winningsBidsOf[user];
    }

    function getReservePrice(int16 x, int16 y) public view returns (uint256) {
        uint256 price = priceOfCategory[getCategory(x, y)];
        require(price != 0, "ERR_NOT_UP_FOR_SALE");
        return price;
    }

    function getPriceOf(int16 x, int16 y) public view returns (uint256) {
        Bid storage currentBid = getCurrentBid[x][y];
        if (currentBid.amount == 0) {
            return getReservePrice(x, y);
        } else {
            // attempt to outbid
            return getOutbidPrice(currentBid.amount);
        }
    }

    function getCategory(int16 x, int16 y) public view returns (int8) {
        (uint16 x_mapped, uint16 y_mapped) = _transformXY(x, y);

        int8 category;
        for (uint16 i = x_mapped; i > 0; i = _subLowbit(i)) {
            for (uint16 j = y_mapped; j > 0; j = _subLowbit(j)) {
                unchecked {
                    category += _categoryBIT[i][j];
                }
            }
        }
        return category;
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
        uint256 bidCount = winningsBidsOf[user];
        int16[] memory xs = new int16[](bidCount);
        int16[] memory ys = new int16[](bidCount);

        uint256 ptr;
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
        uint32[] storage allBids = _allBidsOf[user];
        uint256 bidCount = allBids.length;
        int16[] memory xs = new int16[](bidCount);
        int16[] memory ys = new int16[](bidCount);

        for (uint256 i = 0; i < bidCount; i = _uncheckedInc(i)) {
            (int16 x, int16 y) = _decodeXY(allBids[i]);
            xs[i] = x;
            ys[i] = y;
        }

        return (xs, ys);
    }

    function setGridVal(
        int16 x1,
        int16 y1,
        int16 x2,
        int16 y2,
        int8 val
    ) external onlyRole(GRID_SETTER_ROLE) {
        (uint16 x1_mapped, uint16 y1_mapped) = _transformXY(x1, y1);
        (uint16 x2_mapped, uint16 y2_mapped) = _transformXY(x2, y2);

        _updateGrid(x2_mapped + 1, y2_mapped + 1, val);
        _updateGrid(x1_mapped, y1_mapped, val);
        _updateGrid(x1_mapped, y2_mapped + 1, -val);
        _updateGrid(x2_mapped + 1, y1_mapped, -val);
    }

    function setPriceOfCategory(int8 category, uint256 price)
        external
        onlyRole(GRID_SETTER_ROLE)
    {
        priceOfCategory[category] = price;

        emit CategoryPriceSet(category, price);
    }

    function setStage(uint256 stage) external onlyRole(DEFAULT_ADMIN_ROLE) {
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

    function setMultiBid(bool desiredValue)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(multiBidEnabled != desiredValue, "ERR_ALREADY_DESIRED_VALUE");
        multiBidEnabled = desiredValue;

        emit multiBidToggled(desiredValue);
    }

    function withdraw(address to, uint256 amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        payable(to).transfer(amount);
    }

    function bidOne(int16 x, int16 y)
        external
        payable
        onlyStage(Stage.Bidding)
        nonReentrant
    {
        address user = msg.sender;
        require(availableCapacityOf(user) != 0, "ERR_NO_BIDS_REMAINING");
        require(!isShiboshiZone(x, y), "ERR_NO_MINT_IN_SHIBOSHI_ZONE");
        _bid(user, x, y, msg.value);
    }

    function bidShiboshiZoneOne(
        int16 x,
        int16 y,
        bytes calldata signature
    ) external payable onlyStage(Stage.Bidding) nonReentrant {
        address user = msg.sender;
        require(
            _verifySigner(_hashMessage(user), signature),
            "ERR_SIGNATURE_INVALID"
        );
        require(isShiboshiZone(x, y), "ERR_NOT_IN_SHIBOSHI_ZONE");
        _bid(user, x, y, msg.value);
    }

    function bidMulti(
        int16[] calldata xs,
        int16[] calldata ys,
        uint256[] calldata prices
    ) external payable onlyStage(Stage.Bidding) nonReentrant {
        require(multiBidEnabled, "ERR_MULTI_BID_DISABLED");

        address user = msg.sender;

        uint256 length = xs.length;
        require(length != 0, "ERR_NO_INPUT");
        require(length == ys.length, "ERR_INPUT_LENGTH_MISMATCH");
        require(length == prices.length, "ERR_INPUT_LENGTH_MISMATCH");

        uint256 total;
        require(
            availableCapacityOf(user) >= length,
            "ERR_INSUFFICIENT_BIDS_REMAINING"
        );

        for (uint256 i = 0; i < length; i = _uncheckedInc(i)) {
            total += prices[i];
        }
        require(msg.value == total, "ERR_INSUFFICIENT_AMOUNT_SENT");

        for (uint256 i = 0; i < length; i = _uncheckedInc(i)) {
            int16 x = xs[i];
            int16 y = ys[i];
            require(!isShiboshiZone(x, y), "ERR_NO_MINT_IN_SHIBOSHI_ZONE");
            _bid(user, x, y, prices[i]);
        }
    }

    function bidShiboshiZoneMulti(
        int16[] calldata xs,
        int16[] calldata ys,
        uint256[] calldata prices,
        bytes calldata signature
    ) external payable onlyStage(Stage.Bidding) nonReentrant {
        require(multiBidEnabled, "ERR_MULTI_BID_DISABLED");

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
            _bid(user, x, y, prices[i]);
        }
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

            address user = getCurrentBid[x][y].bidder;
            require(user != address(0), "ERR_NO_BID_FOUND");
            landRegistry.mint(user, x, y);
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
        _mintPublicOrPrivate(msg.sender, x, y);
        emit LandBought(
            msg.sender,
            _encodeXY(x, y),
            x,
            y,
            msg.value,
            Stage.PrivateSale
        );
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
        _mintPublicOrPrivate(msg.sender, x, y);
        emit LandBought(
            msg.sender,
            _encodeXY(x, y),
            x,
            y,
            msg.value,
            Stage.PrivateSale
        );
    }

    function mintPublic(int16 x, int16 y)
        external
        payable
        onlyStage(Stage.PublicSale)
        nonReentrant
    {
        _mintPublicOrPrivate(msg.sender, x, y);
        emit LandBought(
            msg.sender,
            _encodeXY(x, y),
            x,
            y,
            msg.value,
            Stage.PublicSale
        );
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

    function _bid(
        address user,
        int16 x,
        int16 y,
        uint256 price
    ) internal onlyValid(x, y) {
        uint32 encXY = _encodeXY(x, y);
        Bid storage currentBid = getCurrentBid[x][y];
        if (currentBid.amount == 0) {
            // first bid on this land
            require(
                price >= getReservePrice(x, y),
                "ERR_INSUFFICIENT_AMOUNT_SENT"
            );
        } else {
            // attempt to outbid
            require(user != currentBid.bidder, "ERR_CANNOT_OUTBID_YOURSELF");
            require(
                price >= getOutbidPrice(currentBid.amount),
                "ERR_INSUFFICIENT_AMOUNT_SENT"
            );
            _safeTransferETHWithFallback(currentBid.bidder, currentBid.amount);
            winningsBidsOf[currentBid.bidder] -= 1;
            _statusOfBidsOf[currentBid.bidder][encXY] = 2;
        }

        currentBid.bidder = user;
        currentBid.amount = price;
        winningsBidsOf[user] += 1;

        if (_statusOfBidsOf[user][encXY] == 0) {
            // user has never bid on this land earlier
            _allBidsOf[user].push(encXY);
        }
        _statusOfBidsOf[user][encXY] = 1;

        emit BidCreated(user, encXY, x, y, price, block.timestamp);
    }

    function _mintPublicOrPrivate(
        address user,
        int16 x,
        int16 y
    ) internal onlyValid(x, y) {
        Bid storage currentBid = getCurrentBid[x][y];
        require(currentBid.amount == 0, "ERR_NOT_UP_FOR_SALE");
        require(
            msg.value == getReservePrice(x, y),
            "ERR_INSUFFICIENT_AMOUNT_SENT"
        );

        currentBid.bidder = user;
        currentBid.amount = msg.value;
        winningsBidsOf[user] += 1;

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

    /**
     * @notice Transfer ETH. If the ETH transfer fails, wrap the ETH and try send it as WETH.
     */
    function _safeTransferETHWithFallback(address to, uint256 amount) internal {
        if (!_safeTransferETH(to, amount)) {
            IWETH(weth).deposit{value: amount}();
            IERC20(weth).transfer(to, amount);
        }
    }

    /**
     * @notice Transfer ETH and return the success status.
     * @dev This function only forwards 30,000 gas to the callee.
     */
    function _safeTransferETH(address to, uint256 value)
        internal
        returns (bool)
    {
        (bool success, ) = to.call{value: value, gas: 30_000}(new bytes(0));
        return success;
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

    // Functions for BIT

    function _updateGrid(
        uint16 x,
        uint16 y,
        int8 val
    ) internal {
        for (uint16 i = x; i <= N; i = _addLowbit(i)) {
            for (uint16 j = y; j <= M; j = _addLowbit(j)) {
                unchecked {
                    _categoryBIT[i][j] += val;
                }
            }
        }
    }

    function _addLowbit(uint16 i) internal pure returns (uint16) {
        unchecked {
            return i + uint16(int16(i) & (-int16(i)));
        }
    }

    function _subLowbit(uint16 i) internal pure returns (uint16) {
        unchecked {
            return i - uint16(int16(i) & (-int16(i)));
        }
    }
}