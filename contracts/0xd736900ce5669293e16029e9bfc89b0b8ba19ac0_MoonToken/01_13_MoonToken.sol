// contracts/Cheeth.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@openzeppelin/contracts/utils/math/Math.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

contract MoonToken is ERC20Burnable, Ownable, IERC721Receiver {
    using EnumerableSet for EnumerableSet.UintSet;

    address nullAddress = 0x0000000000000000000000000000000000000000;

    address public dystomiceAddress;
    address public spacemiceAddress;
    uint256 private rate;
    uint256 private expiration; 

    mapping(address => EnumerableSet.UintSet) private _deposits;
    mapping(address => EnumerableSet.UintSet) private _depositsSpace;
    mapping(address => mapping(uint256 => uint256)) public depositBlocks;
    mapping(address => mapping(uint256 => uint256)) public depositBlocksSpace;

    constructor(address _dystomice, address _spacemice, uint256 _rate, uint256 _expiration) ERC20("MoonToken", "Moon") {
        dystomiceAddress = _dystomice; 
        spacemiceAddress = _spacemice;
        rate = _rate;
        expiration = block.number + _expiration;
    }

    function depositsOf(address account)
        external
        view
        returns (uint256[] memory)
    {
        EnumerableSet.UintSet storage depositSet = _deposits[account];
        uint256[] memory tokenIds = new uint256[](depositSet.length());

        for (uint256 i; i < depositSet.length(); i++) {
            tokenIds[i] = depositSet.at(i);
        }

        return tokenIds;
    }

    function setRate(uint256 _rate) public onlyOwner() {
        rate = _rate;
    }

    function setExpiration(uint256 _expiration) public onlyOwner() {
        expiration = _expiration;
    }

    function depositsOfSpace(address account)
        external
        view
        returns (uint256[] memory)
    {
        EnumerableSet.UintSet storage depositSet = _depositsSpace[account];
        uint256[] memory tokenIds = new uint256[](depositSet.length());

        for (uint256 i; i < depositSet.length(); i++) {
            tokenIds[i] = depositSet.at(i);
        }

        return tokenIds;
    }

    function depositDystoMice(uint256[] calldata tokenIds) external {
        claimRewards(tokenIds);

        for (uint256 i; i < tokenIds.length; i++) {
            IERC721(dystomiceAddress).safeTransferFrom(
                msg.sender,
                address(this),
                tokenIds[i],
                ''
            );

            _deposits[msg.sender].add(tokenIds[i]);
        }
    }

    function depositSpaceMice(uint256[] calldata tokenIds) external {
        claimRewards(tokenIds);

        for (uint256 i; i < tokenIds.length; i++) {
            IERC721(spacemiceAddress).safeTransferFrom(
                msg.sender,
                address(this),
                tokenIds[i],
                ''
            );

            _depositsSpace[msg.sender].add(tokenIds[i]);
        }
    }

    function calculateRewards(address account, uint256[] memory tokenIds)
        public
        view
        returns (uint256[] memory rewards)
    {
        rewards = new uint256[](tokenIds.length);

        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            rewards[i] =
                rate *
                (_deposits[account].contains(tokenId) ? 1 : 0) *
                (Math.min(block.number, expiration) -
                    depositBlocks[account][tokenId]);
        }
    }

    function calculateRewardsSpace(address account, uint256[] memory tokenIds)
        public
        view
        returns (uint256[] memory rewards)
    {
        rewards = new uint256[](tokenIds.length);

        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            rewards[i] =
                2 * rate *
                (_depositsSpace[account].contains(tokenId) ? 1 : 0) *
                (Math.min(block.number, expiration) -
                    depositBlocksSpace[account][tokenId]);
        }
    }

    function claimRewards(uint256[] calldata tokenIds) public {
        uint256 reward;
        uint256 block = Math.min(block.number, expiration);

        uint256[] memory rewards = calculateRewards(msg.sender, tokenIds);

        for (uint256 i; i < tokenIds.length; i++) {
            reward += rewards[i];
            depositBlocks[msg.sender][tokenIds[i]] = block;
        }

        if (reward > 0) {
            _mint(msg.sender, reward); 
        }
    }

    function claimRewardsSpace(uint256[] calldata tokenIds) public {
        uint256 reward;
        uint256 block = Math.min(block.number, expiration);

        uint256[] memory rewards = calculateRewardsSpace(msg.sender, tokenIds);

        for (uint256 i; i < tokenIds.length; i++) {
            reward += rewards[i];
            depositBlocksSpace[msg.sender][tokenIds[i]] = block;
        }

        if (reward > 0) {
            _mint(msg.sender, reward); 
        }
    }

    function withdraw(uint256[] calldata tokenIds) external {
        claimRewards(tokenIds);

        for (uint256 i; i < tokenIds.length; i++) {
            require(
                _deposits[msg.sender].contains(tokenIds[i]),
                'token not deposited'
            );

            _deposits[msg.sender].remove(tokenIds[i]);

            IERC721(dystomiceAddress).safeTransferFrom(
                address(this),
                msg.sender,
                tokenIds[i],
                ''
            );
        }
    }

    function withdrawSpace(uint256[] calldata tokenIds) external {
        claimRewards(tokenIds);

        for (uint256 i; i < tokenIds.length; i++) {
            require(
                _depositsSpace[msg.sender].contains(tokenIds[i]),
                'token not deposited'
            );

            _depositsSpace[msg.sender].remove(tokenIds[i]);

            IERC721(spacemiceAddress).safeTransferFrom(
                address(this),
                msg.sender,
                tokenIds[i],
                ''
            );
        }
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