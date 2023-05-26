// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/ILayerZeroReceiver.sol";
import "./interfaces/ILayerZeroUserApplicationConfig.sol";
import "./interfaces/ILayerZeroEndpoint.sol";
import "./LZ/LzApp.sol";
import "./LZ/NonBlockingLzApp.sol";
import "./Sign.sol";

contract StakingRewardsProxy is NonblockingLzApp, Sign {
    using ERC165Checker for address;
    using SafeERC20 for IERC20;

    bytes32 constant internal ACTION_STAKE = "stake";
    bytes32 constant internal ACTION_WITHDRAW = "withdraw";
    bytes32 constant internal ACTION_CLAIM = "claim";

    uint16 public immutable controllerChainId = 12;
    uint8 public paused;
    address public controller;
    address public fund;
    IERC20 public immutable stakingToken;

    struct GasAmounts {
        uint256 proxyWithdraw;
        uint256 proxyClaim;
        uint256 controllerStake;
        uint256 controllerWithdraw;
        uint256 controllerClaim;
    }

    GasAmounts public gasAmounts;
    mapping(uint64 => bool) private nonceRegistry;
    mapping(address => bytes32) public actionInQueue;
    mapping(address => bytes) public signatures;
    mapping(address => uint256) public balances;

    event StakeInitiated(address indexed user, uint256 amount);
    event WithdrawalInitiated(address indexed user);
    event ClaimInitiated(address indexed user);

    event Withdrawn(address indexed user, uint256 amount);
    event Claimed(address indexed user, uint256 amount);

    modifier notPaused() {
        require(paused == 0, "RadarStakingProxy: Contract is paused");
        _;
    }

    modifier notInQueue(address account) {
        require(actionInQueue[account] == bytes32(0x0), "RadarStakingProxy: In queue already! Wait till the callback comes.");
        _;
    }

    constructor(address _owner, address _endpoint, address _fund, address _controller, address _stakingToken) NonblockingLzApp(_endpoint) {
        transferOwnership(_owner);
        require(_controller != address(0), "RadarStakingProxy: invalid controller address");
        require(_stakingToken != address(0), "RadarStakingProxy: invalid staking token address");
        require(_fund != address(0), "RadarStakingProxy: invalid fund address");

        controller = _controller;
        fund = _fund;
        stakingToken = IERC20(_stakingToken);

        gasAmounts.proxyWithdraw = 260000;
        gasAmounts.proxyClaim = 240000;
        gasAmounts.controllerStake = 280000;
        gasAmounts.controllerWithdraw = 360000;
        gasAmounts.controllerClaim = 380000;
    }

    function estimateFees(bytes32 _action, uint256 _amount, bytes memory _signature, uint256 controllerGas) public view returns (uint256 messageFee){
        bytes memory adapterParams = getAdapterParams(_action, controllerGas);

        bytes memory payload = abi.encode(msg.sender, _action, _amount, _signature);
        // get the fees we need to pay to LayerZero for message delivery
        (messageFee,) = lzEndpoint.estimateFees(controllerChainId, controller, payload, false, adapterParams);
    }

    function getGasAmount(bytes32 _action, bool _isProxy) internal view returns (uint256 gasAmount) {
        gasAmount = 0;
        if (_isProxy) {
            if (_action == ACTION_CLAIM) {
                gasAmount =  gasAmounts.proxyClaim;
            } else if (_action == ACTION_WITHDRAW) {
                gasAmount =  gasAmounts.proxyWithdraw;
            }
        } else {
            if (_action == ACTION_CLAIM) {
                gasAmount = gasAmounts.controllerClaim;
            } else if (_action == ACTION_WITHDRAW) {
                gasAmount =  gasAmounts.controllerWithdraw;
            } else if (_action == ACTION_STAKE) {
                gasAmount =  gasAmounts.controllerStake;
            }
        }
        require(gasAmount > 0, "StakingRewardsProxy: unable to retrieve gas amount");
    }

    function getAdapterParams(bytes32 _action, uint256 controllerGas) internal view returns (bytes memory adapterParams) {
        if (_action == ACTION_STAKE) {
            uint16 version = 1;
            uint256 gasForDestinationLzReceive = getGasAmount(_action, false);
            adapterParams = abi.encodePacked(version, gasForDestinationLzReceive);
        } else {
            uint16 version = 2;
            uint256 gasForDestinationLzReceive = getGasAmount(_action, false);

            adapterParams = abi.encodePacked(version, gasForDestinationLzReceive, controllerGas, controller);
        }
    }

    function _sendMessage(bytes32 _action, uint256 _amount, bytes memory _signature, uint256 controllerGas) internal {
        require(msg.value > 0, "StakingRewardsProxy: msg.value is 0");

        if (_action == ACTION_STAKE) {
            StakeData memory actionData = StakeData(bytes32ToString(_action), _amount);
            verify(msg.sender, actionData, _signature);
        } else {
            ClaimWithdrawData memory actionData = ClaimWithdrawData(bytes32ToString(_action));
            verify(msg.sender, actionData, _signature);
        }

        bytes memory payload = abi.encode(msg.sender, _action, _amount, _signature);

        // use adapterParams v1 to specify more gas for the destination
        bytes memory adapterParams = getAdapterParams(_action, controllerGas);

        // get the fees we need to pay to LayerZero for message delivery
        (uint256 messageFee,) = lzEndpoint.estimateFees(controllerChainId, controller, payload, false, adapterParams);

        require(msg.value >= messageFee, "StakingRewardsProxy: msg.value < messageFee");

        _lzSend(// {value: messageFee} will be paid out of this contract!
            controllerChainId, // destination chainId
            payload, // abi.encode()'ed bytes
            payable(msg.sender), // refund address (LayerZero will refund any extra gas back to caller of send()
            address(0x0), // future param, unused for this example
            adapterParams // v1 adapterParams, specify custom destination gas qty
        );
    }

    function stake(uint256 _amount, bytes memory _signature) external payable notPaused {
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        balances[msg.sender] += _amount;

        uint256 controllerGas = 0;
        emit StakeInitiated(msg.sender, _amount);
        _sendMessage(ACTION_STAKE, _amount, _signature, controllerGas);
    }

    function withdraw(bytes memory _signature, uint256 _controllerGas) external payable notPaused notInQueue(msg.sender) {
        require(balances[msg.sender] > 0, "StakingRewardsProxy: Nothing to withdraw");

        actionInQueue[msg.sender] = ACTION_WITHDRAW;
        signatures[msg.sender] = _signature;
        uint256 amount = 0;
        emit WithdrawalInitiated(msg.sender);
        _sendMessage(ACTION_WITHDRAW, amount, _signature, _controllerGas);
    }

    function claim(bytes memory _signature, uint256 _controllerGas) external payable notPaused notInQueue(msg.sender) {
        actionInQueue[msg.sender] = ACTION_CLAIM;
        signatures[msg.sender] = _signature;
        uint256 amount = 0;
        emit ClaimInitiated(msg.sender);
        _sendMessage(ACTION_CLAIM, amount, _signature, _controllerGas);
    }

    function _nonblockingLzReceive(
        uint16, /*_srcChainId*/
        bytes memory, /*_srcAddress*/
        uint64 _nonce,
        bytes memory _payload
    ) internal override notPaused {
        require(!nonceRegistry[_nonce], "This nonce was already processed");

        (address payable target, uint256 rewardAmount, uint256 withdrawAmount, bytes memory signature) = abi.decode(_payload, (address, uint256, uint256, bytes));

        ClaimWithdrawData memory actionData = ClaimWithdrawData(bytes32ToString(actionInQueue[target]));
        verify(target, actionData, signature);

        require(actionInQueue[target] != bytes32(0x0), "StakingRewardsProxy: No claim or withdrawal is in queue for this address");
        require(keccak256(signatures[target]) == keccak256(signature), "StakingRewardsProxy: Invalid signature");

        if (withdrawAmount > 0) {
            require(balances[target] > 0, "StakingRewardsProxy: Invalid withdrawal, no deposits done");
            require(stakingToken.balanceOf(address(this)) >= withdrawAmount, "StakingRewardsProxy: Insufficient proxy token balance");

            stakingToken.safeTransfer(target, withdrawAmount);
            balances[target] = balances[target] - withdrawAmount;
            emit Withdrawn(target, withdrawAmount);
        }

        if (rewardAmount > 0) {
            require(stakingToken.balanceOf(fund) >= rewardAmount, "StakingRewardsProxy: Insufficient fund token balance");

            stakingToken.safeTransferFrom(fund, target, rewardAmount);
            emit Claimed(target, rewardAmount);
        }

        nonceRegistry[_nonce] = true;

        delete actionInQueue[target];
        delete signatures[target];
    }

    function emergency() external onlyOwner {
        paused = 1;

        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "StakingRewardsProxy: unable to send value, recipient may have reverted");
    }

    function emergencyWithdraw() external {
        require(paused == 1, "StakingRewardsProxy: contract is not paused");
        require(balances[msg.sender] > 0, "StakingRewardsProxy: Invalid withdrawal, no deposits done");

        uint256 balance = balances[msg.sender];
        balances[msg.sender] = 0;
        stakingToken.safeTransfer(msg.sender, balance);
        emit Withdrawn(msg.sender, balance);
    }

    function setGasAmounts(uint256 _proxyWithdraw, uint256 _proxyClaim, uint256 _controllerStake, uint256 _controllerWithdraw, uint256 _controllerClaim) public onlyOwner {
        if (_proxyWithdraw > 0) {
            gasAmounts.proxyWithdraw = _proxyWithdraw;
        }

        if (_proxyClaim > 0) {
            gasAmounts.proxyClaim = _proxyClaim;
        }

        if (_controllerStake > 0) {
            gasAmounts.controllerStake = _controllerStake;
        }

        if (_controllerWithdraw > 0) {
            gasAmounts.controllerWithdraw = _controllerWithdraw;
        }

        if (_controllerClaim > 0) {
            gasAmounts.controllerClaim = _controllerClaim;
        }
    }

    receive() external payable {}
}