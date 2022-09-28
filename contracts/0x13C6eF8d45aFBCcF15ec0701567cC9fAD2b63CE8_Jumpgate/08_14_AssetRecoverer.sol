// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

import "Ownable.sol";
import "SafeERC20.sol";
import "IERC20.sol";
import "IERC721.sol";
import "IERC1155.sol";

/// @title Asset Recoverer
/// @author mymphe
/// @notice Recover ether, ERC20, ERC721 and ERC1155 from a derived contract
/// @dev inherit from this contract to enable permissioned asset recovery
abstract contract AssetRecoverer is Ownable {
    using SafeERC20 for IERC20;

    event EtherRecovered(address indexed _recipient, uint256 _amount);
    event ERC20Recovered(
        address indexed _token,
        address indexed _recipient,
        uint256 _amount
    );
    event ERC721Recovered(
        address indexed _token,
        uint256 _tokenId,
        address indexed _recipient
    );
    event ERC1155Recovered(
        address indexed _token,
        uint256 _tokenId,
        address indexed _recipient,
        uint256 _amount
    );

    /// @notice prevents burn for recovery functions
    /// @dev checks for zero address and reverts if true
    /// @param _recipient address of the recovery recipient
    modifier burnDisallowed(address _recipient) {
        require(_recipient != address(0), "Recipient cannot be zero address!");
        _;
    }

    /// @notice prevents `owner` from renouncing ownership and potentially locking assets forever
    /// @dev overrides Ownable's renounceOwnership to always revert
    function renounceOwnership() public view override onlyOwner {
        revert("Renouncing ownership disabled!");
    }

    /// @notice recover all of ether on this contract as the owner
    /// @dev using the safer `call` instead of `transfer`
    /// @param _recipient address to send ether to
    function recoverEther(address _recipient)
        external
        onlyOwner
        burnDisallowed(_recipient)
    {
        uint256 amount = address(this).balance;
        (bool success, ) = _recipient.call{value: amount}("");
        require(success);
        emit EtherRecovered(_recipient, amount);
    }

    /// @notice recover an ERC20 token on this contract's balance as the owner
    /// @dev SafeERC20.safeTransfer doesn't return a bool as it performs an internal `require` check
    /// @param _token address of the ERC20 token that is being recovered
    /// @param _recipient address to transfer the tokens to
    /// @param _amount amount of tokens to transfer
    function recoverERC20(
        address _token,
        address _recipient,
        uint256 _amount
    ) external onlyOwner burnDisallowed(_recipient) {
        IERC20(_token).safeTransfer(_recipient, _amount);
        emit ERC20Recovered(_token, _recipient, _amount);
    }

    /// @notice recover an ERC721 token on this contract's balance as the owner
    /// @dev IERC721.safeTransferFrom doesn't return a bool as it performs an internal `require` check
    /// @param _token address of the ERC721 token that is being recovered
    /// @param _tokenId id of the individual token to transfer
    /// @param _recipient address to transfer the token to
    function recoverERC721(
        address _token,
        uint256 _tokenId,
        address _recipient
    ) external onlyOwner burnDisallowed(_recipient) {
        IERC721(_token).safeTransferFrom(address(this), _recipient, _tokenId);
        emit ERC721Recovered(_token, _tokenId, _recipient);
    }

    /// @notice recover an ERC1155 token on this contract's balance as the owner
    /// @dev IERC1155.safeTransferFrom doesn't return a bool as it performs an internal `require` check
    /// @param _token address of the ERC1155 token that is being recovered
    /// @param _tokenId id of the individual token to transfer
    /// @param _recipient address to transfer the token to
    function recoverERC1155(
        address _token,
        uint256 _tokenId,
        address _recipient
    ) external onlyOwner burnDisallowed(_recipient) {
        uint256 amount = IERC1155(_token).balanceOf(address(this), _tokenId);
        IERC1155(_token).safeTransferFrom(
            address(this),
            _recipient,
            _tokenId,
            amount,
            ""
        );
        emit ERC1155Recovered(_token, _tokenId, _recipient, amount);
    }
}