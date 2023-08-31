/*

88888888888                           .d8888b.            888888                                   
    888                              d88P  "88b             "88b                                   
    888                              Y88b. d88P              888                                   
    888   .d88b.  88888b.d88b.        "Y8888P"               888  .d88b.  888d888 888d888 888  888 
    888  d88""88b 888 "888 "88b      .d88P88K.d88P           888 d8P  Y8b 888P"   888P"   888  888 
    888  888  888 888  888  888      888"  Y888P"            888 88888888 888     888     888  888 
    888  Y88..88P 888  888  888      Y88b .d8888b            88P Y8b.     888     888     Y88b 888 
    888   "Y88P"  888  888  888       "Y8888P" Y88b          888  "Y8888  888     888      "Y88888 
                                                           .d88P                               888 
                                                         .d88P"                           Y8b d88P 
                                                        888P"                              "Y88P"  

Website: https://tomjerryeth.com
Telegram: https://t.me/TomJerryETH
Twitter: https://twitter.com/TomJerryETH

*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./interfaces/ITomJerry.sol";
import "./interfaces/IPool.sol";

contract TomJerryOracle is AccessControl {
    using SafeMath for uint;

    struct Round {
        bool exists;
        uint id;
        address winner;
        uint timestamp;
    }

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    ITomJerry public immutable tom;
    ITomJerry public immutable jerry;
    IPool public immutable tomPool;
    IPool public immutable jerryPool;
    uint public minimumInterval = 3 hours;
    bool public isDiscountEnabled;

    uint public roundId;
    mapping (uint => Round) public rounds;

    address private immutable admin;

    constructor (
        address _tom,
        address _jerry,
        address _tomPool,
        address _jerryPool
    ) {
        tom = ITomJerry(_tom);
        jerry = ITomJerry(_jerry);

        tomPool = IPool(_tomPool);
        jerryPool = IPool(_jerryPool);

        admin = _msgSender();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MANAGER_ROLE, admin);
    }

    function declare() external onlyRole(MANAGER_ROLE) {
        require (
            rounds[roundId].timestamp.add(minimumInterval) < block.timestamp,
            "Minimum interval didn't pass"
        );

        roundId++;
        address winner = getWinner();

        Round memory round = Round(
            true,
            roundId,
            winner,
            block.timestamp
        );

        if (winner == address(tom)) {
            tomPool.distribute();
            if (isDiscountEnabled) {
                tom.setIsDiscounted(true);
                jerry.setIsDiscounted(false);
            }
        } else {
            jerryPool.distribute();
            if (isDiscountEnabled) {
                jerry.setIsDiscounted(true);
                tom.setIsDiscounted(false);
            }
        }

        rounds[roundId] = round;

        emit Declared(roundId, winner, block.timestamp);
    }

    /** VIEW FUNCTIONS */

    function getWinner() public view returns (address) {
        uint tomMarketCap = tom.getMarketCap();
        uint jerryMarketCap = jerry.getMarketCap();

        if (tomMarketCap < jerryMarketCap) {
            return address(tom);
        } else {
            return address(jerry);
        }
    }

    function getRoundData(uint _roundId) external view returns (Round memory round) {
        return rounds[_roundId];
    }

    /** RESTRICTED FUNCTIONS */

    function setMinimumInterval(uint _minimumInterval) external onlyRole(MANAGER_ROLE) {
        minimumInterval = _minimumInterval;
    }

    function setDiscountEnabled(bool _isDiscountEnabled) external onlyRole(MANAGER_ROLE) {
        isDiscountEnabled = _isDiscountEnabled;
    }

    function recoverTokens(address _token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20(_token).transfer(admin, IERC20(_token).balanceOf(address(this)));
    }

    /** EVENTS */

    event Declared(
        uint roundId,
        address indexed winner,
        uint timestamp
    );
}