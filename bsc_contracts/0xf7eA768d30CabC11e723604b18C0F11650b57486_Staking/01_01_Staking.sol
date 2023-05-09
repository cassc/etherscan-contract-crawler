/**
 *  SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.9;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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
    function trySub(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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
    function tryMul(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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
    function tryDiv(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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
    function tryMod(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(
        uint256 value,
        uint256 length
    ) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(
        bytes32 role,
        address account
    ) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

abstract contract AccessControl is Context, IAccessControl {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(
        bytes32 role,
        address account
    ) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(
        bytes32 role,
        address account
    ) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(
        bytes32 role,
        address account
    ) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(
        bytes32 role,
        address account
    ) public virtual override {
        require(
            account == _msgSender(),
            "AccessControl: can only renounce roles for self"
        );

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

interface IERC20 {
    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    function token0() external view returns (address);

    function token1() external view returns (address);
}

contract Staking is AccessControl {
    using SafeMath for uint256;
    bool inited;

    struct StakeInfo {
        uint256 tokenType; //质押代币类型
        address owner;
        uint256 stakeAmount;
        uint256 stakeTime;
        uint256 claimTotal;
        uint256 unStakeTime;
        uint256 stakeDay;
    }

    mapping(uint256 => address) public tokenAddress;
    mapping(uint256 => StakeInfo) public stakeList;
    mapping(address => mapping(uint256 => uint256)) public userStakeTotal; //用户质押总数  地址=>(类型=>数量)
    mapping(uint256 => mapping(uint256 => bool)) public tokenAmountAllow;

    mapping(uint256 => uint256) public stakeTotal;
    // uint256 public claimTotal;
    mapping(address => uint256) public userClaimTotal;
    mapping(uint256 => mapping(uint256 => uint256)) public apr;

    event Stake(
        address indexed user,
        uint256 indexed orderId,
        uint256 indexed stakeType,
        uint256 stakeAmount,
        uint256 stakeDday,
        uint256 timestamp,
        uint256 dayAmount
    );
    event Claim(
        address indexed user,
        uint256 indexed orderId,
        uint256 unStakeAmount,
        uint256 claimToken,
        uint256 timestamp
    );

    uint256 private orderId;

    uint256 public is_stop;

    uint256 public taxFee;
    uint256 public taxFee1;

    address public devAddress;
    address public devAddress1;

    struct Seeds {
        uint256 _r;
        uint256 _s;
        uint256 _v;
    }

    address public verifyAddress;

    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256(
            abi.encodePacked(
                "EIP712Domain(",
                "string name,",
                "string version,",
                "uint256 chainId,",
                "address verifyingContract",
                ")"
            )
        );

    bytes32 public constant DOMAIN_NAME = keccak256("Staking");
    bytes32 public constant DOMAIN_VERSION = keccak256("1");
    bytes32 public DOMAIN_SEPARATOR;
    uint256 public startTime;

    modifier isHuman() {
        require(tx.origin == msg.sender, "sorry humans only");
        // require(!msg.sender.isContract()," address can't be contract");
        _;
    }

    function init(
        address _tokenAddress0,
        address _tokenAddress1,
        uint256 _startTime,
        address _devAddress,
        address _devAddress1
    ) public {
        require(!inited, "inited");

        tokenAddress[0] = _tokenAddress0;
        tokenAddress[1] = _tokenAddress1;
        devAddress = _devAddress;
        devAddress1 = _devAddress1;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        orderId = 20000;
        taxFee = 100;
        taxFee1 = 100;

        uint256 currentChainId = getChainId();
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                DOMAIN_NAME,
                DOMAIN_VERSION,
                currentChainId,
                this
            )
        );

        startTime = _startTime;

        tokenAmountAllow[0][100] = true;
        tokenAmountAllow[0][300] = true;
        tokenAmountAllow[0][500] = true;
        tokenAmountAllow[0][1000] = true;
        tokenAmountAllow[0][3000] = true;
        tokenAmountAllow[0][5000] = true;

        tokenAmountAllow[1][100] = true;
        tokenAmountAllow[1][300] = true;
        tokenAmountAllow[1][500] = true;
        tokenAmountAllow[1][1000] = true;
        tokenAmountAllow[1][3000] = true;
        tokenAmountAllow[1][5000] = true;

        apr[0][15] = 21600;
        apr[0][30] = 25200;
        apr[0][90] = 32400;
        apr[0][180] = 43200;
        apr[0][360] = 54000;

        apr[1][15] = 21600;
        apr[1][30] = 25200;
        apr[1][90] = 32400;
        apr[1][180] = 43200;
        apr[1][360] = 54000;
        inited = true;
    }

    function stake(uint256 _type, uint256 _day, uint256 stakeAmount) public {
        require(is_stop == 0, "is stop");
        require(block.timestamp > startTime, "Time not yet arrived ");
        require(tokenAddress[_type] != address(0), "type not allow");
        require(stakeAmount > 0, "stakeAmount not be zero");
        require(apr[_type][_day] > 0, "apr not found");
        require(tokenAmountAllow[_type][stakeAmount], "amount not allow");
        stakeAmount = stakeAmount.mul(10 ** 18);
        IERC20(tokenAddress[_type]).transferFrom(
            msg.sender,
            address(this),
            stakeAmount
        );

        StakeInfo memory _stakeInfo = StakeInfo(
            _type,
            msg.sender,
            stakeAmount,
            block.timestamp,
            0,
            0,
            _day
        );
        stakeList[orderId] = _stakeInfo;

        userStakeTotal[msg.sender][_type] = userStakeTotal[msg.sender][_type]
            .add(stakeAmount);
        stakeTotal[_type] = stakeTotal[_type].add(stakeAmount);
        uint256 dayAmount = _stakeInfo
            .stakeAmount
            .mul(apr[_type][_day])
            .div(360)
            .div(10000);
        emit Stake(
            msg.sender,
            orderId,
            _type,
            stakeAmount,
            _day,
            block.timestamp,
            dayAmount
        );
        orderId++;
    }

    /**
     * @notice Recover the signatory from a signature
     * @param hash bytes32
     * @param v uint8
     * @param r bytes32
     * @param s bytes32
     */
    function getSignatory(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (address) {
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hash)
        );
        address signatory = ecrecover(digest, v, r, s);
        // Ensure the signatory is not null
        require(signatory != address(0), "INVALID_SIG");
        return signatory;
    }

    function checkSeeds(
        Seeds memory seeds,
        uint256 _orderId,
        uint256 claimAmount,
        uint256 timestamp,
        address _owner
    ) public view returns (bool) {
        uint8 v = uint8(seeds._v);
        bytes32 s = bytes32(seeds._s);
        bytes32 r = bytes32(seeds._r);

        bytes32 hash = keccak256(
            abi.encode(
                keccak256(
                    abi.encodePacked(
                        "payment(uint256 orderId,uint256 claimAmount,uint256 timestamp,address owner)"
                    )
                ),
                _orderId,
                claimAmount,
                timestamp,
                _owner
            )
        );
        if (getSignatory(hash, v, r, s) == verifyAddress) {
            return true;
        } else {
            return false;
        }
    }

    function unStake(
        uint256 _orderId,
        uint256 claimAmount,
        uint256 timestamp,
        Seeds memory seeds
    ) public {
        require(is_stop == 0, "is stop");

        require(
            checkSeeds(seeds, _orderId, claimAmount, timestamp, msg.sender),
            "signature invalid"
        );

        StakeInfo storage _stakeInfo = stakeList[_orderId];
        uint256 _stakeDay = _stakeInfo.stakeDay;
        uint256 left_time = block.timestamp.sub(_stakeInfo.stakeTime);
        uint256 left_day = left_time / 1 days;
        require(_stakeDay <= left_day, "unstake time is not up yet");

        require(_stakeInfo.owner == msg.sender, "invalid owner");
        require(_stakeInfo.unStakeTime == 0, "has unStake");
        require(claimAmount == _stakeInfo.stakeAmount, "claimAmount is error");

        _stakeInfo.claimTotal = claimAmount;
        _stakeInfo.unStakeTime = timestamp;
        uint256 stakeType = _stakeInfo.tokenType;
        userStakeTotal[msg.sender][stakeType] = userStakeTotal[msg.sender][
            stakeType
        ].sub(_stakeInfo.stakeAmount);
        stakeTotal[stakeType] = stakeTotal[stakeType].sub(
            _stakeInfo.stakeAmount
        );

        // claimTotal = claimTotal.add(claimAmount);
        // userClaimTotal[msg.sender] = userClaimTotal[msg.sender].add(claimAmount);

        uint256 _feeAmount = _stakeInfo.stakeAmount.mul(taxFee).div(10000);
        uint256 _feeAmount1 = _stakeInfo.stakeAmount.mul(taxFee1).div(10000);

        uint256 _fee = _feeAmount.add(_feeAmount1);
        uint256 _unstake = _stakeInfo.stakeAmount.sub(_fee);
        IERC20(tokenAddress[stakeType]).transfer(msg.sender, _unstake);
        IERC20(tokenAddress[stakeType]).transfer(devAddress, _feeAmount);
        IERC20(tokenAddress[stakeType]).transfer(devAddress1, _feeAmount1);
        //    IERC20(tokenAddress).transfer(msg.sender,claimAmount);

        emit Claim(msg.sender, _orderId, _unstake, claimAmount, timestamp);
    }

    function getChainId() public view returns (uint256 id) {
        // no-inline-assembly
        assembly {
            id := chainid()
        }
    }

    function setStop(uint256 _stop) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not a admin"
        );
        is_stop = _stop;
    }

    function setTokenAddress(uint256 _type, address _tokenAddress) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not a admin"
        );
        tokenAddress[_type] = _tokenAddress;
    }

    function setTokenAmount(
        uint256 _type,
        uint256 _tokenAmount,
        bool _bool
    ) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not a admin"
        );
        tokenAmountAllow[_type][_tokenAmount] = _bool;
    }

    function setApr(uint256 _type, uint256 _day, uint256 _apr) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not a admin"
        );
        apr[_type][_day] = _apr;
    }

    function setVeirfyAddress(address _veirfyAddress) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not a admin"
        );
        verifyAddress = _veirfyAddress;
    }

    function setStartTime(uint256 _startTime) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not a admin"
        );
        startTime = _startTime;
    }

    function sweep(uint256 _type, address _tokenaddress) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Caller is not a admin"
        );
        if (_type == 0) {
            payable(msg.sender).transfer(address(this).balance);
        } else {
            uint256 amount = IERC20(_tokenaddress).balanceOf(address(this));
            if (amount > 0) {
                IERC20(_tokenaddress).transfer(msg.sender, amount);
            }
        }
    }
}