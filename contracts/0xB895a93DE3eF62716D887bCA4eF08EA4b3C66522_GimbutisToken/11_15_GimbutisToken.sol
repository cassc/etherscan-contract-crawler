// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapRouterV2.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IAggregatorV3.sol";

contract GimbutisToken is OwnableUpgradeable, ERC20BurnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    address public adminAddress;
    address public aswmAddress;
    address public routerAddress;
    address public factoryAddress;
    address public usdcAddress;
    address public oracleAddress;

    uint256 public transferFee;
    uint256 public deliveryFee;
    uint256 public rollOverFee;
    uint256 public rollOverEpochDuration;
    // how many tokens = 1 silver
    uint256 public silverRatio;
    uint256 public minReserveAmount;
    uint256 public minBuyAmount;

    string public streemURL;

    bool public toggleStatus;

    mapping(address => uint256) public reserves;

    /* ========== EVENTS ========== */

    event Initialized(address indexed executor, uint256 at);
    event SetAdminAddress(address indexed _address);
    event SetAswmAddress(address indexed _address);
    event SetrouterAddress(address indexed _address);
    event SetfactoryAddress(address indexed _address);
    event SetUsdcAddress(address indexed _address);
    event SetOracleAddress(address indexed _address);
    event SetTransferFee(uint256 indexed _fee);
    event SetDeliveryFee(uint256 indexed _fee);
    event SetRollOverFee(uint256 indexed _fee);
    event SetRollOverEpochDuration(uint256 indexed _duration);
    event SetSilverRatio(uint256 indexed _silverRatio);
    event SetMinReserveAmount(uint256 indexed _minReserveAmount);
    event SetMinBuyAmount(uint256 indexed _minBuyAmount);
    event SetStreemURL(string indexed _url);
    event SetToggleStatus(bool indexed _status);

    function initialize(
        address _aswmAddress,
        address _routerAddress,
        address _factoryAddress,
        address _usdcAddress,
        address _oracleAddress,
        uint256 _transferFee,
        uint256 _deliveryFee,
        uint256 _rollOverFee,
        uint256 _rollOverEpochDuration,
        uint256 _silverRatio,
        uint256 _minReserveAmount,
        uint256 _minBuyAmount,
        string calldata _streemURL,
        bool _toggleStatus
    ) external initializer {
        adminAddress = msg.sender;
        routerAddress = _routerAddress;
        factoryAddress = _factoryAddress;
        usdcAddress = _usdcAddress;
        aswmAddress = _aswmAddress;
        oracleAddress = _oracleAddress;

        transferFee = _transferFee;
        deliveryFee = _deliveryFee;
        rollOverFee = _rollOverFee;
        rollOverEpochDuration = _rollOverEpochDuration;
        silverRatio = _silverRatio;
        minReserveAmount = _minReserveAmount;
        minBuyAmount = _minBuyAmount;

        streemURL = _streemURL;

        toggleStatus = _toggleStatus;

        __Ownable_init();
        __ERC20_init("GimbutisToken", "GXAG");
        emit Initialized(msg.sender, block.number);
    }

    modifier onlyActive() {
        require(toggleStatus, "GimbutisToken: contract is not available right now ");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == adminAddress || msg.sender == owner(), "GimbutisToken: only admin");
        _;
    }

    modifier onlyASWM() {
        require(msg.sender == aswmAddress, "GimbutisToken: only aswm");
        _;
    }

    function setAdminAddress(address _address) external onlyAdmin {
        adminAddress = _address;

        emit SetAdminAddress(_address);
    }

    function setAswmAddress(address _address) external onlyAdmin {
        aswmAddress = _address;

        emit SetAswmAddress(_address);
    }

    function setRouterAddress(address _address) external onlyAdmin {
        routerAddress = _address;

        emit SetrouterAddress(_address);
    }

    function setFactoryAddress(address _address) external onlyAdmin {
        factoryAddress = _address;

        emit SetfactoryAddress(_address);
    }

    function setUsdcAddress(address _address) external onlyAdmin {
        usdcAddress = _address;

        emit SetUsdcAddress(_address);
    }

    function setOracleAddress(address _address) external onlyAdmin {
        oracleAddress = _address;

        emit SetOracleAddress(_address);
    }

    function setTransferFee(uint256 _fee) external onlyAdmin {
        transferFee = _fee;

        emit SetTransferFee(_fee);
    }

    function setDeliveryFee(uint256 _fee) external onlyAdmin {
        deliveryFee = _fee;

        emit SetDeliveryFee(_fee);
    }

    function setRollOverFee(uint256 _fee) external onlyAdmin {
        rollOverFee = _fee;

        emit SetRollOverFee(_fee);
    }

    function setRollOverEpochDuration(uint256 _duration) external onlyAdmin {
        rollOverEpochDuration = _duration;

        emit SetRollOverEpochDuration(_duration);
    }

    function setStreemURL(string calldata _streemURL) external onlyAdmin {
        streemURL = _streemURL;

        emit SetStreemURL(_streemURL);
    }

    function setToggleStatus(bool _status) external onlyAdmin {
        toggleStatus = _status;

        emit SetToggleStatus(_status);
    }

    function setSilverRatio(uint256 _silverRatio) external onlyAdmin {
        silverRatio = _silverRatio;

        emit SetSilverRatio(_silverRatio);
    }

    function setMinReserveAmount(uint256 _minReserveAmount) external onlyAdmin {
        minReserveAmount = _minReserveAmount;

        emit SetMinReserveAmount(_minReserveAmount);
    }

    function setMinBuyAmount(uint256 _minBuyAmount) external onlyAdmin {
        minBuyAmount = _minBuyAmount;

        emit SetMinBuyAmount(_minBuyAmount);
    }

    /**
     * @notice Functon to add commodities
     * @param _amount amount of commodities
     */
    function addCommodities(uint256 _amount) external onlyAdmin {
        _mint(address(this), silverRatio * _amount * 1e18);
    }

    /**
     * @notice Functon to buy tokens
     * @param _token ERC-20 token address
     * @param _amount amount of tokens
     */
    function buy(address _token, uint256 _amount) external onlyActive {
        uint256 _userBalance = IERC20Upgradeable(_token).balanceOf(msg.sender) *
            (10 ** (18 - IERC20MetadataUpgradeable(_token).decimals()));
        require(_userBalance >= _amount, "GimbutisToken: Invalid balance");

        if (_token == usdcAddress) {
            _buyTokenWithUsdc(msg.sender, _amount);
        } else {
            address _pairAddress = IUniswapV2Factory(factoryAddress).getPair(_token, usdcAddress);
            require(_pairAddress != address(0), "GimbutisToken: Pair with this token not exist");

            _buyToken(msg.sender, _token, _amount, _pairAddress);
        }
    }

    /**
     * @notice Functon to add reserve
     * @param _holder holder address
     * @param _amount amount of reserve
     */
    function addReserve(address _holder, uint256 _amount) external onlyASWM {
        require(reserves[_holder] == 0, "GimbutisToken: already have reserve with this address");
        require(
            super.balanceOf(_holder) >= _amount && minReserveAmount < _amount,
            "GimbutisToken: Invalid amount"
        );

        reserves[_holder] = _amount;
        _transfer(_holder, address(this), _amount);
    }

    /**
     * @notice Functon to release reserve
     * @param _holder holder address
     */
    function releaseReserve(address _holder) external onlyASWM {
        require(reserves[_holder] != 0, "GimbutisToken: invalid reserves");

        _burn(address(this), reserves[_holder]);
        delete reserves[_holder];
    }

    /**
     * @notice Functon to cancel reserve
     * @param _holder holder address
     */
    function cancelReserve(address _holder) external onlyASWM {
        require(reserves[_holder] != 0, "GimbutisToken: invalid reserves");

        uint256 amount = reserves[_holder];
        uint256 fee = (amount * deliveryFee) / 100;
        _transfer(address(this), _holder, amount - fee);
        delete reserves[_holder];
    }

    function mint(address account, uint256 amount) external onlyAdmin {
        _mint(account, amount);
    }

    /**
     * @notice Functon to get erc20 token price in usdc
     * @param _token token address
     */
    function getErc20UsdcPrice(address _token) external view returns (uint256) {
        address _pairAddress = IUniswapV2Factory(factoryAddress).getPair(_token, usdcAddress);
        require(_pairAddress != address(0), "GimbutisToken: Pair with this token not exist");

        uint256 price = _getERC20Price(_pairAddress, _token, 1e18);
        return price;
    }

    /**
     * @notice Functon to transfer tokens
     * @param to receiver address
     * @param amount amount
     */
    function transfer(address to, uint256 amount) public override onlyActive returns (bool) {
        address owner = _msgSender();
        uint256 fee = (amount * transferFee) / 100;
        _transfer(owner, address(this), fee);
        _transfer(owner, to, amount - fee);
        return true;
    }

    /**
     * @notice Functon to transfer tokens
     * @param from sender address
     * @param to receiver address
     * @param amount amount
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override onlyActive returns (bool) {
        address spender = _msgSender();
        uint256 fee = (amount * transferFee) / 100;
        _spendAllowance(from, spender, amount);
        _transfer(from, address(this), fee);
        _transfer(from, to, amount - fee);
        return true;
    }

    /**
     * Returns the latest price GimbutisToken
     */
    function getTokenPrice() public view returns (uint256) {
        (, int256 _price, , , ) = IAggregatorV3(oracleAddress).latestRoundData();
        uint256 _decimals = IAggregatorV3(oracleAddress).decimals();
        return (uint256(_price) * 1e18) / 10 ** _decimals;
    }

    /**
     * @notice Functon to buy gxag tokens with usdc
     * @param _sender sender address
     * @param _amount amount
     */
    function _buyTokenWithUsdc(address _sender, uint256 _amount) private {
        uint256 _gxagAmount = (_amount * 1e18) / getTokenPrice();

        require(_gxagAmount >= minBuyAmount, "GimbutisToken: Invalid amount for buy");
        require(
            super.balanceOf(address(this)) >= _gxagAmount,
            "GimbutisToken: Not enough GimbutisToken tokens"
        );

        IERC20Upgradeable(usdcAddress).safeTransferFrom(_sender, address(this), (_amount / 1e12));
        _transfer(address(this), _sender, _gxagAmount);
    }

    /**
     * @notice Functon to buy gxag tokens with erc20
     * @param _sender sender address
     * @param _token token address
     * @param _amount amount
     * @param _pairAddress pair address
     */
    function _buyToken(
        address _sender,
        address _token,
        uint256 _amount,
        address _pairAddress
    ) private {
        uint256 _gxagUsdPrice = getTokenPrice();
        uint256 erc20UsdPrice = _getERC20Price(_pairAddress, _token, _amount);
        uint256 _gxagAmount = (erc20UsdPrice * 1e18) / _gxagUsdPrice;

        require(_gxagAmount >= minBuyAmount, "GimbutisToken: Invalid amount for buy");
        require(
            super.balanceOf(address(this)) >= _gxagAmount,
            "GimbutisToken: Not enough GimbutisToken tokens"
        );

        IERC20Upgradeable(_token).safeTransferFrom(_sender, address(this), _amount);

        IERC20Upgradeable(_token).safeApprove(routerAddress, _amount);

        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = usdcAddress;

        IUniswapRouterV2(routerAddress).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp + 100
        );

        _transfer(address(this), _sender, _gxagAmount);
    }

    /**
     * Returns the latest price ERC20Token
     */

    /**
     * @notice Returns the latest price ERC20Token
     * @param _pairAddress pair address
     * @param _token token address
     * @param _amount amount
     */
    function _getERC20Price(
        address _pairAddress,
        address _token,
        uint _amount
    ) private view returns (uint256) {
        (uint reserve0, uint reserve1, ) = IUniswapV2Pair(_pairAddress).getReserves();
        uint256 usdcDecimals = 1e18 / 10 ** IERC20MetadataUpgradeable(usdcAddress).decimals();
        uint256 erc20Decimals = 1e18 / 10 ** IERC20MetadataUpgradeable(_token).decimals();
        if (IUniswapV2Pair(_pairAddress).token0() == usdcAddress) {
            return (_amount * reserve0 * usdcDecimals) / (reserve1 * erc20Decimals);
        } else {
            return (_amount * reserve1 * usdcDecimals) / (reserve0 * erc20Decimals);
        }
    }
}