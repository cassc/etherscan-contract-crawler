// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';

contract AYORStaking is Ownable, Pausable, ReentrancyGuard, IERC721Receiver {
    IERC721 public immutable ayor;
    uint256 public totalStaked;

    struct Stake {
        uint256 tokenId;
        uint256 timestamp;
    }

    event AYORStaked(address owner, uint256 tokenId);
    event AYORUnstaked(address owner, uint256 tokenId);

    mapping(address => Stake) public staked;
    mapping(uint256 => address) public staker;

    constructor(IERC721 _ayor) {
        ayor = _ayor;
    }

    function stake(uint256 tokenId) external whenNotPaused nonReentrant {
        require(ayor.ownerOf(tokenId) == msg.sender, 'Not your token');
        require(staked[msg.sender].timestamp == 0, 'Already staked');

        staked[msg.sender] = Stake({tokenId: tokenId, timestamp: block.timestamp});
        staker[tokenId] = msg.sender;
        totalStaked += 1;

        ayor.safeTransferFrom(msg.sender, address(this), tokenId);

        emit AYORStaked(msg.sender, tokenId);
    }

    function unstake() external nonReentrant {
        require(staked[msg.sender].timestamp > 0, 'No token staked');

        _unstake(msg.sender);
    }

    function ayorStuck(uint256[] memory tokens) external onlyOwner nonReentrant {
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 tokenId = tokens[i];
            if (staker[tokenId] != address(0)) {
                _unstake(staker[tokenId]);
            }
        }
    }

    function _unstake(address user) internal {
        Stake memory s = staked[user];
        if (s.timestamp > 0) {
            emit AYORUnstaked(user, s.tokenId);

            ayor.safeTransferFrom(address(this), user, s.tokenId);

            totalStaked -= 1;
            delete staker[s.tokenId];
            delete staked[user];
        }
    }

    function isStaking(address user) external view returns (bool) {
        return staked[user].timestamp > 0;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}