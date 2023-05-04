// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./libraries/ABDKMathQuad.sol";

import "./ArtikTreasury.sol";
import "./ArtikProjectManager.sol";
import "./ArtikProjectManagerV2.sol";
import "./ArtikTreasuryV2.sol";
import "./ArtikTreasuryV1.sol";
import "./ArtikProjectManagerV1.sol";

import "./TreasuryV1.sol";
import "./ProjectManagerV1.sol";
import "./TreasuryV0.sol";
import "./ProjectManagerV0.sol";

contract StakeManagerV0 is Initializable {
    using SafeMath for uint256;

    address private artikToken;
    address payable private admin;

    ArtikTreasury private treasury;
    ArtikProjectManager private artikProjectManager;

    mapping(address => mapping(uint256 => Stake)) private stakedBalance;
    struct Stake {
        uint256 balance;
        uint256 time;
        bool staked;
    }

    address[] public shareholders;
    mapping(address => uint256) private shareholderIndexes;
    uint256 private shareholderCount;

    bool public penaltyIsActive;
    ArtikProjectManagerV2 private artikProjectManagerV2;
    ArtikTreasuryV2 private artikTreasuryV2;
    ArtikTreasuryV1 private artikTreasuryV1;
    ArtikProjectManagerV1 private artikProjectManagerV1;

    TreasuryV1 private treasuryV1;
    ProjectManagerV1 private projectManagerV1;
    TreasuryV0 private treasuryV0;
    ProjectManagerV0 private projectManagerV0;

    function initialize(
        address _tokenAddress,
        address _treasuryAddress,
        address _projectManagerAddr
    ) public initializer {
        artikToken = _tokenAddress;
        treasuryV0 = TreasuryV0(payable(_treasuryAddress));
        projectManagerV0 = ProjectManagerV0(_projectManagerAddr);

        shareholderCount = 0;
        admin = payable(msg.sender);

        penaltyIsActive = true;
    }

    function configureManagers(
        address _projectManagerAddr,
        address _treasuryAddr
    ) external {
        require(msg.sender == admin);
        projectManagerV0 = ProjectManagerV0(_projectManagerAddr);
        treasuryV0 = TreasuryV0(payable(_treasuryAddr));
    }

    function managePenalty(bool _active) external {
        require(msg.sender == admin);
        penaltyIsActive = _active;
    }

    function getStakedBalance(
        address _shareholder,
        uint256 _roundNumber
    ) external view returns (uint256) {
        require(_shareholder != address(0x0));
        require(_roundNumber > 0);
        return stakedBalance[_shareholder][_roundNumber].balance;
    }

    function calculateStakingPercentageTime(
        address _shareholder,
        uint256 _roundNumber
    ) external view returns (uint256) {
        require(_shareholder != address(0x0));
        require(_roundNumber > 0);

        uint256 diff = (treasuryV0.getAirdropDate(_roundNumber) -
            /*stakedBalance[_shareholder].time) /
            60 /
            60 /
            24;*/
            stakedBalance[_shareholder][_roundNumber].time);

        uint256 percentage = 1000000;
        if (penaltyIsActive && diff < 7 * 60 * 60 * 24) {
            percentage = mulDiv(diff, 1000000, 7 * 60 * 60 * 24);
        }
        return percentage;
    }

    function movePreviousStakes() external {
        require(shareholderIndexes[msg.sender] > 0, "not a stakeholder");

        uint256 currentRoundNumber = projectManagerV0.roundNumber();

        for (uint256 i = 1; i <= currentRoundNumber - 1; i++) {
            if (stakedBalance[msg.sender][i].balance > 0) {
                addStakeHolder(
                    msg.sender,
                    stakedBalance[msg.sender][i].balance,
                    stakedBalance[msg.sender][i].time
                );
                stakedBalance[msg.sender][i].balance = 0;
            }
        }
    }

    function unstakeTokens(uint256 _amount) external {
        require(_amount > 0);

        uint256 currentRoundNumber = projectManagerV0.roundNumber();
        require(
            _amount <= stakedBalance[msg.sender][currentRoundNumber].balance
        );
        require(stakedBalance[msg.sender][currentRoundNumber].balance > 0);

        stakedBalance[msg.sender][currentRoundNumber].balance = stakedBalance[
            msg.sender
        ][currentRoundNumber].balance.sub(_amount);

        stakedBalance[msg.sender][currentRoundNumber].time = block.timestamp;

        uint256 totalStakedAmount = 0;
        for (uint256 i = 1; i < currentRoundNumber; i++) {
            totalStakedAmount = totalStakedAmount.add(
                stakedBalance[msg.sender][i].balance
            );
        }

        if (totalStakedAmount <= 0) {
            removeShareHolder(msg.sender);
        }

        IERC20(artikToken).transfer(msg.sender, _amount);
    }

    function addStakeHolder(
        address _stakeholder,
        uint256 _amount,
        uint256 _timestamp
    ) private {
        require(_amount > 0, "amount less than 0");
        require(_stakeholder != address(0x0));

        uint256 currentRoundNumber = projectManagerV0.roundNumber();
        if (!stakedBalance[_stakeholder][currentRoundNumber].staked) {
            stakedBalance[_stakeholder][currentRoundNumber] = Stake(
                _amount,
                _timestamp,
                true
            );
        } else {
            stakedBalance[_stakeholder][currentRoundNumber]
                .balance = stakedBalance[_stakeholder][currentRoundNumber]
                .balance
                .add(_amount);
            stakedBalance[_stakeholder][currentRoundNumber].time = _timestamp;
        }

        addShareHolder(_stakeholder);
    }

    function stakeTokens(uint256 _amount) external {
        require(
            _amount <= IERC20(artikToken).balanceOf(msg.sender),
            "amount greater than balance"
        );
        addStakeHolder(msg.sender, _amount, block.timestamp);
        IERC20(artikToken).transferFrom(msg.sender, address(this), _amount);
    }

    function addShareHolder(address _shareholder) private {
        require(_shareholder != address(0x0));

        if (shareholderIndexes[_shareholder] <= 0) {
            shareholders.push(_shareholder);
            shareholderCount = shareholderCount.add(1);
            shareholderIndexes[_shareholder] = shareholderCount;
        }
    }

    function removeShareHolder(address _shareholder) private {
        require(_shareholder != address(0x0));

        if (shareholderIndexes[_shareholder] > 0) {
            shareholders[shareholderIndexes[_shareholder] - 1] = shareholders[
                shareholders.length - 1
            ];
            shareholders.pop();
            shareholderCount = shareholderCount.sub(1);
            shareholderIndexes[_shareholder] = 0;
        }
    }

    function getShareHolders() external view returns (address[] memory) {
        return shareholders;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 z
    ) public pure returns (uint256) {
        return
            ABDKMathQuad.toUInt(
                ABDKMathQuad.div(
                    ABDKMathQuad.mul(
                        ABDKMathQuad.fromUInt(x),
                        ABDKMathQuad.fromUInt(y)
                    ),
                    ABDKMathQuad.fromUInt(z)
                )
            );
    }
}