// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract AuraSupplyDrop {
    using SafeERC20 for IERC20;

    bytes private emptyData = bytes("");

    address public platformFeeRecipient;
    uint256 public platformFeePercentage; // Fee percentage multiplied by 100 (e.g., 1000 = 10%)

    event PlatformFeeUpdated(address indexed recipient, uint256 percentage);

    constructor(address _platformFeeRecipient, uint256 _platformFeePercentage) {
        platformFeeRecipient = _platformFeeRecipient;
        platformFeePercentage = _platformFeePercentage;
    }

    modifier onlyPlatformFeeRecipient() {
        require(
            msg.sender == platformFeeRecipient,
            "Aura Supply Drop: Caller is not the platform fee recipient"
        );
        _;
    }

    /**
     * @dev Update the platform fee recipient and percentage.
     *
     * - `_platformFeeRecipient`: new address to receive platform fees
     * - `_platformFeePercentage`: new platform fee percentage multiplied by 100
     */
    function updatePlatformFee(
        address _platformFeeRecipient,
        uint256 _platformFeePercentage
    ) external onlyPlatformFeeRecipient {
        require(
            _platformFeeRecipient != address(0),
            "Aura Supply Drop: Invalid platform fee recipient"
        );
        require(
            _platformFeePercentage <= 10000,
            "Aura Supply Drop: Invalid platform fee percentage"
        );

        platformFeeRecipient = _platformFeeRecipient;
        platformFeePercentage = _platformFeePercentage;

        emit PlatformFeeUpdated(_platformFeeRecipient, _platformFeePercentage);
    }

    /**
     * @dev Send ETH to multiple accounts.
     *
     * - `_recipients`: list of receiver's address.
     * - `_values`: list of values in wei will be sent.
     */
    function sendETH(
        address payable[] calldata _recipients,
        uint256[] calldata _values
    ) external payable {
        require(
            _recipients.length == _values.length,
            "Aura Supply Drop: _recipients and _values not equal"
        );

        uint256 totalValue = msg.value;

        for (uint256 i = 0; i < _recipients.length; i++) {
            uint256 feeAmount = (totalValue * platformFeePercentage) / 10000;
            uint256 netValue = totalValue - feeAmount;

            (bool sent, ) = _recipients[i].call{value: netValue}("");
            require(sent, "Aura Supply Drop: Failed to send Ether");

            totalValue -= netValue;
        }

        if (totalValue > 0) {
            (bool sent, ) = platformFeeRecipient.call{value: totalValue}("");
            require(sent, "Aura Supply Drop: Failed to send platform fee");
        }
    }

    /**
     * @dev Send token ERC20 to multiple accounts.
     *
     * - `_tokenAddress`: address of token erc20
     * - `_recipients`: list of receiver's address.
     * - `_values`: list of values in wei will be sent.
     */
    function sendERC20(
        address _tokenAddress,
        address[] calldata _recipients,
        uint256[] calldata _values
    ) external {
        require(
            _recipients.length == _values.length,
            "Aura Supply Drop: _recipients and _values not equal"
        );
        IERC20 token = IERC20(_tokenAddress);

        uint256 totalValue = 0;

        for (uint256 i = 0; i < _recipients.length; i++) {
            totalValue += _values[i];
        }

        for (uint256 i = 0; i < _recipients.length; i++) {
            uint256 feeAmount = (totalValue * platformFeePercentage) / 10000;
            uint256 netValue = totalValue - feeAmount;

            token.safeTransferFrom(msg.sender, _recipients[i], netValue);

            totalValue -= netValue;
        }

        if (totalValue > 0) {
            token.safeTransferFrom(
                msg.sender,
                platformFeeRecipient,
                totalValue
            );
        }
    }

    /**
     * @dev Send token ERC721 to multiple accounts.
     *
     * - `_tokenAddress`: address of token erc721
     * - `_recipients`: list of receiver's address.
     * - `_ids`: list of NFT's ID will be sent.
     */
    function sendERC721(
        address _tokenAddress,
        address[] calldata _recipients,
        uint256[] calldata _ids
    ) external {
        require(
            _recipients.length == _ids.length,
            "Aura Supply Drop: _recipients and _ids not equal"
        );
        IERC721 token = IERC721(_tokenAddress);

        for (uint256 i = 0; i < _recipients.length; i++) {
            token.safeTransferFrom(msg.sender, _recipients[i], _ids[i]);
        }
    }

    /**
     * @dev Send token ERC1155 to multiple accounts.
     *
     * - `_tokenAddress`: address of token erc1155
     * - `_recipients`: list of receiver's address.
     * - `_ids`: list of token IDs will be sent.
     * - `_values`: list of values corresponding to each id
     */
    function sendERC1155(
        address _tokenAddress,
        address[] calldata _recipients,
        uint256[] calldata _ids,
        uint256[] calldata _values
    ) external {
        require(
            _recipients.length == _values.length,
            "Aura Supply Drop: _recipients and _values not equal"
        );
        require(
            _recipients.length == _ids.length,
            "Aura Supply Drop: _recipients and _ids not equal"
        );
        IERC1155 token = IERC1155(_tokenAddress);

        for (uint256 i = 0; i < _recipients.length; i++) {
            token.safeTransferFrom(
                msg.sender,
                _recipients[i],
                _ids[i],
                _values[i],
                emptyData
            );
        }
    }
}