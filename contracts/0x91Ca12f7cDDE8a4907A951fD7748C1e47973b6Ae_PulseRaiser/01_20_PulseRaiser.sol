// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./ClaimTracker.sol";
import "./Normalizer.sol";
import "./interfaces/IPulseRaiser.sol";

contract PulseRaiser is IPulseRaiser, Normalizer, ClaimTracker {
    // guard against ERC20 tokens that do now follow the ERC20, such as USDT
    using SafeERC20 for IERC20;
    // use sendValue to transfer native currency
    using Address for address payable;

    address public wallet;

    // 1111111111, see pppval
    uint256 private constant LOWEST_10_BITS_MASK = 1023;

    // DO NOT MODIFY the PERIODS constant
    uint8 public constant PERIODS = 30;
    uint256 public constant PERIOD_SECONDS = 1 days;

    //
    // - STORAGE
    //

    // The amount of points allocated to each day's normalized price
    uint32 public immutable points;
    // The sale starts at this time
    uint32 public launchAt;

    // Instead of storing 30 uint256 price values for 30 days, which takes 30 SSTOREs
    // use two slots to encode reduced prices for each day. A day's price is contained
    // in a 10-bit span, 25x10 == 250 bits (which fits into a uint256) + 5x10 which fits
    // into a second one.
    uint256[2] public encodedpp;

    // store point balances of all the participating accounts
    mapping(address => uint256) public pointsGained;

    // points allocated here
    uint256 public pointsLocal;
    uint256 public raiseLocal;

    // generation token
    IERC20 public token;
    uint256 public tokenPerPoint;

    bool public claimsEnabled;
    bytes32 public merkleRoot;

    address public immutable wrappedNative;

    constructor(
        address token_,
        address wrappedNative_,
        address wallet_,
        uint32 points_,
        address[] memory stables_,
        address[] memory assets_,
        address[] memory feeds_
    ) Normalizer() {
        // NOTE: ignore token_ being address(0); this would indicate
        // a collatable deployment that doesn't need a token
        require(wrappedNative_ != address(0), "Zero Wrapped Native Token");
        require(wallet_ != address(0), "Zero Wallet Addr");
        require(points_ > 0, "Zero Points");

        points = points_;

        wallet = wallet_;

        wrappedNative = wrappedNative_;

        if (token_ != address(0)) {
            token = IERC20(token_);
        }

        if (assets_.length > 0) {
            _controlAssetsWhitelisting(assets_, feeds_);
        }

        if (stables_.length > 0) {
            bool[] memory states_ = new bool[](stables_.length);
            for (uint8 t = 0; t < stables_.length; t++) {
                states_[t] = true;
            }
            _controlStables(stables_, states_);
        }

        encodedpp[
            0
        ] = 820545819910267688809181204034835617660015146854381185410943199127741239396;
        encodedpp[1] = 823165490612735;
    }

    function estimate(
        address token_,
        uint256 amount
    ) external view returns (uint256) {
        _requireSaleInProgress();
        _requireTokenWhitelisted(token_);

        uint256 numerator_ = points * _normalize(token_, amount);

        uint256 currentPrice_ = _currentPrice();

        return numerator_ / currentPrice_;
    }

    function normalize(
        address token_,
        uint256 amount_
    ) external view returns (uint256) {
        return _normalize(token_, amount_);
    }

    function currentPrice() external view returns (uint256) {
        _requireSaleInProgress();
        return _currentPrice();
    }

    function nextPrice() external view returns (uint256) {
        return _nextPrice();
    }

    //
    // - MUTATORS
    //
    function contribute(
        address token_,
        uint256 tokenAmount,
        string calldata referral
    ) external payable {
        _requireNotPaused();
        _requireSaleInProgress();
        _requireEOA();

        address account = msg.sender;
        uint256 normalizedAmount;

        bool tokenContributionOn = token_ != address(0) && tokenAmount > 0;

        if (tokenContributionOn) {
            _requireTokenWhitelisted(token_);
            normalizedAmount += _normalize(token_, tokenAmount);
        }

        if (msg.value > 0) {
            normalizedAmount += _normalize(wrappedNative, msg.value);
        }

        uint256 pointAmount = (points * normalizedAmount) / _currentPrice();

        require(pointAmount > 0, "Insufficient Contribution");

        pointsGained[account] += pointAmount;

        pointsLocal += pointAmount;

        raiseLocal += normalizedAmount;

        emit PointsGained(account, pointAmount);

        if (bytes(referral).length != 0) {
            emit Referral(referral, normalizedAmount);
        }

        if (tokenContributionOn) {
            IERC20(token_).safeTransferFrom(account, wallet, tokenAmount);
        }

        if (msg.value > 0) {
            payable(wallet).sendValue(msg.value);
        }
    }

    function claim(
        uint256 index_,
        uint256 points_,
        bytes32[] calldata proof_
    ) external {
        _requireNotPaused();
        _requireClaimsEnabled();
        address account = msg.sender;
        uint256 pointsTotal;

        // if there's a points record, delete and add token based on points held
        if (pointsGained[account] > 0) {
            pointsTotal += pointsGained[account];
            delete pointsGained[account];
        }

        // if a valid proof is supplied, mark used and add token based on points held
        if (proof_.length > 0) {
            require(_attempSetClaimed(index_), "Proof Already Used");
            bytes32 node = keccak256(
                abi.encodePacked(index_, account, points_)
            );

            require(
                MerkleProof.verifyCalldata(proof_, merkleRoot, node),
                "Invalid Merkle Proof"
            );

            pointsTotal += points_;
        }

        if (pointsTotal > 0) {
            uint256 amountToDistribute = pointsTotal * tokenPerPoint;
            token.safeTransfer(account, amountToDistribute);
            emit Distributed(account, amountToDistribute);
        }
    }

    //
    // - MUTATORS (ADMIN)
    //
    function launch(uint32 at) external {
        _checkOwner();
        require(launchAt == 0, "No Restarts");
        if (at == 0) {
            launchAt = uint32(block.timestamp);
        } else {
            require(at > block.timestamp, "Future Timestamp Expected");
            launchAt = at;
        }
        emit LaunchTimeSet(launchAt);
    }

    function setRaiseWallet(address wallet_) external {
        _checkOwner();
        require(wallet_ != address(0), "Zero Wallet Addr");

        emit RaiseWalletUpdated(wallet, wallet_);
        wallet = wallet_;
    }

    function modifyPriceBase(uint8 dayIndex_, uint16 priceBase_) external {
        _checkOwner();
        _requireDayInRange(dayIndex_);
        _requireValidPriceBase(priceBase_);

        uint8 encodedppIndex = (dayIndex_ < 25) ? 0 : 1;

        uint16[] memory priceBases = _splitPriceBases(encodedppIndex);

        uint8 from = (dayIndex_ < 25) ? 0 : 25;
        uint8 count = (dayIndex_ < 25) ? 25 : 5;
        priceBases[dayIndex_ - from] = priceBase_;

        encodedpp[encodedppIndex] = _encodePriceBasesMemory(priceBases, count);

        emit PriceBaseModified(dayIndex_, priceBase_);
    }

    function modifyPriceBases(uint16[] calldata priceBases) external {
        _checkOwner();
        require(priceBases.length == PERIODS, "Invalid Bases Count");
        for (uint8 i = 0; i < PERIODS; i++) {
            _requireValidPriceBase(priceBases[i]);
        }

        encodedpp[0] = _encodePriceBases(priceBases, 0, 25);
        encodedpp[1] = _encodePriceBases(priceBases, 25, 5);

        emit PriceBasesBatchModified();
    }

    function distribute(
        bytes32 merkleRoot_,
        uint256 pointsOtherNetworks
    ) external {
        _checkOwner();
        require(address(token) != address(0), "Not the Primary Contract");
        require(
            (launchAt > 0) &&
                (block.timestamp >= launchAt + PERIODS * PERIOD_SECONDS),
            "Wait for Sale to Complete"
        );
        require(!claimsEnabled, "Distribution Locked");
        claimsEnabled = true;

        uint256 pointsTotal = pointsLocal + pointsOtherNetworks;

        uint256 distributionSupply = token.balanceOf(address(this));

        tokenPerPoint = distributionSupply / pointsTotal;

        merkleRoot = merkleRoot_;
        emit TotalPointsAllocated(pointsTotal, tokenPerPoint);
    }

    //
    // - INTERNALS
    //
    function _currentPrice() internal view returns (uint256) {
        // if not yet launched will revert, otherwise will result
        // in days 0..N, where the largest legal N is 29, pppval
        // will revert starting with dayIndex == 30
        uint8 dayIndex = uint8((block.timestamp - launchAt) / PERIOD_SECONDS);

        return _pppval(dayIndex);
    }

    function _nextPrice() internal view returns (uint256) {
        uint256 tmrwIndex = ((block.timestamp - launchAt) / PERIOD_SECONDS) + 1;

        if (tmrwIndex > PERIODS - 1) return 0;

        return _pppval(uint8(tmrwIndex));
    }

    function _pppval(uint8 dayIndex) internal view returns (uint256 price_) {
        _requireDayInRange(dayIndex);
        if (dayIndex < 25)
            price_ =
                ((encodedpp[0] >> (dayIndex * 10)) & LOWEST_10_BITS_MASK) *
                1e16;
        else {
            uint8 adjDayIndex = dayIndex - 25;
            price_ =
                ((encodedpp[1] >> (adjDayIndex * 10)) & LOWEST_10_BITS_MASK) *
                1e16;
        }
    }

    function _requireValidPriceBase(uint16 pb) internal pure {
        require(pb <= 1023, "Price Base Exceeds 10 Bits");
        require(pb > 0, "Zero Price Base");
    }

    function _requireClaimsEnabled() internal view {
        require(claimsEnabled, "Wait for Claims");
    }

    function _encodePriceBases(
        uint16[] calldata bases_,
        uint8 from,
        uint8 count
    ) private pure returns (uint256 encode) {
        for (uint8 d = from; d < from + count; d++) {
            encode = encode | (uint256(bases_[d]) << ((d - from) * 10));
        }
    }

    function _encodePriceBasesMemory(
        uint16[] memory bases_,
        uint8 count
    ) private pure returns (uint256 encode) {
        for (uint8 d = 0; d < count; d++) {
            encode = encode | (uint256(bases_[d]) << (d * 10));
        }
    }

    function _splitPriceBases(
        uint8 encodedppIndex
    ) private view returns (uint16[] memory) {
        uint16[] memory split = new uint16[](25);
        for (uint8 dayIndex = 0; dayIndex < 25; dayIndex++) {
            split[dayIndex] = uint16(
                (encodedpp[encodedppIndex] >> (dayIndex * 10)) &
                    LOWEST_10_BITS_MASK
            );
        }
        return split;
    }

    function _requireSaleInProgress() internal view {
        require(launchAt > 0, "Sale Time Not Set");
        require(block.timestamp >= launchAt, "Sale Not In Progress");
        require(
            block.timestamp <= launchAt + PERIODS * PERIOD_SECONDS,
            "Sale Ended"
        );
    }

    function _requireEOA() internal view {
        require(msg.sender == tx.origin, "Caller Not an EOA");
    }

    function _requireDayInRange(uint8 dayIndex) internal pure {
        require(dayIndex < PERIODS, "Expected a 0-29 Day Index");
    }
}