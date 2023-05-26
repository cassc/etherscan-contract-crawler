// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @title JPEGCardsCigStaking
/// @notice This contract allows JPEG Cards cigarette holders to stake one of their cigarettes to
/// increase the liquidation limit rate and credit limit rate when borrowing from {NFTVault}.
contract JPEGCardsCigStaking is Ownable, ReentrancyGuard, Pausable {

    event Deposit(address indexed account, uint256 indexed cardIndex);
    event Withdrawal(address indexed account, uint256 indexed cardIndex);

    struct UserData {
        uint256 stakedCig;
        bool isStaking;
    }

    IERC721 public immutable cards;

    mapping(uint256 => bool) public cigs;
    mapping(address => UserData) public userData;

    constructor(IERC721 _cards, uint256[] memory _cigList) {
        require(address(_cards) != address(0), "INVALID_ADDRESS");

        uint256 length = _cigList.length;
        require(length > 0, "INVALID_LIST");

        cards = _cards;
        for (uint i; i < length; ++i) {
            cigs[_cigList[i]] = true;
        }

        _pause();
    }

    /// @notice Allows users to deposit one of their cigarette JPEG cards.
    /// @param _idx The index of the NFT to stake.
    function deposit(uint256 _idx) external nonReentrant whenNotPaused {
        require(cigs[_idx], "NOT_CIG");

        UserData storage data = userData[msg.sender];
        require(!data.isStaking, "CANNOT_STAKE_MULTIPLE");
        
        data.isStaking = true;
        data.stakedCig = _idx;

        cards.transferFrom(msg.sender, address(this), _idx);

        emit Deposit(msg.sender, _idx);
    }

    /// @notice Allows users to withdraw their staked cigarette JPEG card.
    /// @param _idx The index of the NFT to unstake.
    function withdraw(uint256 _idx) external nonReentrant whenNotPaused {
        UserData storage data = userData[msg.sender];
        require(data.stakedCig == _idx && data.isStaking, "NOT_STAKED");

        data.isStaking = false;
        data.stakedCig = 0;
        
        cards.safeTransferFrom(address(this), msg.sender, _idx);

        emit Withdrawal(msg.sender, _idx);
    }

    /// @notice Allows the DAO to add a card to the list of cigarettes.
    /// @param _idx The index of the card.
    function addCig(uint256 _idx) external onlyOwner {
        cigs[_idx] = true;
    }

    /// @notice Allows the DAO to pause deposits/withdrawals
    function pause() external onlyOwner {
        _pause();
    }
    
    /// @notice Allows the DAO to unpause deposits/withdrawals
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @return Whether the user is staking a cigarette or not.
    function isUserStaking(address _user) external view returns (bool) {
        return userData[_user].isStaking;
    }
}