/**  

 ██████╗███████╗ █████╗ ███████╗ █████╗ ██████╗     ████████╗ ██████╗ ██╗  ██╗███████╗███╗   ██╗
██╔════╝██╔════╝██╔══██╗██╔════╝██╔══██╗██╔══██╗    ╚══██╔══╝██╔═══██╗██║ ██╔╝██╔════╝████╗  ██║
██║     █████╗  ███████║███████╗███████║██████╔╝       ██║   ██║   ██║█████╔╝ █████╗  ██╔██╗ ██║
██║     ██╔══╝  ██╔══██║╚════██║██╔══██║██╔══██╗       ██║   ██║   ██║██╔═██╗ ██╔══╝  ██║╚██╗██║
╚██████╗███████╗██║  ██║███████║██║  ██║██║  ██║       ██║   ╚██████╔╝██║  ██╗███████╗██║ ╚████║
 ╚═════╝╚══════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝       ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝
                                                                                                   
#########################
Welcome to CEASAR TOKEN        >->->  https://ceasar.top  <-<-<
#########################

Total Supply : 100 trillions CEASAR ( 100 000 000 000 000 )
Circ. Supply : 100 trillions CEASAR ( 100 000 000 000 000 )

-----------
- NO buy tax
- NO sell tax
- NO transfer tax
-----------

May 2023... was born in blockchain, ETH. Immutably yours.

######################################################*/

// SPDX-License-Identifier: MIT

/// @title Ceasar Token
/// @author KRS1
/// @notice Clean Token, No Taxes, No Presale
/// @dev All function calls are currently implemented without side effects

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CeasarToken is ERC20, Ownable {

    bool public IS_MAX_HOLDING_LIMITED = false;
    uint256 public TOTAL_SUPPLY = 100 * 10**12 * 10**18; // (default) 100 trillions
    uint256 public MAX_HOLDING_PERCENT = 2;  // 5% => 5 trillion

    address public uniswapV2Pair;
    mapping(address => bool) public blacklists;

    constructor( string memory name, string memory symbol, uint256 initialSupply
    ) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
        TOTAL_SUPPLY = initialSupply;
    }

    function blacklist(address _address, bool _isBlacklisting) external onlyOwner {
        blacklists[_address] = _isBlacklisting;
    }

    // Set the address of the Uniswap V2 pair.
    function setLiquidity(address _uniswapV2Pair) external onlyOwner {
        uniswapV2Pair = _uniswapV2Pair;
    }

    /**
    * @dev Modifies the contract configuration parameters.
    * @param _is_Max_Holding_Limited Defines whether the maximum holding limit is enabled or disabled. default:true
    * @param _Max_Holding_Percent Defines the maximum allowed holding percentage. default:5%
    */
    function setConfig(bool _is_Max_Holding_Limited, uint256 _Max_Holding_Percent) external onlyOwner {
        IS_MAX_HOLDING_LIMITED = _is_Max_Holding_Limited;
        MAX_HOLDING_PERCENT = _Max_Holding_Percent;
    }

    // Check if a transfer should be allowed.// Check if a transfer should be allowed.
    function _beforeTokenTransfer(address from, address to, uint256 amount) override internal virtual {
        // Check if the sender or receiver is blacklisted.
        require(!blacklists[to] && !blacklists[from], "Blacklisted");

        // Check if the Uniswap V2 pair has been set.
        if (uniswapV2Pair == address(0)) {
            require(from == owner() || to == owner(), "Liquidity LP is not defined yet");
            return;
        }

        // Check if the maximum holding limit is enabled.
        if (IS_MAX_HOLDING_LIMITED && from == uniswapV2Pair && from != address(0) && to != address(0)) {
            // Calculate the maximum holding amount.
            uint256 maxHoldingAmount = (TOTAL_SUPPLY - balanceOf(address(this))) * MAX_HOLDING_PERCENT / 100;
            // Check if the transfer amount exceeds the maximum holding percentage.
            require(super.balanceOf(to) + amount <= maxHoldingAmount, "Transfer amount exceeds max holding percentage");
        }
    }

    // Burn tokens.
    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}