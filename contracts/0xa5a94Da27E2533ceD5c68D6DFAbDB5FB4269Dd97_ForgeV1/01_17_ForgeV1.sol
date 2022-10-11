// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/AccessControl.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import "./interfaces/IUniswapV2Router.sol";
import {IDynaset} from "./interfaces/IDynaset.sol";
import "./interfaces/IDynasetTvlOracle.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ForgeV1 is AccessControl , ReentrancyGuard {
    using SafeERC20 for IERC20;
    /* ==========  Structs  ========== */

    struct ForgeInfo {
        bool isEth;
        address contributionToken;
        uint256 dynasetLp;
        uint256 totalContribution;
        uint256 minContribution;
        uint256 maxContribution;
        uint256 maxCap;
        uint256 contributionPeriod;
        bool withdrawEnabled;
        bool depositEnabled;
        bool forging;
        uint256 nextForgeContributorIndex;
    }

    struct UserInfo {
        uint256 depositAmount;
        uint256 dynasetsOwed;
    }

    struct Contributor {
        address contributorAddress;
        uint256 contributedAmount;
    }

    /* ==========  Constants  ========== */
    bytes32 public constant BLACK_SMITH = keccak256(abi.encode("BLACK_SMITH"));

    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    uint256 public constant USDC_DECIMALS = 6;
    uint256 public constant DYNASET_DECIMALS = 18;

    uint256 public constant SLIPPAGE_FACTOR = 1000;
    uint256 public constant WITHDRAW_FEE_FACTOR = 10000;
    uint256 public constant WITHDRAW_FEE_5_PERCENT = 500;
    uint256 public constant WITHDRAW_FEE_4_PERCENT = 400;
    uint256 public constant WITHDRAW_FEE_2_5_PERCENT = 250;

    uint256 public constant WITHDRAW_FEE_5_PERCENT_PERIOD = 30 days;
    uint256 public constant WITHDRAW_FEE_4_PERCENT_PERIOD = 60 days;
    uint256 public constant WITHDRAW_FEE_2_5_PERCENT_PERIOD = 90 days;

    /* ==========  State  ========== */
    
    // forgeID => Contributor
    mapping(uint256 => Contributor[]) public contributors; 
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    ForgeInfo[] public forgeInfo;

    IDynaset public dynaset;
    IDynasetTvlOracle public dynasetTvlOracle;
    address public uniswapV2Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    uint256 public totalForges;
    uint256 public slippage = 50;
    uint256 public totalFee;
    bool    public lpWithdraw;

    uint256 public deadline;

    /* ==========  Events  ========== */

    event LogForgeAddition(uint256 indexed forgeId, address indexed contributionToken);
    event Deposited(address indexed caller, address indexed user, uint256 amount);
    event ForgingStarted(uint256 indexed forgeId, uint256 indexed nextForgeContributorIndex);
    event DepositedLP(address indexed user, uint256 indexed forgeId, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Redeemed(address indexed user, uint256 amount);
    event Forged(address indexed user, uint256 indexed amount, uint256 price);
    event SetlpWithdraw(bool lpWithdraw);
    event ForgeWithdrawEnabled(bool status, uint256 forgeId);
    event ForgeDepositEnabled(bool status, uint256 forgeId);
    event OracleUpdated(address oracle);
    event RouterUpgraded(address router);

    /* ==========  Constructor  ========== */

    constructor(
        address _blacksmith,
        address _dynaset,
        address _dynasetTvlOracle
    ) {
        require(
            _blacksmith != address(0)
            && _dynaset != address(0)
            && _dynasetTvlOracle != address(0),
            "ERR_ZERO_ADDRESS"
        );
        dynaset = IDynaset(_dynaset);
        dynasetTvlOracle = IDynasetTvlOracle(_dynasetTvlOracle);
        _setupRole(BLACK_SMITH, _blacksmith);
    }

    /* ==========  External Functions  ========== */

    function createForge(
        bool isEth,
        address contributionToken,
        uint256 mincontrib,
        uint256 maxcontrib,
        uint256 maxcapital
    ) external onlyRole(BLACK_SMITH) {
        require(
            mincontrib > 0 && maxcontrib > 0 && maxcapital > 0,
            "PRICE_ERROR"
        );
        if(isEth) {
            require(contributionToken == WETH, "INCORRECT_CONTRIBUTION_TOKEN");
        }
        forgeInfo.push(
            ForgeInfo({
                isEth: isEth,
                dynasetLp: 0,
                contributionToken: contributionToken,
                totalContribution: 0,
                minContribution: mincontrib,
                maxContribution: maxcontrib,
                maxCap: maxcapital,
                contributionPeriod: block.timestamp,
                withdrawEnabled: false,
                depositEnabled: false,
                forging: false,
                nextForgeContributorIndex: 0
            })
        );
        totalForges = totalForges + 1;
        emit LogForgeAddition(forgeInfo.length - 1, contributionToken);
    }

    function startForging(uint256 forgeId) external onlyRole(BLACK_SMITH) {
        ForgeInfo memory forge = forgeInfo[forgeId];
        require(!forge.forging, "ERR_FORGING_STARTED");
        require(
            forge.nextForgeContributorIndex < contributors[forgeId].length,
            "ERR_NO_DEPOSITORS"
        );
        forge.forging = true;
        forge.depositEnabled = false;
        forgeInfo[forgeId] = forge;
        emit ForgingStarted(forgeId, forge.nextForgeContributorIndex);
    }

    //select forge to mint to assign the dynaset tokens to it
    //mint from the contributions set to that forge
    function forgeFunction(
        uint256 forgeId,
        uint256 contributorsToMint,
        uint256 minimumAmountOut
    ) external nonReentrant onlyRole(BLACK_SMITH) {
        uint256 _forgeId = forgeId; // avoid stack too deep
        ForgeInfo memory forge = forgeInfo[_forgeId];
        require(forge.forging, "ERR_FORGING_NOT_STARTED");
        require(!forge.depositEnabled, "ERR_DEPOSITS_NOT_DISABLED");

        require(contributorsToMint > 0, "CONTRIBUTORS_TO_MINT_IS_ZERO");
        uint256 finalIndex = forge.nextForgeContributorIndex + (contributorsToMint - 1);
        uint256 totalContributors = contributors[_forgeId].length;
        forge.forging = (finalIndex < totalContributors - 1);
        if (finalIndex >= totalContributors) {
            finalIndex = totalContributors - 1;
        }

        uint256 forgedAmount;
        uint256 amountToForge;
        uint256 i;

        for (i = forge.nextForgeContributorIndex; i <= finalIndex; i++) {
            amountToForge += contributors[_forgeId][i].contributedAmount;
        }
        require(amountToForge > 0, "ERR_AMOUNT_TO_FORGE_ZERO");
        uint256 tokensMinted = _mintDynaset(forge.contributionToken, amountToForge);
        require(tokensMinted >= minimumAmountOut, "ERR_MINIMUM_AMOUNT_OUT");
        
        for (i = forge.nextForgeContributorIndex; i <= finalIndex && forgedAmount < amountToForge; i++) {
            address contributorAddress = contributors[_forgeId][i].contributorAddress;
            UserInfo storage user = userInfo[_forgeId][contributorAddress];
            uint256 userContributedAmount = contributors[_forgeId][i].contributedAmount;
            
            forgedAmount += userContributedAmount;
            user.depositAmount = user.depositAmount - userContributedAmount;
            uint256 userTokensMinted = tokensMinted * userContributedAmount / amountToForge;
            user.dynasetsOwed += userTokensMinted;
            emit Forged(
                contributorAddress,
                userTokensMinted,
                userContributedAmount
            );
        }
        forge.nextForgeContributorIndex = finalIndex + 1;
        forge.totalContribution = forge.totalContribution - forgedAmount;
        forge.dynasetLp += tokensMinted;
        forgeInfo[_forgeId] = forge;
    }

    // deposits funds to the forge and the contribution is added to the to address.
    // the to address will receive the dynaset LPs.
    function deposit(
        uint256 forgeId,
        uint256 amount,
        address to
    ) external nonReentrant payable {
        require(to != address(0), "ERR_ZERO_ADDRESS");
        ForgeInfo memory forge = forgeInfo[forgeId];
        require(forge.depositEnabled, "ERR_DEPOSIT_DISABLED");

        UserInfo storage user = userInfo[forgeId][to];
        if (forge.isEth) {
            require(amount == msg.value, "ERR_INVALID_AMOUNT_VALUE");

            uint256 totalContribution = user.depositAmount + msg.value;

            require(
                forge.minContribution <= amount,
                "ERR_AMOUNT_BELOW_MINCONTRIBUTION"
            );

            require(
                totalContribution <= forge.maxContribution,
                "ERR_AMOUNT_ABOVE_MAXCONTRIBUTION"
            );

            //3. `forge.maxCap` limit may be exceeded if `forge.isEth` flag is `true`.
            require(
                (forge.totalContribution + msg.value) <= forge.maxCap,
                "MAX_CAP"
            );
            //convert to weth the eth deposited to the contract
            //comment to run tests
            user.depositAmount = (user.depositAmount + msg.value);
            forge.totalContribution = (forge.totalContribution + msg.value);
            forgeInfo[forgeId] = forge;
            contributors[forgeId].push(Contributor(to, msg.value));

            IWETH(WETH).deposit{value: msg.value}();
            emit Deposited(msg.sender, to, amount);
        } else {
            require(
                (forge.totalContribution + amount) <= forge.maxCap,
                "MAX_CAP"
            );
            IERC20 tokenContribution = IERC20(forge.contributionToken);
            require(
                tokenContribution.balanceOf(msg.sender) >= amount,
                "ERR_NOT_ENOUGH_TOKENS"
            );
            require(
                tokenContribution.allowance(msg.sender, address(this)) >=
                    amount,
                "ERR_INSUFFICIENT_ALLOWANCE"
            );

            uint256 contribution = user.depositAmount + amount;

            require(
                forge.minContribution <= contribution,
                "ERR_AMOUNT_BELOW_MINCONTRIBUTION"
            );

            require(
                contribution <= forge.maxContribution,
                "ERR_AMOUNT_ABOVE_MAXCONTRIBUTION"
            );
            require(
                tokenContribution.balanceOf(address(this)) <= forge.maxCap,
                "MAX_CAP"
            );
            user.depositAmount = contribution;
            forge.totalContribution = forge.totalContribution + amount;
            forgeInfo[forgeId] = forge;
            contributors[forgeId].push(Contributor(to, amount));
            tokenContribution.safeTransferFrom(
                msg.sender,
                address(this),
                amount
            );
            emit Deposited(msg.sender, to, amount);
        }
    }

    function redeem(
        uint256 forgeId,
        uint256 amount,
        address redeemToken,
        uint256 minimumAmountOut
    ) public nonReentrant {
        ForgeInfo memory forge = forgeInfo[forgeId];
        require(forge.withdrawEnabled, "ERR_WITHDRAW_DISABLED");

        UserInfo storage user = userInfo[forgeId][msg.sender];
        //require(userbalance on dynaset)
        require(user.dynasetsOwed >= amount, "ERR_INSUFFICIENT_USER_BALANCE");

        uint256 dynasetBalance = dynaset.balanceOf(
            address(this)
        );
        require(dynasetBalance >= amount, "ERR_FORGE_BALANCE_INSUFFICIENT");
        uint256 startTime = forge.contributionPeriod;
        uint256 amountSlashed = capitalSlash(amount, startTime);
        totalFee = totalFee + (amount - amountSlashed);
        (address[] memory tokens, uint256[] memory amounts) = dynaset.calcTokensForAmount(amountSlashed);
        address _redeemToken = redeemToken; // avoid stack too deep
        require(
            _checkValidToken(tokens, _redeemToken),
            "ERR_INVALID_REDEEM_TOKEN"
        );

        uint256 initialRedeemTokenBalance = IERC20(_redeemToken).balanceOf(
            address(this)
        );
        forge.dynasetLp = forge.dynasetLp - amount;
        forgeInfo[forgeId] = forge;
        user.dynasetsOwed = user.dynasetsOwed - amount;
        userInfo[forgeId][msg.sender] = user;
        dynaset.exitDynaset(amountSlashed);
        uint256 amountOut = 0;
        for (uint256 i = 0; i < tokens.length; i++) {
            address tokenOut = tokens[i];
            uint256 amountIn = amounts[i];
            require(
                IERC20(tokenOut).balanceOf(address(this)) >= amountIn,
                "ERR_INSUFFICIENT_FUNDS_MINT"
            );
            // for all tokens execpt the redeem token Swap the tokens and
            // send them to the user address
            // if the tokenOut == redeemToken the funds will be transfered outsede this for loop
            if (tokenOut != _redeemToken) {
                IERC20(tokenOut).safeIncreaseAllowance(
                    uniswapV2Router,
                    amountIn
                );
                address wethAddress = WETH;
                uint256 pathLength;
                if (tokenOut != wethAddress && _redeemToken != wethAddress) {
                    pathLength = 3;
                } else {
                    pathLength = 2;
                }
                address[] memory path;
                path = new address[](pathLength);
                path[0] = tokenOut;
                if (tokenOut != wethAddress && _redeemToken != wethAddress) {
                    path[1] = wethAddress;
                    path[2] = _redeemToken;
                } else {
                    path[1] = _redeemToken;
                }
                uint256[] memory uniAmountsOut = IUniswapV2Router(uniswapV2Router).getAmountsOut(amountIn, path);
                uint256 minimumAmountOut_ = uniAmountsOut[pathLength - 1] 
                                            * (SLIPPAGE_FACTOR - slippage) / SLIPPAGE_FACTOR;
                //then we will call swapExactTokensForTokens
                //for the deadline we will pass in block.timestamp + deadline
                //the deadline is the latest time the trade is valid for
                uint256[] memory amountsOut = IUniswapV2Router(uniswapV2Router)
                    .swapExactTokensForTokens(
                        amountIn,
                        minimumAmountOut_,
                        path,
                        msg.sender,
                        block.timestamp + deadline
                    );
                require(amountsOut.length == path.length, "ERR_SWAP_FAILED");
                amountOut += amountsOut[amountsOut.length - 1];
            } else {
                amountOut += amountIn;
            }
        }
        require(amountOut >= minimumAmountOut, "ERR_MINIMUM_AMOUNT_OUT");
        uint256 amountToTransfer = (IERC20(_redeemToken).balanceOf(address(this)) - initialRedeemTokenBalance);
        IERC20(_redeemToken).safeTransfer(msg.sender, amountToTransfer);
        emit Redeemed(msg.sender, amount);
    }

    function setlpWithdraw(bool status) external onlyRole(BLACK_SMITH) {
        lpWithdraw = status;
        emit SetlpWithdraw(lpWithdraw);
    }

    function withdrawFee() external nonReentrant onlyRole(BLACK_SMITH) {
        require(dynaset.balanceOf(address(this)) >= totalFee, "ERR_INSUFFICIENT_BALANCE");
        uint256 feeToRedeem = totalFee;
        totalFee = 0;
        require(dynaset.transfer(msg.sender, feeToRedeem), "ERR_TRANSFER_FAILED");
    }

    function setWithdraw(bool status, uint256 forgeId) external onlyRole(BLACK_SMITH) {
        require(forgeId < totalForges, "ERR_NONEXISTENT_FORGE");
        ForgeInfo memory forge = forgeInfo[forgeId];
        forge.withdrawEnabled = status;
        forgeInfo[forgeId] = forge;
        emit ForgeWithdrawEnabled(status, forgeId);
    }

    function setDeposit(bool status, uint256 forgeId) external onlyRole(BLACK_SMITH) {
        require(forgeId < totalForges, "ERR_NONEXISTENT_FORGE");
        ForgeInfo memory forge = forgeInfo[forgeId];
        forge.depositEnabled = status;
        forgeInfo[forgeId] = forge;
        emit ForgeDepositEnabled(status, forgeId);
    }

    function setDeadline(uint256 newDeadline) external onlyRole(BLACK_SMITH) {
        deadline = newDeadline;
    }

    function upgradeUniswapV2Router(address newUniswapV2Router) external onlyRole(BLACK_SMITH) {
        require(newUniswapV2Router != address(0), "ERR_ADDRESS_ZERO");
        uniswapV2Router = newUniswapV2Router;
        emit RouterUpgraded(newUniswapV2Router);
    }

    function depositOutput(uint256 forgeId, uint256 amount) public nonReentrant {
        ForgeInfo memory forge = forgeInfo[forgeId];
        UserInfo storage user = userInfo[forgeId][msg.sender];

        require(dynaset.balanceOf(msg.sender) >= amount, "ERR_INSUFFICIENT_DEPOSITOR_BALANCE");

        user.dynasetsOwed = user.dynasetsOwed + amount;
        userInfo[forgeId][msg.sender] = user;

        forge.dynasetLp = forge.dynasetLp + amount;
        forgeInfo[forgeId] = forge;

        require(dynaset.transferFrom(msg.sender, address(this), amount), "ERR_TRANSFER_FAILED");
        emit DepositedLP(msg.sender, forgeId, amount);
    }

    function withdrawOutput(uint256 forgeId, uint256 amount) external nonReentrant {
        ForgeInfo memory forge = forgeInfo[forgeId];
        UserInfo storage user = userInfo[forgeId][msg.sender];

        require(lpWithdraw, "ERR_WITHDRAW_DISABLED");
        require(dynaset.balanceOf(address(this)) >= user.dynasetsOwed, "ERR_INSUFFICIENT_CONTRACT_BALANCE");
        require(user.dynasetsOwed >= amount, "ERR_INSUFFICIENT_USER_BALANCE");
        
        user.dynasetsOwed = user.dynasetsOwed - (amount);
        userInfo[forgeId][msg.sender] = user;

        forge.dynasetLp = forge.dynasetLp - (amount);
        forgeInfo[forgeId] = forge;

        require(dynaset.transfer(msg.sender, amount), "ERR_TRANSFER_FAILED");
        emit Withdraw(msg.sender, amount);
    }

    // the dynaset tokens are transfered from wallet to forgeContract
    // which are then redeemed to desired redeemToken
    // Did not add reEntrency Guard because both depositOutput and
    // redeem are nonReentrant 
    function redeemFromWallet(
        uint256 forgeId,
        uint256 amount,
        address redeemToken,
        uint256 minimumAmountOut
    ) external {
        depositOutput(forgeId, amount);
        redeem(forgeId, amount, redeemToken, minimumAmountOut);
    }

    function setSlippage(uint256 newSlippage) external onlyRole(BLACK_SMITH) {
        require(newSlippage < (SLIPPAGE_FACTOR / 2), "SLIPPAGE_TOO_HIGH");
        slippage = newSlippage;
    }
    
    function updateOracle(address newDynasetTvlOracle) external onlyRole(BLACK_SMITH) {
        dynasetTvlOracle = IDynasetTvlOracle(newDynasetTvlOracle);
        emit OracleUpdated(newDynasetTvlOracle);
    }

    function getUserDynasetsOwned(uint256 forgeId, address user) external view returns (uint256) {
        return userInfo[forgeId][user].dynasetsOwed;
    }

    function getUserContribution(uint256 forgeId, address user) external view returns (uint256) {
        return userInfo[forgeId][user].depositAmount;
    }

    function getForgeBalance(uint256 forgeId) external view returns (uint256) {
        return forgeInfo[forgeId].totalContribution;
    }

    function getContributor(uint256 id, uint256 index) external view returns (address) {
        return contributors[id][index].contributorAddress;
    }

    /* ==========  Public Functions  ========== */

    function calculateContributionUsdc(uint256 forgeId) public view returns (uint256 contrib) {
        ForgeInfo memory forge = forgeInfo[forgeId];
        uint256 contributionAmount = forge.totalContribution;
        address contributionToken = forge.contributionToken;
        if (contributionToken == USDC) {
            return contributionAmount;
        } else {
            return dynasetTvlOracle.tokenUsdcValue(contributionToken, contributionAmount);
        }
    }

    // withdrawal fee calculation based on contribution time
    // 0-30 days 5%
    // 31-60 days 4%
    // 61 - 90 days 2.5%
    // above 91 days 0%
    function capitalSlash(uint256 amount, uint256 contributionTime) public view returns (uint256) {
        uint256 currentTime = block.timestamp;
        if ((contributionTime <= currentTime)
        && (currentTime < contributionTime + WITHDRAW_FEE_5_PERCENT_PERIOD)) {
            return amount * (WITHDRAW_FEE_FACTOR - WITHDRAW_FEE_5_PERCENT) / WITHDRAW_FEE_FACTOR;
        }
        if ((contributionTime + WITHDRAW_FEE_5_PERCENT_PERIOD <= currentTime) 
        && (currentTime < contributionTime + WITHDRAW_FEE_4_PERCENT_PERIOD)) {
            return amount * (WITHDRAW_FEE_FACTOR - WITHDRAW_FEE_4_PERCENT) / WITHDRAW_FEE_FACTOR;
        }
        if ((contributionTime + WITHDRAW_FEE_4_PERCENT_PERIOD <= currentTime) 
        && (currentTime < contributionTime + WITHDRAW_FEE_2_5_PERCENT_PERIOD)) {
            return amount * (WITHDRAW_FEE_FACTOR - WITHDRAW_FEE_2_5_PERCENT) / WITHDRAW_FEE_FACTOR;
        }
        return amount;
    }
  
    // ! Keeping it commented to verify it is not used anywhere.
    // function getDepositors(uint256 forgeId) external view returns (address[] memory depositors) {
    //     uint256 length = contributors[forgeId].length;
    //     depositors = new address[](length);
    //     for (uint256 i = 0; i < length; i++) {
    //         depositors[i] = contributors[forgeId][i].contributorAddress;
    //     }
    // }

    // This method should multiply by 18 decimals before doing division 
    // to be sure that the outputAmount has 18 decimals precision
    function getOutputAmount(uint256 forgeId) public view returns (uint256 amount) {
        uint256 contributionUsdcValue = calculateContributionUsdc(forgeId);
        uint256 output = (contributionUsdcValue * (10**(DYNASET_DECIMALS + DYNASET_DECIMALS - USDC_DECIMALS)))
                         / dynasetTvlOracle.dynasetUsdcValuePerShare();
        return output;
    }

    /* ==========  Internal Functions  ========== */


    function _mintDynaset(address _contributionToken, uint256 contributionAmount) internal returns (uint256) {
        uint256 contributionUsdcValue = dynasetTvlOracle.tokenUsdcValue(_contributionToken, contributionAmount);
        address[] memory tokens;
        uint256[] memory ratios;
        uint256 totalUSDC;
        (tokens, ratios, totalUSDC) = dynasetTvlOracle.dynasetTokenUsdcRatios();
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            uint256 amountIn = contributionAmount * ratios[i] / 1e18;
            uint256 amountOut;
            if (token == _contributionToken) {
                amountOut = amountIn;
            } else {
                address contributionToken = _contributionToken;
                bool routeOverWeth = (contributionToken != WETH && token != WETH);
                uint256 pathLength = routeOverWeth ? 3 : 2;
                address[] memory path = new address[](pathLength);
                path[0] = contributionToken;
                if (routeOverWeth) {
                    path[1] = WETH;
                }
                path[pathLength - 1] = token;

                uint256[] memory amountsOut = IUniswapV2Router(uniswapV2Router).getAmountsOut(amountIn, path);
                amountOut = amountsOut[pathLength - 1];

                IERC20(contributionToken).safeIncreaseAllowance(uniswapV2Router, amountIn);
                require(
                    IUniswapV2Router(uniswapV2Router)
                        .swapExactTokensForTokens(
                            amountIn,
                            amountOut * (SLIPPAGE_FACTOR - slippage) / SLIPPAGE_FACTOR,
                            path,
                            address(this),
                            block.timestamp + deadline
                        )
                        .length == path.length,
                    "ERR_SWAP_FAILED"
                );
            }
            IERC20(token).safeIncreaseAllowance(address(dynaset), amountOut);
        }
        uint256 totalSupply = dynaset.totalSupply();
        uint256 sharesToMint = contributionUsdcValue * totalSupply / totalUSDC;
        return dynaset.joinDynaset(sharesToMint);
    }

    function _checkValidToken(address[] memory tokens, address redeemToken) internal pure returns (bool valid) {
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == redeemToken) {
                valid = true;
                break;
            }
        }
    }
}