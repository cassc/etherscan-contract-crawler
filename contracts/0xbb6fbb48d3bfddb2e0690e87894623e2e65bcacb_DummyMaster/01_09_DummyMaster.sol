// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./DummyMasterToken.sol";

interface IMasterChef {
	function deposit(uint256, uint256) external;

	function withdraw(uint256, uint256) external;

	function userInfo(uint256, address) external view returns (uint256, uint256);
}

contract DummyMaster {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;

	IERC20 public immutable TOKEN;
	IMasterChef public masterchef;
	IERC20 public SDT;

	address public governance;
	uint256 public pid;
	uint256 public constant totalWeight = 10000;

	address[] internal _endAddresses;
	mapping(address => bool) public existingEndAddresses;
	mapping(address => uint256) public weights;

	function endAddresses() external view returns (address[] memory) {
		return _endAddresses;
	}

	constructor(address _masterchef, address _SDT) public {
		TOKEN = IERC20(address(new DummyMasterToken()));
		masterchef = IMasterChef(_masterchef);
		SDT = IERC20(_SDT);
		governance = msg.sender;
	}

	function setGovernance(address _governance) public {
		require(msg.sender == governance, "!governance");
		governance = _governance;
	}

	function _vote(address[] memory _addresses, uint256[] memory _weights) internal {
		uint256 _count = _addresses.length;
		uint256 _totalWeight = 0;

		require(_count == _endAddresses.length, "you should vote for every addresses");

		for (uint256 i = 0; i < _count; i++) {
			address _endAddress = _addresses[i];
			uint256 _endAddressWeight = _weights[i];

			if (_endAddress != address(0x0)) {
				weights[_endAddress] = _endAddressWeight;
				_totalWeight = _totalWeight.add(_endAddressWeight);
			}
		}

		require(_totalWeight == totalWeight, "total weight != 10000");
	}

	function vote(address[] calldata _addresses, uint256[] calldata _weights) external {
		require(msg.sender == governance, "!gov");
		require(_addresses.length == _weights.length, "_addresses.length != _weights.length");
		_vote(_addresses, _weights);
	}

	function addEndAddress(address _endAddress) external {
		require(msg.sender == governance, "!gov");
		require(existingEndAddresses[_endAddress] == false, "exists");
		existingEndAddresses[_endAddress] = true;
		_endAddresses.push(_endAddress);
	}

	// Sets MasterChef PID
	function setPID(uint256 _pid) external {
		require(msg.sender == governance, "!gov");
		pid = _pid;
	}

	function deposit() public {
		require(msg.sender == governance, "!gov");
		require(pid > 0, "pid not initialized");
		IERC20 _token = TOKEN;
		uint256 _balance = _token.balanceOf(address(this));

		_token.safeApprove(address(masterchef), 0);
		_token.safeApprove(address(masterchef), _balance);
		masterchef.deposit(pid, _balance);
	}

	function distribute() external {
		require(msg.sender == governance, "!gov");
		masterchef.deposit(pid, 0);
		uint256 _balance = SDT.balanceOf(address(this));

		if (_balance > 0 && totalWeight > 0) {
			for (uint256 i = 0; i < _endAddresses.length; i++) {
				address _endAddress = _endAddresses[i];
				uint256 _reward = _balance.mul(weights[_endAddress]).div(totalWeight);
				if (_reward > 0) {
					SDT.safeTransfer(_endAddress, _reward);
				}
			}
		}
	}
}