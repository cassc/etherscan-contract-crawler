// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/access/AccessControl.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IWriteDistributionHelperV2 {
    event TokenSet(address indexed token);

    event TokenFaucetSet(
        address indexed previousTokenFaucet,
        address indexed newTokenFaucet
    );

    event LimitSet(uint256 previousLimit, uint256 newLimit);
}

/**
 * @title Write distribution helper.
 * @author MirrorXYZ
 * @custom:security-contact [email protected]
 */
contract WriteDistributionHelperV2 is
    IWriteDistributionHelperV2,
    AccessControl
{
    /// @notice Write token.
    address public immutable token;

    /// @notice Administrator role.
    bytes32 public immutable ADMINISTRATOR_ROLE =
        keccak256("ADMINISTRATOR_ROLE");

    /// @notice Distributor role.
    bytes32 public immutable DISTRIBUTOR_ROLE = keccak256("DISTRIBUTOR_ROLE");

    /// @notice Token holder.
    address public tokenFaucet;

    /// @notice Token transfer limit.
    uint256 public limit;

    /// @notice Admin and distributors can distribute tokens.
    modifier allowed() {
        require(
            hasRole(ADMINISTRATOR_ROLE, msg.sender) ||
                hasRole(DISTRIBUTOR_ROLE, msg.sender),
            "WriteDistributionHelperV2: not allowed"
        );
        _;
    }

    /// @notice Set token, token faucet, limit, role admins and grant roles.
    /// @param _token The token that will be distributed.
    /// @param _tokenFaucet The account that will hold the tokens.
    /// @param _limit The max number of accounts that can be distributed to.
    /// @param _admin The admin account.
    /// @param _distributorRoles The accounts that will receive a distributor role.
    constructor(
        address _token,
        address _tokenFaucet,
        uint256 _limit,
        address _admin,
        address[] memory _distributorRoles
    ) {
        token = _token;
        emit TokenSet(_token);

        tokenFaucet = _tokenFaucet;
        emit TokenFaucetSet(address(0), _tokenFaucet);

        limit = _limit;
        emit LimitSet(0, _limit);

        // Set role admins.
        _setRoleAdmin(ADMINISTRATOR_ROLE, ADMINISTRATOR_ROLE);
        _setRoleAdmin(DISTRIBUTOR_ROLE, ADMINISTRATOR_ROLE);

        // Set admin role.
        _grantRole(ADMINISTRATOR_ROLE, _admin);

        for (uint256 i = 0; i < _distributorRoles.length; ) {
            _grantRole(DISTRIBUTOR_ROLE, _distributorRoles[i]);
            unchecked {
                i++;
            }
        }
    }

    /// @notice Distribute tokens to a list of accounts.
    /// @dev Only admin or distributor can call this function.
    function distribute(address[] memory accounts) public allowed {
        require(accounts.length < limit, "WriteDistributionHelperV2: limit");

        for (uint256 i = 0; i < accounts.length; i++) {
            IERC20(token).transferFrom(tokenFaucet, accounts[i], 1 * 1 ether);
        }
    }

    /// @notice Set token faucet.
    /// @dev Only admin can call this function.
    function setTokenFaucet(address _tokenFaucet)
        public
        onlyRole(ADMINISTRATOR_ROLE)
    {
        emit TokenFaucetSet(tokenFaucet, _tokenFaucet);

        tokenFaucet = _tokenFaucet;
    }

    /// @notice Set limit.
    /// @dev Only admin can call this function.
    function setLimit(uint256 _limit) public onlyRole(ADMINISTRATOR_ROLE) {
        emit LimitSet(limit, _limit);

        limit = _limit;
    }
}