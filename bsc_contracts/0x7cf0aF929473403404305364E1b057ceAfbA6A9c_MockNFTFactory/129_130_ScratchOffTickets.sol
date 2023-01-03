// SPDX-License-Identifier: MIT

//This is the test contract
pragma solidity 0.7.4;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract ScratchOffTickets is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    
    uint256 public constant pauseCountdown = 1 hours;

    address public verifier;
    mapping(address => uint256) public exhangeTotalPerUser;
    uint256 public startTime;
    uint256 public supplyPerRound;
    uint256 public ticketPrice;
    mapping(uint256 => uint256) public exhangeTotalPerRound;

    event NewSupplyPerRound(uint256 oldTotal, uint256 newTotal);
    event NewVerifier(address oldVerifier, address newVerifier);
    event ExchangeScratchOff(address account, uint256 amount);
    event NewTicketPrice(uint256 oldPrice, uint256 newPrice);

    function setVerifier(address _verifier) external onlyOwner {
        emit NewVerifier(verifier, _verifier);
        verifier = _verifier;
    }

    function setTicketPrice(uint256 _ticketPrice) external onlyOwner {
        emit NewTicketPrice(ticketPrice, _ticketPrice);
        ticketPrice = _ticketPrice;
    }

    function setSupplyPerRound(uint256 _supplyPerRound) external onlyOwner {
        emit NewSupplyPerRound(supplyPerRound, _supplyPerRound);
        supplyPerRound = _supplyPerRound;
    }

    function currentRound() public view returns(uint256) {
        return now().sub(startTime).div(1 weeks).add(1);
    }

    constructor(uint256 _ticketPrice, uint256 _startTime, uint256 _supplyPerRound, address _verifier) {
        startTime = _startTime;
        emit NewTicketPrice(ticketPrice, _ticketPrice);
        ticketPrice = _ticketPrice;
        emit NewSupplyPerRound(supplyPerRound, _supplyPerRound);
        supplyPerRound = _supplyPerRound;
        emit NewVerifier(verifier, _verifier);
        verifier = _verifier;
    }

    function getEncodePacked(address user, uint balance) public pure returns (bytes memory) {
        return abi.encodePacked(user, balance);
    }

    function getHash(address user, uint balance) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(user, balance));
    }

    function getHashToSign(address user, uint balance) external pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(user, balance))));
    }

    function verify(address user, uint balance, uint8 v, bytes32 r, bytes32 s) public view returns (bool) {
        return ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(user, balance)))), v, r, s) == verifier;
    }

    function exchange(uint balance, uint number, uint8 v, bytes32 r, bytes32 s) external {
        address user = msg.sender;
        require(verify(user, balance, v, r, s), "illegal verifier.");
        uint _round = currentRound();
        uint nextRound = now().add(pauseCountdown).sub(startTime).div(1 weeks).add(1);
        require(nextRound == _round, "exchange on hold");
        uint amount = ticketPrice.mul(number);
        exhangeTotalPerRound[_round] = exhangeTotalPerRound[_round].add(number);
        require(exhangeTotalPerRound[_round] <= supplyPerRound, "exceeded maximum limit");
        require(exhangeTotalPerUser[user].add(amount) <= balance, "insufficient balance");
        exhangeTotalPerUser[user] = exhangeTotalPerUser[user].add(amount);
        emit ExchangeScratchOff(user, number);
    }

    uint256 public extraTime;

    function fastForward(uint256 s) external onlyOwner {
        extraTime = extraTime.add(s);
    }

    function now() public view returns(uint256) {
        return block.timestamp.add(extraTime);
    }
}