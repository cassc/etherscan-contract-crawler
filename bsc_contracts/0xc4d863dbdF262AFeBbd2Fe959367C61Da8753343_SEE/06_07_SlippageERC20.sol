// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract SlippageERC20 is ERC20 {

    /// @notice permission tpye
    /// main permission
    uint8 public constant OWNER = 0;
    /// mint permission
    uint8 public constant MINTER = 1;

    /// @notice param tpye
    /// from slip, general for sell
    uint8 public constant FROM_SLIP = 2;
    /// to slip, general for buy
    uint8 public constant TO_SLIP = 3;
    /// set slip white list
    uint8 public constant SLIP_WHITE_LIST = 4;
    /// set black list
    uint8 public constant BLACK_LIST = 5;
    /// withdraw token
    uint8 public constant WITHDRAW = 6;
    /// set default tax rate
    uint8 public constant DEFAULT_TAX_RATE = 7;

    /// default tax rate, transfer tax rate except fromSlip, toSlip, slipWhiteList
    uint32 public defaultTaxRateE5 = 0;

    /// @notice permission => caller => isPermission
    mapping (uint8 => mapping(address => bool)) public permissions;
    /// @notice set permission event
    event PermissionSet(uint8 indexed permission, address indexed account, bool indexed value);

    /// @notice check permission
    modifier onlyCaller(uint8 _permission) {
        require(permissions[_permission][msg.sender], "Calls have not allowed");
        _;
    }

    /// @notice from
    mapping(address => uint32) public fromSlipE5;
    /// @notice to
    mapping(address => uint32) public toSlipE5;

    mapping(address => bool) public slipWhiteList;
    mapping(address => bool) public blackList;

    constructor() {
        // set permission for own
        address _owner = msg.sender;
        
        _setPermission(OWNER, _owner, true);
        _setPermission(MINTER, _owner, true);
    }

    /// @notice set permission
    function _setPermission(uint8 _permission, address _account, bool _value) internal {
        permissions[_permission][_account] = _value;
        emit PermissionSet(_permission, _account, _value);
    }

    /// @notice set permissions
    function setPermissions(uint8[] calldata _permissions, address[] calldata _accounts, bool[] calldata _values) external onlyCaller(OWNER) {
        require(_permissions.length == _accounts.length && _accounts.length == _values.length, "Lengths are not equal");
        for (uint i = 0; i < _permissions.length; i++) {
            _setPermission(_permissions[i], _accounts[i], _values[i]);
        }
    }

    /// @notice set
    function setConfig(uint8[] calldata _configTypes, bytes[] calldata _datas) external onlyCaller(OWNER) {
        uint len = _configTypes.length;
        for(uint i = 0; i < len; i++) {
            if (_configTypes[i] == FROM_SLIP) {
                (address _from, uint32 _feeE5) = abi.decode(_datas[i], (address, uint32));
                fromSlipE5[_from] = _feeE5;
            } else if (_configTypes[i] == TO_SLIP) {
                (address _to, uint32 _feeE5) = abi.decode(_datas[i], (address, uint32));
                toSlipE5[_to] = _feeE5;
            } else if (_configTypes[i] == SLIP_WHITE_LIST) {
                (address _account, bool _value) = abi.decode(_datas[i], (address, bool));
                slipWhiteList[_account] = _value;
            } else if (_configTypes[i] == BLACK_LIST) {
                (address _account, bool _value) = abi.decode(_datas[i], (address, bool));
                blackList[_account] = _value;
            } else if (_configTypes[i] == WITHDRAW) {
                (address _to, uint _amount) = abi.decode(_datas[i], (address, uint));
                _balanceOf[address(this)] -= _amount;
                _balanceOf[_to] += _amount;
                emit Transfer(address(this), _to, _amount);
            } else if (_configTypes[i] == DEFAULT_TAX_RATE) {
                (uint32 _feeE5) = abi.decode(_datas[i], (uint32));
                defaultTaxRateE5 = _feeE5;
            }
        }
    }

    /// @notice slipperage transfer
    function _transfer(address _from, address _to, uint256 _amount) internal override {
        require(!blackList[_from] && !blackList[_to], "blacklisted");
        uint _fee = 0;
        if (!slipWhiteList[_from] && !slipWhiteList[_to]) {
            _fee = _amount * (fromSlipE5[_from] + toSlipE5[_to]) / 1e5;
            /// @dev default tax rate without slip
            if ( defaultTaxRateE5 > 0 && _fee == 0) {
                _fee = _amount * defaultTaxRateE5 / 1e5;
            }
            
            if (_fee > 0) {
                _transferSlippage(_from, _to, _amount, _fee);
            }
        }
        _balanceOf[_from] -= _amount;
        _balanceOf[_to] += _amount - _fee;
        emit Transfer(_from, _to, _amount);
        _transferAfter(_from, _to, _amount, _fee);
    }

    /// @notice default transfer fee
    function _transferSlippage(address _from, address, uint256, uint _fee) internal virtual {
        _balanceOf[address(this)] += _fee;
        emit Transfer(_from, address(this), _fee);
    }

    function _transferAfter(address _from, address _to, uint _amount, uint _fee) internal virtual {}

    function burn(uint256 _amount) external {
        _burn(msg.sender, _amount);
    }
}