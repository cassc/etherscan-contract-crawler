// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

import "./LyfePool.sol";

contract Pool_USDC is LyfePool {
    address public USDC_address;
    constructor(
        address _lyfe_contract_address,
        address _bloc_contract_address,
        address _collateral_address,
        address _creator_address,
        address _timelock_address,
        uint256 _pool_ceiling
    ) 
    LyfePool(_lyfe_contract_address, _bloc_contract_address, _collateral_address, _creator_address, _timelock_address, _pool_ceiling)
    public {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        USDC_address = _collateral_address;
    }
}
