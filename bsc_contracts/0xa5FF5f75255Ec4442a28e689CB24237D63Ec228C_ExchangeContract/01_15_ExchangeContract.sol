// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC721.sol";
import "IERC20.sol";
import "SafeERC20.sol";
import "SafeMath.sol";
import "AccessControl.sol";

contract ExchangeContract is AccessControl {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event coinExchanged(uint256 getTokenValue, uint256 sendTokenValue);

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant TRANSFEROUT_ROLE = keccak256("TRANSFEROUT_ROLE");

    struct ExchangeManagement {
        address getToken;
        address sendToken;
        uint256 slabCounter;
        address treasury;
        bool exchangeOpen;
        uint256 currentRate;
        uint256 slabTotalSendTokenAvailable;
        uint256 maxPerWalletGetTokenLimit;
        uint256 totalRaised;
        uint256 totalSold;
        // bool isTaxed;
    }

    ExchangeManagement[] public exchangeInfo;

    bool isInitialised = false;

    function initialize() public {
        require(!isInitialised, "Already Initialised");
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, msg.sender);
        _setupRole(TRANSFEROUT_ROLE, msg.sender);
        isInitialised = true;
    }

    function checkRole(address account, bytes32 role) public view {
        require(hasRole(role, account), "Role Does Not Exist");
    }

    function giveRole(address wallet, uint256 _roleId) public {
        require(_roleId >= 0 && _roleId <= 2, "Invalid roleId");
        checkRole(msg.sender, DEFAULT_ADMIN_ROLE);
        bytes32 _role;
        if (_roleId == 0) {
            _role = OPERATOR_ROLE;
        } else if (_roleId == 1) {
            _role = TRANSFEROUT_ROLE;
        }
        grantRole(_role, wallet);
    }

    function revokeRole(address wallet, uint256 _roleId) public {
        require(_roleId >= 0 && _roleId < 2, "Invalid roleId");
        checkRole(msg.sender, DEFAULT_ADMIN_ROLE);
        bytes32 _role;
        if (_roleId == 0) {
            _role = OPERATOR_ROLE;
        } else if (_roleId == 1) {
            _role = TRANSFEROUT_ROLE;
        }
        revokeRole(_role, wallet);
    }

     function transferRoleOwner(address wallet)
        external
    {
        checkRole(msg.sender, DEFAULT_ADMIN_ROLE);
        grantRole(DEFAULT_ADMIN_ROLE, wallet);
        revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function renounceOwnership() public {
        checkRole(msg.sender, DEFAULT_ADMIN_ROLE);
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function addExchangeCombination(
        address _getToken,
        address _sendToken,
        address _treasury,
        bool _exchangeOpen,
        uint256 _currentRate,
        uint256 _slabTotalSendTokenAvailable,
        uint256 _maxPerWalletGetTokenLimit
        // bool _isTaxed
    ) public {
        checkRole(msg.sender, OPERATOR_ROLE);
        exchangeInfo.push(
            ExchangeManagement({
                getToken: _getToken,
                sendToken: _sendToken,
                slabCounter: 0,
                treasury: _treasury,
                exchangeOpen: _exchangeOpen,
                currentRate: _currentRate,
                slabTotalSendTokenAvailable: _slabTotalSendTokenAvailable,
                maxPerWalletGetTokenLimit: _maxPerWalletGetTokenLimit,
                totalRaised: 0,
                totalSold: 0
            })
        );
    }
    function updateExchangeTokens(
        uint256 _exchangeId,
        address _getToken,
        address _sendToken
    ) external {
        checkRole(msg.sender, OPERATOR_ROLE);
        exchangeInfo[_exchangeId].getToken = _getToken;
        exchangeInfo[_exchangeId].sendToken = _sendToken;
    }

    function updateExchangeTreasuryAddress(
        uint256 _exchangeId,
        address _treasury
    ) external {
        checkRole(msg.sender, OPERATOR_ROLE);
        exchangeInfo[_exchangeId].treasury = _treasury;
    }

    function exchangeCoin(uint256 _exchangeId, uint256 _amountIn) external {
        ExchangeManagement storage _exchangeInfo = exchangeInfo[_exchangeId];

        require(
            IERC20(_exchangeInfo.getToken).balanceOf(msg.sender) >= _amountIn,
            "Not enough coin in your wallet!"
        );

        uint256 sendTokenToGive = (_amountIn.mul(_exchangeInfo.currentRate))
            .div(10**18);

        // Giving back based on Max Exchangable Send Token
        uint256 amountOut = min(
            (_exchangeInfo.slabTotalSendTokenAvailable -
                _exchangeInfo.slabCounter),
            sendTokenToGive
        );

        _amountIn = (amountOut.mul(10**18)).div(_exchangeInfo.currentRate);

        sendTokenToGive = (_amountIn.mul(_exchangeInfo.currentRate)).div(10**18);

        require(_exchangeInfo.exchangeOpen, "Exchange is not open!");
        require(
            _exchangeInfo.slabCounter <
                _exchangeInfo.slabTotalSendTokenAvailable,
            "All coin sold out. Wait for the next round."
        );

        require(
            sendTokenToGive <= _exchangeInfo.maxPerWalletGetTokenLimit,
            "Exceeded exchange Limit. Ask a discord admin on how to buy more."
        );
        require(
            sendTokenToGive <=
                IERC20(_exchangeInfo.sendToken).balanceOf(address(this)),
            "Not enough coin to sell!"
        );
        _exchangeInfo.slabCounter += amountOut;
        _exchangeInfo.totalRaised += sendTokenToGive;
        _exchangeInfo.totalSold += amountOut;

        IERC20(_exchangeInfo.getToken).safeTransferFrom(
            msg.sender,
            _exchangeInfo.treasury,
            _amountIn
        );

        IERC20(_exchangeInfo.sendToken).safeTransfer(
            msg.sender,
            sendTokenToGive
        );

        emit coinExchanged(sendTokenToGive, amountOut);
    }

    function transferOut(
        address _token,
        uint256 value,
        address to
    ) public {
        checkRole(msg.sender, TRANSFEROUT_ROLE);
        require(
            value >= IERC20(_token).balanceOf(address(this)),
            "Requested Value Exceeds Balance."
        );
        IERC20(_token).safeTransfer(to, value);
    }

    function setNewSlab(
        uint256 _exchangeId,
        uint256 _newSlab,
        uint256 _newPrice
    ) external {
        checkRole(msg.sender, OPERATOR_ROLE);
        ExchangeManagement storage _exchangeInfo = exchangeInfo[_exchangeId];

        _exchangeInfo.slabCounter = 0;
        _exchangeInfo.currentRate = _newPrice;
        _exchangeInfo.slabTotalSendTokenAvailable = _newSlab;
    }

    function startExchange(uint256 _exchangeId) external {
        checkRole(msg.sender, OPERATOR_ROLE);
        exchangeInfo[_exchangeId].exchangeOpen = true;
    }

    function startAllExchanges() external {
        checkRole(msg.sender, OPERATOR_ROLE);
        for (uint256 i = 0; i < exchangeInfo.length; i++) {
            exchangeInfo[i].exchangeOpen = true;
        }
    }

    function pauseExchange(uint256 _exchangeId) external {
        checkRole(msg.sender, OPERATOR_ROLE);
        exchangeInfo[_exchangeId].exchangeOpen = false;
    }

    function fetchSendTokenBalance(uint256 _exchangeId)
        external
        view
        returns (uint256)
    {
        return
            IERC20(exchangeInfo[_exchangeId].sendToken).balanceOf(
                address(this)
            );
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function setPerWalletMaxBuyLimitBUSD(uint256 _exchangeId, uint256 _limit)
        external
    {
        checkRole(msg.sender, OPERATOR_ROLE);
        exchangeInfo[_exchangeId].maxPerWalletGetTokenLimit = _limit;
    }
}