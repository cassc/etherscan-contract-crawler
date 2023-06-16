pragma solidity 0.8.20;

// SPDX-License-Identifier: MIT

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./IContract.sol";


//Roshambo is an AI - based social platform that will connect people across the globe. Roshambo will provide opportunity to find someone that interests you wheather its for dating, work or just building a community. 
//The true mashup of Tinder, Linkdin and Telegram. It is not just a text and talk platform but it opens the door to the Roshambo world in Metaverse where the opportunities, fun and entertainment is endless. 
//Roshambo is here to change how people meet in this new digital world taking the billion dollar industry to the Next Generation.
//
//TG: https://t.me/RoshamboOfficialCoin
//Website: https://www.roshambo.community/
//Twitter: https://twitter.com/RoshamboCoin

contract Roshambo is ERC20, ERC20Burnable, Ownable {
    
    constructor() ERC20("Roshambo", "ROS") {
        _mint(msg.sender, 5e28);
    }
    
    // function to allow admin to transfer *any* ERC20 tokens from this contract..
    function transferAnyERC20Tokens(address tokenAddress, address recipient, uint256 amount) public onlyOwner {
        require(amount > 0, "ROS: amount must be greater than 0");
        require(recipient != address(0), "ROS: recipient is the zero address");
        IContract(tokenAddress).transfer(recipient, amount);
    }
    
    // function to allow admin to transfer ETH from this contract..
    function transferETH(uint256 amount, address payable recipient) public onlyOwner {
        recipient.transfer(amount);
    }
    
    // function to allow admin to enable trading..
    function enableTrading() public onlyOwner {
        require(!isTradingEnabled, "ROS: Trading already enabled..");
        require(uniswapV2Pair != address(0), "ROS: Set uniswapV2Pair first..");
        isTradingEnabled = true;
        tradingEnabledAt = block.timestamp;
    }
    
    // function to allow admin to set uniswap pair..
    function setUniswapPair(address uniPair) public onlyOwner {
        uniswapV2Pair = uniPair;
    }
}