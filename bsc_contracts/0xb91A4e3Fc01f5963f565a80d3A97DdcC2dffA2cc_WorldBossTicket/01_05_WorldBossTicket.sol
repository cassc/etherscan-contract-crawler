// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WorldBossTicket is Ownable {
    using SafeMath for uint256;
    IERC20 public dnlContract;

    event TicketBought(
        address indexed buyer,
        uint256 indexed bossId,
        uint256 indexed ticketQuantity
    );

    uint256[] public ticketQuantityMilestones;
    uint256[] public ticketDiscounts;

    struct Boss {
        uint256 bossId;
        uint256 ticketPrice;
    }

    mapping(uint256 => Boss) public bosses;
    uint256 constant denominator = 10000;
    uint256 public minTicketQuantity = 10;
    mapping(address => mapping(uint256 => uint256)) public addressToBossTickets;

    constructor(IERC20 _dnlContract) {
        Boss memory boss1 = Boss(1, 200 ether);
        Boss memory boss2 = Boss(2, 250 ether);
        Boss memory boss3 = Boss(3, 300 ether);
        Boss memory boss4 = Boss(4, 350 ether);
        Boss memory boss5 = Boss(5, 400 ether);
        
        bosses[1] = boss1;
        bosses[2] = boss2;
        bosses[3] = boss3;
        bosses[4] = boss4;
        bosses[5] = boss5;

        ticketQuantityMilestones = [0, 50, 100, 500, 1000];
        ticketDiscounts = [0, 200, 500, 1000, 1500];

        dnlContract = _dnlContract;
    }

    function updateTicketPrice(uint256 _bossId, uint256 _price)
        external
        onlyOwner
    {
        Boss storage boss = bosses[_bossId];
        boss.ticketPrice = _price;
    }

    function setBoss(uint256 _bossId, uint256 _ticketPrice) external onlyOwner {
        Boss memory boss = Boss(_bossId, _ticketPrice);
        bosses[_bossId] = boss;
    }

    function setMinTicketQuantity(uint256 _minTicketQuantity)
        external
        onlyOwner
    {
        minTicketQuantity = _minTicketQuantity;
    }

    function setTicketDiscount(
        uint256[] memory _ticketQuantityMilestones,
        uint256[] memory _ticketDiscounts
    ) external onlyOwner {
        require(
            ticketQuantityMilestones.length == ticketDiscounts.length,
            "Not the same length"
        );
        ticketQuantityMilestones = _ticketQuantityMilestones;
        ticketDiscounts = _ticketDiscounts;
    }

    function calculatePrice(uint256 _bossId, uint256 _ticketQuantity)
        public
        view
        returns (uint256)
    {
        require(bosses[_bossId].ticketPrice > 0, "Boss has not exist");
        uint256 ticketPrice = bosses[_bossId].ticketPrice;
        uint256 milestoneIndex = 0;
        for (uint256 i = ticketQuantityMilestones.length - 1; i >= 0; i--) {
            if (_ticketQuantity >= ticketQuantityMilestones[i]) {
                milestoneIndex = i;
                break;
            }
        }
        uint256 discountPercent = ticketDiscounts[milestoneIndex];
        return
            ticketPrice
                .mul(_ticketQuantity)
                .mul(denominator.sub(discountPercent))
                .div(denominator);
    }

    function buyTickets(uint256 _bossId, uint256 _ticketQuantity) external {
        require(
            _ticketQuantity >= minTicketQuantity,
            "Ticket quantity is too low"
        );
        uint256 spentAmount = calculatePrice(_bossId, _ticketQuantity);
        require(
            dnlContract.transferFrom(msg.sender, address(this), spentAmount),
            "DNL transfer failed"
        );
        addressToBossTickets[msg.sender][_bossId] = addressToBossTickets[
            msg.sender
        ][_bossId].add(_ticketQuantity);
        emit TicketBought(msg.sender, _bossId, _ticketQuantity);
    }

    function withdrawERC20(address _to, uint256 _amount) external onlyOwner {
        require(dnlContract.transfer(_to, _amount), "DNL transfer failed");
    }
}