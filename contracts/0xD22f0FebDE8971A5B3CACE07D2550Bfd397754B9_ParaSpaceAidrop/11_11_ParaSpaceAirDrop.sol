// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {IERC20} from "../dependencies/openzeppelin/contracts/IERC20.sol";
import {Ownable} from "../dependencies/openzeppelin/contracts/Ownable.sol";
import {SafeERC20} from "../dependencies/openzeppelin/contracts/SafeERC20.sol";
import {IERC721} from "../dependencies/openzeppelin/contracts/IERC721.sol";
import {IERC1155} from "../dependencies/openzeppelin/contracts/IERC1155.sol";
import {ReentrancyGuard} from "../dependencies/openzeppelin/contracts/ReentrancyGuard.sol";

contract ParaSpaceAidrop is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct AidropStatus {
        uint128 amount;
        bool claimed;
    }

    /**
     * @dev Emitted during rescueERC20()
     * @param token The address of the token
     * @param to The address of the recipient
     * @param amount The amount being rescued
     **/
    event RescueERC20(
        address indexed token,
        address indexed to,
        uint256 amount
    );

    /**
     * @dev Emitted during rescueERC721()
     * @param token The address of the token
     * @param to The address of the recipient
     * @param ids The ids of the tokens being rescued
     **/
    event RescueERC721(
        address indexed token,
        address indexed to,
        uint256[] ids
    );

    /**
     * @dev Emitted during RescueERC1155()
     * @param token The address of the token
     * @param to The address of the recipient
     * @param ids The ids of the tokens being rescued
     * @param amounts The amount of NFTs being rescued for a specific id.
     * @param data The data of the tokens that is being rescued. Usually this is 0.
     **/
    event RescueERC1155(
        address indexed token,
        address indexed to,
        uint256[] ids,
        uint256[] amounts,
        bytes data
    );

    event AidropClaim(address indexed user, uint128 amount);

    IERC20 immutable aidropToken;
    mapping(address => AidropStatus) public userStatus;

    uint256 public immutable deadline; // change later. we can also make dynamic if needed

    constructor(address _token, uint256 _deadline) {
        aidropToken = IERC20(_token);
        deadline = _deadline;
    }

    function setUsersAirdropAmounts(
        address[] calldata _users,
        uint128[] calldata _amounts
    ) external onlyOwner {
        require(_users.length == _amounts.length);

        for (uint256 index = 0; index < _users.length; index++) {
            require(_amounts[index] != 0, "amount should not be zero");
            userStatus[_users[index]].amount = _amounts[index];
        }
    }

    function claimAidrop() external nonReentrant {
        AidropStatus memory status = userStatus[msg.sender];
        require(status.amount != 0, "no airdrop set for this user");
        require(!status.claimed, "airdrop already claimed");
        require(block.timestamp < deadline, "airdrop ended");

        userStatus[msg.sender].claimed = true;

        aidropToken.safeTransfer(msg.sender, status.amount);

        emit AidropClaim(msg.sender, status.amount);
    }

    function rescueERC20(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).safeTransfer(to, amount);
        emit RescueERC20(token, to, amount);
    }

    function rescueERC721(
        address token,
        address to,
        uint256[] calldata ids
    ) external onlyOwner {
        for (uint256 i = 0; i < ids.length; i++) {
            IERC721(token).safeTransferFrom(address(this), to, ids[i]);
        }
        emit RescueERC721(token, to, ids);
    }

    function rescueERC1155(
        address token,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external onlyOwner {
        IERC1155(token).safeBatchTransferFrom(
            address(this),
            to,
            ids,
            amounts,
            data
        );
        emit RescueERC1155(token, to, ids, amounts, data);
    }
}