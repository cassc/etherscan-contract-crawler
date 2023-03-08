pragma solidity 0.5.4;

import "./external/openzeppelin-solidity-2.2.0/contracts/token/ERC20/ERC20Detailed.sol";
import "./external/tenx/interfaces/IModerator.sol";
import "./external/tenx/token/ERC1400.sol";

// 1594 - Moderated, issuable
// 1644 - Controllable

/**
 * @notice Hydra Token
 */
contract HydraToken is
    ERC1400,
    ERC20Detailed("Hydra DAO", "HYDRA", 18)
{
    constructor(IModerator _moderator) public ERC1400(_moderator) {}
}