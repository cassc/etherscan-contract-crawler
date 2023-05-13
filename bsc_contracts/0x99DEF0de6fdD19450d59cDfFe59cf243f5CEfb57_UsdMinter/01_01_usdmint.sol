// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ISwapRouter {
    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

library TransferHelper {
    function safeTransfer(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }
}

interface IUSD {
    function owner() external view returns (address);

    function burn(address account, uint256 amount) external;

    function mint(address to, uint256 amount) external;

    function depositAddress() external view returns (address);
}

interface IDepositUSD {
    function withdrawToken(
        address token_,
        address to_,
        uint256 amount_
    ) external;
}

contract UsdMinter {
    address public immutable usdTokenAddress;
    address public immutable depositAddress;
    address public immutable tokenAddress;

    address public constant routerAddress =
        0x45936F6739F5ECC46E9bc63ab3dd553067fa0Af4;
    address public constant usdtAddress =
        0x55d398326f99059fF775485246999027B3197955;

    uint256 public usdtMintWeight = 99;
    uint256 public usdtBurnWeight = 99;

    uint256 public mintFee = 500;
    uint256 public burnFee = 500;

    uint256 public totalUsdtFee;
    uint256 public totalTokenFee;

    uint256 public hourMintLimit = 1000 * 1e18;
    uint256 public hourBurnLimit = 1000 * 1e18;
    uint256 public dayMintLimit = 10000 * 1e18;
    uint256 public dayBurnLimit = 10000 * 1e18;

    bool public isCheckMintWihte = false;
    bool public isCheckBurnWihte = false;
    mapping(address => bool) public whiteList;

    uint256 public hourLimitTime;
    uint256 public dayLimitTime;
    uint256 public hourMintLimitAmount;
    uint256 public dayMintLimitAmount;
    uint256 public hourBurnLimitAmount;
    uint256 public dayBurnLimitAmount;

    constructor(address token_, address usd_) {
        usdTokenAddress = usd_;
        tokenAddress = token_;
        depositAddress = IUSD(usd_).depositAddress();
    }

    modifier onlyOwner() {
        require(
            msg.sender == IUSD(usdTokenAddress).owner(),
            "caller is not the owner"
        );
        _;
    }

    function setCheckWhite(bool _isMint, bool _isBurn) external onlyOwner {
        isCheckMintWihte = _isMint;
        isCheckBurnWihte = _isBurn;
    }

    function setWhiteList(address addr, bool status) external onlyOwner {
        whiteList[addr] = status;
    }

    function setUsdtWeight(
        uint256 mintWeight_,
        uint256 burnWeight_
    ) external onlyOwner {
        usdtMintWeight = mintWeight_;
        usdtBurnWeight = burnWeight_;
    }

    function setFee(uint256 mintFee_, uint256 burnFee_) external onlyOwner {
        mintFee = mintFee_;
        burnFee = burnFee_;
    }

    function setLimit(
        uint256 hourMintLimit_,
        uint256 hourBurnLimit_,
        uint256 dayMintLimit_,
        uint256 dayBurnLimit_
    ) external onlyOwner returns (bool) {
        hourMintLimit = hourMintLimit_;
        hourBurnLimit = hourBurnLimit_;
        dayMintLimit = dayMintLimit_;
        dayBurnLimit = dayBurnLimit_;
        return true;
    }

    function withdrawFee() external onlyOwner {
        IDepositUSD(depositAddress).withdrawToken(
            usdtAddress,
            msg.sender,
            totalUsdtFee
        );
        totalUsdtFee = 0;

        IDepositUSD(depositAddress).withdrawToken(
            tokenAddress,
            msg.sender,
            totalTokenFee
        );
        totalTokenFee = 0;
    }

    function mintUsd(uint256 usdtAmount) external {
        if (isCheckMintWihte) {
            require(whiteList[msg.sender], "not allow");
        } else {
            require(
                (!isContract(msg.sender)) && (msg.sender == tx.origin),
                "contract not allowed"
            );
        }

        uint256 tokenAmount;
        uint256 usdAmount = (usdtAmount * 100) / usdtMintWeight;
        require(usdAmount > 0, "usd amount error");

        _updateEpochLimit(true, usdAmount);

        TransferHelper.safeTransferFrom(
            usdtAddress,
            msg.sender,
            depositAddress,
            usdtAmount
        );
        totalUsdtFee += (usdtAmount * mintFee) / 10000;

        if (usdtMintWeight < 100) {
            uint256 diffUsdt = usdAmount - usdtAmount;
            tokenAmount = getSwapToken(diffUsdt, tokenAddress);
            TransferHelper.safeTransferFrom(
                tokenAddress,
                msg.sender,
                depositAddress,
                tokenAmount
            );
            totalTokenFee += (tokenAmount * mintFee) / 10000;
        }

        IUSD(usdTokenAddress).mint(
            msg.sender,
            usdAmount - (usdAmount * mintFee) / 10000
        );
    }

    function burnUsd(uint256 usdAmount) external {
        require(usdAmount > 0, "usd amount error");

        if (isCheckBurnWihte) {
            require(whiteList[msg.sender], "not allow");
        } else {
            require(
                (!isContract(msg.sender)) && (msg.sender == tx.origin),
                "contract not allowed"
            );
        }

        uint256 tokenAmount;
        uint256 usdtAmount = (usdAmount * usdtBurnWeight) / 100;
        uint256 usdtFee = (usdtAmount * burnFee) / 10000;

        _updateEpochLimit(false, usdAmount);
        IUSD(usdTokenAddress).burn(msg.sender, usdAmount);

        IDepositUSD(depositAddress).withdrawToken(
            usdtAddress,
            msg.sender,
            usdtAmount - usdtFee
        );
        totalUsdtFee += usdtFee;

        if (usdtBurnWeight < 100) {
            uint256 diffUsdt = usdAmount - usdtAmount;
            tokenAmount = getSwapToken(diffUsdt, tokenAddress);
            uint256 tokenFee = (tokenAmount * burnFee) / 10000;

            IDepositUSD(depositAddress).withdrawToken(
                tokenAddress,
                msg.sender,
                tokenAmount - tokenFee
            );
            totalTokenFee += tokenFee;
        }
    }

    function _updateEpochLimit(bool isMint, uint256 usdAmount) private {
        uint256 _epoch_hour = block.timestamp / 3600;
        if (_epoch_hour > hourLimitTime) {
            hourLimitTime = _epoch_hour;
            hourMintLimitAmount = 0;
            hourBurnLimitAmount = 0;
        }

        uint256 _epoch_day = block.timestamp / 86400;
        if (_epoch_day > dayLimitTime) {
            dayLimitTime = _epoch_day;
            dayMintLimitAmount = 0;
            dayBurnLimitAmount = 0;
        }

        if (isMint) {
            (uint256 hourLimit, uint256 dayLimit) = getMintLimit();

            hourMintLimitAmount += usdAmount;
            require(usdAmount <= hourLimit, "hour mint limit error");

            dayMintLimitAmount += usdAmount;
            require(usdAmount <= dayLimit, "day mint limit error");
        } else {
            (uint256 hourLimit, uint256 dayLimit) = getBurnLimit();

            hourBurnLimitAmount += usdAmount;
            require(usdAmount <= hourLimit, "hour burn limit error");

            dayBurnLimitAmount += usdAmount;
            require(usdAmount <= dayLimit, "day burn limit error");
        }
    }

    function getMintLimit()
        public
        view
        returns (uint256 hourLimit, uint256 dayLimit)
    {
        uint256 _hourAmount = hourMintLimitAmount;
        uint256 _epoch_hour = block.timestamp / 3600;
        if (_epoch_hour > hourLimitTime) {
            _hourAmount = 0;
        }

        uint256 _dayAmount = dayMintLimitAmount;
        uint256 _epoch_day = block.timestamp / 86400;
        if (_epoch_day > dayLimitTime) {
            _dayAmount = 0;
        }

        hourLimit = hourMintLimit - _hourAmount;
        dayLimit = dayMintLimit - _dayAmount;
        return (hourLimit, dayLimit);
    }

    function getBurnLimit()
        public
        view
        returns (uint256 hourLimit, uint256 dayLimit)
    {
        uint256 _hourAmount = hourBurnLimitAmount;
        uint256 _epoch_hour = block.timestamp / 3600;
        if (_epoch_hour > hourLimitTime) {
            _hourAmount = 0;
        }

        uint256 _dayAmount = dayBurnLimitAmount;
        uint256 _epoch_day = block.timestamp / 86400;
        if (_epoch_day > dayLimitTime) {
            _dayAmount = 0;
        }
        hourLimit = hourBurnLimit - _hourAmount;
        dayLimit = dayBurnLimit - _dayAmount;

        return (hourLimit, dayLimit);
    }

    function getSwapToken(
        uint256 amount,
        address token
    ) public view returns (uint256) {
        return _getSwapPrice(amount, usdtAddress, token);
    }

    function _getSwapPrice(
        uint256 amount,
        address tokenIn,
        address tokenTo
    ) private view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenTo;

        uint256[] memory amounts = ISwapRouter(routerAddress).getAmountsOut(
            amount,
            path
        );
        return amounts[amounts.length - 1];
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        if (addr == address(0)) return false;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}