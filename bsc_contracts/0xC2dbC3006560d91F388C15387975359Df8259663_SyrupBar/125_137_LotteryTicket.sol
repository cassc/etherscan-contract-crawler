// SPDX-License-Identifier: MIT

//This is the test contract
pragma solidity 0.7.4;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract LotteryTicket is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant pauseCountdown = 30 minutes;

    uint256 public startTime;
    uint256 public supplyPerRound;
    address public vault;
    
    mapping(uint256 => uint256) public exchangeTotalPerRound;
    mapping(address => uint256) public ticketPriceUsingToken;
    mapping(address => mapping(uint256 => uint256)) public userExhangeTotalPerRound;

    event NewSupplyPerRound(uint256 oldTotal, uint256 newTotal);
    event NewVault(address oldVault, address newVault);
    event ExchangeLotteryTicket(address account, uint256 amount, address token, uint256 );
    event NewTicketPrice(address token, uint256 oldPrice, uint256 newPrice);


    function setTicketPrice(address _token, uint256 _ticketPrice) external onlyOwner {
        require(_token != address(0), "token cannot be zero address, check it");
        emit NewTicketPrice(_token, ticketPriceUsingToken[_token], _ticketPrice);
        ticketPriceUsingToken[_token] = _ticketPrice;
    }

    function setSupplyPerRound(uint256 _supplyPerRound) external onlyOwner {
        emit NewSupplyPerRound(supplyPerRound, _supplyPerRound);
        supplyPerRound = _supplyPerRound;
    }

    function setVault(address _vault) external onlyOwner {
        require(_vault != address(0), "vault cannot be zero address");
        emit NewVault(vault, _vault);
        vault = _vault;
    }

    function currentRound() public view returns(uint256) {
        return now().sub(startTime).div(1 weeks).add(1);
    }

    constructor(address _vault, uint256 _startTime, uint256 _supplyPerRound) {
        startTime = _startTime;
        emit NewVault(vault, _vault);
        vault = _vault;
        emit NewSupplyPerRound(supplyPerRound, _supplyPerRound);
        supplyPerRound = _supplyPerRound;
    }

    function exchange(address token,  uint number) external nonReentrant {
        address user = msg.sender;
        uint _round = currentRound();
        uint nextRound = now().add(pauseCountdown).sub(startTime).div(1 weeks).add(1);
        require(nextRound == _round, "exchange on hold");
        require(ticketPriceUsingToken[token] > 0, "unsupported token");
        uint amount = ticketPriceUsingToken[token].mul(number);
        IERC20(token).safeTransferFrom(user, vault, amount);
        exchangeTotalPerRound[_round] = exchangeTotalPerRound[_round].add(number);
        require(exchangeTotalPerRound[_round] <= supplyPerRound, "exceeded maximum limit");
        userExhangeTotalPerRound[user][_round] = userExhangeTotalPerRound[user][_round].add(number);
        emit ExchangeLotteryTicket(user, number, token, amount);
    }

    uint public extraTime;

    function fastForward(uint256 s) external onlyOwner {
        extraTime = extraTime.add(s);
    }

    function now() public view returns(uint256) {
        return block.timestamp.add(extraTime);
    }
}