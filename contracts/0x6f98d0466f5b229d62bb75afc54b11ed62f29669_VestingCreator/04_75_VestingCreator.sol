// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.16;

import "./Vester.sol";

interface IMectSwapApprover {
    function approvals(address) external returns (bool);

    function setApproval(bool _approval) external;
}

contract VestingCreator {
    bool public constant RES = false; // Whether the vesting can be claimed by the user only.
    uint256 public constant CLIFF = 0; // No cliff duration.
    uint256 public constant DURATION = 77760000; // Duration of the vesting in unix timestamp (30 months).
    address public constant MORPHO_DAO = 0xcBa28b38103307Ec8dA98377ffF9816C164f9AFa;
    IMectSwapApprover public constant MECT_SWAP_APPROVER = IMectSwapApprover(0x6327d36F66Fec925FadD387153eCE94d109f3D66);

    Vester public immutable VESTER;

    modifier onlyDAO() {
        require(msg.sender == MORPHO_DAO);
        _;
    }

    constructor(address _vester) {
        VESTER = Vester(_vester);
    }


    /// @notice Creates vestings only if the users have approved to swap their MECT for MORPHO.
    /// @dev Only the DAO can trigger this function.
    /// @param _usr The recipient of the reward.
    /// @param _tot The total amount of the vest.
    /// @param _bgn The start of the vesting period.
    /// @param _bls Whether the vesting is uninterruptible or not (True = uninterruptible).
    function createVesting(address _usr, uint256 _tot, uint256 _bgn, address _mgr, bool _bls) external onlyDAO returns (uint256) {
        if (MECT_SWAP_APPROVER.approvals(_usr)) {
            return VESTER.create_custom(_usr, _tot, _bgn, DURATION, CLIFF, _mgr, RES, _bls);
        } else {
            return type(uint256).max;
        }
    }
}