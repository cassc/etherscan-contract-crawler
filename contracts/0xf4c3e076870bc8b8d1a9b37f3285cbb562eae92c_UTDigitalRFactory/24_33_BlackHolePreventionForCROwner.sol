// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICommunityRegistry {
    function isUserCommunityAdmin(bytes32, address) external view returns (bool);
}

contract BlackHolePreventionForCROwner {

    bytes32                        public constant DEFAULT_ADMIN_ROLE = 0x00;
    ICommunityRegistry             public immutable communityRegistry;

    error BlackHolePreventionForCROwnerNotAuthorized(address value);

    constructor(
        address _communityRegistry
    ) {
        communityRegistry = ICommunityRegistry(_communityRegistry);
    }

    modifier onlyAllowed() { 

        if (!communityRegistry.isUserCommunityAdmin(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert BlackHolePreventionForCROwnerNotAuthorized(msg.sender);
        }
        _;
    }

    // blackhole prevention methods

    function retrieveETH() external onlyAllowed {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function retrieveERC20(address _tracker, uint256 amount) external onlyAllowed {
        IERC20(_tracker).transfer(msg.sender, amount);
    }

    function retrieve721(address _tracker, uint256 id) public onlyAllowed {
        IERC721(_tracker).transferFrom(address(this), msg.sender, id);
    }

    function retrieveMultiple721(address _tracker, uint256[] memory ids) external onlyAllowed {
        for (uint16 i = 0; i < ids.length; i++) {
            retrieve721(_tracker, ids[i]);
        }
    }
}