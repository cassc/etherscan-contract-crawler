// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IGemGlobalConfig } from "../../interfaces/IGemGlobalConfig.sol";

/**
 * @dev DeFiner Users are rewarded with FIN tokens, this contract receives the
 * winner information and FIN tokens from DeFiner admin. Then users can claim
 * their shares of FIN tokens.
 */
contract Claim is Initializable {
    using SafeERC20 for IERC20;

    mapping(address => uint256) public winner;
    IGemGlobalConfig public gemGlobalConfig;
    IERC20 public tokenFIN;

    event WinnerAdded(address indexed winner, uint256 amount);
    event RewardClaimed(address indexed winner, uint256 amount);

    /* NO CONSTRUCTOR FOR THIS CONTRACT */

    modifier onlyDefinerAdmin() {
        require(msg.sender == gemGlobalConfig.definerAdmin(), "not a definerAdmin");
        _;
    }

    function initialize(address _gemGlobalConfig) public initializer {
        gemGlobalConfig = IGemGlobalConfig(_gemGlobalConfig);
        tokenFIN = IERC20(gemGlobalConfig.finToken());
    }

    function addWinners(address[] memory _winners, uint256[] memory _amounts) public onlyDefinerAdmin {
        require(_winners.length == _amounts.length, "array lengths don't match");
        for (uint256 i; i < _winners.length; i++) {
            winner[_winners[i]] += _amounts[i];
            emit WinnerAdded(_winners[i], _amounts[i]);
        }
    }

    function claim() public {
        uint256 amount = winner[msg.sender];
        if (amount == 0) return;

        winner[msg.sender] = 0;
        tokenFIN.safeTransfer(msg.sender, amount);
        emit RewardClaimed(msg.sender, amount);
    }

    function emergencyExit(
        address _to,
        address _token,
        uint256 _amount
    ) public onlyDefinerAdmin {
        IERC20(_token).safeTransfer(_to, _amount);
    }
}