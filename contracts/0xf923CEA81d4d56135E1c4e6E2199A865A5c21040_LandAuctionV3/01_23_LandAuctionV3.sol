// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@unification-com/xfund-router/contracts/lib/ConsumerBase.sol";

import "./interfaces/ILandRegistry.sol";
import "./LandAuction.sol";

contract LandAuctionV3 is ConsumerBase, Ownable, ReentrancyGuard {
    uint32 constant clearLow = 0xffff0000;
    uint32 constant clearHigh = 0x0000ffff;
    uint32 constant factor = 0x10000;

    int16 public constant xLow = -96;
    int16 public constant yLow = -99;
    int16 public constant xHigh = 96;
    int16 public constant yHigh = 99;

    enum Stage {
        Default,
        Inactive1,
        Inactive2,
        PublicSale
    }

    uint256 public ethToShib;
    bool public multiMintEnabled;

    LandAuction public auctionV1;
    LandAuction public auctionV2;
    ILandRegistry public landRegistry;

    IERC20 public immutable SHIB;
    Stage public currentStage;

    mapping(address => uint32[]) private _allMintsOf;

    event StageSet(uint256 stage);
    event multiMintToggled(bool newValue);
    event LandBoughtWithShib(
        address indexed user,
        uint32 indexed encXY,
        int16 x,
        int16 y,
        uint256 price,
        uint256 time,
        Stage saleStage
    );

    constructor(
        IERC20 _shib,
        LandAuction _auctionV1,
        LandAuction _auctionV2,
        ILandRegistry _landRegistry,
        address _router,
        address _xfund
    ) ConsumerBase(_router, _xfund) {
        SHIB = _shib;
        auctionV1 = _auctionV1;
        auctionV2 = _auctionV2;
        landRegistry = _landRegistry;
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

    function bidInfoOf(address user)
        external
        view
        returns (int16[] memory, int16[] memory)
    {
        (int16[] memory xsV1, int16[] memory ysV1) = auctionV2.bidInfoOf(user);
        uint256 lengthV1 = xsV1.length;

        uint256 bidCount = _allMintsOf[user].length;
        int16[] memory xs = new int16[](bidCount + lengthV1);
        int16[] memory ys = new int16[](bidCount + lengthV1);

        for (uint256 i = 0; i < lengthV1; i = _uncheckedInc(i)) {
            xs[i] = xsV1[i];
            ys[i] = ysV1[i];
        }

        uint256 ptr = lengthV1;
        uint32[] storage allMints = _allMintsOf[user];
        uint256 length = allMints.length;

        for (uint256 i = 0; i < length; i = _uncheckedInc(i)) {
            (int16 x, int16 y) = _decodeXY(allMints[i]);
            xs[ptr] = x;
            ys[ptr] = y;
            ptr = _uncheckedInc(ptr);
        }

        return (xs, ys);
    }

    function getReservePriceShib(int16 x, int16 y)
        public
        view
        onlyValid(x, y)
        returns (uint256)
    {
        // this will revert if not up for sale
        uint256 reservePrice = auctionV1.getReservePrice(x, y);

        // to check if this was bid on, in the bidding stage
        (uint256 cAmount, ) = auctionV1.getCurrentBid(x, y);
        require(cAmount == 0, "ERR_ALREADY_BOUGHT");

        uint256 reservePriceInShib = (ethToShib * reservePrice) / 1 ether;

        require(reservePriceInShib > 0, "ERR_BAD_PRICE");
        return reservePriceInShib;
    }

    function mintPublicWithShib(int16 x, int16 y)
        external
        onlyStage(Stage.PublicSale)
        nonReentrant
    {
        // this will revert if not up for sale
        uint256 reservePriceInShib = getReservePriceShib(x, y);

        address user = msg.sender;

        SHIB.transferFrom(user, address(this), reservePriceInShib);

        uint32 encXY = _encodeXY(x, y);
        _allMintsOf[user].push(encXY);

        landRegistry.mint(user, x, y);

        emit LandBoughtWithShib(
            user,
            encXY,
            x,
            y,
            reservePriceInShib,
            block.timestamp,
            Stage.PublicSale
        );
    }

    function mintPublicWithShibMulti(
        int16[] calldata xs,
        int16[] calldata ys,
        uint256[] calldata prices
    ) external onlyStage(Stage.PublicSale) nonReentrant {
        require(multiMintEnabled, "ERR_MULTI_BID_DISABLED");

        uint256 length = xs.length;
        require(length != 0, "ERR_NO_INPUT");
        require(length == ys.length, "ERR_INPUT_LENGTH_MISMATCH");
        require(length == prices.length, "ERR_INPUT_LENGTH_MISMATCH");

        uint256 total;
        for (uint256 i = 0; i < length; i = _uncheckedInc(i)) {
            total += prices[i];
        }

        address user = msg.sender;

        SHIB.transferFrom(user, address(this), total);

        for (uint256 i = 0; i < length; i = _uncheckedInc(i)) {
            int16 x = xs[i];
            int16 y = ys[i];

            uint256 reservePriceInShib = getReservePriceShib(x, y);
            require(
                reservePriceInShib == prices[i],
                "ERR_INSUFFICIENT_SHIB_SENT"
            );

            uint32 encXY = _encodeXY(x, y);
            _allMintsOf[user].push(encXY);

            landRegistry.mint(user, x, y);

            emit LandBoughtWithShib(
                user,
                encXY,
                x,
                y,
                prices[i],
                block.timestamp,
                Stage.PublicSale
            );
        }
    }

    function setStage(uint256 stage) external onlyOwner {
        currentStage = Stage(stage);
        emit StageSet(stage);
    }

    function setLandRegistry(address _landRegistry) external onlyOwner {
        landRegistry = ILandRegistry(_landRegistry);
    }

    function setAuctionV1(LandAuction _auctionV1) external onlyOwner {
        auctionV1 = _auctionV1;
    }

    function setAuctionV2(LandAuction _auctionV2) external onlyOwner {
        auctionV2 = _auctionV2;
    }

    function setMultiMint(bool desiredValue) external onlyOwner {
        require(multiMintEnabled != desiredValue, "ERR_ALREADY_DESIRED_VALUE");
        multiMintEnabled = desiredValue;

        emit multiMintToggled(desiredValue);
    }

    function increaseRouterAllowance(uint256 _amount) external onlyOwner {
        require(_increaseRouterAllowance(_amount), "ERR_FAILED_TO_INCREASE");
    }

    function getData(address _provider, uint256 _fee)
        external
        onlyOwner
        returns (bytes32)
    {
        bytes32 data = 0x4554482e534849422e50522e4156430000000000000000000000000000000000; // ETH.SHIB.PR.AVC
        return _requestData(_provider, _fee, data);
    }

    function withdrawShib(address to, uint256 amount) external onlyOwner {
        SHIB.transfer(to, amount);
    }

    function withdrawAny(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).transfer(to, amount);
    }

    function receiveData(uint256 _price, bytes32) internal override {
        ethToShib = _price;
    }

    function _uncheckedInc(uint256 i) internal pure returns (uint256) {
        unchecked {
            return i + 1;
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