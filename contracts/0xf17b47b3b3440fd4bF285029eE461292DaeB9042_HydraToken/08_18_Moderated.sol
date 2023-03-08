pragma solidity 0.5.4;

import "../../openzeppelin-solidity-2.2.0/contracts/utils/Address.sol";
import "../interfaces/IModerator.sol";
import "../roles/ControllerRole.sol";


contract Moderated is ControllerRole {
    IModerator public moderator; // External moderator contract

    event ModeratorUpdated(address moderator);

    constructor(IModerator _moderator) public {
        moderator = _moderator;
    }

    /**
    * @notice Links a Moderator contract to this contract.
    * @param _moderator Moderator contract address.
    */
    function setModerator(IModerator _moderator) external onlyController {
        require(address(moderator) != address(0), "Moderator address must not be a zero address.");
        require(Address.isContract(address(_moderator)), "Address must point to a contract.");
        moderator = _moderator;
        emit ModeratorUpdated(address(_moderator));
    }
}