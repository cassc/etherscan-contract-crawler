// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title IslandG1Staking contract
/// @custom:juice 100%
/// @custom:security-contact [email protected]
contract IslandG1Staking is ERC721Holder, ReentrancyGuard, AccessControl, Pausable {
    using Address for address;
    using Strings for uint256;
    
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    IERC721 public token;

    uint256 public totalStaked;
    mapping(address => uint256) private balances;
    mapping(uint256 => address) private assets;

    constructor(
        address token_
    ) {
        token = IERC721(token_);

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MANAGER_ROLE, _msgSender());
    }

    function stake(uint256 tokenId)
        public
        nonReentrant
        whenNotPaused
    {
        assets[tokenId] = _msgSender();

        balances[_msgSender()] += 1;

        totalStaked += 1;

        token.safeTransferFrom(_msgSender(), address(this), tokenId);

        emit Staked(_msgSender(), tokenId);
    }

    function withdraw(uint256 tokenId)
        public
        nonReentrant
        whenNotPaused
    {
        require(assets[tokenId] == _msgSender(), "IslandG1Staking: not the staker");

        assets[tokenId] = address(0);

        balances[_msgSender()] -= 1;
        
        totalStaked -= 1;

        token.safeTransferFrom(address(this), _msgSender(), tokenId);

        emit Withdrawn(_msgSender(), tokenId);
    }
    
    function withdrawForce(uint256 tokenId)
        public
        nonReentrant
        onlyRole (MANAGER_ROLE)
    {
        address staker = assets[tokenId];

        require(staker != address(0), "IslandG1Staking: not staked");

        assets[tokenId] = address(0);

        balances[staker] -= 1;
        
        totalStaked -= 1;

        token.safeTransferFrom(address(this), staker, tokenId);

        emit Withdrawn(staker, tokenId);
    }

    function pause()
        external
        onlyRole (MANAGER_ROLE)
    {
        _pause();
    }

    function unpause()
        external
        onlyRole (MANAGER_ROLE)
    {
        _unpause();
    }

    function balanceOf(address owner)
        public
        view
        virtual
        returns (uint256)
    {
        require(owner != address(0), "IslandG1Staking: address zero is not a valid owner");

        return balances[owner];
    }

    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        returns (address)
    {
        address owner = assets[tokenId];

        require(owner != address(0), "IslandG1Staking: invalid token ID");

        return owner;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override (AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    event Staked(address indexed staker, uint256 indexed tokenId);
    event Withdrawn(address indexed staker, uint256 indexed tokenId);
}