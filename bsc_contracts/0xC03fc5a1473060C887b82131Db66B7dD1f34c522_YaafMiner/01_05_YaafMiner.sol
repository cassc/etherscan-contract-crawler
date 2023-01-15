// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

contract YaafMiner is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    // constants
    uint256 constant START_DELAY_DAYS = 0;
    uint256 constant YaafMiner_TO_BREEDING_BREEDER = 1080000;
    uint256 constant PSN = 10000;
    uint256 constant PSNH = 5000;
    uint256 constant PercentDiv = 10000;
    uint256 constant PercentDevFee = 150;
    uint256 constant PercentMarketFee = 250;

    IERC20 public busd;

    address public addressReceive;
    address public dev;
    address private signer;
    // attributes
    uint256 public marketYaafMiner;
    uint256 public startTime = 6666666666;
    uint256[] public ReferralCommissions = [1000, 200, 50, 50];

    mapping(uint256 => bool) public signedIds;
    mapping(address => uint256) private depositTotal;
    mapping(address => uint256) private lastBreeding;
    mapping(address => uint256) private breedingBreeders;
    mapping(address => uint256) private claimedYaafMiner;
    mapping(address => uint256) private tempClaimedYaafMiner;
    mapping(address => uint256) private lvlonecommisions;
    mapping(address => uint256) private lvltwocommisions;
    mapping(address => uint256) private lvlthreecommisions;
    mapping(address => uint256) private lvlfourcommisions;
    mapping(address => address) private referrals;
    mapping(address => ReferralData) private referralData;

    // structs
    /* An ECDSA signature. */
    struct Sig {
        /* v parameter */
        uint8 v;
        /* r parameter */
        bytes32 r;
        /* s parameter */
        bytes32 s;
    }

    struct CouponSigData {
        uint256 id;
        address owner;
        uint256 amount;
        uint256 payAmount;
    }

    struct ReferralData {
        address[] invitees;
        uint256 rebates;
        address[] lvloneinvitees;
        uint256 lvlonecommisions;
        address[] lvltwoinvitees;
        uint256 lvltwocommisions;
        address[] lvlthreeinvitees;
        uint256 lvlthreecommisions;
        address[] lvlfourinvitees;
        uint256 lvlfourcommisions;
    }

    modifier onlyOpen() {
        require(block.timestamp > startTime, "not open");
        _;
    }

    modifier onlyStartOpen() {
        require(marketYaafMiner > 0, "not start open");
        _;
    }

    // events
    event Create(
        address indexed sender,
        uint256 indexed logTime,
        uint256 payAmount,
        uint256 amount,
        uint256 indexed couponID
    );
    event Merge(
        address indexed sender,
        uint256 indexed logTime,
        uint256 amount
    );
    event Rebalance(
        address indexed sender,
        uint256 indexed logTime,
        uint256 amount
    );
    event AddCoupon(uint256 id);

    constructor(
        IERC20 _busdContract,
        address _signer,
        address _addressReceive,
        address _dev
    ) {
        busd = _busdContract;
        signer = _signer;
        addressReceive = _addressReceive;
        dev = _dev;
        startTime = TimeCheck() + 2 days;
    }

    function setSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    function setAddressReceive(address _addressReceive) public onlyOwner {
        addressReceive = _addressReceive;
    }

    function setDev(address _dev) public onlyOwner {
        dev = _dev;
    }

    // Create YaafMiner
    function createYaafMiner(uint256 amount, address _ref)
        external
        payable
        onlyStartOpen
    {
        require(amount >= 1 ether, "Input value must more then 1BUSD");
        busd.safeTransferFrom(msg.sender, address(this), amount);
        depositTotal[msg.sender] += amount;
        uint256 YaafMinerDivide = calculateYaafMinerDivide(
            amount,
            busd.balanceOf(address(this)) - amount
        );
        YaafMinerDivide -= marketFee(YaafMinerDivide);
        YaafMinerDivide -= devFee(YaafMinerDivide);

        busd.safeTransfer(addressReceive, marketFee(amount));
        busd.safeTransfer(dev, devFee(amount));

        claimedYaafMiner[msg.sender] += YaafMinerDivide;
        divideYaafMiner(_ref);

        emit Create(msg.sender, block.timestamp, amount, 0, 0);
    }

    // Divide YaafMiner
    function divideYaafMiner(address _ref) public onlyStartOpen {
        if (
            _ref == msg.sender ||
            _ref == address(0) ||
            breedingBreeders[_ref] == 0
        ) {
            _ref = dev;
        }

        if (referrals[msg.sender] == address(0)) {
            referrals[msg.sender] = _ref;

            address upline = _ref;
            for (uint256 i = 0; i < 4; i++) {
                if (upline != address(0)) {
                    referralData[upline].invitees.push(msg.sender); //all
                    if (i == 0) {
                        referralData[upline].lvloneinvitees.push(msg.sender); //1
                    }
                    if (i == 1) {
                        referralData[upline].lvltwoinvitees.push(msg.sender); //2
                    }
                    if (i == 2) {
                        referralData[upline].lvlthreeinvitees.push(msg.sender); //3
                    }
                    if (i == 3) {
                        referralData[upline].lvlfourinvitees.push(msg.sender); //4
                    }

                    if (upline == referrals[upline]) {
                        break;
                    } else {
                        upline = referrals[upline];
                    }
                } else break;
            }
        }

        uint256 YaafMinerUsed = getMyYaafMiner(msg.sender);
        uint256 newBreeders = YaafMinerUsed / YaafMiner_TO_BREEDING_BREEDER;
        breedingBreeders[msg.sender] += newBreeders;
        claimedYaafMiner[msg.sender] = 0;
        lastBreeding[msg.sender] = block.timestamp > startTime
            ? block.timestamp
            : startTime;

        //////////////////
        if (referrals[msg.sender] != address(0)) {
            address upline = referrals[msg.sender];
            for (uint256 i = 0; i < 4; i++) {
                if (upline != address(0)) {
                    uint256 amount = (YaafMinerUsed * ReferralCommissions[i]) /
                        PercentDiv;
                    claimedYaafMiner[upline] += amount;
                    tempClaimedYaafMiner[upline] += amount;

                    if (i == 0) {
                        lvlonecommisions[upline] += amount;
                    }
                    if (i == 1) {
                        lvltwocommisions[upline] += amount;
                    }
                    if (i == 2) {
                        lvlthreecommisions[upline] += amount;
                    }
                    if (i == 3) {
                        lvlfourcommisions[upline] += amount;
                    }
                    upline = referrals[upline];
                } else break;
            }
        }

        marketYaafMiner += YaafMinerUsed / 5;
    }

    // Merge YaafMiner
    function mergeYaafMiner() external onlyOpen {
        uint256 hasYaafMiner = getMyYaafMiner(msg.sender);
        uint256 YaafMinerValue = calculateYaafMinerMerge(hasYaafMiner);
        require(
            busd.balanceOf(address(this)) > YaafMinerValue,
            "Insufficient balance"
        );

        if (tempClaimedYaafMiner[msg.sender] > 0) {
            referralData[msg.sender].rebates += calculateYaafMinerMerge(
                tempClaimedYaafMiner[msg.sender]
            );
            referralData[msg.sender]
                .lvlonecommisions += calculateYaafMinerMerge(
                lvlonecommisions[msg.sender]
            );
            referralData[msg.sender]
                .lvltwocommisions += calculateYaafMinerMerge(
                lvltwocommisions[msg.sender]
            );
            referralData[msg.sender]
                .lvlthreecommisions += calculateYaafMinerMerge(
                lvlthreecommisions[msg.sender]
            );
            referralData[msg.sender]
                .lvlfourcommisions += calculateYaafMinerMerge(
                lvlfourcommisions[msg.sender]
            );
        }

        claimedYaafMiner[msg.sender] = 0;
        tempClaimedYaafMiner[msg.sender] = 0;
        lvlonecommisions[msg.sender] = 0;
        lvltwocommisions[msg.sender] = 0;
        lvlthreecommisions[msg.sender] = 0;
        lvlfourcommisions[msg.sender] = 0;
        lastBreeding[msg.sender] = block.timestamp;
        marketYaafMiner += hasYaafMiner;

        uint256 realReward = YaafMinerValue -
            marketFee(YaafMinerValue) -
            devFee(YaafMinerValue);
        busd.safeTransfer(msg.sender, realReward);
        // fee
        busd.safeTransfer(addressReceive, marketFee(YaafMinerValue));
        busd.safeTransfer(dev, devFee(YaafMinerValue));

        emit Merge(msg.sender, block.timestamp, realReward);
    }

    function importProfit(uint256 _amount) external payable onlyOwner {
        require(marketYaafMiner > 0, "Market not open");
        busd.safeTransferFrom(msg.sender, address(this), _amount);
        emit Rebalance(msg.sender, block.timestamp, _amount);
    }

    //only owner
    function seedMarket(uint256 _amount) external payable onlyOwner {
        require(marketYaafMiner == 0);
        require(_amount >= 1 ether, "Input value too low");

        busd.safeTransferFrom(msg.sender, address(this), _amount);

        startTime = TimeCheck() + 1 days * START_DELAY_DAYS;
        marketYaafMiner = 108000000000;
    }

    function TimeCheck() public view returns (uint256) {
        return block.timestamp;
    }

    function YaafMinerRewards(address _address) public view returns (uint256) {
        return calculateYaafMinerMerge(getMyYaafMiner(_address));
    }

    function getMyYaafMiner(address _address) public view returns (uint256) {
        return
            claimedYaafMiner[_address] + getYaafMinerSinceLastDivide(_address);
    }

    function getClaimYaafMiner(address _address) public view returns (uint256) {
        return claimedYaafMiner[_address];
    }

    function getYaafMinerSinceLastDivide(address _address)
        public
        view
        returns (uint256)
    {
        if (block.timestamp > startTime) {
            uint256 secondsPassed = min(
                YaafMiner_TO_BREEDING_BREEDER,
                block.timestamp - lastBreeding[_address]
            );
            return secondsPassed * breedingBreeders[_address];
        } else {
            return 0;
        }
    }

    function getTempClaimYaafMiner(address _address)
        public
        view
        returns (uint256)
    {
        return tempClaimedYaafMiner[_address];
    }

    function getPoolAmount() public view returns (uint256) {
        return busd.balanceOf(address(this));
    }

    function getBreedingBreeders(address _address)
        public
        view
        returns (uint256)
    {
        return breedingBreeders[_address];
    }

    function getReferralData(address _address)
        public
        view
        returns (ReferralData memory)
    {
        return referralData[_address];
    }

    function getReferralAllRebate(address _address)
        public
        view
        returns (uint256)
    {
        return referralData[_address].rebates;
    }

    function getReferralAllInvitee(address _address)
        public
        view
        returns (uint256)
    {
        return referralData[_address].invitees.length;
    }

    function calculateYaafMinerDivide(uint256 _eth, uint256 _contractBalance)
        private
        view
        returns (uint256)
    {
        return calculateTrade(_eth, _contractBalance, marketYaafMiner);
    }

    function calculateYaafMinerMerge(uint256 yaafMiner)
        public
        view
        returns (uint256)
    {
        return
            calculateTrade(
                yaafMiner,
                marketYaafMiner,
                busd.balanceOf(address(this))
            );
    }

    function calculateApr(address _address) public view returns (uint256) {
        uint256 yaafMinerValue = depositTotal[_address];
        uint256 newbreedingBreeders = calculateYaafMinerDivide(
            yaafMinerValue,
            busd.balanceOf(address(this)) - yaafMinerValue
        );
        return
            newbreedingBreeders == 0
                ? (PercentDiv * 365 * (1 days)) / YaafMiner_TO_BREEDING_BREEDER
                : (PercentDiv * 365 * (1 days) * breedingBreeders[_address]) /
                    newbreedingBreeders;
    }

    function calculateTrade(
        uint256 rt,
        uint256 rs,
        uint256 bs
    ) private pure returns (uint256) {
        // return (PSN * bs) / (PSNH + ((PSN * rs + PSNH * rt) / rt));
        return
            rt == 0 || rs == 0
                ? 0
                : (PSN * bs * rt) / (PSNH * rt + PSN * rs + PSNH * rt);
    }

    function devFee(uint256 _amount) private pure returns (uint256) {
        return (_amount * PercentDevFee) / PercentDiv;
    }

    function marketFee(uint256 _amount) private pure returns (uint256) {
        return (_amount * PercentMarketFee) / PercentDiv;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function verifyMessage(
        bytes32 _hashedMessage,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public view returns (bool) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(
            abi.encodePacked(prefix, _hashedMessage)
        );
        return ecrecover(prefixedHashMessage, _v, _r, _s) == signer;
    }

    function applyCoupon(
        CouponSigData calldata coupon,
        Sig calldata sig,
        address _ref
    ) external {
        require(
            verifyMessage(keccak256(abi.encode(coupon)), sig.v, sig.r, sig.s),
            "incorrect signature"
        );
        require(!signedIds[coupon.id], "The coupon has used");
        require(coupon.owner == msg.sender, "Not signature owner");

        signedIds[coupon.id] = true;
        if (coupon.payAmount > 0) {
            busd.safeTransferFrom(msg.sender, address(this), coupon.payAmount);
            busd.safeTransfer(addressReceive, marketFee(coupon.payAmount));
            busd.safeTransfer(dev, devFee(coupon.payAmount));
            depositTotal[msg.sender] += coupon.payAmount;
        }
        uint256 YaafMinerDivide = calculateYaafMinerDivide(
            coupon.amount,
            busd.balanceOf(address(this)) - coupon.payAmount
        );
        YaafMinerDivide -= devFee(YaafMinerDivide);
        claimedYaafMiner[msg.sender] += YaafMinerDivide;
        divideYaafMiner(_ref);

        emit Create(
            msg.sender,
            block.timestamp,
            coupon.payAmount,
            coupon.amount,
            coupon.id
        );
        emit AddCoupon(coupon.id);
    }
}