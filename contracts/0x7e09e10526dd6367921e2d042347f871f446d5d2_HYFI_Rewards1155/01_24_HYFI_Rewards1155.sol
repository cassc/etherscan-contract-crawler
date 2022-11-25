// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../interfaces/IHYFI_RewardsManager.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

// solhint-disable-next-line contract-name-camelcase
contract HYFI_Rewards1155 is
    Initializable,
    IHYFI_RewardsManager,
    ERC1155Upgradeable,
    AccessControlUpgradeable,
    ERC1155BurnableUpgradeable
{
    /// @dev URI_SETTER_ROLE role identifier
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");

    /// @dev MINTER_ROLE role identifier
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @dev name of the token
    string public name;

    /// @dev symbol of the token
    string public symbol;

    /// @dev total supply of tokens per id
    mapping(uint256 => uint256) internal _totalSupply;

    /// @dev total supply of all tokens by all ids
    uint256 internal _totalSupplyAll;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev initializer
     * @param tokenName token name
     * @param tokenSymbol token symbol
     * @param baseUri metadata base uri
     */
    function initialize(
        string memory tokenName,
        string memory tokenSymbol,
        string memory baseUri
    ) external virtual initializer {
        name = tokenName;
        symbol = tokenSymbol;
        __ERC1155_init(baseUri);
        __AccessControl_init();
        __ERC1155Burnable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(URI_SETTER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    /**
     * @dev generate for user amount of NFTS by specific id
     * @param user user address
     * @param amount amount to reveal
     * @param rewardId reward id need to be revealed
     */
    function revealRewards(
        address user,
        uint256 amount,
        uint256 rewardId
    ) external onlyRole(MINTER_ROLE) {
        _mint(user, rewardId, amount, "");
        emit RewardsRevealed(user, rewardId, amount);
    }

    /**
     * @dev set new base URI
     * @param newUri new uri
     */
    function setURI(string memory newUri) public onlyRole(URI_SETTER_ROLE) {
        _setURI(newUri);
    }

    /**
     * @dev mint mannually rewards (can be used in some exceptions)
     * @param to user address minted to
     * @param id nft id (rewards ID)
     * @param amount amount of NFTs to mint
     * @param data additional data
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyRole(MINTER_ROLE) {
        _mint(to, id, amount, data);
    }

    /**
     * @dev batch mint mannually rewards (can be used in some exceptions)
     * @param to user address minted to
     * @param ids array of NFT ids (rewards IDs)
     * @param amounts array of NFTs amounts to mint
     * @param data additional data
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyRole(MINTER_ROLE) {
        _mintBatch(to, ids, amounts, data);
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC1155Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IHYFI_RewardsManager).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Total amount of tokens with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Total amount of tokens for all ids
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupplyAll;
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return totalSupply(id) > 0;
    }

    /**
     * @dev get user rewards amount
     * @param user user to check
     * @param rewardId reward ID
     * @return amount of user owned NFTS for specific ID
     */
    function getUserRewardsAmount(
        address user,
        uint256 rewardId
    ) public view returns (uint256) {
        return balanceOf(user, rewardId);
    }

    /**
     * @dev processor for token transfer, initiated before transfer, recalculate total supply for all tokens
     * @param operator initiator
     * @param from account the transfer should be done from
     * @param to account the transfer should be done to
     * @param ids of user owned NFTS for specific ID
     * @param amounts of user owned NFTS for specific ID
     * @param data additional data
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155Upgradeable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
                _totalSupplyAll += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] -= amounts[i];
                _totalSupplyAll -= amounts[i];
            }
        }
    }
}