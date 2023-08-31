//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ITraitRegistry {
    function addressCanModifyTrait(address, uint16) external view returns (bool);
    function isAllowed(bytes32 role, address user) external view returns (bool);
}

abstract contract UTGenericTimedController {
    bytes32             public constant TRAIT_REGISTRY_ADMIN = keccak256("TRAIT_REGISTRY_ADMIN");
    IERC721             public erc721;                      // NFT ToolBox
    ITraitRegistry      public registry;                    // Trait registry
    bool                public locked       = false;
    uint256             public startTime;
    uint256             public endTime;

    // Errors
    error UTGenericTimedControllerNotAuthorised();
    error UTGenericTimedControllerLocked();
    error UTGenericTimedControllerBeforeValidity();
    error UTGenericTimedControllerAfterValidity();

    constructor(
        address _erc721,
        address _registry,
        uint256 _startTime,
        uint256 _endTime
    ) {
        erc721 = IERC721(_erc721);
        registry = ITraitRegistry(_registry);
        startTime = _startTime;
        endTime = _endTime == 0 ? 9999999999 : _endTime;
    }

    function getTimestamp() public view virtual returns (uint256) {
        return block.timestamp;
    }

    struct contractInfo {
        address erc721;
        address registry;
        bool    locked;
        uint256 startTime;
        uint256 endTime;
        bool    available;
    }

    function tellEverything() external view returns (contractInfo memory) {
        return contractInfo(
            address(erc721),
            address(registry),
            locked,
            startTime,
            endTime,
            (getTimestamp() >= startTime && getTimestamp() <= endTime && !locked )
        );
    }

    /*
    *   Admin Stuff - For controlling the toggleLock() funtion
    */

    function toggleLock() public {
        if(!registry.isAllowed(TRAIT_REGISTRY_ADMIN, msg.sender)) {
            revert UTGenericTimedControllerNotAuthorised();
        }
        locked = !locked;
    }

    /*
    *   Generic validation of controller availability
    */
    modifier checkValidity() {

        if(locked) {
            revert UTGenericTimedControllerLocked();
        }

        if(getTimestamp() < startTime) {
            revert UTGenericTimedControllerBeforeValidity();
        }

        if(getTimestamp() > endTime) {
            revert UTGenericTimedControllerAfterValidity();
        }
        _;
    }

}