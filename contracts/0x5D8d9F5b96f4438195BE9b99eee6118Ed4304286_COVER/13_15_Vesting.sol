// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "./utils/SafeMath.sol";
import "./ERC20/SafeERC20.sol";

/**
 * @title COVER token contract
 * @author Alan
 */
contract Vesting {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant START_TIME = 1605830400; // 11/20/2020 12 AM UTC
    uint256 public constant MIDDLE_TIME = 1621468800; // 5/20/2021 12 AM UTC
    uint256 public constant END_TIME = 1637366400; // 11/20/2021 12 AM UTC

    mapping (address => uint256) private _vested;
    mapping (address => uint256) private _total;

    constructor() {
        // TODO: change addresses to team addresses
        _total[address(0x406a0c87A6bb25748252cb112a7a837e21aAcD98)] = 2700 ether;
        _total[address(0x3e677718f8665A40AC0AB044D8c008b55f277c98)] = 2700 ether;
        _total[address(0x094AD38fB69f27F6Eb0c515ad4a5BD4b9F9B2996)] = 2700 ether;
        _total[address(0xD4C8127AF1dE3Ebf8AB7449aac0fd892b70f3b45)] = 1620 ether;
        _total[address(0x82BBd2F08a59f5be1B4e719ff701e4D234c4F8db)] = 720 ether;
        _total[address(0xF00Bf178E3372C4eF6E15A1676fd770DAD2aDdfB)] = 360 ether;
        // _total[address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8)] = 2700 ether;
        // _total[address(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC)] = 2700 ether;
        // _total[address(0x90F79bf6EB2c4f870365E785982E1f101E93b906)] = 2700 ether;
        // _total[address(0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65)] = 1620 ether;
        // _total[address(0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc)] = 720 ether;
        // _total[address(0x976EA74026E726554dB657fA54763abd0C3a0aa9)] = 360 ether;
    }

    function vest(IERC20 token) external {
        require(block.timestamp >= START_TIME, "Vesting: !started");
        require(_total[msg.sender] > 0, "Vesting: not team");

        uint256 toBeReleased = releasableAmount(msg.sender);
        require(toBeReleased > 0, "Vesting: all vested");

        _vested[msg.sender] = _vested[msg.sender].add(toBeReleased);
        token.safeTransfer(msg.sender, toBeReleased);
    }

    function releasableAmount(address _addr) public view returns (uint256) {
        return unlockedAmount(_addr).sub(_vested[_addr]);
    }

    function unlockedAmount(address _addr) public view returns (uint256) {
        if (block.timestamp <= MIDDLE_TIME) {
            uint256 duration = MIDDLE_TIME.sub(START_TIME);
            uint256 firstHalf = _total[_addr].mul(2).div(3);
            uint256 timePassed = block.timestamp.sub(START_TIME);
            return firstHalf.mul(timePassed).div(duration);
        } else if (block.timestamp > MIDDLE_TIME && block.timestamp <= END_TIME) {
            uint256 duration = END_TIME.sub(MIDDLE_TIME);
            uint256 firstHalf = _total[_addr].mul(2).div(3);
            uint256 secondHalf = _total[_addr].div(3);
            uint256 timePassed = block.timestamp.sub(MIDDLE_TIME);
            return firstHalf.add(secondHalf.mul(timePassed).div(duration));
        } else {
            return _total[_addr];
        }
    }

}