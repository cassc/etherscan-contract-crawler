// SPDX-License-Identifier: NONE
pragma solidity 0.7.6;

import "@balancer-labs/v2-solidity-utils/contracts/openzeppelin/IERC20.sol";
import "@balancer-labs/v2-solidity-utils/contracts/openzeppelin/AccessControl.sol";

abstract contract AMPLRebaser is AccessControl {

    event Rebase(uint256 old_supply, uint256 new_supply);

    bytes32 public constant REBASER_ROLE = keccak256("REBASER_ROLE");

    //
    // Check last AMPL total supply from AMPL contract.
    //
    uint256 public last_ampl_supply;

    uint256 public last_rebase_call;

    IERC20 immutable public ampl_token;

    constructor(IERC20 _ampl_token) {
        require(address(_ampl_token) != address(0), "AMPLRebaser: Invalid ampl token address");
        ampl_token = _ampl_token;
        last_ampl_supply = _ampl_token.totalSupply();
        last_rebase_call = block.timestamp;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(REBASER_ROLE, msg.sender);
        _setRoleAdmin(REBASER_ROLE, DEFAULT_ADMIN_ROLE);
    }

    function rebase(uint256 minimalExpectedEEFI, uint256 minimalExpectedETH) external {
        require(hasRole(REBASER_ROLE, msg.sender), "AMPLRebaser: rebase can only be called by the REBASE manager");
        //require timestamp to exceed 24 hours in order to execute function; tested to ensure call is not manipulable by sending ampl
        require(block.timestamp - 24 hours > last_rebase_call, "AMPLRebaser: rebase can only be called once every 24 hours");
        last_rebase_call = block.timestamp;
        uint256 new_supply = ampl_token.totalSupply();
        _rebase(last_ampl_supply, new_supply, minimalExpectedEEFI, minimalExpectedETH);
        emit Rebase(last_ampl_supply, new_supply);
        last_ampl_supply = new_supply;
    }

    function _rebase(uint256 old_supply, uint256 new_supply, uint256 minimalExpectedEEFI, uint256 minimalExpectedETH) internal virtual;
}