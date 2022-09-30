// SPDX-FileCopyrightText: 2022 Lido <[email protected]>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

import "Ownable.sol";
import "SafeERC20.sol";
import "IERC20.sol";
import "IERC721.sol";
import "IERC1155.sol";

/**
 * @title Lido Insurance Fund
 * @author mymphe
 * @notice serves as a vault for Lido insurance funds
 */
contract InsuranceFund is Ownable {
    using SafeERC20 for IERC20;

    event EtherTransferred(address indexed _recipient, uint256 _amount);
    event ERC20Transferred(
        address indexed _token,
        address indexed _recipient,
        uint256 _amount
    );
    event ERC721Transferred(
        address indexed _token,
        address indexed _recipient,
        uint256 _tokenId,
        bytes _data
    );
    event ERC1155Transferred(
        address indexed _token,
        address indexed _recipient,
        uint256 _tokenId,
        uint256 _amount,
        bytes _data
    );

    /**
     * @notice prevents burn for transfer functions
     * @dev checks for zero address and reverts if true
     * @param _recipient address of the transfer recipient
     */
    modifier burnDisallowed(address _recipient) {
        require(_recipient != address(0), "NO BURN");
        _;
    }

    constructor(address _initialOwner) {
        require(_initialOwner != address(0), "ZERO ADDRESS");
        _transferOwnership(_initialOwner);
    }

    /**
     * @notice forbids owner from renouncing ownership and locking assets forever
     * @dev overrides Ownable's `renounceOwnership` to always revert
     */
    function renounceOwnership() public pure override {
        revert("DISABLED");
    }

    /**
     * @notice transfers ether from this contract
     * @dev using `address.call` is safer to transfer to other contracts
     * @param _recipient address to transfer ether to
     * @param _amount amount of ether to transfer
     */
    function transferEther(address _recipient, uint256 _amount)
        external
        onlyOwner
        burnDisallowed(_recipient)
    {
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "TRANSFER FAILED");
        emit EtherTransferred(_recipient, _amount);
    }

    /**
     * @notice transfer an ERC20 token from this contract
     * @dev `SafeERC20.safeTransfer` doesn't always return a bool
     * as it performs an internal `require` check
     * @param _token address of the ERC20 token
     * @param _recipient address to transfer the tokens to
     * @param _amount amount of tokens to transfer
     */
    function transferERC20(
        address _token,
        address _recipient,
        uint256 _amount
    ) external onlyOwner burnDisallowed(_recipient) {
        IERC20(_token).safeTransfer(_recipient, _amount);
        emit ERC20Transferred(_token, _recipient, _amount);
    }

    /**
     * @notice transfer an ERC721 token from this contract
     * @dev `IERC721.safeTransferFrom` doesn't always return a bool
     * as it performs an internal `require` check
     * @param _token address of the ERC721 token
     * @param _recipient address to transfer the token to
     * @param _tokenId id of the individual token
     * @param _data data to transfer along
     */
    function transferERC721(
        address _token,
        address _recipient,
        uint256 _tokenId,
        bytes memory _data
    ) external onlyOwner burnDisallowed(_recipient) {
        IERC721(_token).safeTransferFrom(
            address(this),
            _recipient,
            _tokenId,
            _data
        );
        emit ERC721Transferred(_token, _recipient, _tokenId, _data);
    }

    /**
     * @notice transfer an ERC1155 token from this contract
     * @dev `IERC1155.safeTransferFrom` doesn't always return a bool
     * as it performs an internal `require` check
     * @param _token address of the ERC1155 token that is being recovered
     * @param _recipient address to transfer the token to
     * @param _tokenId id of the individual token to transfer
     * @param _amount amount of tokens to transfer
     * @param _data data to transfer along
     */
    function transferERC1155(
        address _token,
        address _recipient,
        uint256 _tokenId,
        uint256 _amount,
        bytes calldata _data
    ) external onlyOwner burnDisallowed(_recipient) {
        IERC1155(_token).safeTransferFrom(
            address(this),
            _recipient,
            _tokenId,
            _amount,
            _data
        );
        emit ERC1155Transferred(_token, _recipient, _tokenId, _amount, _data);
    }
}