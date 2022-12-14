/**
 * @title Manager
 * @dev Manager contract
 *
 * @author - <USDFI TRUST>
 * for the USDFI Trust
 *
 * SPDX-License-Identifier: GNU GPLv2
 *
 **/

pragma solidity 0.6.12;

import "./MinterRole.sol";
import "./IBlacklist.sol";
import "./SafeMath.sol";
import "./Pausable.sol";

contract Manager is Pausable {
    using SafeMath for uint256;

    /**
     * @dev Outputs the external contracts.
     */
    IBlacklist public blacklist;

    /**
     * @dev Outputs the `freeMintSupply` variable.
     */
    uint256 public freeMintSupply;
    mapping(address => uint256) public freeMintSupplyMinter;

    /**
     * @dev Sets the {freeMintSupply} up so that the minter can create new coins.
     *
     * The manager decides how many new coins may be created by the minter.
     * The function can only increase the amount of new free coins. 
     *
     * Requirements:
     *
     * - only `manager` can update the `setFreeMintSupplyCom`
     */
    function setFreeMintSupplyCom(address _address, uint256 _supply) public onlyManager {
        freeMintSupply = freeMintSupply.add(_supply);
        freeMintSupplyMinter[_address] = freeMintSupplyMinter[_address].add(_supply);
    }

    /**
     * @dev Sets the {freeMintSupply} down so that the minter can create fewer new coins.
     *
     * The manager decides how many new coins may be created by the minter.
     * The function can only downgrade the amount of new free coins.
     *
     * Requirements:
     *
     * - only `manager` can update the `setFreeMintSupplySub`
     */
    function setFreeMintSupplySub(address _address, uint256 _supply) public onlyManager {
        freeMintSupply = freeMintSupply.sub(_supply);
        freeMintSupplyMinter[_address] = freeMintSupplyMinter[_address].sub(_supply);
    }

    /**
     * @dev Sets `external smart contracts`.
     *
     * These functions have the purpose to be flexible and to connect further automated systems
     * which will require an update in the longer term.
     *
     * Requirements:
     *
     * - only `owner` can update the external smart contracts
     * - `external smart contracts` must be correct and work
     */

    function updateBlacklistContract(address _blacklistContract)
        public
        onlyOwner
    {
        blacklist = IBlacklist(_blacklistContract);
    }
}
