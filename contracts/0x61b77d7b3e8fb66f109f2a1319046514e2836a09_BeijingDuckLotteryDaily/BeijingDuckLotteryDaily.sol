/**
 *Submitted for verification at Etherscan.io on 2023-06-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }

    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function burn(uint256 amount) external;
}
library Address {
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                require(target.code.length > 0, "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        if (returndata.length > 0) {
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}
interface IERC20Permit {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
}
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            forceApprove(token, spender, oldAllowance - value);
        }
    }

    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {

        (bool success, bytes memory returndata) = address(token).call(data);
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
    }
}
library EnumerableSet {

    struct Set {
        bytes32[] _values;
        mapping(bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                set._values[toDeleteIndex] = lastValue;
                set._indexes[lastValue] = valueIndex;
            }

            set._values.pop();

            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    struct Bytes32Set {
        Set _inner;
    }

    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

contract BeijingDuckLotteryDaily is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    struct Lottery {
        uint256 lotteryID;
        uint256 startTime;
        uint256 endTime;
        uint256 priceTicketInDuck;
        uint256 totalDuck;
        uint32 numberWinner;
        address winner;
        bool claimTicket;
    }

    uint256 public NONCE_LOTTERY = 0;
    mapping (uint256 => Lottery) public lotteries;

    uint256 public constant MIN_LENGTH_LOTTERY = 9 minutes;
    uint256 public constant MAX_LENGTH_LOTTERY = 31 days + 5 minutes;

    IERC20 public immutable duckToken;

    mapping(uint256 => mapping(uint32 => address)) public ticketUsers;
    mapping(uint256 => mapping(address => EnumerableSet.UintSet)) private userTickets;

    mapping(uint256 => EnumerableSet.UintSet) private allNumberTickets;

    mapping(address => EnumerableSet.UintSet) private winTickets;

    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    event CreateLottery(uint256 indexed lotteryID, uint256 startTime, uint256 endTime, uint256 priceTicketInDuck);
    event BuyTickets(address indexed user, uint256 indexed lotteryID, uint256 amountDuckToBuy, uint32[] numberTickets);
    event PickWinner(uint256 indexed lotteryID, uint32 numberWinner, address winner);
    event TicketsClaim(address indexed user, uint256 rewardInDuckToClaim);
    event AdminTokenRecovery(address token, uint256 amount);

    constructor() {
        duckToken = IERC20(0x7cB56e7dFFeab266Cdd450adAC67682D8aeB2193);
    }

    function createLottery(uint256 _startTime, uint256 _endTime, uint256 _priceTicketInDuck) external onlyOwner nonReentrant {
        require(_startTime < 1e10 && _endTime < 1e10 && _endTime > block.timestamp, "Timestamp invalid");
        require(_startTime < _endTime && (_endTime - _startTime) > MIN_LENGTH_LOTTERY && (_endTime - _startTime) < MAX_LENGTH_LOTTERY, "Period");
        require(_priceTicketInDuck > 0, "PriceTicketInDuck is not valid");

        Lottery memory _lottery;
        _lottery.lotteryID = NONCE_LOTTERY;
        _lottery.startTime = _startTime;
        _lottery.endTime = _endTime;
        _lottery.priceTicketInDuck = _priceTicketInDuck;
        _lottery.claimTicket = false;
        
        lotteries[NONCE_LOTTERY] = _lottery;

        NONCE_LOTTERY ++;
        emit CreateLottery(_lottery.lotteryID, _startTime, _endTime, _priceTicketInDuck);
    }

    function buyTickets(uint256 _lotteryID, uint32[] calldata _ticketNumbers) external notContract nonReentrant {
        uint256 length_ticketNumbers = _ticketNumbers.length;
        require(length_ticketNumbers > 0, "No ticket specified");
        require(length_ticketNumbers < 11, "Too many tickets one buy");
        require(length_ticketNumbers + userTickets[_lotteryID][msg.sender].length() < 61, "Over quantity many tickets can buy");

        require(block.timestamp > lotteries[_lotteryID].startTime && block.timestamp < lotteries[_lotteryID].endTime, "Not the time to buy");

        uint256 amountDuckToTransfer = _calculateTotalPriceForBuyTickets(lotteries[_lotteryID].priceTicketInDuck, length_ticketNumbers);

        duckToken.safeTransferFrom(address(msg.sender), address(this), amountDuckToTransfer);

        lotteries[_lotteryID].totalDuck += amountDuckToTransfer;

        for (uint256 i = 0; i < length_ticketNumbers;) {
            uint32 thisTicketNumber = _ticketNumbers[i];
            require((thisTicketNumber > 99999) && (thisTicketNumber < 1000000), "Outside range");
            require(!allNumberTickets[_lotteryID].contains(thisTicketNumber), "Ticket already exists");

            ticketUsers[_lotteryID][thisTicketNumber] = msg.sender;
            userTickets[_lotteryID][msg.sender].add(thisTicketNumber);
            allNumberTickets[_lotteryID].add(thisTicketNumber);
            unchecked {
                i++;
            }
        }

        emit BuyTickets(msg.sender, _lotteryID, amountDuckToTransfer, _ticketNumbers);
    }

    function pickWinner(uint256 _lotteryID) external onlyOwner nonReentrant {
        require(lotteries[_lotteryID].numberWinner == 0, "There was winner");
        require(lotteries[_lotteryID].endTime < block.timestamp, "The lottery is not over yet");
        require(allNumberTickets[_lotteryID].length() > 0, "No players");
        
        uint256 index = _generatorRandomIndex(_lotteryID);
        uint32 _numberWinner = uint32(allNumberTickets[_lotteryID].at(index));
        address _winner = ticketUsers[_lotteryID][_numberWinner];
        lotteries[_lotteryID].numberWinner = _numberWinner;
        lotteries[_lotteryID].winner = _winner;

        winTickets[_winner].add(_lotteryID);

        uint256 amountBurnDuck = lotteries[_lotteryID].totalDuck * 10 / 100;
        duckToken.burn(amountBurnDuck);

        emit PickWinner(_lotteryID, _numberWinner, _winner);
    }

    function claimTickets() external notContract nonReentrant {
        require(winTickets[msg.sender].length() > 0, "No prizes to collect");
        uint256 rewardInDuckToTransfer = _calculateTotalDuckForClaimTickets(msg.sender);

        duckToken.safeTransfer(msg.sender, rewardInDuckToTransfer);

        uint256 length = winTickets[msg.sender].length();
        for (uint256 i = 0; i < length;) {
            uint256 _lotteryID = winTickets[msg.sender].at(length - 1 - i);
            lotteries[_lotteryID].claimTicket = true;
            winTickets[msg.sender].remove(_lotteryID);
            unchecked {
                i++;
            }
        }

        emit TicketsClaim(msg.sender, rewardInDuckToTransfer);
    }

    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        require(_tokenAddress != address(duckToken), "Cannot be DUCK token");

        IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);

        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }

    function _calculateTotalDuckForClaimTickets(address winner) private view returns (uint256 reward) {
        uint256 length_winTickets = winTickets[winner].length();
        for (uint256 i = 0; i < length_winTickets;) {
            if (lotteries[winTickets[winner].at(i)].winner == winner && lotteries[winTickets[winner].at(i)].claimTicket == false){
                reward += (lotteries[winTickets[winner].at(i)].totalDuck * 90 / 100);
            }
            unchecked {
                i++;
            }
        }
    }

    function _generatorRandomIndex(uint256 _lotteryID) private view returns (uint256) {
        return uint256(keccak256(abi.encode(block.timestamp,  allNumberTickets[_lotteryID].values()))) % allNumberTickets[_lotteryID].length();
    }

    function _calculateTotalPriceForBuyTickets(uint256 _priceTicket, uint256 _numberTickets) internal pure returns (uint256) {
        return _priceTicket * _numberTickets;
    }

    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    function getUserTickets(uint256 _lotteryID, address _user) public view returns (uint256[] memory) {
        return userTickets[_lotteryID][_user].values();
    }

    function getAllNumberTickets(uint256 _lotteryID) public view returns (uint256[] memory) {
        return allNumberTickets[_lotteryID].values();
    }

    function getWinTickets(address _user) public view returns (uint256[] memory) {
        return winTickets[_user].values();
    }

    function generatorRandomIndex(uint256 _lotteryID) public view returns (uint256) {
        return _generatorRandomIndex(_lotteryID);
    }

    function calculateTotalDuckForClaimTickets(address winner) public view returns (uint256) {
        return _calculateTotalDuckForClaimTickets(winner);
    }
}