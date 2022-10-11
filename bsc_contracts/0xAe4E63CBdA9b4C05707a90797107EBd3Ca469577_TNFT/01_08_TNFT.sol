// SPDX-License-Identifier: MIT
//.
pragma solidity ^0.8.0;
import "./BEP20Detailed.sol";
import "./BEP20.sol";
import "./IUniswapV2Factory.sol";

contract TNFT is BEP20Detailed, BEP20 {
    uint256 public maxSupply = 100000 * 10**18;    // the total supply
    uint8 public sellTax;
    address public uniswapV2Pair;
    address public maketAddress;

    constructor (
        address _maketAddress, 
        address _uniswapV2Factory, 
        address _wbnb
    ) BEP20Detailed("TNFT", "TNFT", 18) {
        _mint(msg.sender, maxSupply);
        sellTax = 3;
        maketAddress = _maketAddress;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Factory)
            .createPair(address(this), _wbnb);
    }

    function setUniswapV2Pair(address _uniswapV2Pair) external onlyOwner {
        uniswapV2Pair = _uniswapV2Pair;
    }

    function setMaketAddress(address _maketAddress) external onlyOwner {
        maketAddress = _maketAddress;
    }  

    function setSellTax(uint8 _sellTax) external onlyOwner {
        require(_sellTax <= 100, "_sellTax <= 100");
        sellTax = _sellTax;
    }

    function _transfer(address sender, address receiver, uint256 amount) internal virtual override {
        uint256 taxAmount = 0;
        if(uniswapV2Pair == receiver) {      
            //It's an LP Pair and it's a sell
            taxAmount = (amount * sellTax) / 100;
        }

        if(taxAmount > 0) {
            super._transfer(sender, maketAddress, taxAmount);
        }    
        super._transfer(sender, receiver, amount - taxAmount);
    }
}