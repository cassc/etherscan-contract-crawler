// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import "../../common/Basic.sol";
import "../automation/IAutomation.sol";
import "../../adapters/IAdapterManager.sol";

contract ControllerLibSub is
    Initializable,
    OwnableUpgradeable,
    Basic,
    IERC3156FlashBorrower
{
    using SafeERC20 for IERC20;

    address public immutable implementationAddress;
    address public eoaOwner;
    address public adapterManager;
    address public autoExecutor;
    address public currentAdapter;

    constructor() {
        implementationAddress = address(this);
    }

    event NewAccount(address adapterManager, address autoExecutor);
    event ResetAccount(address adapterManager, address autoExecutor);
    event WithdrawAssets(address[] tokens, uint256[] amounts);
    event ApproveTokens(IERC20[] tokens, address[] to, uint256[] amounts);
    event OnFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee
    );

    modifier onlyProxy() {
        require(address(this) != implementationAddress, "!proxy");
        _;
    }

    modifier onlyEoaOwner() {
        require(msg.sender == eoaOwner, "!eoaOwner");
        _;
    }

    function initialize(
        address _adapterManager,
        address _autoExecutor,
        bytes calldata _data
    ) public initializer onlyProxy {
        __Ownable_init();
        adapterManager = _adapterManager;
        autoExecutor = _autoExecutor;
        (
            address _eoaOwner,
            IERC20[] memory _tokens,
            address[] memory _spenders,
            uint256[] memory _amounts
        ) = abi.decode(_data, (address, IERC20[], address[], uint256[]));
        eoaOwner = _eoaOwner;
        _approveTokens(_tokens, _spenders, _amounts);

        emit NewAccount(adapterManager, autoExecutor);
    }

    function reinitialize(address _adapterManager, address _autoExecutor)
        external
        onlyEoaOwner
        onlyProxy
    {
        if (_adapterManager != address(0)) {
            adapterManager = _adapterManager;
        }
        if (_autoExecutor != address(0)) {
            autoExecutor = _autoExecutor;
        }
        emit ResetAccount(adapterManager, autoExecutor);
    }

    function getVersion() external pure returns (string memory) {
        return "v0.3";
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

    receive() external payable {}

    function setCurrentAdapter(address _currentAdapter) internal {
        require(
            IAdapterManager(adapterManager).adapterIsAvailable(_currentAdapter),
            "Invalid currentAdapter!"
        );
        currentAdapter = _currentAdapter;
    }

    //callback only for callOnAdapter so far
    function _callOnAdapter(bytes memory _callBytes, bool isNeedCallback)
        internal
        returns (bytes memory returnData)
    {
        (address adapter, uint256 costETH, , ) = abi.decode(
            _callBytes,
            (address, uint256, bytes4, bytes)
        );
        if (isNeedCallback) {
            setCurrentAdapter(adapter);
        }

        returnData = IAdapterManager(adapterManager).execute{
            value: costETH + msg.value
        }(_callBytes);

        if (isNeedCallback) {
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
        onlyOwner
        returns (bytes memory)
    {
        return _executeOnAdapter(_callBytes, _callType, false);
    }

    function multiCall(
        bool[] memory _callType,
        bytes[] memory _callArgs,
        bool[] memory _isNeedCallback
    ) external onlyOwner {
        _multiCall(_callType, _callArgs, _isNeedCallback);
    }

    function _transferAsset(address _token, uint256 _amount) internal {
        if (_token == ethAddr) {
            uint256 _balance = address(this).balance;
            require(_balance >= _amount, "not enough ETH balance");
            safeTransferETH(owner(), _amount);
        } else {
            uint256 _balance = IERC20(_token).balanceOf(address(this));
            require(_balance >= _amount, "not enough token balance");
            IERC20(_token).safeTransfer(owner(), _amount);
        }
    }

    function withdrawAssets(address[] memory _tokens, uint256[] memory _amounts)
        external
        onlyOwner
    {
        require(_tokens.length == _amounts.length, "withdraw length error.");
        for (uint256 i = 0; i < _tokens.length; i++) {
            _transferAsset(_tokens[i], _amounts[i]);
        }
        emit WithdrawAssets(_tokens, _amounts);
    }

    function _approveTokens(
        IERC20[] memory _tokens,
        address[] memory _spenders,
        uint256[] memory _amounts
    ) internal {
        require(
            _tokens.length == _amounts.length &&
                _spenders.length == _amounts.length,
            "approve length error."
        );
        for (uint256 i = 0; i < _tokens.length; i++) {
            _tokens[i].safeApprove(_spenders[i], 0);
            _tokens[i].safeApprove(_spenders[i], _amounts[i]);
        }
    }

    function approveTokens(
        IERC20[] memory _tokens,
        address[] memory _spenders,
        uint256[] memory _amounts
    ) external onlyEoaOwner {
        _approveTokens(_tokens, _spenders, _amounts);

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
            msg.sender == IAutomation(autoExecutor).getLoanProvider(owner()),
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