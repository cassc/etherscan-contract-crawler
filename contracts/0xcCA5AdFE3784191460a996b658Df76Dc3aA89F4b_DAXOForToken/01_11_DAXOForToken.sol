// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.6;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IDAXOForToken.sol";

contract DAXOForToken is
    IDAXOForToken,
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable[2] private _token;
    IERC20Upgradeable private _DAXOToken;
    uint256 private _price;
    uint256 private _userSellableLimitPerPeriod;
    uint256 private _globalSellableLimitPerPeriod;
    uint256 private _periodLength;
    address private WETH;
    address private uniswapRouterV2;
    mapping(address => uint256) private _userToTokenAmountThisPeriod;
    mapping(address => uint256) private _userToLastPeriod;

    uint256 private _totalTokenAmountThisPeriod;
    uint256 private _lastPeriod;

    function initialize() public initializer {
        WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        uniswapRouterV2 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        __Ownable_init();
    }

    function buy(uint8 _tokenType, uint256 _tokenAmount)
        external
        override
        nonReentrant
        returns (uint256)
    {
        require(_tokenType == 0 || _tokenType == 1, "Invalid token type specified");
        uint256 _DALTokenAmount =
            (_tokenAmount * 1e18) / _price;

        _token[_tokenType].safeTransferFrom(tx.origin, address(this), _tokenAmount);

        _updateBuyableAmount(tx.origin, _DALTokenAmount);
        _checkBuyableLimit(tx.origin, _DALTokenAmount);

        _DAXOToken.safeTransfer(tx.origin, _DALTokenAmount);

        emit DAXOSold(tx.origin, _DALTokenAmount, address(_token[_tokenType]), _tokenAmount);
        return _DALTokenAmount;
    }

    function buyWithETH()
        external
        override
        payable
        
        returns (uint256)
    {
        uint256 _DALTokenAmount =
            getEstimatedDAXOOut(msg.value);

        _updateBuyableAmount(tx.origin, _DALTokenAmount);
        _checkBuyableLimit(tx.origin, _DALTokenAmount);

        _DAXOToken.safeTransfer(tx.origin, _DALTokenAmount);

        emit DAXOSold(tx.origin, _DALTokenAmount, address(0), msg.value);
        return _DALTokenAmount;
    }

    function getEstimatedDAXOOut(uint256 _ethAmount) public override view returns (uint256) {
        address factory = IUniswapV2Router02(uniswapRouterV2).factory();

        address[] memory tokenList = new address[](2);
        tokenList[0] = WETH;
        tokenList[1] = address(_token[0]);
        uint256 tokenAmount = IUniswapV2Router02(uniswapRouterV2).getAmountsOut(_ethAmount, tokenList)[1];
        uint256 _DALTokenAmount =
            (tokenAmount * 1e18) / _price;
        return _DALTokenAmount;
    }

    function _updateBuyableAmount(address _user, uint256 _tokenAmount)
        internal
    {
        uint256 _currentPeriod = block.timestamp / _periodLength;
        if (_currentPeriod > _lastPeriod) {
            _totalTokenAmountThisPeriod = 0;
            _lastPeriod = _currentPeriod;
        }
        if (_currentPeriod > _userToLastPeriod[_user]) {
            _userToTokenAmountThisPeriod[_user] = 0;
            _userToLastPeriod[_user] = _currentPeriod;
        }
        _userToTokenAmountThisPeriod[_user] += _tokenAmount;
        _totalTokenAmountThisPeriod += _tokenAmount;
    }

    function _checkBuyableLimit(address _user, uint256 _tokenAmount)
        internal
        view
        returns (bool)
    {
        require(
            _totalTokenAmountThisPeriod <= _globalSellableLimitPerPeriod,
            "Global sellable limit exceeded"
        );
        require(
            _userToTokenAmountThisPeriod[_user] <= _userSellableLimitPerPeriod,
            "User sellable limit exceeded"
        );
    }

    function withdrawERC20(address _token, uint256 _amount)
        external
        override
        onlyOwner
        nonReentrant
    {
        IERC20Upgradeable(_token).safeTransfer(owner(), _amount);
    }

    function withdrawETH()
        external
        override
        onlyOwner
        nonReentrant
    {
        uint256 balance = address(this).balance;
        (bool _success, ) = owner().call{value: balance}("");
        require(_success, "Native token transfer failed");
    }

    function setToken(address[] calldata _newToken) external override onlyOwner {
        require(_newToken.length == 2, "Token list length must be 2");
        _token = [IERC20Upgradeable(_newToken[0]), IERC20Upgradeable(_newToken[1])];
    }

    function setDAXOToken(address _newDALToken) external override onlyOwner {
        _DAXOToken = IERC20Upgradeable(_newDALToken);
    }

    function setDAXOPrice(uint256 _newPrice)
        external
        override
        onlyOwner
    {
        _price = _newPrice;
    }

    function setUserBuyableLimitPerPeriod(
        uint256 _newUserSellableLimitPerPeriod
    ) external override onlyOwner {
        _userSellableLimitPerPeriod = _newUserSellableLimitPerPeriod;
    }

    function setGlobalBuyableLimitPerPeriod(
        uint256 _newGlobalSellableLimitPerPeriod
    ) external override onlyOwner {
        _globalSellableLimitPerPeriod = _newGlobalSellableLimitPerPeriod;
    }

    function setPeriodLength(uint256 _newPeriodLength)
        external
        override
        onlyOwner
    {
        _periodLength = _newPeriodLength;
    }

    function getToken(uint8 _tokenIndex) external view override returns (IERC20Upgradeable) {
        return _token[_tokenIndex];
    }

    function getDAXOToken() external view override returns (IERC20Upgradeable) {
        return _DAXOToken;
    }

    function getDAXOPrice()
        external
        view
        override
        returns (uint256)
    {
        return _price;
    }

    function getUserBuyableLimitPerPeriod()
        external
        view
        override
        returns (uint256)
    {
        return _userSellableLimitPerPeriod;
    }

    function getGlobalBuyableLimitPerPeriod()
        external
        view
        override
        returns (uint256)
    {
        return _globalSellableLimitPerPeriod;
    }

    function getPeriodLength() external view override returns (uint256) {
        return _periodLength;
    }

    function getUserToTokenAmountThisPeriod(address _user)
        external
        view
        override
        returns (uint256)
    {
        uint256 _currentPeriod = block.timestamp / _periodLength;
        if (_currentPeriod > _userToLastPeriod[_user]) {
            return 0;
        }
        return _userToTokenAmountThisPeriod[_user];
    }

    function getTotalTokenAmountThisPeriod()
        external
        view
        override
        returns (uint256)
    {
        uint256 _currentPeriod = block.timestamp / _periodLength;
        if (_currentPeriod > _lastPeriod) {
            return 0;
        }
        return _totalTokenAmountThisPeriod;
    }
}