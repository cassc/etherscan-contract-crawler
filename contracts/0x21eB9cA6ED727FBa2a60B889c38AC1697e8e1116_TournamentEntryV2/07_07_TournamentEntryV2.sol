// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract TournamentEntryV2 is Ownable {
    ERC20Burnable private immutable _token;

    uint256 public startsAt;
    uint256 public endsAt;
    uint256 public registerFee;
    uint256 public maxEntry;

    event Register(address indexed participants, uint256 indexed group);

    mapping(uint256 => uint256) public groupCount;

    // map[group][address] = bool, group(1~60)
    mapping(uint256 => mapping(address => bool)) public isRegistered;


    constructor(address _tokenAddress) {
        // 2022년 6월 21일 화요일 오후 8:00:00 GMT+09:00
        startsAt = 1655809200;
        // 2022년 6월 21일 화요일 오후 10:00:00 GMT+09:00
        endsAt = 1655816400;

        // Mon, Wed, Fri : 5 * 1e18, Sat, Sun : 50 * 1e18
        registerFee = 5 * 1e18;
        _token = ERC20Burnable(_tokenAddress);

        // 그룹 카운트 초기 값이 1이므로 +1을 해준다.
        maxEntry = 128 + 1;

        for (uint256 i = 0; i < 60; i++) {
            groupCount[i] = 1;
        }
    }

    function register(uint256[] calldata groups) external {
        uint256 totalFee = groups.length * registerFee;
        require(block.timestamp >= startsAt && block.timestamp < endsAt, "TournamentEntryV2: Invalid tournament registration period.");

        for (uint256 i = 0; i < groups.length; i++)
        {
            _register(groups[i]);
        }
        _token.transferFrom(msg.sender, address(this), totalFee);
    }

    function _register(uint256 group) internal {
        require(isRegistered[group][msg.sender] == false, "TournamentEntryV2: Already registered.");
        require(groupCount[group] < maxEntry, "TournamentEntryV2: Out of register ticket.");

        groupCount[group]++;
        isRegistered[group][msg.sender] = true;
        emit Register(msg.sender, group);
    }

    function length(uint256 group) external view returns (uint256) {
        return groupCount[group] - 1;
    }

    function withdraw() external onlyOwner {
        _token.transfer(owner(), _token.balanceOf(address(this)));
    }

    function setStartsAt(uint256 _startsAt) external onlyOwner {
        startsAt = _startsAt;
    }

    function setEndsAt(uint256 _endsAt) external onlyOwner {
        endsAt = _endsAt;
    }

    function setRegisterFee(uint256 _registerFee) external onlyOwner {
        registerFee = _registerFee;
    }

    function setMaxParticipants(uint256 _maxEntry) external onlyOwner {
        maxEntry = _maxEntry + 1;
    }

    function burnFee() external onlyOwner {
        _token.burn(_token.balanceOf(address(this)) * uint256(15) / uint256(100));
    }
}