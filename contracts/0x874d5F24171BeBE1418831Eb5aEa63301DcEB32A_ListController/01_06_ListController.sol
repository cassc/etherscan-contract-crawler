//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/INitroCollection1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @author NitroLeague.
contract ListController is Ownable, Pausable, ReentrancyGuard {
    struct Allowlist {
        string listName;
        uint allowed;
    }

    Allowlist[] public allowlists;
    uint public currentList;
    /**list index => (wallet => minted/or remaining mints) */
    mapping(uint => mapping(address => uint)) public mintCount;
    /**allow list name (string) to index mapping */
    mapping(string => uint) public listIndices;

    uint256 private constant maxAllowlistTokenID = 4;
    INitroCollection1155[] public collections;

    event CollectionAdded(address collection);
    event UserMinted(
        address indexed account,
        string indexed listName,
        uint quantity
    );

    constructor(address[] memory _collections) {
        for (uint256 i = 0; i < _collections.length; i++) {
            collections.push(INitroCollection1155(_collections[i]));
            emit CollectionAdded(_collections[i]);
        }
        /**initialize with a public list */
        allowlists.push(Allowlist("public", 1));
        listIndices["public"] = 0;
        /**initialize to list number 1 so that public cannot mint */
        currentList = 1;
        _transferOwnership(_msgSender());
    }

    function mint(uint256 _quantity)
        external
        allowedToMint(_quantity)
        whenNotPaused
    {
        (uint256 i, uint[] memory ids, uint[] memory amounts) = getTokenIDs(
            _quantity
        );

        callMint(i, _quantity, ids, amounts);
    }

    function callMint(
        uint256 i,
        uint256 _quantity,
        uint[] memory ids,
        uint[] memory amounts
    ) internal nonReentrant whenCollectionNotPaused(i) {
        _updateMinted(_msgSender(), _quantity);

        collections[i].mintAllowlisted(_msgSender(), ids, amounts);

        emit UserMinted(
            _msgSender(),
            allowlists[currentList].listName,
            _quantity
        );
    }

    function getNumberOfLists() external view returns (uint listsLength) {
        return allowlists.length;
    }

    modifier allowedToMint(uint quantity) {
        require(quantity > 0, "Quantity Cannot be Zero");
        require(
            getRemainingMints(currentList, _msgSender()) >= quantity,
            "Quantity > Allowed"
        );
        _;
    }

    function getRemainingMints(uint listIndex, address account)
        public
        view
        returns (uint)
    {
        uint allowed = allowlists[listIndex].allowed;
        uint count = mintCount[listIndex][account];
        /** Public mint */
        if (listIndex == 0) {
            if (count > allowed) return 0; /**User minted more than allowed */
            unchecked {
                return allowed - count;
            }
        }

        /**Allow listed mint */
        if (count > allowed) return allowed;

        return count;
    }

    function createAllowlists(
        string[] calldata listNames,
        uint[] calldata allowed
    ) external onlyOwner {
        require(listNames.length == allowed.length, "Array Lengths Mismatch");

        for (uint i = 0; i < listNames.length; i++) {
            allowlists.push(Allowlist(listNames[i], allowed[i]));
            listIndices[listNames[i]] = allowlists.length - 1;
        }
    }

    function setCurrentList(uint listIndex)
        public
        onlyOwner
        validListIndex(listIndex)
    {
        currentList = listIndex;
    }

    function setNextList() external onlyOwner {
        setCurrentList(currentList + 1);
    }

    function addToAllowlist(uint listIndex, address[] memory accounts)
        external
        onlyOwner
        validListIndex(listIndex)
    {
        uint allowed = allowlists[listIndex].allowed;
        for (uint i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            mintCount[listIndex][account] = allowed;
        }
    }

    modifier validListIndex(uint listIndex) {
        /**Check list index is neither negative nor greater than max lists */
        require(
            listIndex >= 0 && listIndex < allowlists.length,
            "Invalid Index"
        );
        _;
    }

    function setMaxMints(uint listIndex, uint allowed)
        external
        onlyOwner
        validListIndex(listIndex)
    {
        allowlists[listIndex].allowed = allowed;
    }

    function _updateMinted(address account, uint quantity) internal {
        if (currentList == 0) mintCount[currentList][account] += quantity;
        else {
            unchecked {
                mintCount[currentList][account] -= quantity;
            }
        }
    }

    function getTokenIDs(uint256 _quantity)
        internal
        view
        returns (
            uint collection,
            uint[] memory ids,
            uint[] memory amounts
        )
    {
        ids = new uint[](_quantity);
        amounts = new uint[](_quantity);
        uint i = 0;
        for (i; i < _quantity; i++) {
            ids[i] = (randomNumber(i) % maxAllowlistTokenID) + 1;
            amounts[i] = 1;
        }
        collection = (randomNumber(i) + 1) % collections.length;
        return (collection, ids, amounts);
    }

    function randomNumber(uint i) internal view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp, i)));
    }

    function addCollection(address _newColletion) external onlyOwner {
        collections.push(INitroCollection1155(_newColletion));
        emit CollectionAdded(_newColletion);
    }

    /**
     * @dev Throws error if daily mints limit is reached
     */
    function isLimitReahed(uint256 i) internal virtual returns (bool) {
        if (collections[i].mintsCounter() >= collections[i].maxDailyMints()) {
            if (block.timestamp >= (collections[i].lastChecked() + 86400))
                return false; /**Day passed which means limit will reset on next call */
            return true;
        }
        return false;
    }

    function collectionPaused(uint i) external view returns (bool) {
        return collections[i].paused();
    }

    modifier inDailyLimit(uint256 i) {
        require(!isLimitReahed(i), "Daily mint reached");
        _;
    }

    modifier whenCollectionNotPaused(uint256 i) {
        require(!collections[i].paused(), "Pausable: paused");
        _;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}