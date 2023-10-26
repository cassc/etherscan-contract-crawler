// SPDX-License-Identifier: LZBL-1.1
// Copyright 2023 LayerZero Labs Ltd.
// You may obtain a copy of the License at
// https://github.com/LayerZero-Labs/license/blob/main/LICENSE-LZBL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../messaging/interfaces/IMessaging.sol";
import "./interfaces/IUSDV.sol";
import "./interfaces/IOperator.sol";
import "./libs/Colors.sol";

abstract contract USDVBase is IUSDV, ERC20PermitUpgradeable {
    using Colors for Colors.Info;
    using SafeCast for uint256;

    uint64 internal totalSupply_;
    // governance
    bool public paused;
    mapping(Role => address) internal roles;

    Colors.Info internal colorInfo;
    mapping(address user => State) public userStates;
    mapping(address user => address colorer) public colorers;

    function __USDVBase_init(address _owner, address _foundation) internal onlyInitializing {
        __ERC20_init_unchained("USDV", "USDV");
        __EIP712_init_unchained("USDV", "1");
        __ERC20Permit_init_unchained("USDV");
        __USDVBase_init_unchained(_owner, _foundation);
    }

    function __USDVBase_init_unchained(address _owner, address _foundation) internal onlyInitializing {
        roles[Role.FOUNDATION] = _foundation;
        roles[Role.OWNER] = _owner;
    }

    // ======================== Modifiers ========================
    modifier notBlacklisted(address _user) {
        if (userStates[_user].blacklisted) revert Blacklisted();
        _;
    }

    modifier onlyRole(Role _role) {
        if (msg.sender != getRole(_role)) revert Unauthorized();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert Paused();
        _;
    }

    // ======================== Only Role / Owner ========================
    /// @dev owner / role can set role
    function setRole(Role _role, address _addr) external {
        if (msg.sender != getRole(_role) && msg.sender != getRole(Role.OWNER)) revert Unauthorized();
        roles[_role] = _addr;
        emit SetRole(_role, _addr);
    }

    // ======================== OnlyFoundation ========================
    function blacklist(address _user, bool _isBlacklisted) external onlyRole(Role.FOUNDATION) {
        userStates[_user].blacklisted = _isBlacklisted;
        emit SetBlacklist(_user, _isBlacklisted);
    }

    // ======================== OnlyOperator ========================
    function setPause(bool _paused) external onlyRole(Role.OPERATOR) {
        paused = _paused;
        emit SetPause(_paused);
    }

    // ======================== OnlyVault ========================
    /// @dev on main chain, VAULT is the VaultManager
    /// @dev on side chain, this can be used to fix the book in emergency e.g. hardfork
    /// action is allowed whenPaused() to fix invalid state
    function mint(address _receiver, uint64 _amount, uint32 _color) external whenNotPaused onlyRole(Role.VAULT) {
        // update the color space
        colorInfo.mint(_color, _amount, 0);
        // update the token space
        _mintBalance(_receiver, _amount, _color);
    }

    /// @dev on main chain, VAULT is the VaultManager
    /// @dev on side chain, this can be used to fix the book in emergency e.g. hardfork
    /// @dev this function might have race condition.
    /// @param _deficits proposed deltas to match surplus (if any)
    /// @return minted used for color, and deltas for deficits. if burn 0 then Delta.amount = 0;
    function burn(
        address _from,
        uint64 _amount,
        uint32[] calldata _deficits
    ) external whenNotPaused onlyRole(Role.VAULT) returns (Delta[] memory) {
        uint32 burntColor = _burnBalance(_from, _amount);

        //update the color space
        return colorInfo.burn(_deficits, _amount, burntColor);
    }

    // ======================== OnlyColorer ========================
    /// @dev property: if defaultColor != nil, then color always equals defaultColor
    /// @dev can also assign to NIL_COLOR to clear the default color
    /// @dev operator can set default color for any account
    function setDefaultColor(address _user, uint32 _defaultColor) external {
        if (msg.sender != _getColorer(_user) && msg.sender != getRole(Role.OPERATOR)) revert Unauthorized(); // assert colorer

        State memory state = userStates[_user];
        // setting to Nil color is also allowed
        state.defaultColor = _defaultColor;

        if (_defaultColor != Colors.NIL) {
            if (_defaultColor > colorInfo.maxKnownColor) revert Colors.InvalidColor(_defaultColor);

            // if the new color is not the same as the old color, update color
            if (state.color != _defaultColor) {
                colorInfo.recolor(state.color, _defaultColor, state.balance);
                // change config
                state.color = _defaultColor;
            }
        }

        userStates[_user] = state;
        emit SetDefaultColor(msg.sender, _user, _defaultColor);
    }

    // ======================== User Configuration ========================
    /// @dev user and operator can set colorer
    function setColorer(address _user, address _colorer) external override {
        if (msg.sender != _user && msg.sender != getRole(Role.OPERATOR)) revert Unauthorized();
        colorers[_user] = _colorer;
        emit SetColorer(msg.sender, _user, _colorer);
    }

    // ======================== overriding ERC20 internal functions ========================

    /// @dev blacklisted not allowed. checked in the internal function
    function _transfer(address _from, address _to, uint _amount) internal override whenNotPaused {
        uint64 amountU64 = _amount.toUint64();
        uint32 fromColor = _debit(_from, amountU64);
        _credit(_to, fromColor, amountU64);
        emit Transfer(_from, _to, _amount);
    }

    /// @dev blacklisted not allowed
    function _spendAllowance(
        address _owner,
        address _spender,
        uint256 _amount
    ) internal override notBlacklisted(_spender) {
        super._spendAllowance(_owner, _spender, _amount);
    }

    // ======================== basic coloring operations ========================

    /// @dev debit will only update storage balance and returns user color
    /// @dev blacklisted not allowed
    function _debit(address _from, uint64 _amount) internal notBlacklisted(_from) returns (uint32 color) {
        if (_from == address(0)) revert InvalidUser();
        uint64 balance = userStates[_from].balance;
        if (balance < _amount) revert InsufficientBalance();
        userStates[_from].balance = balance - _amount;
        return userStates[_from].color;
    }

    /// @dev credit will update user state color and credit balance
    /// @dev blacklisted not allowed
    function _credit(address _to, uint32 _inboundColor, uint64 _amount) internal notBlacklisted(_to) {
        // following OZ's ERC20
        if (_to == address(0)) revert InvalidUser();
        if (_amount == 0) return; // transfer 0 is allowed

        State memory state = userStates[_to];
        if (state.color != _inboundColor) {
            // ONLY if (1) user has not default color && (2) credit amount is greater than balance
            bool changeColor = state.defaultColor == Colors.NIL && _amount > state.balance;
            if (changeColor) {
                // recolor the current to inbound color
                colorInfo.recolor(state.color, _inboundColor, state.balance);
                // change color
                state.color = _inboundColor;
            } else {
                // recolor the inbound color to current color
                colorInfo.recolor(_inboundColor, state.color, _amount);
            }
        } // else, same color, in-kind merge

        // increment the balance
        state.balance += _amount;

        userStates[_to] = state;
    }

    function _mintBalance(address _receiver, uint64 _amount, uint32 _color) internal {
        _credit(_receiver, _color, _amount);
        totalSupply_ += _amount;
        emit Transfer(address(0), _receiver, _amount);
    }

    function _burnBalance(address _from, uint64 _targetAmount) internal returns (uint32 color) {
        // change balance
        color = _debit(_from, _targetAmount);
        totalSupply_ -= _targetAmount;
        emit Transfer(_from, address(0), _targetAmount);
    }

    // ======================== Cross-chain features ========================
    /// all cross chain functions have 3 parts:
    /// (1) quote at source
    /// (2) send at source
    /// (3) ack at destination

    // ======================== SEND ========================
    function quoteSendFee(
        SendParam calldata _param,
        bytes calldata _extraOptions,
        bool _useLZToken,
        bytes calldata _composeMsg
    ) external view returns (uint nativeFee, uint lzTokenFee) {
        return IMessaging(roles[Role.MESSAGING]).quoteSendFee(_param.dstEid, _extraOptions, _useLZToken, _composeMsg);
    }

    function _send(uint64 _amount) internal returns (uint32 color, uint64 theta) {
        if (_amount == 0) revert Colors.InvalidAmount();
        IOperator(getRole(Role.OPERATOR)).tryConsume(msg.sender, _amount);

        color = _burnBalance(msg.sender, _amount);
        // theta == surplus
        theta = colorInfo.send(color, _amount);
    }

    function send(
        SendParam calldata _param,
        bytes calldata _extraOptions,
        MessagingFee calldata _msgFee,
        address payable _refundAddress,
        bytes calldata _composeMsg
    ) external payable whenNotPaused returns (MessagingReceipt memory msgReceipt) {
        // revert if address is 0x0 as it is checked on sendAck
        if (_param.to == bytes32(0)) revert InvalidArgument();

        uint64 amount = _param.amountLD.toUint64();
        (uint32 color, uint64 theta) = _send(amount);
        IMessaging.SendParam memory sendParam = IMessaging.SendParam(_param.dstEid, _param.to, color, amount, theta);

        msgReceipt = IMessaging(getRole(Role.MESSAGING)).send{value: msg.value}(
            sendParam,
            _extraOptions,
            _msgFee,
            _refundAddress,
            _composeMsg
        );

        emit SendOFT(msgReceipt.guid, msg.sender, amount, _composeMsg);
    }

    /// @dev whenNotPaused checked in _sendAck
    /// @dev receive side interface
    function sendAck(
        bytes32 _guid,
        address _receiver,
        uint32 _color,
        uint64 _amount,
        uint64 _theta
    ) external whenNotPaused onlyRole(Role.MESSAGING) {
        _sendAck(_receiver, _color, _amount, _theta);
        emit ReceiveOFT(_guid, _receiver, _amount);
    }

    /// @dev symmetrical operation to the _send()
    function _sendAck(address _receiver, uint32 _color, uint64 _amount, uint64 _theta) internal {
        IOperator(getRole(Role.OPERATOR)).refill(msg.sender, _amount);

        // update the color space
        // must mint out the colors first or the _credit() may fail
        colorInfo.mint(_color, _amount - _theta, _theta);

        // update the token space
        _mintBalance(_receiver, _amount, _color);
    }

    // ================== Synchronization (Sync + Remint) ========================

    /// @dev this function might have race condition.
    /// @param _theta length must be 1 and the color must be THETA
    /// @param _deficits in ascending order
    function syncDelta(
        uint32 _eid,
        uint64 _theta,
        uint32[] calldata _deficits,
        uint64 _feeCap,
        bytes calldata _extraOptions,
        MessagingFee calldata _msgFee,
        address payable _refundAddress
    ) external payable whenNotPaused returns (MessagingReceipt memory msgReceipt) {
        (uint64 surplus, Delta[] memory deltas) = colorInfo.extractDelta(Colors.THETA, _theta, _deficits);
        if (surplus == 0) revert Colors.InvalidAmount();

        address operator = getRole(Role.OPERATOR);
        uint64 fee = IOperator(operator).getSyncFees(msg.sender, deltas, surplus);
        if (fee > 0) {
            if (fee > _feeCap) revert FeeTooHigh();
            _transfer(msg.sender, operator, fee);
        }

        uint32 eid = _eid;
        msgReceipt = IMessaging(getRole(Role.MESSAGING)).syncDelta{value: msg.value}(
            eid,
            deltas,
            _extraOptions,
            _msgFee,
            _refundAddress
        );
        emit Synced(msgReceipt.guid, deltas);
    }

    function syncDeltaAck(Delta[] calldata _deltas) external whenNotPaused onlyRole(Role.MESSAGING) {
        colorInfo.syncDeltaAck(_deltas);
    }

    // @dev race condition may create a longer payload. so should quote with the buffer
    function quoteSyncDeltaFee(
        uint32 _dstEid,
        uint32 _numDeficits,
        bytes calldata _extraOptions,
        bool _useLzToken
    ) external view returns (uint nativeFee, uint lzTokenFee) {
        Delta[] memory deltas = new Delta[](_numDeficits + 1);
        return IMessaging(getRole(Role.MESSAGING)).quoteSyncDeltaFee(_dstEid, deltas, _extraOptions, _useLzToken);
    }

    /// @dev this function might have race condition.
    function _remint(
        uint32 _surplusColor,
        uint64 _surplusAmount,
        uint32[] calldata _deficits,
        uint64 _feeCap
    ) internal returns (uint64 minterRemintFee, Delta[] memory deltas) {
        if (_surplusColor == Colors.THETA) revert Colors.InvalidColor(Colors.THETA);

        uint64 totalSurplus;
        (totalSurplus, deltas) = colorInfo.extractDelta(_surplusColor, _surplusAmount, _deficits);
        if (totalSurplus == 0) revert Colors.InvalidAmount();

        address operator = getRole(Role.OPERATOR);
        uint64 operatorRemintFee;
        (minterRemintFee, operatorRemintFee) = IOperator(operator).getRemintFees(
            msg.sender,
            _surplusColor,
            deltas,
            totalSurplus
        );
        if (minterRemintFee + operatorRemintFee > _feeCap) revert FeeTooHigh();

        // pay operator remint fee
        if (operatorRemintFee > 0) {
            _transfer(msg.sender, operator, operatorRemintFee);
        }
    }

    /// @dev return the configured color if set by the operator or address
    function _getColorer(address _user) internal view returns (address) {
        address colorer = colorers[_user];
        if (colorer != address(0x0)) return colorer;
        return _user;
    }

    // ======================== Views Functions ========================

    function colorStateOf(uint32 _color) public view returns (Colors.ColorState memory) {
        return colorInfo.colorStates[_color];
    }

    function getRole(Role _role) public view returns (address) {
        return roles[_role];
    }

    function getDeltas(uint32 _startColor, uint32 _endColor) external view returns (Delta[] memory) {
        return colorInfo.getDeltas(_startColor, _endColor);
    }

    function getDeltas(uint32[] calldata _colors) external view returns (Delta[] memory) {
        return colorInfo.getDeltas(_colors);
    }

    function maxKnownColor() external view returns (uint32) {
        return colorInfo.maxKnownColor;
    }

    // ======================== ERC20 Views Functions ========================
    function token() external view returns (address) {
        return address(this);
    }

    function totalSupply() public view override(ERC20Upgradeable, IERC20Upgradeable) returns (uint) {
        return totalSupply_;
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function balanceOf(address _user) public view override(ERC20Upgradeable, IERC20Upgradeable) returns (uint) {
        return userStates[_user].balance;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}