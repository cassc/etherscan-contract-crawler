/**
 * @notice Submitted for verification at bscscan.com on 2022-09-18
 */

/*
 _______          ___            ___      ___          ___
|   __   \       |   \          /   |    |   \        |   |
|  |  \   \      |    \        /    |    |    \       |   |
|  |__/    |     |     \      /     |    |     \      |   |
|         /      |      \____/      |    |      \     |   |
|        /       |   |\        /|   |    |   |\  \    |   |
|   __   \       |   | \______/ |   |    |   | \  \   |   |
|  |  \   \      |   |          |   |    |   |  \  \  |   |
|  |__/    |     |   |          |   |    |   |   \  \ |   |
|         /      |   |          |   |    |   |    \  \|   |
|________/       |___|          |___|    |___|     \______|
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../interfaces/ICreatorApproval.sol";
import "../interfaces/IAdminRole.sol";

/**
 * @notice Allows admin accounts to manage creator approvals.
 */
contract BlockMelonCreatorApproval is ICreatorApproval, Context {
    using Address for address;

    /// @notice Emitted when the approval of `account` is granted or revoked
    event CreatorApproval(address indexed account, bool approval);
    event AdminContractUpdated(address indexed adminContract);

    ///@dev The contract address which manages admin accounts
    IAdminRole public adminContract;
    /// @dev Indicates whether or not a creator is allowed to mint
    mapping(address => bool) private _creatorApprovals;

    modifier onlyBlockMelonAdmin() {
        require(
            adminContract.isAdmin(_msgSender()),
            "caller is not a BlockMelon admin"
        );
        _;
    }

    constructor(address _adminContract) {
        _updateAdminContract(_adminContract);
    }

    function setCreatorApprovals(address[] memory creators, bool approval)
        external
        onlyBlockMelonAdmin
    {
        for (uint256 i = 0; i < creators.length; i++) {
            address creator = creators[i];
            _creatorApprovals[creator] = approval;
            emit CreatorApproval(creator, approval);
        }
    }

    function isApprovedCreator(address account)
        public
        view
        override
        returns (bool)
    {
        return _creatorApprovals[account];
    }

    /**
     * @notice Allows BlockMelon to change the admin contract address.
     */
    function updateAdminContract(address _adminContract)
        external
        onlyBlockMelonAdmin
    {
        _updateAdminContract(_adminContract);
    }

    function _updateAdminContract(address _adminContract) internal {
        require(_adminContract.isContract(), "address is not a contract");
        adminContract = IAdminRole(_adminContract);

        emit AdminContractUpdated(_adminContract);
    }
}