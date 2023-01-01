// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./staking/interfaces/IRewardRouter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract SyrupMultisig is Initializable, OwnableUpgradeable {
    IRewardRouter public rewardRouter;

    uint256 public constant MAX_BUFFER = 5 days;
    uint256 public buffer;
    uint256 public minSignaturesRequired;

    mapping(address => bool) public isSigner;
    mapping(bytes32 => bool) public pendingActions;
    mapping(address => mapping(bytes32 => uint256)) public signedActions;

    address[] public signers;

    modifier onlySigner() {
        require(isSigner[msg.sender], "Timelock: forbidden");
        _;
    }

    modifier onlySignerAndOwner() {
        require(
            isSigner[msg.sender] || msg.sender == owner(),
            "Timelock: forbidden"
        );
        _;
    }

    event SignerAdded(address indexed signer, uint256 timestamp);
    event SignerRemoved(address indexed signer, uint256 timestamp);
    event SignalPendingAction(bytes32 action);
    event SignalApprove(
        address token,
        address spender,
        uint256 amount,
        bytes32 action
    );
    event SignalWithdrawToken(
        address token,
        address receiver,
        uint256 amount,
        bytes32 action
    );
    event SignalDepositSLP(
        address target,
        address token,
        uint256 amount,
        uint256 amountOut,
        bytes32 action
    );

    event SignalWithdrawSLP(
        address _token,
        uint256 _amount,
        uint256 _minOut,
        address _reciever
    );

    event MinSignaturesRequiredSet(uint256 minSignaturesRequired);

    function initialize() external initializer {
        __Ownable_init();

        buffer = 0;
        minSignaturesRequired = 1;
    }

    function setMinSignaturesRequired(
        uint256 _minSignaturesRequired
    ) external onlyOwner {
        minSignaturesRequired = _minSignaturesRequired;
        emit MinSignaturesRequiredSet(_minSignaturesRequired);
    }

    function setRewardRouter(address _rewardRouter) external onlyOwner {
        rewardRouter = IRewardRouter(_rewardRouter);
    }

    function setBuffer(uint256 _buffer) external onlyOwner {
        require(_buffer <= MAX_BUFFER, "Timelock: buffer too long");
        buffer = _buffer;
    }

    function addSigner(address _signer) external onlyOwner {
        isSigner[_signer] = true;
        signers.push(_signer);
        emit SignerAdded(_signer, block.timestamp);
    }

    function removeSigner(address _signer) external onlyOwner {
        isSigner[_signer] = false;
        for (uint256 i = 0; i < signers.length; i++) {
            if (signers[i] == _signer) {
                signers[i] = signers[signers.length - 1];
                signers.pop();
                break;
            }
        }
        emit SignerRemoved(_signer, block.timestamp);
    }

    function signalDepositSLP(
        address _token,
        uint256 _amount,
        uint256 _minUsdg,
        uint256 _minSlp
    ) external onlySignerAndOwner {
        bytes32 action = keccak256(
            abi.encodePacked("depositSLP", _token, _amount, _minUsdg, _minSlp)
        );
        _setPendingAction(action);
        signedActions[msg.sender][action]++;
    }

    function signalApprove(
        address _token,
        address _spender,
        uint256 _amount
    ) external onlySignerAndOwner {
        bytes32 action = keccak256(
            abi.encodePacked("approve", _token, _spender, _amount)
        );
        _setPendingAction(action);
        signedActions[msg.sender][action]++;
    }

    function signalWithdrawToken(
        address _token,
        address _receiver,
        uint256 _amount
    ) external onlySignerAndOwner {
        bytes32 action = keccak256(
            abi.encodePacked("withdrawToken", _token, _receiver, _amount)
        );
        _setPendingAction(action);
        signedActions[msg.sender][action]++;
    }

    function signalWithdrawSLP(
        address _target,
        address _token,
        uint256 _amount,
        uint256 _minUsdg,
        uint256 _minSlp
    ) external onlySignerAndOwner {
        bytes32 action = keccak256(
            abi.encodePacked(
                "withdrawSLP",
                _target,
                _token,
                _amount,
                _minUsdg,
                _minSlp
            )
        );
        _setPendingAction(action);
        signedActions[msg.sender][action]++;
    }

    function signDepositSLP(
        address _token,
        uint256 _amount,
        uint256 _minUsdg,
        uint256 _minSlp
    ) external onlySignerAndOwner {
        bytes32 action = keccak256(
            abi.encodePacked("depositSLP", _token, _amount, _minUsdg, _minSlp)
        );
        _validateAction(action);
        signedActions[msg.sender][action]++;
        emit SignalDepositSLP(msg.sender, _token, _amount, _minSlp, action);
    }

    function signApprove(
        address _token,
        address _spender,
        uint256 _amount
    ) external onlySignerAndOwner {
        bytes32 action = keccak256(
            abi.encodePacked("approve", _token, _spender, _amount)
        );
        _validateAction(action);
        signedActions[msg.sender][action]++;
        emit SignalApprove(_token, _spender, _amount, action);
    }

    function signWithdrawToken(
        address _token,
        address _receiver,
        uint256 _amount
    ) external onlySignerAndOwner {
        bytes32 action = keccak256(
            abi.encodePacked("withdrawToken", _token, _receiver, _amount)
        );
        _validateAction(action);
        signedActions[msg.sender][action]++;
        emit SignalWithdrawToken(_token, _receiver, _amount, action);
    }

    function signWithdrawSLP(
        address _token,
        uint256 _amount,
        uint256 _minOut,
        address _reciever
    ) external onlySignerAndOwner {
        bytes32 action = keccak256(
            abi.encodePacked("withdrawSLP", _token, _amount, _minOut, _reciever)
        );
        _validateAction(action);
        signedActions[msg.sender][action]++;
        emit SignalWithdrawSLP(_token, _amount, _minOut, _reciever);
    }

    function depositSLP(
        address _token,
        uint256 _amount,
        uint256 _minUsdg,
        uint256 _minSlp
    ) external onlySignerAndOwner {
        bytes32 action = keccak256(
            abi.encodePacked("depositSLP", _token, _amount, _minUsdg, _minSlp)
        );
        _validateAction(action);
        _validateAuthorization(action);
        delete pendingActions[action];
        delete signedActions[msg.sender][action];
        // IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        IERC20(_token).approve(address(rewardRouter), _amount);
        rewardRouter.mintAndStakeSlp(_token, _amount, _minUsdg, _minSlp);
    }

    function approve(
        address _token,
        address _spender,
        uint256 _amount
    ) external onlySignerAndOwner {
        bytes32 action = keccak256(
            abi.encodePacked("approve", _token, _spender, _amount)
        );
        _validateAction(action);
        _validateAuthorization(action);
        delete pendingActions[action];
        delete signedActions[msg.sender][action];
        IERC20(_token).approve(_spender, _amount);
    }

    function withdrawToken(
        address _token,
        address _receiver,
        uint256 _amount
    ) external onlySignerAndOwner {
        bytes32 action = keccak256(
            abi.encodePacked("withdrawToken", _token, _receiver, _amount)
        );
        _validateAction(action);
        _validateAuthorization(action);
        delete pendingActions[action];
        delete signedActions[msg.sender][action];
        IERC20(_token).transfer(_receiver, _amount);
    }

    function withdrawSLP(
        address _token,
        uint256 _amount,
        uint256 _minOut,
        address _reciever
    ) external onlySignerAndOwner {
        bytes32 action = keccak256(
            abi.encodePacked("withdrawSLP", _token, _amount, _minOut, _reciever)
        );
        _validateAction(action);
        _validateAuthorization(action);
        delete pendingActions[action];
        delete signedActions[msg.sender][action];
        rewardRouter.unstakeAndRedeemSlp(_token, _amount, _minOut, _reciever);
    }

    function _setPendingAction(bytes32 _action) private {
        require(!pendingActions[_action], "Timelock: action already signalled");
        pendingActions[_action] = true;
        emit SignalPendingAction(_action);
    }

    function _validateAction(bytes32 _action) private view {
        require(pendingActions[_action], "TokenManager: action not signalled");
    }

    function _validateAuthorization(bytes32 _action) private view {
        require(
            signedActions[msg.sender][_action] >= minSignaturesRequired,
            "TokenManager: insufficient authorization"
        );
    }

    //gap
    uint256[50] private __gap;
}