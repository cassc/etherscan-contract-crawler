// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./mathFunclib.sol";

interface IRouter {
    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

contract SpaceBot is Ownable {
    using SafeERC20 for IERC20;

    IRouter public constant ROUTER =
        IRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    IERC20 public immutable TOKEN_1;
    IERC20 public immutable TOKEN_2;
    SpaceBotStation public immutable STATION;
    uint256 public slippage;

    address public adminDelegator;
    address public teamWalletAddr;
    uint256 public fees;
    address[] public path1;
    address[] public path2;
    uint256 public pathLen;

    event trade(uint dexaggSelector, IERC20 tokenin, uint256 inAmt, uint256 outAmt);

    constructor(address token1, address token2, SpaceBotStation station) {
        TOKEN_1 = IERC20(token1);
        TOKEN_2 = IERC20(token2);
        STATION = station;
        TOKEN_1.safeApprove(address(STATION), type(uint256).max);
        TOKEN_2.safeApprove(address(STATION), type(uint256).max);

        path1.push(token1);
        path1.push(token2);
        path2.push(token2);
        path2.push(token1);
        pathLen = 2;

        slippage = mathFuncs.decDiv18(997, 1000);
        fees = mathFuncs.decDiv18(2, 1000);
        adminDelegator = 0x5b592Cb46e9c9c7524C9502F03E0F2a39110139b;
        teamWalletAddr = 0xc2723929f3bD8A95EE7Fb5fF2aDa6EAe94215F8B;
        _transferOwnership(0xc2723929f3bD8A95EE7Fb5fF2aDa6EAe94215F8B);
    }

    function swapTrade(
        uint256 aggSelector,
        bytes calldata data,
        IERC20 tokenIn,
        uint256 amountIn
    ) external {
        require(msg.sender == adminDelegator, "Not approved to call");
        require(tokenIn == TOKEN_1 || tokenIn == TOKEN_2, "Unapproved token");

        uint256 tokenInAmountBefore = tokenIn.balanceOf(address(this));
        require(
            amountIn < tokenInAmountBefore,
            "Not allowed to bring balance down to zero"
        );

        IERC20 tokenOut = tokenIn == TOKEN_1 ? TOKEN_2 : TOKEN_1;
        uint256 tokenOutAmountBefore = tokenOut.balanceOf(address(this));

        uint256[] memory minAmountsOut;
        if (tokenIn == TOKEN_1) {
            minAmountsOut = ROUTER.getAmountsOut(amountIn, path1);
        } else {
            minAmountsOut = ROUTER.getAmountsOut(amountIn, path2);
        }

        address dexAgg = STATION.dexAggs(aggSelector);
        tokenIn.safeApprove(dexAgg, amountIn);
        (bool success, ) = dexAgg.call(data);
        require(success, "Trade failed");
        require(
            tokenInAmountBefore - tokenIn.balanceOf(address(this)) == amountIn,
            "Did not swap the exact amount"
        );

        uint256 tokenOutDiff = tokenOut.balanceOf(address(this)) -
            tokenOutAmountBefore;
        require(
            tokenOutDiff >=
                mathFuncs.decMul18(
                    minAmountsOut[minAmountsOut.length - 1],
                    slippage
                ),
            "Received less amount of tokenOut than expected"
        );
        uint256 tradingFees = mathFuncs.decMul18(tokenOutDiff, fees);
        tokenOut.safeTransfer(teamWalletAddr, tradingFees);

        
        emit trade(aggSelector,tokenIn,amountIn,tokenOutDiff);
    }

    function updateDelegator(address newAddress) external onlyOwner {
        adminDelegator = newAddress;
    }

    function updateFees(
        uint256 _newFees,
        address _newFeesRecipient
    ) external onlyOwner {
        require(
            _newFees <= 4000000000000000,
            "Exceeded maximum allowed fee of 0.4%"
        );
        fees = _newFees;
        teamWalletAddr = _newFeesRecipient;
    }

    function setPath(address[] calldata routerPath) external onlyOwner {
        require(
            routerPath[0] == address(TOKEN_1) &&
                routerPath[routerPath.length - 1] == address(TOKEN_2),
            "Incorrect routerPath argument"
        );
        for (uint i = 1; i < routerPath.length - 1; i++) {
            require(
                routerPath[i] != address(TOKEN_1) &&
                    routerPath[i] != address(TOKEN_2),
                "Not allowed to have TOKEN_1 and TOKEN_2 in the middle of the path"
            );
        }
        path1 = routerPath;
        pathLen = routerPath.length;
        delete path2;
        for (uint i = 0; i < routerPath.length; i++) {
            path2.push(routerPath[routerPath.length - 1 - i]);
        }
    }

    function setSlippage(uint256 newSlippage) external onlyOwner {
        // 1000000000000000000 is 100%
        // 990000000000000000 is 99%
        require(
            newSlippage <= 1000000000000000000 &&
                newSlippage >= 990000000000000000,
            "Slippage out of allowed range"
        );
        slippage = newSlippage;
    }
}

contract SpaceBotStation is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Metadata;

    uint256 constant SHARES_DECIMALS = 10 ** 18;

    address public adminDelegator;

    bool public contractEnabled = true;

    struct vaultParams {
        string vaultName;
        address token1Address;
        address token2Address;
        address vaultAddress;
        string vaultStrat;
    }
    mapping(uint256 => vaultParams) public vaultInfo;
    uint256 public vaultCount;

    address[] public dexAggs;
    uint256 public dexAggsLen;

    mapping(uint256 => uint256) public totalVaultShares;

    struct vaultSharesStruct {
        uint256 shares;
        uint256 shareholdersIndex;
    }
    mapping(address => mapping(uint256 => vaultSharesStruct)) public userShares;
    mapping(uint256 => address[]) private shareholdersPerVault;

    event amountStaked(
        address indexed _from,
        uint256 _vaultId,
        uint256 _token1Amt,
        uint256 _token2Amt
    );
    event amountUnstaked(
        address indexed _from,
        uint256 _vaultId,
        uint256 _token1Amt,
        uint256 _token2Amt
    );

    constructor() {
        _transferOwnership(0xc2723929f3bD8A95EE7Fb5fF2aDa6EAe94215F8B);
        adminDelegator = 0x5b592Cb46e9c9c7524C9502F03E0F2a39110139b;
    }

    function stakeInVault(
        uint256 vaultId,
        uint256 token1Desired,
        uint256 token2Desired
    ) external nonReentrant {
        require(contractEnabled, "Disabled");
        IERC20Metadata token1 = IERC20Metadata(
            vaultInfo[vaultId].token1Address
        );
        IERC20 token2 = IERC20(vaultInfo[vaultId].token2Address);

        uint256 token1Amt = token1Desired;
        uint256 token2Amt = token2Desired;

        {
            uint256 token1Reserve = token1.balanceOf(
                vaultInfo[vaultId].vaultAddress
            );
            uint256 token2Reserve = token2.balanceOf(
                vaultInfo[vaultId].vaultAddress
            );

            uint256 totalShares = totalVaultShares[vaultId];

            uint256 addedShares = (token1Desired * SHARES_DECIMALS) /
                10 ** token1.decimals();

            if (totalShares > 0) {
                token2Amt = (token1Amt * token2Reserve) / token1Reserve;
                if (token2Amt > token2Desired) {
                    token2Amt = token2Desired;
                    token1Amt = (token2Amt * token1Reserve) / token2Reserve;
                    assert(token1Amt <= token1Desired);
                }
                addedShares = (token1Amt * totalShares) / token1Reserve;
            }
            require(
                token1Amt > 0 && token2Amt > 0 && addedShares > 0,
                "Not enough tokens added"
            );
            totalVaultShares[vaultId] += addedShares;
            userShares[msg.sender][vaultId].shares += addedShares;
        }

        {
            uint256 index = userShares[msg.sender][vaultId].shareholdersIndex;
            uint256 length = shareholdersPerVault[vaultId].length;

            if (
                (index >= length ||
                    shareholdersPerVault[vaultId][index] != msg.sender)
            ) {
                userShares[msg.sender][vaultId].shareholdersIndex = length;
                shareholdersPerVault[vaultId].push(msg.sender);
            }
        }

        token1.safeTransferFrom(
            msg.sender,
            vaultInfo[vaultId].vaultAddress,
            token1Amt
        );
        token2.safeTransferFrom(
            msg.sender,
            vaultInfo[vaultId].vaultAddress,
            token2Amt
        );

        emit amountStaked(msg.sender, vaultId, token1Amt, token2Amt);
    }

    function unstakeFromVault(
        uint256 vaultId,
        uint256 shares
    ) external nonReentrant {
        IERC20 token1 = IERC20(vaultInfo[vaultId].token1Address);
        IERC20 token2 = IERC20(vaultInfo[vaultId].token2Address);

        uint256 token1Reserve = token1.balanceOf(
            vaultInfo[vaultId].vaultAddress
        );
        uint256 token2Reserve = token2.balanceOf(
            vaultInfo[vaultId].vaultAddress
        );

        require(
            shares <= userShares[msg.sender][vaultId].shares,
            "Not enough shares"
        );

        uint256 totalShares = totalVaultShares[vaultId];

        uint256 token1Amt = (shares * token1Reserve) / totalShares;
        uint256 token2Amt = (shares * token2Reserve) / totalShares;

        require(
            shares == totalShares ||
                (token1Amt < token1Reserve && token2Amt < token2Reserve),
            "Not enough tokens"
        );

        totalVaultShares[vaultId] -= shares;
        userShares[msg.sender][vaultId].shares -= shares;

        uint256 index = userShares[msg.sender][vaultId].shareholdersIndex;
        uint256 length = shareholdersPerVault[vaultId].length;

        if (
            userShares[msg.sender][vaultId].shares == 0 &&
            index < length &&
            shareholdersPerVault[vaultId][index] == msg.sender
        ) {
            shareholdersPerVault[vaultId][index] = shareholdersPerVault[
                vaultId
            ][length - 1];
            shareholdersPerVault[vaultId].pop();
        }

        token1.safeTransferFrom(
            vaultInfo[vaultId].vaultAddress,
            msg.sender,
            token1Amt
        );
        token2.safeTransferFrom(
            vaultInfo[vaultId].vaultAddress,
            msg.sender,
            token2Amt
        );

        emit amountUnstaked(msg.sender, vaultId, token1Amt, token2Amt);
    }

    /*************************
     * START of Admin Functions
     *************************/

    function turnOnOffTrading(bool value) external onlyOwner {
        contractEnabled = value;
    }

    function updateDelegator(address newAddress) external onlyOwner {
        adminDelegator = newAddress;
    }

    function addVault(
        string calldata vaultname,
        address _token1address,
        address _token2address,
        string calldata _vaultstrat
    ) external {
        require(msg.sender == adminDelegator, "Not approved to call");
        SpaceBot newPair = new SpaceBot(_token1address, _token2address, this);
        vaultInfo[vaultCount++] = vaultParams(
            vaultname,
            _token1address,
            _token2address,
            address(newPair),
            _vaultstrat
        );
    }

    function addDexAgg(address aggAddress) external onlyOwner {
        dexAggs.push(aggAddress);
        dexAggsLen++;
    }

    function removeDexAgg(uint256 aggSelector) external onlyOwner {
        dexAggs[aggSelector] = dexAggs[dexAggs.length - 1];
        dexAggs.pop();
        dexAggsLen--;
    }

    /***********************
     * End of Admin Functions
     ***********************/

    function desiredAmount(
        uint256 vaultId,
        address desiredToken,
        uint256 desiredAmt
    ) external view returns (uint256) {
        address token1 = vaultInfo[vaultId].token1Address;
        address token2 = vaultInfo[vaultId].token2Address;

        require(
            desiredToken == token1 || desiredToken == token2,
            "Token not in vault"
        );

        uint256 token1Reserve = IERC20(token1).balanceOf(
            vaultInfo[vaultId].vaultAddress
        );
        uint256 token2Reserve = IERC20(token2).balanceOf(
            vaultInfo[vaultId].vaultAddress
        );

        if (desiredToken == token1) {
            return (desiredAmt * token2Reserve) / token1Reserve;
        }
        return (desiredAmt * token1Reserve) / token2Reserve;
    }

    function userTokenAmounts(
        address user,
        uint256 vaultId
    ) external view returns (uint256 token1Amt, uint256 token2Amt) {
        IERC20 token1 = IERC20(vaultInfo[vaultId].token1Address);
        IERC20 token2 = IERC20(vaultInfo[vaultId].token2Address);

        uint256 shares = userShares[user][vaultId].shares;
        uint256 totalShares = totalVaultShares[vaultId];

        if (totalShares == 0) return (0, 0);

        token1Amt =
            (shares * token1.balanceOf(vaultInfo[vaultId].vaultAddress)) /
            totalShares;
        token2Amt =
            (shares * token2.balanceOf(vaultInfo[vaultId].vaultAddress)) /
            totalShares;
    }

    function shareholders(
        uint256 vaultId
    ) external view returns (address[] memory) {
        return shareholdersPerVault[vaultId];
    }
}