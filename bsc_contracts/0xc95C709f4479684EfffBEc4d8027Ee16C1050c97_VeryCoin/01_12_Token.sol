/*

###########################################
## Token generated with ❤️ on 20lab.app ##
##########################################

*/

// SPDX-License-Identifier: No License

pragma solidity 0.8.7;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol"; 
import "./Mintable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";

contract VeryCoin is ERC20, ERC20Burnable, Ownable, Mintable {
    
    mapping (address => bool) public blacklisted;

    address public veryAddress;
    uint16[3] public veryFees;

    mapping (address => bool) public isExcludedFromFees;

    uint16[3] public totalFees;
    bool private _swapping;

    IUniswapV2Router02 public routerV2;
    address public pairV2;
    mapping (address => bool) public AMMPairs;
 
    event BlacklistUpdated(address indexed account, bool isBlacklisted);

    event veryAddressUpdated(address veryAddress);
    event veryFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event veryFeeSent(address recipient, uint256 amount);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event RouterV2Updated(address indexed routerV2);
    event AMMPairsUpdated(address indexed AMMPair, bool isPair);
 
    constructor()
        ERC20("VeryCoin", "VRI") 
        Mintable(1000000000)
    {
        address supplyRecipient = 0x9a457701A17290C2C0d3357e4cd8DE1e9Be602d7;
        
        veryAddressSetup(0x9a457701A17290C2C0d3357e4cd8DE1e9Be602d7);
        veryFeesSetup(100, 100, 100);

        excludeFromFees(supplyRecipient, true);
        excludeFromFees(address(this), true); 

        _updateRouterV2(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        _mint(supplyRecipient, 800000000 * (10 ** decimals()));
        _transferOwnership(0x9a457701A17290C2C0d3357e4cd8DE1e9Be602d7);
    }

    receive() external payable {}

    function decimals() public pure override returns (uint8) {
        return 18;
    }
    
    function blacklist(address account, bool isBlacklisted) external onlyOwner {
        blacklisted[account] = isBlacklisted;

        emit BlacklistUpdated(account, isBlacklisted);
    }

    function _sendInTokens(address from, address to, uint256 amount) private {
        super._transfer(from, to, amount);
    }

    function veryAddressSetup(address _newAddress) public onlyOwner {
        veryAddress = _newAddress;

        excludeFromFees(_newAddress, true);

        emit veryAddressUpdated(_newAddress);
    }

    function veryFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        veryFees = [_buyFee, _sellFee, _transferFee];

        totalFees[0] = 0 + veryFees[0];
        totalFees[1] = 0 + veryFees[1];
        totalFees[2] = 0 + veryFees[2];
        require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

        emit veryFeesUpdated(_buyFee, _sellFee, _transferFee);
    }

    function excludeFromFees(address account, bool isExcluded) public onlyOwner {
        isExcludedFromFees[account] = isExcluded;
        
        emit ExcludeFromFees(account, isExcluded);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        
        if (!_swapping && amount > 0 && to != address(routerV2) && !isExcludedFromFees[from] && !isExcludedFromFees[to]) {
            uint256 fees = 0;
            uint8 txType = 3;
            
            if (AMMPairs[from]) {
                if (totalFees[0] > 0) txType = 0;
            }
            else if (AMMPairs[to]) {
                if (totalFees[1] > 0) txType = 1;
            }
            else if (totalFees[2] > 0) txType = 2;
            
            if (txType < 3) {
                
                uint256 veryPortion = 0;

                fees = amount * totalFees[txType] / 10000;
                amount -= fees;
                
                if (veryFees[txType] > 0) {
                    veryPortion = fees * veryFees[txType] / totalFees[txType];
                    _sendInTokens(from, veryAddress, veryPortion);
                    emit veryFeeSent(veryAddress, veryPortion);
                }

                fees = fees - veryPortion;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
        }
        
        super._transfer(from, to, amount);
        
    }

    function _updateRouterV2(address router) private {
        routerV2 = IUniswapV2Router02(router);
        pairV2 = IUniswapV2Factory(routerV2.factory()).createPair(address(this), routerV2.WETH());
        
        _setAMMPair(pairV2, true);

        emit RouterV2Updated(router);
    }

    function setAMMPair(address pair, bool isPair) public onlyOwner {
        require(pair != pairV2, "DefaultRouter: Cannot remove initial pair from list");

        _setAMMPair(pair, isPair);
    }

    function _setAMMPair(address pair, bool isPair) private {
        AMMPairs[pair] = isPair;

        if (isPair) { 
        }

        emit AMMPairsUpdated(pair, isPair);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        require(!blacklisted[from] && !blacklisted[to], "Blacklist: Sender or recipient is blacklisted");

        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        super._afterTokenTransfer(from, to, amount);
    }
}