// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Exchange
///
/// @dev This contract is to exchange ETH or others erc20 token for VegasONE.
contract Exchange is AccessControlEnumerable, ReentrancyGuard {

    using SafeERC20 for IERC20;
    
    /**
     * Global Variables, Struct
     */

    /// @dev The identifier of the role which maintains other settings.
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    struct ERC20TOKEN {
        uint256 tokenID;
        string tokenSymbol;
        IERC20 tokenAddress;
        uint256 tokenExchangeRate;
        uint256 tokenDecimals;
        bool tokenStatus;
    }

    /// @dev A mapping of all of the ERC20 token details.
    mapping(uint256 => ERC20TOKEN) public erc20Token;

    /// @dev The exchange rate of VegasONE for ETH.
    uint256 public ethRate;

    /// @dev The minimum value of each exchange amount.
    uint256 public exchangeMinValue;

    /// @dev The number of erc20 tokens in this contract.
    uint256 public tokenCount;

    /// @dev A flag indicating whether VegasONE is exchangeable within the contract.
    bool internal enableExchange;

    /**
     * Events
     */

    event addERC20TokenEvent(
        address indexed account,
        uint256 indexed tokenID,
        string tokenSymbol,
        address indexed tokenAddress,
        uint256 tokenExchangeRate,
        uint256 tokenDecimals,
        bool tokenStatus
    );
    event EthExchangeEvnet(address indexed from, uint256 ethAmount, uint256 vegasONEAmount);
    event ERC20TokenExchangeEvnet(
        IERC20 indexed tokenAddress,
        address indexed from,
        uint256 tokenAmount,
        uint256 vegasONEAmount
    );
    event SetEthRateEvent(uint256 rate);
    event SetERC20ExchangeRateEvent(address indexed tokenAddress, uint256 rate);
    event SetContractExchangeStatusEvent(bool);
    event setERC20ExchangeStatusEvent(address indexed tokenAddress, bool);
    event setExchangeMinValueEvent(uint256 amount);
    event EthDrawEvent(address indexed to, uint256 amount);
    event ERC20DrawEvent(address indexed tokenAddress, address indexed to, uint256 amount);

    /**
     * Constructor
     */

    constructor(
        ERC20 VegasONEAddress,
        ERC20 USDTAddress,
        ERC20 USDCAddress,
        ERC20 BUSDAddress,
        ERC20 BNBAddress,
        ERC20 wBTCAddress
    ){
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);

        //VegasONE
        erc20Token[0] = ERC20TOKEN(
            0,
            VegasONEAddress.symbol(),
            VegasONEAddress,
            1 * (10 ** VegasONEAddress.decimals()),
            10 ** VegasONEAddress.decimals(),
            false
        );
        //USDT 0xdAC17F958D2ee523a2206206994597C13D831ec7
        erc20Token[1] = ERC20TOKEN(
            1,
            USDTAddress.symbol(),
            USDTAddress,
            14 * (10 ** USDTAddress.decimals()),
            10 ** USDTAddress.decimals(),
            true
        );
        //USDC 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
        erc20Token[2] = ERC20TOKEN(
            2,
            USDCAddress.symbol(),
            USDCAddress,
            14 * (10 ** USDCAddress.decimals()),
            10 ** USDCAddress.decimals(),
            true
        );
        //BUSD 0x4Fabb145d64652a948d72533023f6E7A623C7C53
        erc20Token[3] = ERC20TOKEN(
            3,
            BUSDAddress.symbol(),
            BUSDAddress,
            14 * (10 ** BUSDAddress.decimals()),
            10 ** BUSDAddress.decimals(),
            true
        );
        //BNB 0xB8c77482e45F1F44dE1745F52C74426C631bDD52
        erc20Token[4] = ERC20TOKEN(
            4,
            BNBAddress.symbol(),
            BNBAddress,
            3920 * (10 ** BNBAddress.decimals()),
            10 ** BNBAddress.decimals(),
            true
        );
        //wBTC 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599
        erc20Token[5] = ERC20TOKEN(
            5,
            wBTCAddress.symbol(),
            wBTCAddress,
            285714 * (10 ** wBTCAddress.decimals()),
            10 ** wBTCAddress.decimals(),
            true
        );

        exchangeMinValue = 1e18;
        ethRate = 22857;
        tokenCount = 6;
    }

    /**
     * Modifier
     */

    /// @dev A modifier which asserts the caller has the admin role.
    modifier checkAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Exchange: Only Admin can use.");
        _;
	}

    /// @dev A modifier which asserts the contract is enabled for exchanges.
    modifier checkIsEnableChange() {
        require(enableExchange, "Exchange: Cannot exchange now.");
        _;
    }

    /// @dev A modifier which asserts that the tokenID exists.
    modifier checkTokenIDExist(uint256 tokenID) {
        require(address(erc20Token[tokenID].tokenAddress) != address(0), "Exchange: This token does not exist.");
        _;
    }

    /// @dev A modifier which asserts that address is not a zero address.
    modifier checkAdress(address account) {
        require(account != address(0), "Exchange: Address can not be a zero address.");
        _;
    }

    /**
     * External/Public Functions
     */

    /// @dev Add a erc20 token to exchange for VegasONE.
    ///
    /// This function reverts if the caller does not have the admin role.
    ///
    /// @param tokenAddress         the address of the token.
    /// @param tokenExchangeRate    the exchange rate of the tokens,
    ///                             the entry value should be multiplied by the decimal of the selected token.
    /// @param tokenStatus          ture if the token is exchangeable, false otherwise.
    function addERC20Token(
        ERC20 tokenAddress,
        uint256 tokenExchangeRate,
        bool tokenStatus
    ) external checkAdmin {
        erc20Token[tokenCount] = ERC20TOKEN(
            tokenCount,
            tokenAddress.symbol(),
            tokenAddress,
            tokenExchangeRate,
            10 ** tokenAddress.decimals(),
            tokenStatus
        );
        emit addERC20TokenEvent(
            msg.sender,
            tokenCount,
            tokenAddress.symbol(),
            address(tokenAddress),
            tokenExchangeRate,
            10 ** tokenAddress.decimals(),
            tokenStatus
        );
        tokenCount++;
    }

    /// @dev Convert the ETH to VEGASONE according to the exchanging rate.
    ///
    /// This function reverts if `isEnableExchange()` is false or if amount does not reach the minimum amount.
    ///
    /// @param walletAddress    the address to exchange tokens to.
    function ethToVegasONE(address walletAddress) external checkIsEnableChange nonReentrant payable {
        uint256 amount = msg.value * ethRate;
        require(amount >= exchangeMinValue, "Exchange: Minimum amount not reached.");
        erc20Token[0].tokenAddress.safeTransfer(walletAddress, amount);
        emit EthExchangeEvnet(walletAddress, msg.value, amount);
    }

    /// @dev Convert the selected token to VEGASONE according to each exchange rate.
    ///
    /// This function reverts if `isEnableExchange()` is false, if eithor the selected tokenId does not exists,
    ///  selected token status is false, or the amount does not reach the minimum amount.
    ///
    /// @param walletAddress    the address to exchange tokens to.
    /// @param tokenID          the number of the selected token id.
    /// @param amount           the amount of tokens to exchange,
    ///                         the entry value should be multiplied by selected token decimals.
    function erc20ToVegasONE(
        address walletAddress,
        uint256 tokenID,
        uint256 amount
    ) external checkIsEnableChange nonReentrant checkTokenIDExist(tokenID) {
        ERC20TOKEN memory token = erc20Token[tokenID];
        require(token.tokenStatus, "Exchange: This token can't exchange now.");
        uint256 vegasONEAmount = amount * erc20Token[0].tokenDecimals 
            * token.tokenExchangeRate / token.tokenDecimals / token.tokenDecimals;
        require(vegasONEAmount >= exchangeMinValue, "Exchange: Minimum amount not reached.");
        // transfer erc20 token to contract.
        erc20Token[tokenID].tokenAddress.safeTransferFrom(walletAddress, address(this), amount);
        // transfer VegasONE to walletAddress.
        erc20Token[0].tokenAddress.safeTransfer(walletAddress, vegasONEAmount);
        emit ERC20TokenExchangeEvnet(
            token.tokenAddress,
            walletAddress,
            amount,
            vegasONEAmount
        );
    }

    /// @dev Withdraw the Eth within the contract to the assigned address.
    ///
    /// This function reverts if the caller does not have the admin role or if the assigned address is a zero address.
    /// 
    /// @param to       the address to withdraw tokens to.
    /// @param amount   the amount of tokens to withdraw, the entry value should be multiplied by selected token decimals.
    function ethWithdraw(address to, uint256 amount) external checkAdmin checkAdress(to) nonReentrant {
        payable(to).transfer(amount);
        emit EthDrawEvent(to , amount);
    }

    /// @dev Withdraw the selected tokens within the contract to the assigned address.
    ///
    /// This function reverts if the caller does not have the admin role or the assigned address is a zero address.
    ///
    /// @param tokenID  the number of the selected token id.
    /// @param to       the address to withdraw tokens to.
    /// @param amount   the amount of tokens to withdraw, the entry value should be multiplied by selected token decimals.
    function erc20Withdraw(
        uint256 tokenID,
        address to,
        uint256 amount
    ) external checkAdmin checkAdress(to) checkTokenIDExist(tokenID) nonReentrant {
        erc20Token[tokenID].tokenAddress.safeTransfer(to, amount);
        emit ERC20DrawEvent(address(erc20Token[tokenID].tokenAddress), to, amount);
    }

    /// @dev Set the exchange rate for ETH.
    ///
    /// This function reverts if the caller does not have the admin role.
    ///
    /// @param rate the exchange rate of ETH.
    function setETHExchangeRate(uint256 rate) external checkAdmin {
        ethRate = rate;
        emit SetEthRateEvent(ethRate);
    }

    /// @dev Set the exchange rate of VegasONE for the selected token.
    ///
    /// This function reverts if the caller does not have the admin role or the selected tokenId does not exists.
    ///
    /// @param tokenID  the number of the selected token id.
    /// @param rate     the exchange rate of token, the entry value should be multiplied by selected token decimals.
    function setERC20TokenExchangeRate(uint256 tokenID, uint256 rate) 
        external 
        checkAdmin 
        checkTokenIDExist(tokenID) 
    {
        erc20Token[tokenID].tokenExchangeRate = rate;
        emit SetERC20ExchangeRateEvent(address(erc20Token[tokenID].tokenAddress), rate);
    }

    /// @dev Set the exchangeable VegasONE status for ETH.
    ///
    /// This function reverts if the caller does not have the admin role.
    function setContractExchangeStatus() external checkAdmin {
        enableExchange = !enableExchange;
        emit SetContractExchangeStatusEvent(enableExchange);
    }

    /// @dev Set the exchangeable VegasONE status for the selected token.
    ///
    /// This function reverts if the caller does not have the admin role or the selected token does not exist.
    ///
    /// @param tokenID the number of the selected token id.
    function setTokenExchangeStatus(uint256 tokenID) external checkAdmin checkTokenIDExist(tokenID) {
        erc20Token[tokenID].tokenStatus = !erc20Token[tokenID].tokenStatus;
        emit setERC20ExchangeStatusEvent(
            address(erc20Token[tokenID].tokenAddress),
            erc20Token[tokenID].tokenStatus
        );
    }

    /// @dev Set the minimum exchange amount.
    ///
    /// This function reverts if the caller does not have the admin role.
    ///
    /// @param amount the amount of minimum exchange.
    function setExchangeMinValue(uint256 amount) external checkAdmin {
        exchangeMinValue = amount;
        emit setExchangeMinValueEvent(exchangeMinValue);
    }

    /**
     * View Functions
     */

    /// @dev Get the exchangeable VegasONE status of the contract.
    ///
    /// True if the state is exchangeable, false othewise.
    ///
    /// @return enableExchange the exchangeable VegasONE state.
    function isEnableExchange() external view returns (bool) {
        return enableExchange;
    }
}