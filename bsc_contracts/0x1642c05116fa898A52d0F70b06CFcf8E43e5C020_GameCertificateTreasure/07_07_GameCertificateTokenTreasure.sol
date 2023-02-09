// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract GameCertificateTreasure is Ownable, Pausable, IERC721Receiver {
    constructor() {}

    event TopUp(
        address indexed sender,
        address token,
        uint256 tokenID,
        uint256 nonce
    );
    event TopUpBatch(
        address indexed sender,
        address[] tokens,
        uint256[] tokenIDs,
        uint256 nonce
    );

    receive() external payable {}

    /// @notice Top up
    function topUp(
        address _token,
        uint256 _tokenID,
        uint256 _nonce
    ) public whenNotPaused {
        IERC721(_token).transferFrom(msg.sender, address(this), _tokenID);
        emit TopUp(msg.sender, _token, _tokenID, _nonce);
    }

    /// @notice Top up Multi NFTs
    function topUpBatch(
        address[] memory _tokens,
        uint256[] memory _tokenIDs,
        uint256 _nonce
    ) public whenNotPaused {
        for (uint256 i; i < _tokens.length; i++) {
            IERC721(_tokens[i]).transferFrom(
                msg.sender,
                address(this),
                _tokenIDs[i]
            );
        }
        emit TopUpBatch(msg.sender, _tokens, _tokenIDs, _nonce);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function unLockEther() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public view virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}