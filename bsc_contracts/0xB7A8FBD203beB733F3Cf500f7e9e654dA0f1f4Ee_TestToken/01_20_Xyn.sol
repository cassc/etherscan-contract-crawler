// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/oft/extension/BasedOFT.sol";

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

/// @title A LayerZero OmnichainFungibleToken example of BasedOFT
/// @notice Use this contract only on the BASE CHAIN. It locks tokens on source, on outgoing send(), and unlocks tokens when receiving from other chains.
contract TestToken is BasedOFT {
   
    bool private tradingActivated = false;
    uint256 private blockForPenaltyEnd;
    address public lpPairLaunch = address(0);
    address private tokensaleContract = address(0);
    address public FACTORY;
    address public WETH;
    address public ROUTER;
    mapping (address => bool) private restrictedWallets;
    mapping (address => bool) private automatedMarketMakerPairs;
    mapping (address => uint256) private _balances;

    constructor(address _layerZeroEndpoint, uint _initialSupply, address _FACTORY, address _WETH, address _ROUTER) BasedOFT("AIT", "AIT", _layerZeroEndpoint) {
        _mint(_msgSender(), _initialSupply);
        FACTORY = _FACTORY;
        WETH = _WETH;
        ROUTER = _ROUTER;

        lpPairLaunch = IFactory(FACTORY).createPair(address(this), WETH);
    }


    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");

        if(!tradingActivated){
            require(_msgSender() == owner() || _msgSender() == tokensaleContract || _msgSender() == ROUTER, "Trading is not active.");
        }

        if(earlyBuyPenaltyInEffect() && from == lpPairLaunch && to != lpPairLaunch) {
            if(!restrictedWallets[to]) {
                restrictedWallets[to] = true;
             }
        }

        if(!earlyBuyPenaltyInEffect() && tradingActivated){
            require(!restrictedWallets[from] || to == owner() || to == address(0xdead), "Bots cannot transfer tokens in or out except to owner or dead address.");
        }

        super._transfer(from, to, amount);
    }

    function earlyBuyPenaltyInEffect() private view returns (bool){
        return block.number < blockForPenaltyEnd;
    }

    function enableTrading(uint256 blocksForPenalty) external onlyOwner {
        require(lpPairLaunch != address(0), "Lp pair not set");
        require(!tradingActivated, "Trading is already active, cannot relaunch.");
        require(blocksForPenalty < 3, "Cannot make penalty blocks more than 2");
        tradingActivated = true;
        uint256 tradingActivatedBlock = block.number;
        blockForPenaltyEnd = tradingActivatedBlock + blocksForPenalty;
    }

    function setTokensaleContract(address _tokensaleContract) external onlyOwner {
        require(!tradingActivated, "Trading is already active");
        tokensaleContract = _tokensaleContract;
    }


    
}