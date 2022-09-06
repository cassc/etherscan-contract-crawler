// SPDX-License-Identifier: MIT
// Decontracts Protocol. @2022
pragma solidity >=0.8.14;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IFundAccount, FundCreateParams} from "../interfaces/fund/IFundAccount.sol";
import {IFundManager} from "../interfaces/fund/IFundManager.sol";
import {IPriceOracle} from "../interfaces/fund/IPriceOracle.sol";
import {IPositionViewer} from "../interfaces/fund/IPositionViewer.sol";
import {IFundFilter} from "../interfaces/fund/IFundFilter.sol";

import {PaymentGateway} from "../fund/PaymentGateway.sol";
import {Errors} from "../libraries/Errors.sol";
import {Constants} from "../libraries/Constants.sol";

import {INonfungiblePositionManager} from "../intergrations/uniswap/INonfungiblePositionManager.sol";
import {IV3SwapRouter} from "../intergrations/uniswap/IV3SwapRouter.sol";
import {Path} from "../libraries/Path.sol";

contract FundManager is IFundManager, Pausable, ReentrancyGuard, PaymentGateway, Ownable {
    using Path for bytes;

    // Address of master account for cloning
    address public masterAccount;

    IFundFilter public override fundFilter;

    // All accounts list related to this address
    mapping(address => address[]) public accounts;

    // Mapping account address => historical minted position tokenIds
    mapping(address => uint256[]) private accountMintedPositions;

    // Mapping account address => tokenId => closed flag
    mapping(address => mapping(uint256 => bool)) private accountClosedPositions;

    // Contract version
    uint256 public constant version = 1;
    
    modifier onlyAllowedAdapter() {
        require(fundFilter.protocolAdapter() == msg.sender, Errors.NotAllowedAdapter);
        _;
    }

    // @dev FundManager constructor
    // @param _masterAccount Address of master account for cloning
    constructor(address _masterAccount, address _weth, address _fundFilter) PaymentGateway(_weth) {
        masterAccount = _masterAccount;
        fundFilter = IFundFilter(_fundFilter);
    }

    modifier validCreateParams(FundCreateParams memory params) {
        require(
            params.initiator == msg.sender, Errors.InvalidInitiator
        );
        require(
            params.recipient != address(0) &&
            params.recipient != params.initiator, Errors.InvalidRecipient
        );
        require(
            params.gp == params.initiator ||
            params.gp == params.recipient, Errors.InvalidGP
        );
        require(
            bytes(params.name).length >= Constants.NAME_MIN_SIZE &&
            bytes(params.name).length <= Constants.NAME_MAX_SIZE, Errors.InvalidNameLength
        );
        require(
            params.managementFee >= fundFilter.minManagementFee() &&
            params.managementFee <= fundFilter.maxManagementFee(), Errors.InvalidManagementFee
        );
        require(
            params.carriedInterest >= fundFilter.minCarriedInterest() &&
            params.carriedInterest <= fundFilter.maxCarriedInterest(), Errors.InvalidCarriedInterest
        );
        require(
            fundFilter.isUnderlyingTokenAllowed(params.underlyingToken), Errors.InvalidUnderlyingToken
        );
        require(
            params.allowedProtocols.length > 0, Errors.InvalidAllowedProtocols
        );
        for (uint256 i = 0; i < params.allowedProtocols.length; i++) {
            require(
                fundFilter.isProtocolAllowed(params.allowedProtocols[i]), Errors.InvalidAllowedProtocols
            );
        }
        require(
            params.allowedTokens.length > 0, Errors.InvalidAllowedTokens
        );
        bool includeUnderlying;
        bool includeWETH9;
        for (uint256 i = 0; i < params.allowedTokens.length; i++) {
            require(
                fundFilter.isTokenAllowed(params.allowedTokens[i]), Errors.InvalidAllowedTokens
            );
            if (params.allowedTokens[i] == params.underlyingToken) {
                includeUnderlying = true;
            }
            if (params.allowedTokens[i] == weth9) {
                includeWETH9 = true;
            }
        }
        require(
            includeUnderlying && includeWETH9, Errors.InvalidAllowedTokens
        );
        _;
    }

    // @dev create FundAccount with the given parameters
    // @param params the instance of FundCreateParams
    function createAccount(FundCreateParams memory params) external validCreateParams(params) payable whenNotPaused nonReentrant returns (address account) {
        account = Clones.clone(masterAccount);
        IFundAccount(account).initialize(params);
        accounts[params.initiator].push(account);
        accounts[params.recipient].push(account);

        if (params.initiatorAmount > 0) {
            IFundAccount(account).buy(params.initiator, params.initiatorAmount);
            pay(params.underlyingToken, params.initiator, account, params.initiatorAmount);
        }
        _refundETH();

        emit AccountCreated(account, params.initiator, params.recipient);
    }

    function updateName(address accountAddr, string memory newName) external whenNotPaused nonReentrant {
        IFundAccount account = IFundAccount(accountAddr);
        require(account.gp() == msg.sender, Errors.NotGP);
        require(bytes(newName).length >= Constants.NAME_MIN_SIZE && bytes(newName).length <= Constants.NAME_MAX_SIZE, Errors.InvalidName);

        account.updateName(newName);
    }

    function buyFund(address accountAddr, uint256 buyAmount) external payable whenNotPaused nonReentrant {
        IFundAccount account = IFundAccount(accountAddr);
        require(msg.sender == account.initiator() || msg.sender == account.recipient(), Errors.NotGPOrLP);
        require(buyAmount > 0, Errors.MissingAmount);

        account.buy(msg.sender, buyAmount);
        pay(account.underlyingToken(), msg.sender, accountAddr, buyAmount);
        _refundETH();
    }

    function sellFund(address accountAddr, uint256 sellRatio) external whenNotPaused nonReentrant {
        IFundAccount account = IFundAccount(accountAddr);
        require(msg.sender == account.initiator() || msg.sender == account.recipient(), Errors.NotGPOrLP);
        require(sellRatio > 0 && sellRatio < 1e4, Errors.InvalidSellUnit);

        account.sell(msg.sender, sellRatio);
    }

    function collect(address accountAddr) external whenNotPaused nonReentrant {
        IFundAccount account = IFundAccount(accountAddr);
        require(account.gp() == msg.sender, Errors.NotGP);

        account.collect();
    }

    function close(AccountCloseParams calldata params) external whenNotPaused nonReentrant {
        IFundAccount account = IFundAccount(params.account);
        require(msg.sender == account.initiator() || msg.sender == account.recipient(), Errors.NotGPOrLP);

        _convertAllAssetsToUnderlying(params.account, params.paths);
        account.close();
    }

    function unwrapWETH9(address accountAddr) external whenNotPaused nonReentrant {
        IFundAccount account = IFundAccount(accountAddr);
        require(account.gp() == msg.sender, Errors.NotGP);

        account.unwrapWETH9();
    }

    // @dev Returns quantity of all created accounts
    function getAccountsCount(address addr) external view returns (uint256) {
        return accounts[addr].length;
    }

    // @dev Returns array of all created accounts
    function getAccounts(address addr) external view returns (address[] memory) {
        return accounts[addr];
    }

    function owner() public view virtual override(IFundManager, Ownable) returns (address) {
        return Ownable.owner();
    }

    function calcTotalValue(address account) external view override returns (uint256 total) {
        IPriceOracle priceOracle = IPriceOracle(fundFilter.priceOracle());
        IFundAccount fundAccount = IFundAccount(account);
        address underlyingToken = fundAccount.underlyingToken();
        address[] memory allowedTokens = fundAccount.allowedTokens();
        for (uint256 i = 0; i < allowedTokens.length; i++) {
            address token = allowedTokens[i];
            uint256 balance = IERC20(token).balanceOf(account);
            if (token == weth9) {
                balance += fundAccount.ethBalance();
            }
            total += priceOracle.convert(token, underlyingToken, balance);
        }
        uint256[] memory lpTokenIds = lpTokensOfAccount(account);
        for (uint256 i = 0; i < lpTokenIds.length; i++) {
            (address token0, address token1, ,uint256 amount0, uint256 amount1, uint256 fee0, uint256 fee1)
            = IPositionViewer(fundFilter.positionViewer()).query(lpTokenIds[i]);
            total += priceOracle.convert(token0, underlyingToken, (amount0 + fee0));
            total += priceOracle.convert(token1, underlyingToken, (amount1 + fee1));
        }
        uint256 collectAmount = fundAccount.lastUpdateManagementFeeAmount();
        if (total > collectAmount) {
            total -= collectAmount;
        } else {
            total = 0;
        }
    }

    function lpTokensOfAccount(address account) public view returns (uint256[] memory) {
        uint256[] storage mintedTokenIds = accountMintedPositions[account];
        uint256[] memory temp = new uint256[](mintedTokenIds.length);
        uint256 k = 0;
        for (uint256 i = 0; i < mintedTokenIds.length; i++) {
            uint256 tokenId = mintedTokenIds[i];
            if (!accountClosedPositions[account][tokenId]) {
                temp[k] = tokenId;
                k++;
            }
        }
        uint256[] memory tokenIds = new uint256[](k);
        for (uint256 i = 0; i < k; i++) {
            tokenIds[i] = temp[i];
        }
        return tokenIds;
    }

    /// @dev Approve tokens for account. Restricted for adapters only
    /// @param account Account address
    /// @param token Token address
    /// @param protocol Target protocol address
    /// @param amount Approve amount
    function provideAccountAllowance(
        address account,
        address token,
        address protocol,
        uint256 amount
    ) external onlyAllowedAdapter() whenNotPaused nonReentrant {
        IFundAccount(account).approveToken(token, protocol, amount);
    }

    /// @dev Executes filtered order on account which is connected with particular borrower
    /// @param account Account address
    /// @param protocol Target protocol address
    /// @param data Call data for call
    function executeOrder(
        address account,
        address protocol,
        bytes calldata data,
        uint256 value
    ) external onlyAllowedAdapter() whenNotPaused nonReentrant returns (bytes memory) {
        return IFundAccount(account).execute(protocol, data, value);
    }

    function onMint(
        address account,
        uint256 tokenId
    ) external onlyAllowedAdapter() whenNotPaused nonReentrant {
        uint256[] memory tokenIds = lpTokensOfAccount(account);
        require(tokenIds.length < 20, Errors.ExceedMaximumPositions);
        accountMintedPositions[account].push(tokenId);
    }

    function onCollect(
        address account,
        uint256 tokenId
    ) external onlyAllowedAdapter() whenNotPaused nonReentrant {
        (, , , uint256 amount0, uint256 amount1, uint256 fee0, uint256 fee1) = IPositionViewer(fundFilter.positionViewer()).query(tokenId);
        if (amount0 == 0 && amount1 == 0 && fee0 == 0 && fee1 == 0) {
            accountClosedPositions[account][tokenId] = true;
        }
    }

    function onIncrease(
        address account,
        uint256 tokenId
    ) external onlyAllowedAdapter() whenNotPaused nonReentrant {
        accountClosedPositions[account][tokenId] = false;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function _convertAllAssetsToUnderlying(
        address account,
        bytes[] calldata paths
    ) private {
        IFundAccount fundAccount = IFundAccount(account);
        address positionManager = fundFilter.positionManager();
        uint256[] memory tokenIds = lpTokensOfAccount(account);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            (, , , , , , , uint128 liquidity, , , , ) = INonfungiblePositionManager(positionManager).positions(tokenIds[i]);
            if (liquidity > 0) {
                bytes memory decreaseLiquidityCall = abi.encodeWithSelector(
                    INonfungiblePositionManager.decreaseLiquidity.selector,
                    INonfungiblePositionManager.DecreaseLiquidityParams({
                        tokenId: tokenIds[i],
                        liquidity: liquidity,
                        amount0Min: 0,
                        amount1Min: 0,
                        deadline: block.timestamp
                    })
                );
                fundAccount.execute(positionManager, decreaseLiquidityCall, 0);
            }
            bytes memory collectCall = abi.encodeWithSelector(
                INonfungiblePositionManager.collect.selector,
                INonfungiblePositionManager.CollectParams({
                    tokenId: tokenIds[i],
                    recipient: account,
                    amount0Max: type(uint128).max,
                    amount1Max: type(uint128).max
                })
            );
            fundAccount.execute(positionManager, collectCall, 0);

            accountClosedPositions[account][tokenIds[i]] = true;
        }

        address swapRouter = fundFilter.swapRouter();
        address underlyingToken = fundAccount.underlyingToken();
        address[] memory allowedTokens = fundAccount.allowedTokens();
        address allowedToken;

        // Traverse account's allowedTokens to avoid incomplete paths input
        for (uint256 i = 0; i < allowedTokens.length; i++) {
            allowedToken = allowedTokens[i];
            if (allowedToken == underlyingToken) continue;
            if (allowedToken == weth9) {
                fundAccount.wrapWETH9();
            }
            uint256 balance = IERC20(allowedToken).balanceOf(account);
            if (balance == 0) continue;

            bytes memory matchPath;
            for (uint256 j = 0; j < paths.length; j++) {
                (address tokenIn, address tokenOut) = paths[j].decode();
                if (tokenIn == allowedToken && tokenOut == underlyingToken) {
                    matchPath = paths[j];
                    break;
                }
            }
            require(matchPath.length > 0, Errors.PathNotAllowed);

            fundAccount.approveToken(allowedToken, swapRouter, balance);
            bytes memory swapCall = abi.encodeWithSelector(
                IV3SwapRouter.exactInput.selector,
                IV3SwapRouter.ExactInputParams({
                    path: matchPath,
                    recipient: account,
                    amountIn: balance,
                    amountOutMinimum: 0
                })
            );
            fundAccount.execute(swapRouter, swapCall, 0);
        }

        if (underlyingToken == weth9) {
            fundAccount.unwrapWETH9();
        }
    }

    function _refundETH() private {
        if (address(this).balance > 0) payable(msg.sender).transfer(address(this).balance);
    }

}