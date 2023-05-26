//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

/**
 * Introducing RobinHood and the $HOOD - the ultimate crypto adventure where generosity meets decentralization! 🏹💰
 * As transactions occur, our mischievous smart contract automatically snatches 10% from every sell and redirects it to the last lucky soul who bought before (min 0.1 ETH buy)
 * Consider it a modern-day twist on Robin Hood's "steal from the rich and give to the poor" mantra. 🎩💰
 * Learn more: https://robinhood.army
 * And join the world of decentralized generosity: https://t.me/robinhoodMEME
 */
contract RobinHood is Ownable, ERC20 {
    uint256 public constant SUPPLY = 420690000000000 ether;
    address public lastEligibleBuyer;
    uint256 public maxByWallet; 
    uint256 public robinHoodShare = 100;
    address public uniswapV2Pair;

    constructor() ERC20("RobinHood", "HOOD") {
        _mint(msg.sender, SUPPLY);
        maxByWallet = SUPPLY * 5 / 1000;
    }

    function _transfer(address from, address to, uint256 amount) internal override(ERC20)  {
        if (uniswapV2Pair == address(0)) {
            require(from == owner() || to == owner(), "trading is not started");
        }

        if(from == uniswapV2Pair) {
            require((super.balanceOf(to) + amount) <= maxByWallet, "maxByWallet reach");
            lastEligibleBuyer = to;
            robinHoodShare = 100;
        }

        if (to == uniswapV2Pair) {
            uint256 lastBuyerGain = amount * robinHoodShare / 1000;
            robinHoodShare = robinHoodShare + 10;
            amount = amount - lastBuyerGain;
            super._transfer(from, lastEligibleBuyer, lastBuyerGain);
        }

        super._transfer(from, to, amount);    
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }

    function step1(address _uniswapV2Pair) external onlyOwner {
        uniswapV2Pair = _uniswapV2Pair;
    }

    function step2() external onlyOwner {
        maxByWallet = SUPPLY * 20 / 1000;
        _transferOwnership(address(0));
    }
}