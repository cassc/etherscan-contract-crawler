// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/* 
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMXKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0XMMMMMMMMMM
MMMMMMMMWk'.c0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0c.'kWMMMMMMMM
MMMMMMMNo.   .:xKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKx:.   .oNMMMMMMM
MMMMMMXc        .;cdxOKXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKOkdc;.        cXMMMMMM
MMMMMXc               ..,:oxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxl;..               cXMMMMM
MMMMNl                      .,oKWMMMMMMMMMMMMMMMMMMWWNNXXNNMMMMMMMMMWKd;.                     lNMMMM
MMMWx.                         .lKMMMMMMMMMMWXOxlc:;,'..,l0WMMMMMMW0c.                        .xWMMM
MMMK;      .dOOOkxoc,.           'kWMMMMMNOo;.         ,kNMMMMMMWKl.          .,codkOOOd.      ;KMMM
MMMx.      lWMMMMMMMWXkl'         .xWMWKd,.           cXMMWNKXWWk'         'lkXWMMMMMMMWl      .xMMM
MMNl      .kMMMMMMMMMMMMXx'        .kXd.              ;olc;'.lXd.        ,xXWMMMMMMMMMMMk.      lNMM
MMX:      ,KMMMMMMMMMMMMMMXl.       .'                      .xd.       .lXMMMMMMMMMMMMMMK,      ;XMM
MMX;      ;XMMMMMMMMMMMMMMMWd.                              .;.       .dWMMMMMMMMMMMMMMMX;      ;XMM
MMX:      ,KMMMMMMMMMMMMMMMMNo.                                      .oWMMMMMMMMMMMMMMMMK;      :XMM
MMWl      '0MMMMMMMMMMMMMMMMMX;                                      ;XMMMMMMMMMMMMMMMMM0'      lWMM
MMMk.     .xMMMMMMMMMMMMMMMMMWd.                                    .dWMMMMMMMMMMMMMMMMMx.     .kMMM
MMMX:      :XMMMMMMMMMMMMMMMMNd.                                    .dNWMMMMMMMMMMMMMMMX:      :XMMM
MMMMk.     .xWMMMMMMMMMMMN0dc'.                                      .':d0NMMMMMMMMMMMWx.     .kMMMM
MMMMNo.     'OMMMMMMMMWKd,.                                              .,dXMMMMMMMMMO'     .oNMMMM
MMMMMNl      'OWMMMMMNd.     .,clolc;.                        .;clolc,.     'dNMMMMMWO'      lNMMMMM
MMMMMMXl.     .xWMMMXc     'dKWMWXxodkkc.                  .ckKOddONMWKd'     cKMMMNx.     .lXMMMMMM
MMMMMMMNd.     .cKWNc     ;KMMMNd.   .xNO;                ;OW0:.   :KMMMK;     cXWKc.     .dNMMMMMMM
MMMMMMMMWO;      .ol.    ,0MMMWx.     .kMXc              cXMX;      :XMMM0,    .lo.      ;OWMMMMMMMM
MMMMMMMMMMNd'            oWMMMX;       cNMK;            ;KMMx.      .OMMMWo            .oXWNKKNMMMMM
MMMMMMMMMMMWO;          .xMMMMK,       :XMWx.          .xMMWd       .xMMMMx.           .',,',dNMMMMM
MMMMMMMN0xl;.           .xMMMMK;       cNMMO.          .OMMMx.      .OMMMMx.               ,kNMMMMMM
MMMMNOl,.                lNMMMNl      .dWMMk.          .kMMM0'      ,KMMMNl             .:xNMMMMMMMM
MMMXc.                   .kWMMMO'     ;KMMNl  .;llll,   lNMMNo     .dWMMWk.            'oKWMMMMMMMMM
MMMx.                     .:dOXNk,...cKMMNd.  ,0MMMMk.  .dWMMXl...,xXXOd:.               .;dKWMMMMMM
MMMd.                         .,::;:oxkxo;.    cXMMK;    .;oxxxl::c:,.                      .xWMMMMM
MMMO.          .'.                              ckk:                                         .kMMMMM
MMMX:       'lO0l.                                                                            cNMMMM
MMMMO.    'dXMNo.                                                                             ;XMMMM
MMMMWd.  :KMMMO.       .                                                 ...        .:dol:'.  :XMMMM
MMMMMNl.cXMMMM0'  .;ok000kd:.                                         .lO0K0Oxc'    .OMMMWN0o,oWMMMM
MMMMMMXOKMMMMMWO,,kWMMMMMMMWXx;.                                   .,dKWMMMMMMMXd. .oNMMMMMMMNNMMMMM
MMMMMMMMMMMMMMMMNNMMMMMMMMMMMMW0d:.                             .;o0NMMMMMMMMMMMWOcxNMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOdl;'..                .';cdOXWMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNX0OkxdoolllooodxO0KNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
*/

contract VestedMeowl is ERC20, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    event Claim(address indexed claimer, uint256 initialAmount);

    uint16[] public cumulativeScheduleInBPS;
    uint256 public immutable timePeriodInSeconds;
    uint256 public immutable startTime;

    mapping(address => uint128) public claimedByAccount;

    IERC20 public immutable meowl;

    constructor(
        IERC20 meowl_,
        uint16[] memory cumulativeScheduleInBPS_,
        uint256 timePeriodInDays
    ) ERC20("vMeowl", "VMEOWL") {
        meowl = meowl_;
        startTime = block.timestamp;
        cumulativeScheduleInBPS = cumulativeScheduleInBPS_;
        timePeriodInSeconds = timePeriodInDays * 1 days;
    }

    function multiMint(
        address[] calldata accounts,
        uint256[] calldata initialAmounts
    ) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            mint(accounts[i], initialAmounts[i]);
        }
    }

    function mint(address account, uint256 initialAmount) public onlyOwner {
        _mint(account, initialAmount);
    }

    function _claim(address account) private returns (uint128 claimable) {
        claimable = uint128(claimableOf(account));
        if (claimable > 0) {
            claimedByAccount[account] += claimable;
            _burn(account, claimable);
            emit Claim(account, claimable);
        }
    }

    function _vestingSnapshot(
        address account
    ) internal view returns (uint256, uint256, uint256) {
        uint128 claimed = claimedByAccount[account];
        uint256 balance = balanceOf(account);
        uint256 initialAllocation = balance + claimed;
        return (
            _totalVestedOf(initialAllocation, block.timestamp),
            claimed,
            balance
        );
    }

    function claim(address recipient) external nonReentrant {
        uint256 claimable = _claim(recipient);
        require(claimable > 0, "VMEOWL/ZERO_VESTED");
        meowl.transfer(recipient, claimable);
    }

    function _totalVestedOf(
        uint256 initialAllocation,
        uint256 currentTime
    ) internal view returns (uint256 total) {
        if (currentTime <= startTime) {
            return 0;
        }
        uint16[] memory _cumulativeScheduleInBPS = cumulativeScheduleInBPS;
        uint256 elapsed = Math.min(
            currentTime - startTime,
            _cumulativeScheduleInBPS.length * timePeriodInSeconds
        );
        uint256 currentPeriod = elapsed / timePeriodInSeconds;
        uint256 elapsedInCurrentPeriod = elapsed % timePeriodInSeconds;
        uint256 cumulativeMultiplierPast = 0;

        if (currentPeriod > 0) {
            cumulativeMultiplierPast = _cumulativeScheduleInBPS[
                currentPeriod - 1
            ];
            total = (initialAllocation * cumulativeMultiplierPast) / 10000;
        }

        if (elapsedInCurrentPeriod > 0) {
            uint256 currentMultiplier = _cumulativeScheduleInBPS[
                currentPeriod
            ] - cumulativeMultiplierPast;
            uint256 periodAllocation = (initialAllocation * currentMultiplier) /
                10000;
            total +=
                (periodAllocation * elapsedInCurrentPeriod) /
                timePeriodInSeconds;
        }
    }

    function vestedOf(address account) external view returns (uint256) {
        (uint256 vested, , ) = _vestingSnapshot(account);
        return vested;
    }

    function claimableOf(address account) public view returns (uint256) {
        (uint256 vested, uint256 claimed, uint256 balance) = _vestingSnapshot(
            account
        );
        return Math.min(vested - claimed, balance);
    }

    function rescue() external onlyOwner {
        require(
            block.timestamp >
                startTime +
                    (cumulativeScheduleInBPS.length * timePeriodInSeconds),
            "vMEOWL/RESCUE_BEFORE_END"
        );
        meowl.transfer(owner(), meowl.balanceOf(address(this)));
    }
}