// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IMintableToken.sol";

struct VestingSchedule {
	uint256 amount;
	uint256 startDate;
	uint256 endDate;
}

contract Vesting is Ownable {
	bytes32 public immutable name; // A string that can be used to identify this vesting schedule to clients.
	IMintableToken public immutable token; // Token
	mapping(address => VestingSchedule[]) public schedule; // Vesting Schedule
	mapping(address => uint256) public previouslyClaimed; // Amounts users have claimed.

	constructor(address _token, bytes32 _name) {
		require(_token != address(0), 'Vesting: invalid token address');
		require(_name != 0, 'Vesting: invalid name');

		name = _name;
		token = IMintableToken(_token);
	}

	function addToSchedule(address[] memory addresses, VestingSchedule[] memory entries) external onlyOwner {
		require(entries.length > 0, 'Vesting: no entries');
		require(addresses.length == entries.length, 'Vesting: length mismatch');

		uint256 length = addresses.length; // Gas optimisation
		for (uint256 i = 0; i < length; i++) {
			address to = addresses[i];

			require(to != address(0), 'Vesting: to address must not be 0');

			schedule[to].push(entries[i]);

			emit ScheduleChanged(to, schedule[to]);
		}
	}

	event ScheduleChanged(address indexed to, VestingSchedule[] newSchedule);

	function scheduleLength(address to) public view returns (uint256) {
		return schedule[to].length;
	}

	function withdrawalAmount(address to) public view returns (uint256) {
		uint256 total; // Note: Not explicitly initialising to zero to save gas, default value of uint256 is 0.

		// Calculate the total amount the user is entitled to at this point.
		VestingSchedule[] memory entries = schedule[to];
		uint256 length = entries.length;
		for (uint256 i = 0; i < length; i++) {
			VestingSchedule memory entry = entries[i];

			if (entry.startDate <= block.timestamp) {
				if (entry.endDate <= block.timestamp) {
					total += entry.amount;
				} else {
					uint256 totalTime = entry.endDate - entry.startDate;
					uint256 currentTime = block.timestamp - entry.startDate;
					total += entry.amount * currentTime / totalTime;
				}
			}
		}

		uint256 claimed = previouslyClaimed[to];
		return claimed >= total ? 0 : total - claimed;
	}

	function withdraw() public {
		uint256 available = withdrawalAmount(msg.sender);

		require(available > 0, 'Vesting: no amount to withdraw');

		previouslyClaimed[msg.sender] += available;
		token.mint(msg.sender, available);
		emit Vested(msg.sender, available);
	}

	event Vested(address indexed who, uint256 amount);
}