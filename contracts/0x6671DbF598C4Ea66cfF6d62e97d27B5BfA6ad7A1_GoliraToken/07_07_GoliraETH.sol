// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

/*                                                                      
                                      ████████████████                              
                                    ██▒▒▒▒▒▒▒▒▒▒▒▒▒▒████                            
                                  ▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██▓▓                          
                                ██▒▒██████████▓▓▓▓▒▒▒▒▓▓▓▓██                        
                                ████  ░░  ░░░░████▓▓▒▒▒▒▓▓▓▓██                      
                                ██░░░░░░░░░░░░▒▒██▓▓▒▒▒▒▒▒▓▓▓▓██                    
                                ██████░░░░██████████▓▓▒▒████▓▓▓▓██                  
                              ██░░██░░    ░░██░░▒▒██▓▓██░░██▒▒▓▓██                  
                              ██  ░░░░░░░░  ░░░░▒▒████▓▓████▒▒▓▓▓▓██                
                            ██      ██░░██  ░░  ░░░░████▓▓▒▒▒▒▒▒▓▓████              
                          ██                  ░░░░░░░░██▒▒▓▓▒▒▒▒████████            
                          ████████░░    ░░░░░░░░░░░░░░████▓▓▒▒▒▒████▓▓████          
                          ██░░░░░░░░░░░░░░░░░░░░░░░░▒▒████▒▒▒▒██▓▓▒▒▒▒▓▓████        
                            ██░░░░░░▒▒▒▒░░▒▒▒▒▒▒▒▒▒▒████▓▓▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓██▓▓      
                            ██████████████████████████▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓██      
                          ██▒▒██▓▓▓▓██████████████▓▓▓▓▒▒▓▓▒▒▒▒▒▒▓▓▒▒▒▒▒▒▒▒▒▒████    
          ██████        ██▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒██▓▓▓▓▒▒▒▒▒▒▒▒▓▓████  
          ██    ██    ██▒▒▒▒▒▒▒▒▒▒▒▒████████████▒▒▓▓▒▒▒▒▒▒▒▒▒▒██▓▓▓▓▒▒▒▒▒▒▒▒▓▓████  
        ██░░  ░░░░████▒▒▒▒▒▒▒▒▒▒▒▒██░░░░░░░░░░░░████▒▒▒▒▒▒▒▒▒▒▓▓██▓▓▓▓▒▒▒▒▒▒▒▒▓▓████
        ██  ░░░░██████▒▒▒▒▒▒██▒▒▒▒██░░      ░░░░░░████▒▒▒▒▒▒▒▒▓▓████▓▓▓▓▒▒▒▒▒▒▒▒▓▓██
        ██░░░░▒▒██▒▒▒▒██▒▒▓▓██▒▒██░░▒▒░░██  ░░▒▒░░░░██▒▒▓▓▒▒▓▓██████████▒▒▒▒▓▓▒▒▓▓██
          ████████▒▒▒▒▓▓▓▓▓▓██▒▒████████▒▒████████████▒▒▓▓▓▓██████████████▒▒▒▒▒▒▒▒▓▓
          ██▒▒██▒▒▒▒▒▒▓▓▓▓████▓▓▒▒████      ░░██████▓▓▓▓▓▓██▒▒▒▒▒▒▓▓██████▓▓▒▒████▓▓
          ██▒▒██▒▒▒▒▓▓████████▓▓▒▒██    ░░  ░░░░██▓▓▓▓▓▓██▒▒▒▒▒▒▒▒▓▓▓▓████████░░░░██
            ██▒▒▓▓▓▓██████▓▓▓▓██▒▒██      ░░░░░░████▓▓██▒▒▒▒██▒▒▒▒████▓▓████░░░░░░██
          ██  ████████████████▓▓▓▓██    ██░░░░░░████▓▓██▒▒██░░████▓▓██▓▓██░░██░░▒▒██
          ██        ██████░░████▓▓▓▓██░░░░░░░░████▓▓██▒▒▒▒████  ██████████████░░▒▒██
            ██      ██░░████░░██▓▓▓▓██░░░░░░████▓▓▓▓██▒▒▒▒██  ██░░██████    ██░░██  
              ██    ████  ░░░░████▓▓▓▓██████████▓▓████▒▒██░░  ░░░░████    ██░░██    
                ██    ██░░  ░░██████▓▓▓▓██████████████▒▒██  ░░░░████        ██      
  ████          ██      ██░░░░▒▒████████████████████████  ░░▒▒████░░░░░░            
████████████████    ░░░░░░██░░▒▒████████████████████████░░▒▒████░░░░░░░░░░░░░░░░    
  ████████████        ░░░░░░████░░░░░░░░░░░░░░░░░░░░░░░░████░░░░░░░░░░░░░░░░        

                        Joey Golira Official ERC-20 Contract

                    Discord: https://discord.gg/SGMjB7jgPu
                    Twitter: https://twitter.com/JoeyGoliraETH
*/

/*
 * @title GoliraETH ERC20
 * @author Max Bridgland <@maxbridgland>
 * @notice Golira Love Monke. Monke Love Golira.
 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract GoliraToken is ERC20, Ownable {

    uint256 public immutable MAX_SUPPLY =  1_000_000_000_000 * 1 ether; // 1 Trillion Max Supply
    uint256 public immutable MAX_TRADE_AMOUNT = 30_000_000_000 * 1 ether; // Do not allow more than 3% to be bought/sold at a time
    
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant UNISWAP_V2_FACTORY_ADDRESS = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public uniswapV2Pair;

    bool limited = true; // Limit trading until ready. Can only be turned off, not back on.

    error TradingHasNotBegun();
    error MoreThan3Percent();

    constructor () ERC20("Joey Golira", "GOLIRA") {
        _mint(msg.sender, MAX_SUPPLY);
        uniswapV2Pair = IUniswapV2Factory(UNISWAP_V2_FACTORY_ADDRESS).createPair(
            address(this),
            WETH
        );
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override virtual {
        if ((from != owner() && to != owner()) && limited) {
            revert TradingHasNotBegun();
        }

        if ((to == uniswapV2Pair || from == uniswapV2Pair) && amount > MAX_TRADE_AMOUNT && (to != owner() && from != owner())) {
            revert MoreThan3Percent();
        }
    }

    function setUniswapPair(address _uniswapV2Pair) external onlyOwner {
        uniswapV2Pair = _uniswapV2Pair;
    }

    function removeLimitedTrading() external onlyOwner {
        limited = false;
    }

    function discordURL() public pure returns (string memory) {
        return "https://discord.gg/SGMjB7jgPu";
    }

    function twitterURL() public pure returns (string memory) {
        return "https://twitter.com/JoeyGoliraETH";
    }

}