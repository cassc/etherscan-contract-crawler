// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ILockProvider.sol";
import "./IMissionControlStaking.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";

contract MissionControlStaking is
    IMissionControlStaking,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC1155Holder,
    ERC721Holder
{
    mapping(address => mapping(uint256 => bool)) public tokenWhitelisted; // tokenAddress => tokenId => isWhitelisted
    mapping(address => mapping(address => mapping(uint256 => Lockup))) public userStaked; //user => tokenAddress => tokenId => amount
    mapping(address => mapping(uint256 => address)) public unlockProvider; // tokenAddress => tokenId => unlock provider
    uint256 private constant LOCKUP_PERIOD = 30 days;

    function initialize() external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    function stakeNonFungible(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _relayerFee
    ) public {
        require(
            ERC165CheckerUpgradeable.supportsInterface(_tokenAddress, type(IERC721).interfaceId),
            "MC_STAKING: NOT ERC721"
        );
        require(tokenWhitelisted[_tokenAddress][_tokenId], "MC_STAKING: TOKEN NOT WHITELISTED");

        Lockup storage lockup = userStaked[msg.sender][_tokenAddress][_tokenId];
        lockup.amount = 1;
        lockup.lockedAt = block.timestamp;

        if (unlockProvider[_tokenAddress][_tokenId] != address(0)) {
            address _lockProvider = unlockProvider[_tokenAddress][_tokenId];
            ILockProvider(_lockProvider).onTokenLocked(msg.sender, _tokenAddress, _tokenId, lockup.amount, _relayerFee);
        }

        IERC721(_tokenAddress).safeTransferFrom(msg.sender, address(this), _tokenId);

        emit TokenStaked(_tokenAddress, _tokenId, 1, msg.sender);
    }

    function stakeSemiFungible(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _relayerFee
    ) public {
        require(
            ERC165CheckerUpgradeable.supportsInterface(_tokenAddress, type(IERC1155).interfaceId),
            "MC_STAKING: NOT ERC1155"
        );
        require(tokenWhitelisted[_tokenAddress][_tokenId], "MC_STAKING: TOKEN NOT WHITELISTED");

        Lockup storage lockup = userStaked[msg.sender][_tokenAddress][_tokenId];
        lockup.amount += _amount;
        lockup.lockedAt = block.timestamp;

        if (unlockProvider[_tokenAddress][_tokenId] != address(0)) {
            address _lockProvider = unlockProvider[_tokenAddress][_tokenId];
            ILockProvider(_lockProvider).onTokenLocked(msg.sender, _tokenAddress, _tokenId, lockup.amount, _relayerFee);
        }

        IERC1155(_tokenAddress).safeTransferFrom(msg.sender, address(this), _tokenId, _amount, "");

        emit TokenStaked(_tokenAddress, _tokenId, _amount, msg.sender);
    }

    function stakeManyNonFungible(
        address[] memory _tokenAddresses,
        uint256[] memory _tokenIds,
        uint256 _relayerFee
    ) external {
        require(_tokenAddresses.length == _tokenIds.length, "MC_STAKING: INVALID ARRAY LENGTHS");

        for (uint256 i; i < _tokenAddresses.length; i++) {
            stakeNonFungible(_tokenAddresses[i], _tokenIds[i], _relayerFee);
        }
    }

    function stakeManySemiFungible(
        address[] memory _tokenAddresses,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts,
        uint256 _relayerFee
    ) external {
        require(
            _tokenAddresses.length == _tokenIds.length && _tokenAddresses.length == _amounts.length,
            "MC_STAKING: INVALID ARRAY LENGTHS"
        );

        for (uint256 i; i < _tokenAddresses.length; i++) {
            stakeSemiFungible(_tokenAddresses[i], _tokenIds[i], _amounts[i], _relayerFee);
        }
    }

    function unstake(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _relayerFee
    ) public nonReentrant {
        Lockup storage lockup = userStaked[msg.sender][_tokenAddress][_tokenId];
        require(lockup.amount >= _amount, "MC_STAKING: USER DOES NOT HAVE ENOUGH STAKED");
        require(block.timestamp > lockup.lockedAt + LOCKUP_PERIOD, "MC_STAKING: LOCKUP PERIOD NOT YET OVER");

        bool isERC721 = ERC165CheckerUpgradeable.supportsInterface(_tokenAddress, type(IERC721).interfaceId);
        bool isERC1155 = ERC165CheckerUpgradeable.supportsInterface(_tokenAddress, type(IERC1155).interfaceId);

        if (lockup.amount == _amount) delete userStaked[msg.sender][_tokenAddress][_tokenId];
        else lockup.amount -= _amount;

        if (unlockProvider[_tokenAddress][_tokenId] != address(0)) {
            address _lockProvider = unlockProvider[_tokenAddress][_tokenId];
            ILockProvider(_lockProvider).onTokenUnlocked(
                msg.sender,
                _tokenAddress,
                _tokenId,
                lockup.amount,
                _relayerFee
            );
        }

        if (isERC721) IERC721(_tokenAddress).safeTransferFrom(address(this), msg.sender, _tokenId);
        if (isERC1155) IERC1155(_tokenAddress).safeTransferFrom(address(this), msg.sender, _tokenId, _amount, "");

        emit TokenUnstaked(_tokenAddress, _tokenId, _amount, msg.sender);
    }

    function unstakeMany(
        address[] memory _tokenAddresses,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts,
        uint256 _relayerFee
    ) external {
        require(
            _tokenAddresses.length == _tokenIds.length && _tokenAddresses.length == _amounts.length,
            "MC_STAKING: INVALID ARRAY LENGTHS"
        );

        for (uint256 i; i < _tokenAddresses.length; i++) {
            unstake(_tokenAddresses[i], _tokenIds[i], _amounts[i], _relayerFee);
        }
    }

    function whitelistTokens(
        address _tokenAddress,
        uint256[] memory _tokenIds,
        bool isWhitelisted
    ) external {
        require(_tokenAddress != address(0), "MC_STAKING: ADDRESS ZERO");
        for (uint256 i; i < _tokenIds.length; i++) tokenWhitelisted[_tokenAddress][_tokenIds[i]] = isWhitelisted;

        emit TokensWhitelisted(_tokenAddress, _tokenIds);
    }

    function setUnstakeProvider(
        address _tokenAddress,
        uint256[] memory _tokenIds,
        address _provider
    ) external {
        require(
            ERC165CheckerUpgradeable.supportsInterface(_provider, type(ILockProvider).interfaceId),
            "MC_STAKING: NOT AN UNLOCK PROVIDER"
        );
        for (uint256 i; i < _tokenIds.length; i++) unlockProvider[_tokenAddress][_tokenIds[i]] = _provider;

        emit UnstakeProviderSet(_tokenAddress, _tokenIds, _provider);
    }

    function getUserStakedBalance(
        address _user,
        address _tokenAddress,
        uint256 _tokenId
    ) external view returns (uint256) {
        return userStaked[_user][_tokenAddress][_tokenId].amount;
    }

    function getUserStakedAt(
        address _user,
        address _tokenAddress,
        uint256 _tokenId
    ) external view returns (uint256) {
        return userStaked[_user][_tokenAddress][_tokenId].lockedAt;
    }
}