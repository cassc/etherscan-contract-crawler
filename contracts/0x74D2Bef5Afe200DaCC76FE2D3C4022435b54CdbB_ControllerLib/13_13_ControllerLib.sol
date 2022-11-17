// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import "../../common/Basic.sol";
import "../automation/AutomationCallable.sol";
import "../automation/IAutomation.sol";
import "../../adapters/IAdapterManager.sol";

interface IWalletFactory {
    function createSubAccount(
        address _adapterManager,
        address _autoExecutor,
        bytes memory _data
    ) external payable returns (address);
}

contract ControllerLib is
    Initializable,
    OwnableUpgradeable,
    Basic,
    AutomationCallable,
    IERC3156FlashBorrower
{
    using SafeERC20 for IERC20;

    address public immutable implementationAddress;
    address public adapterManager;
    bool public advancedOptionEnable;
    address public walletFactory;
    address public currentAdapter;
    mapping(address => bool) public isSubAccount;

    event NewAccount(address owner, address account);
    event ResetAccount(
        address adapterManager,
        address autoExecutor,
        address walletFactory
    );
    event SetAdvancedOption(bool);
    event NewSubAccount(address _subAccount);
    event WithdrawAssets(
        address[] _tokens,
        address _receiver,
        uint256[] _amounts
    );
    event ApproveToken(IERC20 _token, address _spender, uint256 _amount);
    event ApproveTokens(
        IERC20[] _tokens,
        address[] _spenders,
        uint256[] _amounts
    );
    event OnFlashLoan(
        address _initiator,
        address _token,
        uint256 _amount,
        uint256 _fee
    );

    constructor() {
        implementationAddress = address(this);
    }

    modifier onlyProxy() {
        require(address(this) != implementationAddress, "!proxy");
        _;
    }

    function initialize(
        address _owner,
        address _autoExecutor,
        address _adapterManager
    ) public initializer onlyProxy {
        __Ownable_init();
        _setAutomation(_autoExecutor);
        adapterManager = _adapterManager;
        walletFactory = msg.sender;
        emit NewAccount(_owner, address(this));
    }

    function reinitialize(
        address _adapterManager,
        address _autoExecutor,
        address _walletFactory
    ) external onlyOwner onlyProxy {
        if (_adapterManager != address(0)) {
            adapterManager = _adapterManager;
        }
        if (_autoExecutor != address(0)) {
            _setAutomation(_autoExecutor);
        }
        if (_walletFactory != address(0)) {
            walletFactory = _walletFactory;
        }
        emit ResetAccount(_adapterManager, _autoExecutor, _walletFactory);
    }

    function getVersion() external pure returns (string memory) {
        return "v0.4";
    }

    function _fallbackForAdapter() internal {
        (bool success, bytes memory returnData) = currentAdapter.delegatecall(
            msg.data
        );
        require(success, string(returnData));
        currentAdapter = address(0);
    }

    fallback() external payable {
        require(
            msg.sender == currentAdapter,
            "Not allowed: caller is not the currentAdapter"
        );
        _fallbackForAdapter();
    }

    modifier onlyAutomationOrOwner() {
        require(
            // autoExecutor or owner
            autoExecutor == msg.sender || owner() == msg.sender,
            "Permit: sender not permitted"
        );
        _;
    }

    function setCurrentAdapter(address _currentAdapter) internal {
        require(
            IAdapterManager(adapterManager).adapterIsAvailable(_currentAdapter),
            "Invalid currentAdapter!"
        );
        currentAdapter = _currentAdapter;
    }

    function createSubAccount(bytes memory _data, uint256 _costETH)
        external
        payable
        onlyOwner
        returns (address newSubAccount)
    {
        newSubAccount = IWalletFactory(walletFactory).createSubAccount{
            value: _costETH + msg.value
        }(adapterManager, autoExecutor, _data);
        isSubAccount[newSubAccount] = true;

        emit NewSubAccount(newSubAccount);
    }

    //callback only for callOnAdapter so far
    function _callOnAdapter(bytes memory _callBytes, bool _isNeedCallback)
        internal
        returns (bytes memory returnData)
    {
        (address adapter, uint256 costETH, , ) = abi.decode(
            _callBytes,
            (address, uint256, bytes4, bytes)
        );
        if (_isNeedCallback) {
            setCurrentAdapter(adapter);
        }

        returnData = IAdapterManager(adapterManager).execute{
            value: costETH + msg.value
        }(_callBytes);

        if (_isNeedCallback) {
            require(currentAdapter == address(0), "!not reset");
        }
    }

    function _delegatecallOnAdapter(bytes memory _callBytes)
        internal
        returns (bytes memory)
    {
        (address adapter, bytes memory callData) = abi.decode(
            _callBytes,
            (address, bytes)
        );
        require(
            IAdapterManager(adapterManager).adapterIsAvailable(adapter),
            "Permission verification failed!"
        );

        (bool success, bytes memory returnData) = adapter.delegatecall(
            callData
        );
        require(success, string(returnData));
        return returnData;
    }

    function _executeOnAdapter(
        bytes memory _callBytes,
        bool _callType,
        bool _isNeedCallback
    ) internal returns (bytes memory returnData) {
        returnData = _callType
            ? _delegatecallOnAdapter(_callBytes)
            : _callOnAdapter(_callBytes, _isNeedCallback);
    }

    function _multiCall(
        bool[] memory _callType,
        bytes[] memory _callArgs,
        bool[] memory _isNeedCallback
    ) internal {
        require(
            _callType.length == _callArgs.length &&
                _callArgs.length == _isNeedCallback.length
        );
        for (uint256 i; i < _callArgs.length; i++) {
            _executeOnAdapter(_callArgs[i], _callType[i], _isNeedCallback[i]);
        }
    }

    function executeOnAdapter(bytes memory _callBytes, bool _callType)
        external
        payable
        onlyAutomationOrOwner
        returns (bytes memory)
    {
        return _executeOnAdapter(_callBytes, _callType, false);
    }

    function multiCall(
        bool[] memory _callType,
        bytes[] memory _callArgs,
        bool[] memory _isNeedCallback
    ) external onlyAutomationOrOwner {
        _multiCall(_callType, _callArgs, _isNeedCallback);
    }

    function _callDirectly(
        address _target,
        bytes calldata _callArgs,
        uint256 _amountETH
    ) internal {
        (bool success, bytes memory returnData) = _target.call{
            value: _amountETH + msg.value
        }(_callArgs);
        require(success, string(returnData));
    }

    function callDirectly(
        address _target,
        bytes calldata _callArgs,
        uint256 _amountETH
    ) external payable onlyOwner {
        require(advancedOptionEnable, "Not allowed!");
        _callDirectly(_target, _callArgs, _amountETH);
    }

    function callOnSubAccount(
        address _target,
        bytes calldata _callArgs,
        uint256 _amountETH
    ) external payable onlyAutomationOrOwner {
        require(isSubAccount[_target], "Not my subAccount!");
        _callDirectly(_target, _callArgs, _amountETH);
    }

    function setAdvancedOption(bool val) external onlyOwner {
        advancedOptionEnable = val;

        emit SetAdvancedOption(advancedOptionEnable);
    }

    function _transferAsset(
        address _token,
        uint256 _amount,
        address _receiver
    ) internal {
        if (_token == ethAddr) {
            uint256 _balance = address(this).balance;
            require(_balance >= _amount, "not enough ETH balance");
            safeTransferETH(_receiver, _amount);
        } else {
            uint256 _balance = IERC20(_token).balanceOf(address(this));
            require(_balance >= _amount, "not enough token balance");
            IERC20(_token).safeTransfer(_receiver, _amount);
        }
    }

    function _transferAssets(
        address[] memory _tokens,
        uint256[] memory _amounts,
        address _receiver
    ) internal {
        require(_tokens.length == _amounts.length, "withdraw length error.");
        for (uint256 i = 0; i < _tokens.length; i++) {
            _transferAsset(_tokens[i], _amounts[i], _receiver);
        }
    }

    function withdrawAssets(
        address[] memory _tokens,
        address _receiver,
        uint256[] memory _amounts
    ) external onlyOwner {
        if (_receiver != owner() && !isSubAccount[_receiver]) {
            require(advancedOptionEnable, "Not allowed!");
        }
        _transferAssets(_tokens, _amounts, _receiver);

        emit WithdrawAssets(_tokens, _receiver, _amounts);
    }

    function approve(
        IERC20 _token,
        address _spender,
        uint256 _amount
    ) external onlyAutomationOrOwner {
        _token.safeApprove(_spender, 0);
        _token.safeApprove(_spender, _amount);

        emit ApproveToken(_token, _spender, _amount);
    }

    function approveTokens(
        IERC20[] memory _tokens,
        address[] memory _spenders,
        uint256[] memory _amounts
    ) external onlyAutomationOrOwner {
        require(
            _tokens.length == _amounts.length &&
                _spenders.length == _amounts.length,
            "approve length error."
        );
        for (uint256 i = 0; i < _tokens.length; i++) {
            _tokens[i].safeApprove(_spenders[i], 0);
            _tokens[i].safeApprove(_spenders[i], _amounts[i]);
        }

        emit ApproveTokens(_tokens, _spenders, _amounts);
    }

    function onFlashLoan(
        address _initiator,
        address _token,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _data
    ) external override returns (bytes32) {
        require(autoExecutor == _initiator, "Initiator verification failed.");
        require(
            msg.sender ==
                IAutomation(autoExecutor).getLoanProvider(address(this)),
            "FlashLoan verification failed."
        );
        (
            bool[] memory _callType,
            bytes[] memory _callArgs,
            bool[] memory _isNeedCallback
        ) = abi.decode(_data, (bool[], bytes[], bool[]));
        _multiCall(_callType, _callArgs, _isNeedCallback);
        // Handle native token.
        IERC20 borrow = IERC20(_token);
        borrow.safeApprove(msg.sender, 0);
        borrow.safeApprove(msg.sender, _amount + _fee);

        emit OnFlashLoan(_initiator, _token, _amount, _fee);
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }
}