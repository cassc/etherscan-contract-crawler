// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

// Custom
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./PausableCloneableERC20.sol";
import "./OnlyTokenAdmin.sol";

contract TokenFactory is OnlyTokenAdmin {
    address public immutable tokenImplementation;

    constructor(address _initialTokenAdminContract) {
        tokenImplementation = address(new PausableCloneableERC20());
        require(tokenImplementation != address(0), "ERC20 deployment failed");
        __OnlyTokenAdmin_init(_initialTokenAdminContract);
    }

    function mintERC20(
        string calldata _name,
        string calldata _symbol,
        uint256 _initialSupply,
        address _owner
    ) external onlyTokenAdminContract returns (address) {
        address clone = Clones.clone(tokenImplementation);

        /* The final _owner arg here will determine:
        A) The Owner (account which can pause() and unpause() the ERC20) 
        B) The Initial token holder to whom all initial supply will be minted
        */
        PausableCloneableERC20(clone).initialize(
            _name,
            _symbol,
            _initialSupply,
            _owner
        );

        return clone;
    }
}