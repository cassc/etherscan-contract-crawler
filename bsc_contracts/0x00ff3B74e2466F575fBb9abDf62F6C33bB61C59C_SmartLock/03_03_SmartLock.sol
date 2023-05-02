//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address _owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 internal _status;

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

library SafeMath {
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

    function trySub(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

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

    function tryDiv(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

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

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract SmartLock is Ownable, ReentrancyGuard, Initializable {
    using SafeMath for uint256;
    struct Items {
        address tokenAddress;
        address withdrawalAddress;
        uint256 tokenAmount;
        uint256 unlockTime;
        bool withdrawn;
    }

    uint256 public bnbFee;
    // for statistic
    uint256 public totalBnbFees;
    // withdrawable values
    uint256 public remainingBnbFees;

    uint256 public depositId;
    uint256[] public allDepositIds;

    mapping(uint256 => Items) public lockedToken;

    mapping(address => uint256[]) public depositsByWithdrawalAddress;
    mapping(address => uint256[]) public depositsByTokenAddress;

    // Token -> { sender1: locked amount, ... }
    mapping(address => mapping(address => uint256)) public walletTokenBalance;

    event TokensLocked(
        address indexed tokenAddress,
        address indexed sender,
        uint256 amount,
        uint256 unlockTime,
        uint256 depositId
    );
    event TokensWithdrawn(
        address indexed tokenAddress,
        address indexed receiver,
        uint256 amount
    );

    function initialize() external initializer {
        bnbFee = 0.001 ether;
        totalBnbFees = 0;
        remainingBnbFees = 0;
        _status = 1;
        _transferOwnership(_msgSender());
    }

    function lockTokens(
        address _tokenAddress,
        uint256 _amount,
        uint256 _unlockTime
    ) external returns (uint256 _id) {
        require(_amount > 0, "Tokens amount must be greater than 0");
        require(
            _unlockTime < 10000000000,
            "Unix timestamp must be in seconds, not milliseconds"
        );
        require(_unlockTime > block.timestamp, "Unlock time must be in future");

        require(
            IBEP20(_tokenAddress).approve(address(this), _amount),
            "Failed to approve tokens"
        );
        require(
            IBEP20(_tokenAddress).transferFrom(
                msg.sender,
                address(this),
                _amount
            ),
            "Failed to transfer tokens to locker"
        );

        uint256 lockAmount = _amount;

        walletTokenBalance[_tokenAddress][msg.sender] = walletTokenBalance[
            _tokenAddress
        ][msg.sender].add(_amount);

        address _withdrawalAddress = msg.sender;
        _id = ++depositId;
        lockedToken[_id].tokenAddress = _tokenAddress;
        lockedToken[_id].withdrawalAddress = _withdrawalAddress;
        lockedToken[_id].tokenAmount = lockAmount;
        lockedToken[_id].unlockTime = _unlockTime;
        lockedToken[_id].withdrawn = false;

        allDepositIds.push(_id);
        depositsByWithdrawalAddress[_withdrawalAddress].push(_id);
        depositsByTokenAddress[_tokenAddress].push(_id);

        emit TokensLocked(
            _tokenAddress,
            msg.sender,
            _amount,
            _unlockTime,
            depositId
        );
    }

    function withdrawTokens(uint256 _id) external payable {
        require(
            block.timestamp >= lockedToken[_id].unlockTime,
            "Tokens are locked"
        );
        require(!lockedToken[_id].withdrawn, "Tokens already withdrawn");
        require(
            msg.sender == lockedToken[_id].withdrawalAddress,
            "Can withdraw from the address used for locking"
        );
        require(msg.value >= bnbFee, "BNB fee not provided");

        address tokenAddress = lockedToken[_id].tokenAddress;
        address withdrawalAddress = lockedToken[_id].withdrawalAddress;
        uint256 amount = lockedToken[_id].tokenAmount;

        require(
            IBEP20(tokenAddress).transfer(withdrawalAddress, amount),
            "Failed to transfer tokens"
        );

        lockedToken[_id].withdrawn = true;
        uint256 previousBalance = walletTokenBalance[tokenAddress][msg.sender];
        walletTokenBalance[tokenAddress][msg.sender] = previousBalance.sub(
            amount
        );

        totalBnbFees = totalBnbFees.add(msg.value);
        remainingBnbFees = remainingBnbFees.add(msg.value);

        // Remove depositId from withdrawal addresses mapping
        uint256 i;
        uint256 j;
        uint256 byWLength = depositsByWithdrawalAddress[withdrawalAddress]
            .length;
        uint256[] memory newDepositsByWithdrawal = new uint256[](byWLength - 1);

        for (j = 0; j < byWLength; j++) {
            if (depositsByWithdrawalAddress[withdrawalAddress][j] == _id) {
                for (i = j; i < byWLength - 1; i++) {
                    newDepositsByWithdrawal[i] = depositsByWithdrawalAddress[
                        withdrawalAddress
                    ][i + 1];
                }
                break;
            } else {
                newDepositsByWithdrawal[j] = depositsByWithdrawalAddress[
                    withdrawalAddress
                ][j];
            }
        }
        depositsByWithdrawalAddress[
            withdrawalAddress
        ] = newDepositsByWithdrawal;

        // Remove depositId from tokens mapping
        uint256 byTLength = depositsByTokenAddress[tokenAddress].length;
        uint256[] memory newDepositsByToken = new uint256[](byTLength - 1);
        for (j = 0; j < byTLength; j++) {
            if (depositsByTokenAddress[tokenAddress][j] == _id) {
                for (i = j; i < byTLength - 1; i++) {
                    newDepositsByToken[i] = depositsByTokenAddress[
                        tokenAddress
                    ][i + 1];
                }
                break;
            } else {
                newDepositsByToken[j] = depositsByTokenAddress[tokenAddress][j];
            }
        }
        depositsByTokenAddress[tokenAddress] = newDepositsByToken;

        emit TokensWithdrawn(tokenAddress, withdrawalAddress, amount);
    }

    function getTotalTokenBalance(
        address _tokenAddress
    ) public view returns (uint256) {
        return IBEP20(_tokenAddress).balanceOf(address(this));
    }

    function getTokenBalanceByAddress(
        address _tokenAddress,
        address _walletAddress
    ) public view returns (uint256) {
        return walletTokenBalance[_tokenAddress][_walletAddress];
    }

    function getAllDepositIds() public view returns (uint256[] memory) {
        return allDepositIds;
    }

    function getDepositDetails(
        uint256 _id
    ) public view returns (address, address, uint256, uint256, bool) {
        return (
            lockedToken[_id].tokenAddress,
            lockedToken[_id].withdrawalAddress,
            lockedToken[_id].tokenAmount,
            lockedToken[_id].unlockTime,
            lockedToken[_id].withdrawn
        );
    }

    function getDepositsByWithdrawalAddress(
        address _withdrawalAddress
    ) public view returns (uint256[] memory) {
        return depositsByWithdrawalAddress[_withdrawalAddress];
    }

    function getDepositsByTokenAddress(
        address _tokenAddress
    ) public view returns (uint256[] memory) {
        return depositsByTokenAddress[_tokenAddress];
    }

    function setBnbFee(uint256 fee) external onlyOwner {
        require(fee > 0, "Fee is too small");
        bnbFee = fee;
    }

    function withdrawFees(
        address payable withdrawalAddress
    ) external onlyOwner {
        if (remainingBnbFees > 0) {
            withdrawalAddress.transfer(remainingBnbFees);
            remainingBnbFees = 0;
        }
    }
}