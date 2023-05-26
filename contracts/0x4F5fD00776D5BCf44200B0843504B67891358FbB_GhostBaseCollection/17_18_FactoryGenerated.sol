// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../interfaces/IAdminWhitelistable.sol';
import '../../node_modules/@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '../../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '../../node_modules/@openzeppelin/contracts/access/Ownable.sol';

abstract contract FactoryGenerated is Ownable {
    using SafeERC20 for IERC20;

    address payable public factory;
    event UpdateFactory(address _factory);
    event NonFungibleTokenRecovery(address indexed token, uint256 tokenId);
    event TokenRecovery(address indexed token, uint256 amount);
    modifier onlyFactory() {
        require(msg.sender == factory, 'FactoryGenerated : msg.sender is not factory');
        _;
    }

    modifier onlyFactoryWhitelist() {
        require(
            IAdminWhitelistable(factory).isInWhitelist(msg.sender),
            'FactoryGenerated : msg.sender is not in factory admin whitelist'
        );
        _;
    }

    modifier onlyOwnerOrFactoryWhitelist() {
        require(
            msg.sender == owner() || IAdminWhitelistable(factory).isInWhitelist(msg.sender),
            'FactoryGenerated : msg.sender is neither owner nor factory admin whitelist'
        );
        _;
    }

    /**
     * @notice Update new factory address
     * @param _newFactoryAddress: Factory address
     */
    function _updateFactory(address _newFactoryAddress) internal {
        factory = payable(_newFactoryAddress);
        emit UpdateFactory(_newFactoryAddress);
    }

    function updateFactory(address _newFactoryAddress) external onlyFactoryWhitelist {
        _updateFactory(_newFactoryAddress);
    }

    /**
     * @notice Allows the owner to recover non-fungible tokens sent to the contract by mistake
     * @param _token: NFT token address
     * @param _tokenId: tokenId
     * @dev Callable by owner
     */
    function recoverNonFungibleToken(address _token, uint256 _tokenId) external onlyFactoryWhitelist {
        IERC721(_token).transferFrom(address(this), address(msg.sender), _tokenId);
        emit NonFungibleTokenRecovery(_token, _tokenId);
    }

    /**
     * @notice Allows the owner to recover tokens sent to the contract by mistake
     * @param _token: token address
     * @dev Callable by owner
     */
    function recoverToken(address _token) external onlyFactoryWhitelist {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        require(balance != 0, 'Operations: Cannot recover zero balance');
        IERC20(_token).safeTransfer(address(msg.sender), balance);
        emit TokenRecovery(_token, balance);
    }

    /**
     * @notice Restore by factory admin whitelist
     * @param _newOwner: Factory address
     * @param _newFactory: Factory address
     */
    function restoreByFactoryWhitelist(address _newOwner, address _newFactory) external onlyFactoryWhitelist {
        _transferOwnership(_newOwner);
        _updateFactory(_newFactory);
    }
}