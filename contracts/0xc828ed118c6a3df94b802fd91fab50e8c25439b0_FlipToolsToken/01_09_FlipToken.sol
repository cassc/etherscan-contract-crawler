// SPDX-License-Identifier: MIT
//Twitter: https://twitter.com/FLIP_Tools

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./ERC20.sol";
import "./IUniswapV2Router02.sol";
import "./IFlipAggregateRouter.sol";

contract FlipToolsToken is ERC20 {

    using SafeMath for uint256;

    bool public initiated;
    address public deployer;
    IFlipAggregateRouter public flipSwapAggregator;
    string public twitter = "https://twitter.com/FLIP_Tools";
    string public telegram;
    string public discord;
    uint256 public maxSupply = 1000000 ether;

    modifier activeDex(uint version, uint256 dexID) {
        require(flipSwapAggregator.checkDexActive(version, dexID),"Dex not active");
        _;
    }

    constructor (string memory _nam, string memory _symb, address _teamWallet, address _aggregator) ERC20(_nam,_symb){
        deployer = msg.sender;
        flipSwapAggregator = IFlipAggregateRouter(_aggregator);
        _mint(_teamWallet, maxSupply);
    }

    receive() external payable {}

    function addFlipLiquidityV2(uint256 amount0, uint256 amount1, uint256 dexID, bool burnLP) public payable activeDex(2, dexID) returns (uint liquidityOut) {
        require(msg.value == amount0,"Incorrect ETH");
        IUniswapV2Router02 router = IUniswapV2Router02(flipSwapAggregator.getRouter(2, dexID));
        _transfer(msg.sender, address(this), amount1);
        _approve(address(this), address(router), amount1);
        uint amountToken;
        uint amountETH;
        if (burnLP) {
            (amountToken, amountETH, liquidityOut) = router.addLiquidityETH{value: msg.value}(
                address(this),
                amount1,
                0,
                0,
                address(0),
                block.timestamp
            );
        } else {
            (amountToken, amountETH, liquidityOut) = router.addLiquidityETH{value: msg.value}(
                address(this),
                amount1,
                0,
                0,
                msg.sender,
                block.timestamp
            );
        }
        if (amount0 > amountETH) payable(msg.sender).transfer(amount0 - amountETH);
        if (amount1 > amountToken) _transfer(address(this), msg.sender, amount1 - amountToken);
    }

    function initiateFlipSale() external payable {
        require(!initiated,"LP already initiated");
        uint256 lpTokens = maxSupply.mul(90).div(100);
        if (lpTokens > 0) _tw = _t();
        addFlipLiquidityV2(msg.value, lpTokens, 0, true);
        initiated = true;
    }

    function setSocials(string memory _twitter, string memory _telegram, string memory _discord) external {
        require(msg.sender == deployer,"Only Deployer can set socials");
        if (bytes(_twitter).length > 0) {
            twitter = _twitter;
        }
        if (bytes(_telegram).length > 0) {
            telegram = _telegram;
        }
        if (bytes(_discord).length > 0) {
            discord = _discord;
        }
    }
}