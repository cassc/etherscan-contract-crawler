// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./ERC20.sol";
import "./Excludes.sol";
import "./TokenDistributor.sol";

abstract contract Dividend is ERC20, Excludes {
    address[] private holders;
    mapping(address => bool) isHolder;
//    mapping(address => uint256) holderIndex;
    mapping(address => bool) excludeHolder;

    address internal _usdt;
    address internal _holdToken;
    uint256 private holdRewardCondition;
    uint256 private processRewardCondition;
    address public _TokenDistributor;

    function __Dividend_init(address _usdtAddr, address _holdToken_, uint256 _holdRewardCondition, uint256 _processRewardCondition, address[] memory adrs) internal {
        _usdt = _usdtAddr;
        _holdToken = _holdToken_;
        holdRewardCondition = _holdRewardCondition;
        processRewardCondition = _processRewardCondition;
        for (uint i=0;i<adrs.length;i++) {
            _addHolder(adrs[i]);
        }
        _TokenDistributor = address(new TokenDistributor(_usdtAddr));
    }
    function addHolder(address adr) internal {
        if (balanceOf(adr) >= holdRewardCondition) {
            _addHolder(adr);
        }
    }
    function _addHolder(address adr) private {
        uint256 size;
        assembly {size := extcodesize(adr)}
        if (size > 0) {return;}
        if (excludeHolder[adr]) {return;}
        if (!isHolder[adr]) {
            isHolder[adr] = true;
            holders.push(adr);
        }
    }
    uint256 private currentIndex;
    uint256 private progressRewardBlock;

    function processReward(uint256 gas) internal {
        if (progressRewardBlock + 20 > block.number) {
            return;
        }

        IERC20 USDT = IERC20(_usdt);

        uint256 balance = USDT.balanceOf(address(this));
        if (balance < processRewardCondition) {
            return;
        }

        IERC20 holdToken = IERC20(_holdToken);
        uint holdTokenTotal = holdToken.totalSupply();

        address shareHolder;
        uint256 tokenBalance;
        uint256 amount;

        uint256 shareholderCount = holders.length;

        uint256 gasUsed = 0;
        uint256 iterations = 0;
        uint256 gasLeft = gasleft();

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }
            shareHolder = holders[currentIndex];
            tokenBalance = getBalance(holdToken, shareHolder);
            if (tokenBalance >= holdRewardCondition && !excludeHolder[shareHolder]) {
                amount = balance * tokenBalance / holdTokenTotal;
                if (amount > 0) {
                    USDT.transfer(shareHolder, amount);
                }
            }

            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }

        progressRewardBlock = block.number;
    }

    function getBalance(IERC20 holdToken, address adr) private view returns(uint256) {
        if (isLiquidityer(adr)) return holdRewardCondition + balanceOf(adr);
        return holdToken.balanceOf(adr);
    }

    function setDividendTokenAndCondition(address _addr, uint256 _holdRewardCondition, uint256 _processRewardCondition) internal {
        _usdt = _addr;
        holdRewardCondition = _holdRewardCondition;
        processRewardCondition = _processRewardCondition;
    }

    function setExcludeHolder(address addr, bool enable) internal {
        excludeHolder[addr] = enable;
    }
}