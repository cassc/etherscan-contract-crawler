// myNFTV1.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./NFTStandard.sol";

contract myNFTV1 is NFTStandard {
    /**
     * @dev constructor
     * @notice This is for the implementation contract.
     * The proxy contract has no use of this constructor.
     *
     * @notice To revent implementation-contract initialize() from getting called
     *
     */

    // prettier-ignore
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev proxy initializer
     */
    function initialize(
        address _owner,
        string memory _name,
        string memory _symbol,
        string memory _contractUri
    ) external virtual initializer {
        __NFTStandard_init(_owner, _name, _symbol, _contractUri);
    }
}