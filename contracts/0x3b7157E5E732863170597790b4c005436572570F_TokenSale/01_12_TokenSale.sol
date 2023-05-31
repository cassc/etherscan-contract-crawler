// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../interfaces/IAggregatorV3Interface.sol";
import "../interfaces/IWETH.sol";

/// @title JPEG'd Governance token sale contract
/// @notice ETH (WETH) and USDC can be deposited in this contract to get JPEG tokens once the sale ends. The rate depends on the dollar value of the tokens raised
contract TokenSale is Ownable, ReentrancyGuard {
    using SafeCast for int256;
    using SafeERC20 for IERC20;
    using Address for address;

    /// @dev Data relative to a user's account
    /// @param token The token the user deposited
    /// @param depositedAmount the amount of `token` deposited by the user
    struct Account {
        address token;
        uint256 depositedAmount;
    }

    /// @dev Data relative to a supported token
    /// @param oracle Address of the token/USD chainlink feed
    /// @param totalRaised Amount of tokens raised
    /// @param USDPrice Dollar value of a single token, only set after the sale has been finalized
    struct SupportedToken {
        address oracle;
        uint256 totalRaised;
        uint256 USDPrice;
    }

    /// @dev The sale's schedule
    /// @param startTimestamp The sale's start timestamp
    /// @param endTimestamp The sale's end timestamp
    struct SaleSchedule {
        uint256 startTimestamp;
        uint256 endTimestamp;
    }

    /// @dev WETH address stored separately to allow wrapping/unwrapping
    address public immutable WETH;
    address public immutable treasury;
    /// @notice Address of the token being sold
    address public immutable saleToken;

    /// @notice Amount of `saleToken` allocated for this sale
    /// @dev Can only be set by the owner using the `allocateTokensForSale` function
    uint256 public availableTokens;
    /// @notice Dollar value of the tokens raised, only set after the end of the sale
    /// @dev Set by the `finalizeRaise` function, 8 decimals
    uint256 public totalRaisedUSD;
    /// @notice Whether or not `saleToken` can be withdrawn from this contract
    /// @dev Set to true by the `enableWithdrawals` function
    bool public withdrawalsEnabled;

    /// @notice Sale start and end times
    /// @dev Can only be set by the owner in the `setSaleSchedule` function
    SaleSchedule public saleSchedule;

    /// @dev Array containing the addresses of all supported tokens (WETH/USDC). Used in `finalizeRaise`
    address[] internal supportedTokens;

    mapping(address => SupportedToken) internal supportedTokensData;
    mapping(address => Account) public userAccounts;

    /// @notice Emitted after a deposit
    /// @param depositor Address that made the deposit
    /// @param token Token used for the deposit (either WETH or USDC)
    /// @param amount Amount of `token` deposited
    event Deposited(
        address indexed depositor,
        address indexed token,
        uint256 amount
    );
    /// @notice Emitted after a withdraw
    /// @param withdrawer Address that withdrew assets
    /// @param amount Amount withdrawn
    event Withdrawn(address indexed withdrawer, uint256 amount);
    /// @notice Emitted after the owner has allocated `amount` of `saleToken`
    /// @param amount amount of `saleToken` allocated
    event TokensAllocated(uint256 amount);
    /// @notice Emitted after the owner has set the sale's schedule
    /// @param startTimestamp The sale's start timestamp
    /// @param endTimestamp The sale's end timestamp
    event SaleScheduleSet(uint256 startTimestamp, uint256 endTimestamp);
    /// @notice Emitted after the raise has been finalized and the total value of the tokens raised has been calculated
    /// @param totalRaisedUSD Dollar value of the tokens raised at the time this even was emitted, 8 decimals
    event RaiseFinalized(uint256 totalRaisedUSD);
    /// @notice Emitted after withdrawals have been enabled by the owner
    event WithdrawalsEnabled();
    /// @notice Emitted after `token` has been transferred to the `treasury` address
    /// @param token The token that has been transferred
    /// @param amount The amount of `token` that has been transferred
    event TreasuryTransfer(address indexed token, uint256 amount);

    /// @param _weth WETH address
    /// @param _usdc USDC address
    /// @param _wethOracle WETH chainlink price feed
    /// @param _usdcOracle USDC chainlink price feed
    /// @param _saleToken The address of the token to sell
    /// @param _treasury The treasury address
    constructor(
        address _weth,
        address _usdc,
        address _wethOracle,
        address _usdcOracle,
        address _saleToken,
        address _treasury
    ) {
        require(_weth != address(0), "INVALID_WETH");
        require(_usdc != address(0), "INVALID_USDC");
        require(_wethOracle != address(0), "INVALID_WETH_ORACLE");
        require(_usdcOracle != address(0), "INVALID_USDC_ORACLE");
        require(_saleToken != address(0), "INVALID_SALE_TOKEN");
        require(_treasury != address(0), "INVALID_TREASURY");

        WETH = _weth;
        supportedTokensData[_weth] = SupportedToken(_wethOracle, 0, 0);
        supportedTokensData[_usdc] = SupportedToken(_usdcOracle, 0, 0);
        saleToken = _saleToken;
        treasury = _treasury;

        supportedTokens.push(_weth);
        supportedTokens.push(_usdc);
    }

    /// @dev Accept direct ETH deposits
    receive() external payable {
        depositETH();
    }

    /// @notice Function used to allocate the amount of `saleToken` available for sale. Can only be called by the owner
    /// @dev Can only be called once
    /// @param _amount Amount of `saleToken` to sell
    function allocateTokensForSale(uint256 _amount) external onlyOwner {
        require(availableTokens == 0, "TOKENS_ALREADY_ALLOCATED");
        require(_amount > 0, "INVALID_ALLOCATED_AMOUNT");

        IERC20(saleToken).safeTransferFrom(msg.sender, address(this), _amount);
        availableTokens = _amount;

        emit TokensAllocated(_amount);
    }

    /// @notice Function used to set the sale's start and end timestamps. Can only be called by the owner
    /// @dev Can only be called once and only AFTER the `allocateTokensForSale` function has been called
    /// @param _start The sale's start timestamp
    /// @param _end The sale's end timestamp
    function setSaleSchedule(uint256 _start, uint256 _end) external onlyOwner {
        require(availableTokens != 0, "TOKENS_NOT_ALLOCATED");
        require(_start > block.timestamp, "INVALID_START_TIMESTAMP");
        require(_end > _start, "INVALID_END_TIMESTAMP");
        require(saleSchedule.startTimestamp == 0, "SCHEDULE_ALREADY_SET");

        saleSchedule.startTimestamp = _start;
        saleSchedule.endTimestamp = _end;
    }

    /// @notice Function used to calculate the dollar value of the raised tokens, to ensure everyone gets `saleToken` at the same price. Can only be called by the owner at the end of the sale
    /// @dev Can only be called once
    function finalizeRaise() external onlyOwner {
        require(
            saleSchedule.endTimestamp > 0 &&
                block.timestamp >= saleSchedule.endTimestamp,
            "SALE_NOT_ENDED"
        );
        require(totalRaisedUSD == 0, "ALREADY_FINALIZED");

        //Total dollar value raised
        uint256 value;
        for (uint256 i = 0; i < supportedTokens.length; i++) {
            address token = supportedTokens[i];
            SupportedToken storage tokenData = supportedTokensData[token];

            uint256 answer = IAggregatorV3Interface(tokenData.oracle)
                .latestAnswer()
                .toUint256();
            require(answer > 0, "INVALID_ORACLE_ANSWER");

            value +=
                (tokenData.totalRaised * answer) /
                10**ERC20(token).decimals(); //Chainlink USD prices are always to 8
            tokenData.USDPrice = answer;
        }

        totalRaisedUSD = value;

        emit RaiseFinalized(value);
    }

    /// @notice Function used to enable withdrawals of `saleToken`. Can only be called by the owner after `finalizeRaise`
    /// @dev Can only be called once
    function enableWithdrawals() external onlyOwner {
        require(totalRaisedUSD != 0, "NOT_FINALIZED");
        require(!withdrawalsEnabled, "ALREADY_ENABLED");

        withdrawalsEnabled = true;

        emit WithdrawalsEnabled();
    }

    /// @notice Function used to transfer raised funds to the treasury. Can only be called after withdrawals have been enabled
    function transferToTreasury() external onlyOwner {
        require(withdrawalsEnabled, "WITHDRAWALS_NOT_ENABLED");

        for (uint256 i = 0; i < supportedTokens.length; i++) {
            IERC20 token = IERC20(supportedTokens[i]);
            uint256 balance = token.balanceOf(address(this));
            token.safeTransfer(treasury, balance);

            emit TreasuryTransfer(address(token), balance);
        }
    }

    /// @notice ETH deposit function. To deposit WETH/USDC please see `deposit`
    /// @dev `deposit` and `depositETH` have been split to simplify logic
    function depositETH() public payable nonReentrant {
        address _weth = WETH;
        _depositFor(msg.sender, _weth, msg.value);
        IWETH(_weth).deposit{value: msg.value}();
    }

    /// @notice Token deposit function (WETH/USDC, not ETH). Users can deposit more than once, but only using the same token
    /// @param _token The token to deposit
    /// @param _amount The amount of `_token` to deposit
    function deposit(address _token, uint256 _amount) external nonReentrant {
        _depositFor(msg.sender, _token, _amount);
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
    }

    /// @notice `saleToken` withdraw function. Users get an amount of tokens based on their share of deposited dollar value. Can only be called after withdrawals have been enabled
    /// @dev Can only be called after the owner has called `enableWithdrawals`
    function withdraw() external nonReentrant {
        require(withdrawalsEnabled, "WITHDRAWALS_NOT_ENABLED");

        uint256 toSend = getUserClaimableTokens(msg.sender);
        require(toSend > 0, "NO_TOKENS");

        delete userAccounts[msg.sender];

        IERC20(saleToken).safeTransfer(msg.sender, toSend);

        emit Withdrawn(msg.sender, toSend);
    }

    /// @notice View function to get all supported tokens
    /// @return Array containing all supported token addresses
    function getSupportedTokens() external view returns (address[] memory) {
        return supportedTokens;
    }

    /// @notice View function to get all the oracles used by this contract
    /// @return oracles Array containing all oracle addresses
    function getTokenOracles() external view returns (address[] memory oracles) {
        oracles = new address[](supportedTokens.length);
        for (uint256 i = 0; i < supportedTokens.length; i++) {
            oracles[i] = supportedTokensData[supportedTokens[i]].oracle;
        }
    }

    /// @notice View function to get the oracle relative to a supported token's address
    /// @return Oracle address if found, else `address(0)`
    function getTokenOracle(address _token) external view returns (address) {
        return supportedTokensData[_token].oracle;
    }

    /// @notice Calculates the amount of claimable tokens by a user by calculating their share of the total dollar value deposited
    /// @dev Returns a meaningful result only after the sale has been finalized, otherwise it returns 0
    /// @param _user The user address
    /// @return The amount of tokens claimable by `_user`
    function getUserClaimableTokens(address _user) public view returns (uint256) {
        Account memory account = userAccounts[_user];
        
        if (account.depositedAmount == 0)
            return 0;

        uint256 totalRaise = totalRaisedUSD;
        //if sale hasn't been finalized yet
        if (totalRaise == 0)
            return 0;
        
        //calculates the dollar value of the amount of tokens deposited by msg.sender, multiplied by `account.token`'s decimals for additional precision
        uint256 depositedValueWithPrecision = supportedTokensData[account.token]
            .USDPrice * account.depositedAmount;
        //calculates the amount of `saleToken` claimable by calculating the user's share of deposited dollar value and multiplying it by
        //the total available tokens:
        //user share = user deposited value / total deposited value
        //user tokens = user share * total tokens
        return (depositedValueWithPrecision * availableTokens) /
            totalRaise /
            //remove `account.token`'s decimals
            10**ERC20(account.token).decimals();
    }

    /// @dev Deposit logic. Called by `deposit` and `depositETH`
    /// @param _account Depositor account
    /// @param _token The token being deposited
    /// @param _amount Amount of `_token` being deposited
    function _depositFor(
        address _account,
        address _token,
        uint256 _amount
    ) internal {
        require(
            block.timestamp >= saleSchedule.startTimestamp &&
                block.timestamp < saleSchedule.endTimestamp,
            "DEPOSITS_NOT_ACCEPTED"
        );
        require(_amount > 0, "INVALID_AMOUNT");
        require(
            supportedTokensData[_token].oracle != address(0),
            "TOKEN_NOT_SUPPORTED"
        );

        Account storage account = userAccounts[_account];
        if (account.token == address(0)) {
            account.token = _token;
        } else {
            //only allow users to deposit one of the two deposit assets (WETH and USDC)
            require(account.token == _token, "SINGLE_ASSET_DEPOSITS");
        }

        //a single `_account` can deposit more than once
        account.depositedAmount += _amount;
        supportedTokensData[_token].totalRaised += _amount;

        emit Deposited(_account, _token, _amount);
    }
}