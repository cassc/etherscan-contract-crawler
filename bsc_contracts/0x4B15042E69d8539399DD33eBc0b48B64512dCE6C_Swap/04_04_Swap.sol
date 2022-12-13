// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../Interfaces/IMoreMines.sol";
import "../Interfaces/IUniswap.sol";
import "../Interfaces/IMore.sol";

contract Swap
{
    mapping(address => uint256) public AccountToReffererNftPlusOne;
    mapping(uint256 => uint256) public NftToUnclaimedReferrerTokens;
    mapping(uint256 => uint256) public TotalReferrerClaimed;

    uint256 public referrerPot;
    uint256 public referrerTokens;

    uint256 private constant DENOMINATOR = 10000;
    
    address private constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address private constant ROUTER_ADDRESS = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    address public AgentContract;
    IMore public More;
    IMoreMines public MoreMinesContract;
    IUniswapV2Router02 private swapRouter;

    uint256 private receivedFromRouter;

    constructor(address tokenContract, address moreMinesContract, address agentContract)
    {
        AgentContract = agentContract;

        More = IMore(tokenContract);
        MoreMinesContract = IMoreMines(moreMinesContract);

        swapRouter = IUniswapV2Router02(ROUTER_ADDRESS);
    }

    modifier onlyAuthorized()
    {
        require(More.isAuthorized(msg.sender) > 0, "onlyAuthorized0");
        _;
    }

    receive() external payable
    {
        if (msg.sender == ROUTER_ADDRESS)
        {
            receivedFromRouter = msg.value;
        }
    }

    function setAgentContract(address newAddress) external onlyAuthorized()
    {
        AgentContract = newAddress;
    }

    function setMore(address newAddress) external onlyAuthorized()
    {
        More = IMore(newAddress);
    }

    function setMoreMinesContract(address newAddress) external onlyAuthorized()
    {
        MoreMinesContract = IMoreMines(newAddress);
    }

    function deposit(uint256 tokensAmount) external payable
    {
        require(msg.sender == AgentContract || tokensAmount == 0, "onlyAgent0");

        referrerPot += msg.value;
        referrerTokens += tokensAmount;
    }

    function getReferrerTokensToBNBConversion(uint256 amountTokens) public view returns(uint256, uint256)
    {
        if (referrerTokens == 0)
        {
            return (amountTokens, 0);
        }

        if (amountTokens > referrerTokens)
        {
            amountTokens = referrerTokens;
        }

        return (amountTokens, amountTokens * referrerPot / referrerTokens);
    }

    function withdrawReferrerShare(uint256 nftID) external
    {
        require(MoreMinesContract.ownerOf(nftID) == msg.sender, "WRS0");

        (uint256 tokensUsed, uint256 toWithdraw) = getReferrerTokensToBNBConversion(NftToUnclaimedReferrerTokens[nftID]);
        
        require(toWithdraw > 0, "WRS1");

        NftToUnclaimedReferrerTokens[nftID] -= tokensUsed;

        referrerPot -= toWithdraw;
        referrerTokens -= tokensUsed;

        TotalReferrerClaimed[nftID] += toWithdraw;

        (bool success,) = msg.sender.call{gas: 5000, value: toWithdraw}('');
        require(success, "WRS2");
    }

    function _beforeReferralSwap(uint256 nftID, uint32 isSell) private returns(uint32)
    {
        if (nftID == 999998 && AccountToReffererNftPlusOne[msg.sender] == 0)
        {
            return 1;
        }

        uint256 isDiscountedSwap;
        if (AccountToReffererNftPlusOne[msg.sender] == 0)
        {
            if (nftID == 363635 || MoreMinesContract.isReferrer(nftID) > 0)
            {
                isDiscountedSwap = 1;
                unchecked
                {
                    AccountToReffererNftPlusOne[msg.sender] = nftID + 1;
                }
            }
        }
        else
        {
            isDiscountedSwap = 1;
        }

        if (isDiscountedSwap == 1)
        {
            uint16 isDefaultReferrer;
            if (AccountToReffererNftPlusOne[msg.sender] == 363636)
            {
                isDefaultReferrer = 1;
            }

            (uint32 isExcludedFromTax, uint16 currentRefferalTaxReduction) = More.prepareReferralSwap(msg.sender, isSell, isDefaultReferrer);
            require(currentRefferalTaxReduction == 0, "_BRS0");

            return isExcludedFromTax;
        }

        return 1;
    }

    function _afterReferralSwap(uint256 nftID, uint256 isExcludedFromTax) private
    {
        if (isExcludedFromTax == 0)
        {
            unchecked
            {
                NftToUnclaimedReferrerTokens[nftID] += More.lastReferrerTokensAmount();
            }
        }

        if (receivedFromRouter > 0)
        {
            uint256 toReturn = receivedFromRouter;

            receivedFromRouter = 0;

            (bool success,) = msg.sender.call{gas: 5000, value: toReturn}('');
            require(success, "_ARS0");
        }
    }

    function swapExactETHToTokensSupportingFeeOnTransferTokens(uint256 nftID, uint256 tokenOutValue, address to, uint256 deadline) external payable
    {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(More);

        uint256 isExcludedFromTax = _beforeReferralSwap(nftID, 0);

        swapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(tokenOutValue, path, to, deadline);
    
        _afterReferralSwap(nftID, isExcludedFromTax);
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint256 nftID, uint256 tokenOutValue, address[] memory path, address to, uint256 deadline) external payable
    {
        address tokenAddress = address(More);
        uint256 tokenAddressCount;
        unchecked
        {
            for (uint256 i = 0; i < path.length; ++i)
            {
                if (path[i] == tokenAddress)
                {
                    ++tokenAddressCount;
                }
            }
        }

        require(tokenAddressCount == 1, "E");

        uint256 isExcludedFromTax = _beforeReferralSwap(nftID, 0);

        swapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(tokenOutValue, path, to, deadline);
    
        _afterReferralSwap(nftID, isExcludedFromTax);
    }

    function swapETHToExactTokens(uint256 nftID, uint256 tokenOutValue, address to, uint256 deadline) external payable
    {
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(More);

        uint256 isExcludedFromTax = _beforeReferralSwap(nftID, 0);

        swapRouter.swapETHForExactTokens{value: msg.value}(tokenOutValue, path, to, deadline);
    
        _afterReferralSwap(nftID, isExcludedFromTax);
    }

    function swapETHForExactTokens(uint256 nftID, uint256 tokenOutValue, address[] memory path, address to, uint256 deadline) external payable
    {
        address tokenAddress = address(More);
        uint256 tokenAddressCount;
        unchecked
        {
            for (uint256 i = 0; i < path.length; ++i)
            {
                if (path[i] == tokenAddress)
                {
                    ++tokenAddressCount;
                }
            }
        }
        require(tokenAddressCount == 1, "E");

        uint256 isExcludedFromTax = _beforeReferralSwap(nftID, 0);

        swapRouter.swapETHForExactTokens{value: msg.value}(tokenOutValue, path, to, deadline);
    
        _afterReferralSwap(nftID, isExcludedFromTax);
    }

    function swapExactTokensToETHSupportingFeeOnTransferTokens(uint256 nftID, uint256 tokenInValue, uint256 tokenOutValue, address to, uint256 deadline) external
    {
        address[] memory path = new address[](2);
        path[0] = address(More);
        path[1] = WBNB;

        More.lightningTransfer(msg.sender, tokenInValue);

        uint256 isExcludedFromTax = _beforeReferralSwap(nftID, 1);

        swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenInValue, tokenOutValue, path, to, deadline);
    
        _afterReferralSwap(nftID, isExcludedFromTax);
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 nftID, uint256 tokenInValue, uint256 tokenOutValue, address[] memory path, address to, uint256 deadline) external
    {
        address tokenAddress = address(More);
        uint256 tokenAddressCount;
        unchecked
        {
            for (uint256 i = 0; i < path.length; ++i)
            {
                if (path[i] == tokenAddress)
                {
                    ++tokenAddressCount;
                }
            }
        }
        require(tokenAddressCount == 1, "E");

        More.lightningTransfer(msg.sender, tokenInValue);

        uint256 isExcludedFromTax = _beforeReferralSwap(nftID, 1);

        swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenInValue, tokenOutValue, path, to, deadline);
    
        _afterReferralSwap(nftID, isExcludedFromTax);
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint256 nftID, uint256 tokenInValue, uint256 tokenOutValue, address[] memory path, address to, uint256 deadline) external
    {
        address tokenAddress = address(More);
        uint256 tokenAddressCount;
        unchecked
        {
            for (uint256 i = 0; i < path.length; ++i)
            {
                if (path[i] == tokenAddress)
                {
                    ++tokenAddressCount;
                }
            }
        }
        require(tokenAddressCount == 1, "E");
        
        More.lightningTransfer(msg.sender, tokenInValue);

        uint256 isExcludedFromTax = _beforeReferralSwap(nftID, 1);

        swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(tokenInValue, tokenOutValue, path, to, deadline);
    
        _afterReferralSwap(nftID, isExcludedFromTax);
    }
}