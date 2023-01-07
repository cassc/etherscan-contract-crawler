// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/* ========== External Inheritance ========== */
import "./AbstractDynasetFactory.sol";
import "./BscDynaset.sol";

/**
 * @title DynasetFactory
 * @author singdaodev
 */
contract BscDynasetFactory is AbstractDynasetFactory {
    constructor(address gnosis)
        AbstractDynasetFactory(gnosis) {
    }

    /* ==========  External Functions  ========== */

    /**   @notice Creates new dynaset contract
     * @dev dam and controller can can not be zero as the checks are
            added to constructor of Dynaset contract
     * @param dam us the asset manager of the new deployed dynaset.
     * @param controller will is the BLACK_SMITH role user for dynaset contract.
     * @param name, @param symbol will be used for dynaset ERC20 token
     */
    function deployDynaset(
        address dam,
        address controller,
        string calldata name,
        string calldata symbol
    ) external override onlyOwner {
        BscDynaset dynaset = new BscDynaset(
            address(this),
            dam,
            controller,
            name,
            symbol
        );
        dynasetList[address(dynaset)] = DynasetEntity({
            name: name,
            bound: true,
            initialised: false,
            forge: address(0),
            dynaddress: address(dynaset),
            performanceFee: 0,
            managementFee: 0,
            timelock: block.timestamp + 30 days,
            tvlSnapshot: 0
        });
        dynasets.push(address(dynaset));
        emit NewDynaset(address(dynaset), dam, controller);
    }

}