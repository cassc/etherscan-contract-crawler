// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IUniswapV2Router02.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenDividendTracker is Ownable {
    using SafeMath for uint256;
    address[] public shareholders;
    uint256 public currentIndex;
    uint256 processBalance;
    uint256 processShareholderCount;
    mapping(address => bool) public _isDividendExempt;
    mapping(address => bool) private _updated;
    mapping(address => uint256) public shareholderIndexes;

    IUniswapV2Router02 uniswapV2Router;
    address public uniswapV2Pair;
    address public lpRewardToken;

    uint256 public LPRewardLastSendTime;
    uint256 public lastSwapTokenTime;

    bool public processing;
    bool public swapping;

    modifier inSwapping() {
        if(swapping)return;
        swapping = true;
        _;
        lastSwapTokenTime = block.timestamp;
        swapping = false;
    }

    modifier inProcessing() {
        if(processing)return;
        processing = true;
        _;
        LPRewardLastSendTime = block.timestamp;
        processing = false;
    }

    constructor(
        IUniswapV2Router02 uniswapV2Router_,
        address uniswapV2Pair_,
        address lpRewardToken_
    ) {
        uniswapV2Router = uniswapV2Router_;
        uniswapV2Pair = uniswapV2Pair_;
        lpRewardToken = lpRewardToken_;
    }

    function resetLPRewardLastSendTime() public onlyOwner {
        LPRewardLastSendTime = 0;
    }

    function swapTokensForUSDT(uint256 tokenAmount,address[] calldata path)
        external
        onlyOwner
        inSwapping
    {
        IERC20(path[0]).approve(address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );

    }

    function process(uint256 gas) external onlyOwner inProcessing {
        if (currentIndex == 0) {
            processShareholderCount = shareholders.length;
            processBalance = IERC20(lpRewardToken).balanceOf(address(this));
        }

        if (processShareholderCount == 0 || processBalance == 0) {
            return;
        }
        
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;
        while (gasUsed < gas && iterations <= processShareholderCount) {
            if (currentIndex >= processShareholderCount) {
                currentIndex = 0;
                break;
            }

            uint256 amount = processBalance
                .mul(
                    IERC20(uniswapV2Pair).balanceOf(shareholders[currentIndex])
                )
                .div(IERC20(uniswapV2Pair).totalSupply());

            if (amount == 0 || _isDividendExempt[shareholders[currentIndex]]) {
                currentIndex++;
                iterations++;
                continue;
            }

            if (IERC20(lpRewardToken).balanceOf(address(this)) < amount)break;
            IERC20(lpRewardToken).transfer(shareholders[currentIndex], amount);
            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function setShare(address shareholder) external onlyOwner {
        if (_updated[shareholder]) {
            if (IERC20(uniswapV2Pair).balanceOf(shareholder) == 0)
                quitShare(shareholder);
            return;
        }
        addShareholder(shareholder);
        _updated[shareholder] = true;
    }

    function setLpShare(address shareholder) external onlyOwner {
        if (_updated[shareholder]) {
            return;
        }
        addShareholder(shareholder);
        _updated[shareholder] = true;
    }

    function setDividendExempt(address shareholder,bool bool_) external onlyOwner {
        _isDividendExempt[shareholder] = bool_;
    }

    function quitShare(address shareholder) internal {
        removeShareholder(shareholder);
        _updated[shareholder] = false;
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[
            shareholders.length - 1
        ];
        shareholderIndexes[
            shareholders[shareholders.length - 1]
        ] = shareholderIndexes[shareholder];
        shareholders.pop();
    }

    function getShareholdersCount() external view returns (uint256) {
        return shareholders.length;
    }
}