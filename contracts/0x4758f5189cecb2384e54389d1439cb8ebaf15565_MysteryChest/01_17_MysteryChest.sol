// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/IMetasaurs.sol";

/**
 * ╔═╗╔═╗░░╔╗░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
 * ║║╚╝║║░╔╝╚╗░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
 * ║╔╗╔╗╠═╩╗╔╬══╦══╦══╦╗╔╦═╦══╗  Metasaurs - Mystery Chest NFT  ░░░░░░░░░░░░░░░
 * ║║║║║║║═╣║║╔╗║══╣╔╗║║║║╔╣══╣  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
 * ║║║║║║║═╣╚╣╔╗╠══║╔╗║╚╝║║╠══║  Website: https://www.metasaurs.com/  ░░░░░░░░░
 * ╚╝╚╝╚╩══╩═╩╝╚╩══╩╝╚╩══╩╝╚══╝  Discord: https://discord.com/invite/metasaurs
 *
 * @notice An NFT token of Mystery Chest for Metasaurs
 * @dev Each chest carries a certain bonus. The chest burns out after use.
 * @custom:security-contact [email protected]
 */
contract MysteryChest is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Burnable,
    AccessControl
{
    /// @notice Contract roles
    bytes32 public constant LOTTERY_ROLE = keccak256("LOTTERY_ROLE");

    /// @notice Public address for users
    address public metasaursAddress;

    /// @notice MTS interface
    IMetasaurs internal metasaurs;

    /// @notice List of already claimed chests
    mapping(uint256 => bool) public isChestClaimed;

    /// @notice List of chest types
    mapping(uint256 => uint8) public chestTypes;

    /// @notice Time until which you can get your chests
    uint256 public claimEndAt;

    /// @notice The types of chests and their bonuses will be announced later
    uint8 public typesList;

    /// @notice Base URI for token URI
    string public baseURI;

    /// @notice Is claiming paused
    bool public isPaused;

    /// @notice When new chest minted
    event NewChest(address user, uint256 tokenId);

    /// @notice When new chest minted
    event ChestOpened(uint256 tokenId, uint8 chestType);

    /**
     * @notice Runs once after deploying the implementation of the contract
     * @param _metasaurs - Metasaurs contract address
     * @param _initialOwner - Initial owner
     * @param _claimEndAt - Claiming period stop at
     */
    constructor(
        address _metasaurs,
        address _initialOwner,
        uint256 _claimEndAt
    ) ERC721("Mystery Chest", "MCH") {
        require(_metasaurs != address(0), "zero address");
        require(_initialOwner != address(0), "zero address");
        _setupRole(DEFAULT_ADMIN_ROLE, _initialOwner);
        _setupRole(LOTTERY_ROLE, _initialOwner);
        metasaursAddress = _metasaurs;
        metasaurs = IMetasaurs(_metasaurs);
        claimEndAt = _claimEndAt;
    }

    /**
     * @notice Set the number of types of chests
     * @param types - Number of types
     */
    function setChestTypes(uint8 types) external onlyRole(LOTTERY_ROLE) {
        typesList = types;
    }

    /**
     * @notice Update claim ending
     * @param newClaimEndAt - Timestamp
     */
    function setClaimEndAt(uint256 newClaimEndAt)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        claimEndAt = newClaimEndAt;
    }

    /**
     * @notice Pause or unpause claiming
     * @param _isPaused - True or false
     */
    function setIsPaused(bool _isPaused) external onlyRole(DEFAULT_ADMIN_ROLE) {
        isPaused = _isPaused;
    }

    /**
     * @notice Set baseURI param
     * @param newBaseURI - New base URI
     */
    function setBaseURI(string memory newBaseURI)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        baseURI = newBaseURI;
    }

    /**
     * @notice Set chests types (by lottery contract)
     * @param ids - Metasaur ids
     * @param types - Types of chests
     */
    function updateChests(uint256[] memory ids, uint8[] memory types)
        external
        onlyRole(LOTTERY_ROLE)
    {
        require(typesList > 0, "set types first");
        require(ids.length == types.length, "wrong length");
        require(ids.length > 0, "wrong size");
        for (uint256 i = 0; i < ids.length; i++) {
            require(types[i] > 0, "num is too low");
            require(typesList >= types[i], "num is too big");
            require(ids[i] <= 9999, "exceeded max amount");
            chestTypes[ids[i]] = types[i];
        }
    }

    /**
     * @notice Set chest type (by lottery contract)
     * @param id - Metasaur id
     * @param typeOfChest - Type of chests
     */
    function updateChest(uint256 id, uint8 typeOfChest)
        external
        onlyRole(LOTTERY_ROLE)
    {
        require(typesList > 0, "set types first");
        require(typeOfChest > 0, "num is too low");
        require(typesList >= typeOfChest, "num is too big");
        require(id <= 9999, "exceeded max amount");
        chestTypes[id] = typeOfChest;
    }

    /**
     * @notice Claim tokens
     * @param tokenIds - Array of Metasaur token IDs
     * @return True on success
     */
    function claim(uint256[] memory tokenIds) external returns (bool) {
        require(!isPaused, "claiming is paused");
        require(block.timestamp <= claimEndAt, "claiming period is over");
        for (uint16 i = 0; i < tokenIds.length; i++) {
            require(_claim(tokenIds[i]), "something went wrong");
        }
        return true;
    }

    /**
     * @notice Can I claim my chests now?
     * @return True if you can
     */
    function isClaimingActive() external view returns (bool) {
        return block.timestamp <= claimEndAt;
    }

    /**
     * @notice Get array of unclaimed metasaurs id
     * @param owner - Address to check
     * @return Array of unclaimed tokens
     */
    function getUnclaimed(address owner)
        external
        view
        returns (uint256[] memory)
    {
        return _getUnclaimed(owner);
    }

    /**
     * @notice Get array of all unclaimed metasaurs
     * @return Array of unclaimed metasaurs
     */
    function getUnclaimedAll() external view returns (bool[9999] memory) {
        bool[9999] memory result;
        for (uint256 i = 0; i < 9999; i++) {
            result[i] = isChestClaimed[i];
        }
        return result;
    }

    /**
     * @notice Get list of owner tokens
     * @param owner - Address to check
     * @return Array of IDs
     */
    function tokensOfOwner(address owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 count = balanceOf(owner);
        if (count == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory ids = new uint256[](count);
            uint256 i;
            for (i = 0; i < count; i++) {
                ids[i] = tokenOfOwnerByIndex(owner, i);
            }
            return ids;
        }
    }

    /**
     * @notice "Open" chest
     * @dev This will be done by a lottery contract
     * @param tokenId - Chest ID
     */
    function burn(uint256 tokenId) public override onlyRole(LOTTERY_ROLE) {
        _burn(tokenId);
    }

    /**
     * @notice Claim token
     * @param tokenId - Metasaur token ID
     * @return True on success
     */
    function _claim(uint256 tokenId) private returns (bool) {
        require(metasaurs.ownerOf(tokenId) == msg.sender, "not your token");
        isChestClaimed[tokenId] = true;
        _safeMint(msg.sender, tokenId);
        emit NewChest(msg.sender, tokenId);
        return true;
    }

    /**
     * @notice Get array of unclaimed tokens
     * @param holder - Metasaur token owner
     * @return Array of unclaimed tokens
     */
    function _getUnclaimed(address holder)
        private
        view
        returns (uint256[] memory)
    {
        uint256[] memory myMetasaurs = metasaurs.tokensOfOwner(holder);
        uint256 count = myMetasaurs.length;
        if (count == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory unclaimed = new uint256[](count);
            for (uint256 i = 0; i < count; i++) {
                if (!isChestClaimed[myMetasaurs[i]]) {
                    unclaimed[i] = myMetasaurs[i];
                }
            }
            return unclaimed;
        }
    }

    /// @notice Logic before the start of the transfer
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @notice "Open" chest
     * @dev This will be done by a lottery contract
     * @param tokenId - Chest ID
     */
    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
        emit ChestOpened(tokenId, chestTypes[tokenId]);
    }

    /// @notice tokenURI override
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /// @notice supportsInterface override
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @notice _baseURI override
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}