/**
 *Submitted for verification at Etherscan.io on 2023-10-13
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

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
}

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() {}

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

//
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface Ifactory {
    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);
}

interface Irouter {
    function factory() external pure returns (address);

    function getAmountsIn(
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract Limitorder is Ownable {
    uint public orderId;
    Irouter public router;
    address public signer;
    bool public lockStatus;
    uint256 public expiration_time = 90 days;
    uint256 public processFee = 0.001e18;

    struct userDetails {
        bool initiate;
        bool completed;
        address useraddress;
        uint8 flag;
        address[] path;
        uint depAmt;
        uint expectAmt;
        uint expiry;
    }

    mapping(uint => userDetails) public users;

    event Initialize(
        uint orderid,
        uint8 flag,
        address indexed from,
        uint DepAmt,
        uint Fee,
        uint ExpectAmt,
        address[] path
    );
    event Swap(
        address indexed from,
        uint Orderid,
        uint8 _flag,
        uint givenAmt,
        uint getAmount
    );

    constructor(address _router, address _signer) {
        router = Irouter(_router);
        signer = _signer;
    }

    modifier onlySigner() {
        require(msg.sender == signer, "Only signer");
        _;
    }

    /**
     * @dev Throws if lockStatus is true
     */
    modifier isLock() {
        require(lockStatus == false, " Contract Locked");
        _;
    }

    /**
     * @dev Throws if called by other contract
     */
    modifier isContractCheck(address _user) {
        require(!isContract(_user), "Invalid address");
        _;
    }

    modifier isValidUser(uint id) {
        require(msg.sender == users[id].useraddress, "Invalid user");
        _;
    }

    modifier isPairExist(address[] memory path) {
        require(
            Ifactory(router.factory()).getPair(path[0], path[1]) != address(0),
            "Invalid user"
        );
        _;
    }

    function updateRouter (address _router) external onlyOwner {
        router = Irouter(_router);
    }

    function initialize(
        uint _depAmt,
        address[] memory path,
        uint8 _flag,
        uint _expectAmt
    ) external payable isPairExist(path) isLock {
        require(_flag >= 1 && _flag <= 3, "Incorrect flag");
        require(_depAmt > 0, "Incorrect params");

        address _user = _msgSender();

        orderId++;
        userDetails storage user = users[orderId];

        if (_flag == 1)
            require(msg.value >= _depAmt + processFee, "Incorrect flag1 amt");
        else {
            require(msg.value == processFee, "Incorrect flag2 amt");
            tokenSafeTransferFrom(
                IERC20(path[0]),
                _user,
                address(this),
                _depAmt
            );
        }

        sendEth(owner(), processFee);

        user.depAmt = _depAmt;
        user.initiate = true;
        user.useraddress = _user;
        user.path = path;
        user.flag = _flag;
        user.expectAmt = _expectAmt;
        user.expiry = block.timestamp + expiration_time;

        emit Initialize(
            orderId,
            _flag,
            _user,
            _depAmt,
            processFee,
            _expectAmt,
            path
        );
    }

    function swap(uint _orderId) public onlySigner {
        require(_orderId > 0 && _orderId <= orderId, "Incorrect id");
        userDetails storage user = users[_orderId];
        require(!user.completed, "Already completed");
        require(user.initiate, "No order for swap");
        require(user.expiry >= block.timestamp,'Order Expiry');
        uint inAmt = _update(user);

        if (user.flag == 1) {
            router.swapExactETHForTokensSupportingFeeOnTransferTokens{
                value: inAmt
            }(0, user.path, user.useraddress, block.timestamp + 900);
        } else if (user.flag == 2) {
            IERC20(user.path[0]).approve(address(router),inAmt);
            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                inAmt,
                0,
                user.path,
                user.useraddress,
                block.timestamp + 900
            );
        } else {
            IERC20(user.path[0]).approve(address(router),inAmt);
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                inAmt,
                0,
                user.path,
                user.useraddress,
                block.timestamp + 900
            );
        }

        user.completed = true;
        emit Swap(user.useraddress, _orderId, user.flag, inAmt, user.expectAmt);
    }

    function _update(userDetails storage user) internal returns (uint) {
        uint[] memory amt = router.getAmountsIn(user.expectAmt, user.path);
        if (user.flag == 1) {
            if (amt[0] < user.depAmt) {
                sendEth(user.useraddress, user.depAmt - amt[0]);
                return amt[0];
            } else return amt[0];
        } else {
            if (amt[0] < user.depAmt) {
                tokenSafeTransfer(
                    IERC20(user.path[0]),
                    user.useraddress,
                    user.depAmt - amt[0]
                );
                return amt[0];
            } else return amt[0];
        }
    }

    function cancel(uint id) external isValidUser(id) {
        require(id > 0, "Incorrect id");
        userDetails storage user = users[id];
        address _user = _msgSender();
        require(
            !user.completed && _user == user.useraddress,
            "No order for cancel"
        );

        uint amount = user.depAmt;

        require(amount > 0, "Invalid Amount");

        if (user.flag == 1) sendEth(_user, amount);
        else tokenSafeTransfer(IERC20(user.path[0]), _user, amount);
        user.initiate = false;
    }

    function viewPath(uint _id) public view returns (address[] memory) {
        return users[_id].path;
    }

    function updateSigner(address _signer) external  onlyOwner {
        signer = _signer;
    }

    function updateExpiryTime (uint256 _time) external  onlyOwner {
        expiration_time = _time;
    }

    function updateFee (uint256 _fee) external onlyOwner {
        processFee = _fee; 
    }

    function emergencyWithdraw(
        address source,
        address user,
        uint256 amount
    ) external onlyOwner {
        if (source == address(0)) sendEth(user, amount);
        else tokenSafeTransfer(IERC20(source), user, amount);
    }

    function contractLock(bool _lockStatus) external onlyOwner returns (bool) {
        lockStatus = _lockStatus;
        return true;
    }

    function isContract(address _account) public view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_account)
        }
        if (size != 0) return true;
        return false;
    }

    function sendEth(address _devAddr, uint256 _amt) internal {
        bool success;
        assembly {
            success := call(gas(), _devAddr, _amt, 0, 0, 0, 0)
        }
        require(success, "Transfer Failed");
    }

    function tokenSafeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(
                freeMemoryPointer,
                0xa9059cbb00000000000000000000000000000000000000000000000000000000
            )
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(
                    and(eq(mload(0), 1), gt(returndatasize(), 31)),
                    iszero(returndatasize())
                ),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function tokenSafeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(
                freeMemoryPointer,
                0x23b872dd00000000000000000000000000000000000000000000000000000000
            )
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(
                    and(eq(mload(0), 1), gt(returndatasize(), 31)),
                    iszero(returndatasize())
                ),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }
}