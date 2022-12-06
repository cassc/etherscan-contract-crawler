// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../Interfaces/IMore.sol";
import "../Interfaces/IUniswap.sol";

contract Treasury
{
    address private constant ROUTER_ADDRESS = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address private constant BUSD_ADDRESS = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

    IERC20 BusdContract = IERC20(BUSD_ADDRESS);

    IUniswapV2Router02 private SwapRouter;

    uint256 public nonMarketingReserves;

    struct MWRequest
    {
        uint32 isSwapBackRequest;
        uint32 confirmation1;
        uint32 confirmation2;
        uint32 isCompleted;
        uint32 isBUSD;
        uint128 amount;
        address to;
    }

    mapping(uint256 => uint256) public requestToMinBNBOnSwap;

    uint256 public lastConfirmationTime;
    uint256 private claimedByTimeoutAmountBNB;
    uint256 private claimedByTimeoutAmountBUSD;

    MWRequest[] public MWRequests;

    address public Admin1;
    address public Admin2;

    uint256 public boughtBackAndBurned;
    uint256 public boughtBackAndLiquified;
    uint256 public liquifiedAndLocked;

    IMore More;

    modifier onlyAdmin()
    {
        require(msg.sender == Admin1 || msg.sender == Admin2, "onlyAdmin0");
        _;
    }

    modifier onlyAuthorized()
    {
        require(More.isAuthorized(msg.sender) > 0, "onlyAuthorized0");
        _;
    }

    constructor(address payable tokenContract, address admin1, address admin2)
    {
        More = IMore(tokenContract);

        Admin1 = admin1;
        Admin2 = admin2;

        SwapRouter = IUniswapV2Router02(ROUTER_ADDRESS);

        lastConfirmationTime = block.timestamp;
    }

    receive() external payable { }

    fallback() external payable { }

    function receiveAlt() external payable
    {
        nonMarketingReserves += msg.value;
    }

    function receiveExact(uint256 nonMarketingAmount) external payable
    {
        require(msg.value >= nonMarketingAmount);
        nonMarketingReserves += nonMarketingAmount;
    }

    function buyBackAndBurn(uint256 amount) external onlyAuthorized()
    {
        require(gasleft() > 500000);

        nonMarketingReserves -= amount;

        boughtBackAndBurned += amount;

        More.buybackAndBurn{value: amount}();
    }

    function buyBackAndLockToLiquidity(uint256 amount) external onlyAuthorized()
    {
        require(gasleft() > 500000);

        nonMarketingReserves -= amount;

        boughtBackAndLiquified += amount;

        More.buybackAndLockToLiquidity{value: amount}();
    }

    function addBNBToLiquidityPot(uint256 amount) external onlyAuthorized()
    {
        nonMarketingReserves -= amount;

        liquifiedAndLocked += amount;

        More.addBNBToLiquidityPot{value: amount}();
    }

    function getStats() external view returns(uint256, uint256, uint256)
    {
        return (boughtBackAndBurned, boughtBackAndLiquified, liquifiedAndLocked);
    }

    function makeRequest(uint128 amount, uint256 isBUSD, uint256 isSwapBackRequest) external onlyAdmin()
    {
        if (isBUSD > 0 || isSwapBackRequest > 0)
        {
            require(BusdContract.balanceOf(address(this)) >= amount, "RMW0");
        }
        else
        {
            require(address(this).balance - nonMarketingReserves >= amount, "RMW1");
        }
        
        uint256 requestsCount = MWRequests.length;
        
        if (requestsCount != 0 && MWRequests[requestsCount - 1].isCompleted != 1)
        {
            MWRequest storage pendingRequest = MWRequests[requestsCount - 1];
            pendingRequest.isCompleted = 2;
        }

        createRequest(amount, isBUSD, isSwapBackRequest);
    }

    function createRequest(uint128 amount, uint256 isBUSD, uint256 isSwapBackRequest) private
    {
        MWRequest memory request;
        request.amount = amount;
        request.to = msg.sender;

        if (msg.sender == Admin1)
        {
            request.confirmation1 = 1;
        }
        else if (msg.sender == Admin2)
        {
            request.confirmation2 = 1;
        }

        request.isBUSD = isBUSD > 0 ? 1 : 0;
        request.isSwapBackRequest = isSwapBackRequest > 0 ? 1 : 0;

        MWRequests.push(request);

        if (isSwapBackRequest > 0)
        {
            requestToMinBNBOnSwap[MWRequests.length - 1] = isBUSD;
        }
    }

    function approveRequest(uint256 index) external
    {
        require(gasleft() > 500000);

        MWRequest storage pendingRequest = MWRequests[index];

        require(pendingRequest.isCompleted == 0, "miss");

        if (msg.sender == Admin1)
        {
            require(pendingRequest.confirmation1 == 0, "AMW1");

            pendingRequest.confirmation1 = 1;
            
            processRequest(index);
        }
        else if (msg.sender == Admin2)
        {
            require(pendingRequest.confirmation2 == 0, "AMW2");

            pendingRequest.confirmation2 = 1;

            processRequest(index);
        }
        else
        {
            revert("AMW0");
        }
    }

    function processRequest(uint256 index) private
    {
        MWRequest storage pendingRequest = MWRequests[index];

        pendingRequest.isCompleted = 1;

        if (pendingRequest.isSwapBackRequest == 0)
        {
            lastConfirmationTime = block.timestamp;

            if (pendingRequest.isBUSD == 1)
            {
                transferBUSD(pendingRequest.amount, pendingRequest.to);
            }
            else
            {
                transferBNB(pendingRequest.amount, pendingRequest.to);
            }
        }
        else
        {
            swapToBNB(pendingRequest.amount, requestToMinBNBOnSwap[index]);
        }
    }

    function claimHalfByTimeout() external onlyAdmin()
    {
        require(block.timestamp - lastConfirmationTime >= 86400 * 365, "CHBT0");

        if (claimedByTimeoutAmountBNB == 0 && claimedByTimeoutAmountBUSD == 0)
        {
            uint256 halfBNB = address(this).balance / 2;
            uint256 halfBUSD = BusdContract.balanceOf(address(this));

            transferBNB(halfBNB, msg.sender);
            transferBUSD(halfBUSD, msg.sender);

            claimedByTimeoutAmountBNB = halfBNB;
            claimedByTimeoutAmountBUSD = halfBUSD;
        }
        else
        {
            transferBNB(claimedByTimeoutAmountBNB, msg.sender);
            transferBUSD(claimedByTimeoutAmountBUSD, msg.sender);
        }
    }

    function claimAllByTimeout() external onlyAdmin()
    {
        require(block.timestamp - lastConfirmationTime >= 86400 * 365 * 3 / 2, "CABT0");

        nonMarketingReserves = 0;

        transferBNB(address(this).balance, msg.sender);
        transferBUSD(BusdContract.balanceOf(address(this)), msg.sender);
    }

    function swapToBUSD(uint256 amount, uint256 amountOutMin) external
    {
        require(gasleft() > 500000);

        if (msg.sender != Admin1 && msg.sender != Admin2)
        {
            require(More.isAuthorized(msg.sender) > 0, "STBUSD0");
        }

        address[] memory path = new address[](2);
        path[0] = SwapRouter.WETH();
        path[1] = BUSD_ADDRESS;

        SwapRouter.swapExactETHForTokens{value: amount}(amountOutMin, path, address(this), block.timestamp);
    }

    function swapToBNB(uint256 amount, uint256 amountOutMin) private
    {
        address[] memory path = new address[](2);
        path[0] = BUSD_ADDRESS;
        path[1] = SwapRouter.WETH();

        BusdContract.approve(ROUTER_ADDRESS, amount);
        SwapRouter.swapExactTokensForETH(amount, amountOutMin, path, address(this), block.timestamp);
    }

    function transferBNB(uint256 amount, address to) private
    {
        (bool success,) = to.call{value: amount}('');
        require(success, "TBNB0");
    }

    function transferBUSD(uint256 amount, address to) private
    {
        BusdContract.transfer(to, amount);
    }
}