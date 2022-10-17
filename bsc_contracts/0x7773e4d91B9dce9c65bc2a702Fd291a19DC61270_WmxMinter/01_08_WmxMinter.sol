// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import { Ownable } from "@openzeppelin/contracts-0.8/access/Ownable.sol";
import { Wmx } from "./Wmx.sol";

/**
 * @title   WmxMinter
 * @notice  Wraps the WmxToken minterMint function and protects from inflation until
 *          3 years have passed.
 * @dev     Ownership initially owned by the DAO, but likely transferred to smart contract
 *          wrapper or additional value system at some stage as directed by token holders.
 */
contract WmxMinter is Ownable {
    /// @dev Wmx token
    Wmx public immutable wmx;
    /// @dev Timestamp upon which minting will be possible
    uint256 public immutable inflationProtectionTime;

    constructor(address _wmx, address _dao) Ownable() {
        wmx = Wmx(_wmx);
        _transferOwnership(_dao);
        inflationProtectionTime = block.timestamp + 156 weeks;
    }

    /**
     * @dev Mint function allows the owner of the contract to inflate WMX post protection time
     * @param _to Recipient address
     * @param _amount Amount of tokens
     */
    function mint(address _to, uint256 _amount) external onlyOwner {
        require(block.timestamp > inflationProtectionTime, "Inflation protected for now");
        wmx.minterMint(_to, _amount);
    }
}