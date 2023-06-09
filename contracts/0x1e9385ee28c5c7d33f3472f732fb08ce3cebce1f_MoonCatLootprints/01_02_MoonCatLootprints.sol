// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.1;

interface IMoonCatAcclimator {
    function getApproved(uint256 tokenId) external view returns (address);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function ownerOf(uint256 tokenId) external view returns (address);
}

interface IMoonCatRescue {
    function rescueOrder(uint256 tokenId) external view returns (bytes5);
    function catOwners(bytes5 catId) external view returns (address);
}

interface IReverseResolver {
    function claim(address owner) external returns (bytes32);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256);
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IMoonCatLootprintsMetadata {
    function getJSON(uint256 lootprintId,
                     uint8 classId,
                     uint8 colorId,
                     uint8 bays,
                     string calldata shipName)
        external view returns (string memory);
    function getImage(uint256 lootprintId,
                      uint8 classId,
                      uint8 colorId,
                      uint8 bays,
                      string calldata shipName)
        external view returns (string memory);
    function getClassName(uint8 classId) external view returns (string memory);
    function getColorName(uint8 classId) external view returns (string memory);
}


/**
 * @dev Derived from OpenZeppelin standard template
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/structs/EnumerableSet.sol
 * b0cf6fbb7a70f31527f36579ad644e1cf12fdf4e
 */
library EnumerableSet {
    struct Set {
        uint256[] _values;
        mapping (uint256 => uint256) _indexes;
    }

    function at(Set storage set, uint256 index) internal view returns (uint256) {
        return set._values[index];
    }

    function contains(Set storage set, uint256 value) internal view returns (bool) {
        return set._indexes[value] != 0;
    }

    function length(Set storage set) internal view returns (uint256) {
        return set._values.length;
    }

    function add(Set storage set, uint256 value) internal returns (bool) {
        if (!contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function remove(Set storage set, uint256 value) internal returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];
        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            if (lastIndex != toDeleteIndex) {
                uint256 lastvalue = set._values[lastIndex];
                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();
            // Delete the index for the deleted slot
            delete set._indexes[value];
            return true;
        } else {
            return false;
        }
    }
}

/**
 * @title MoonCat​Lootprints
 * @dev MoonCats have found some plans for building spaceships
 */
contract MoonCatLootprints is IERC165, IERC721Enumerable, IERC721Metadata {

    /* ERC-165 */

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
        return (interfaceId == type(IERC721).interfaceId ||
                interfaceId == type(IERC721Metadata).interfaceId ||
                interfaceId == type(IERC721Enumerable).interfaceId);
    }

    /* External Contracts */

    IMoonCatAcclimator MCA = IMoonCatAcclimator(0xc3f733ca98E0daD0386979Eb96fb1722A1A05E69);
    IMoonCatRescue MCR = IMoonCatRescue(0x60cd862c9C687A9dE49aecdC3A99b74A4fc54aB6);
    IMoonCatLootprintsMetadata public Metadata;

    /* Name String Data */

    string[4] internal honorifics =
        [
         "Legendary",
         "Notorious",
         "Distinguished",
         "Renowned"
         ];

    string[32] internal adjectives =
        [
         "Turbo",
         "Tectonic",
         "Rugged",
         "Derelict",
         "Scratchscarred",
         "Purrfect",
         "Rickety",
         "Sparkly",
         "Ethereal",
         "Hissing",
         "Pouncing",
         "Stalking",
         "Standing",
         "Sleeping",
         "Playful",
         "Menancing", // Poor Steve.
         "Cuddly",
         "Neurotic",
         "Skittish",
         "Impulsive",
         "Sly",
         "Ponderous",
         "Prodigal",
         "Hungry",
         "Grumpy",
         "Harmless",
         "Mysterious",
         "Frisky",
         "Furry",
         "Scratchy",
         "Patchy",
         "Hairless"
         ];

    string[15] internal mods =
        [
         "Star",
         "Galaxy",
         "Constellation",
         "World",
         "Moon",
         "Alley",
         "Midnight",
         "Wander",
         "Tuna",
         "Mouse",
         "Catnip",
         "Toy",
         "Kibble",
         "Hairball",
         "Litterbox"
         ];

    string[32] internal mains =
        [
         "Lightning",
         "Wonder",
         "Toebean",
         "Whisker",
         "Paw",
         "Fang",
         "Tail",
         "Purrbox",
         "Meow",
         "Claw",
         "Scratcher",
         "Chomper",
         "Nibbler",
         "Mouser",
         "Racer",
         "Teaser",
         "Chaser",
         "Hunter",
         "Leaper",
         "Sleeper",
         "Pouncer",
         "Stalker",
         "Stander",
         "TopCat",
         "Ambassador",
         "Admiral",
         "Commander",
         "Negotiator",
         "Vandal",
         "Mischief",
         "Ultimatum",
         "Frolic"
         ];

    string[16] internal designations =
        [
         "Alpha",
         "Tau",
         "Pi",
         "I",
         "II",
         "III",
         "IV",
         "V",
         "X",
         "Prime",
         "Proper",
         "1",
         "1701-D",
         "2017",
         "A",
         "Runt"
         ];

    /* Data */

    bytes32[400] ColorTable;

    /* Structs */

    struct Lootprint {
        uint16 index;
        address owner;
    }

    /* State */

    using EnumerableSet for EnumerableSet.Set;

    address payable public contractOwner;

    bool public frozen = true;

    bool public mintingWindowOpen = true;

    uint8 revealCount = 0;

    uint256 public price = 50000000000000000;

    bytes32[100] NoChargeList;

    bytes32[20] revealBlockHashes;

    Lootprint[25600] public Lootprints; // lootprints by lootprintId/rescueOrder

    EnumerableSet.Set internal LootprintIdByIndex;

    mapping(address => EnumerableSet.Set) internal LootprintsByOwner;

    mapping(uint256 => address) private TokenApprovals; // lootprint id -> approved address

    mapping(address => mapping(address => bool)) private OperatorApprovals; // owner address -> operator address -> bool

    /* Modifiers */

    modifier onlyContractOwner () {
        require(msg.sender == contractOwner, "Only Contract Owner");
        _;
    }

    modifier lootprintExists (uint256 lootprintId) {
        require(LootprintIdByIndex.contains(lootprintId), "ERC721: operator query for nonexistent token");
        _;
    }

    modifier onlyOwnerOrApproved(uint256 lootprintId) {
        require(LootprintIdByIndex.contains(lootprintId), "ERC721: query for nonexistent token");
        address owner = ownerOf(lootprintId);
        require(msg.sender == owner || msg.sender == TokenApprovals[lootprintId] || OperatorApprovals[owner][msg.sender],
                "ERC721: transfer caller is not owner nor approved");
        _;
    }

    modifier notFrozen () {
        require(!frozen, "Frozen");
        _;
    }

    /* ERC-721 Helpers */

    function setApprove(address to, uint256 lootprintId) private {
        TokenApprovals[lootprintId] = to;
        emit Approval(msg.sender, to, lootprintId);
    }

    function handleTransfer(address from, address to, uint256 lootprintId) private {
        require(to != address(0), "ERC721: transfer to the zero address");
        setApprove(address(0), lootprintId);
        LootprintsByOwner[from].remove(lootprintId);
        LootprintsByOwner[to].add(lootprintId);
        Lootprints[lootprintId].owner = to;
        emit Transfer(from, to, lootprintId);
    }

    /* ERC-721 */

    function totalSupply() public view override returns (uint256) {
        return LootprintIdByIndex.length();
    }

    function balanceOf(address owner) public view override returns (uint256 balance) {
        return LootprintsByOwner[owner].length();
    }

    function ownerOf(uint256 lootprintId) public view override returns (address owner) {
        return Lootprints[lootprintId].owner;
    }

    function approve(address to, uint256 lootprintId) public override lootprintExists(lootprintId) {
        address owner = ownerOf(lootprintId);
        require(to != owner, "ERC721: approval to current owner");
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "ERC721: approve caller is not owner nor approved for all");
        setApprove(to, lootprintId);
    }

    function getApproved(uint256 lootprintId) public view override returns (address operator) {
        return TokenApprovals[lootprintId];
    }

    function setApprovalForAll(address operator, bool approved) public override {
        require(operator != msg.sender, "ERC721: approve to caller");
        OperatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return OperatorApprovals[owner][operator];
    }

    function safeTransferFrom(address from, address to, uint256 lootprintId, bytes memory _data) public override onlyOwnerOrApproved(lootprintId) {
        handleTransfer(from, to, lootprintId);
        uint256 size;
        assembly {
            size := extcodesize(to)
        }
        if (size > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, lootprintId, _data) returns (bytes4 retval) {
                if (retval != IERC721Receiver.onERC721Received.selector) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }

    function safeTransferFrom(address from, address to, uint256 lootprintId) public override {
        safeTransferFrom(from, to, lootprintId, "");
    }

    function transferFrom(address from, address to, uint256 lootprintId) public override onlyOwnerOrApproved(lootprintId) {
        handleTransfer(from, to, lootprintId);
    }

    /* ERC-721 Enumerable */

    function tokenByIndex(uint256 index) public view override returns (uint256) {
        return LootprintIdByIndex.at(index);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return LootprintsByOwner[owner].at(index);
    }

    /* Reveal */

    bool pendingReveal = false;
    uint256 revealPrepBlock;
    bytes32 revealSeedHash;

    /**
     * @dev How many lootprints are awaiting being revealed?
     */
    function pendingRevealCount() public view returns (uint256) {
        uint256 numRevealed = revealCount * 2560;
        if (numRevealed > LootprintIdByIndex.length()) return 0;
        return LootprintIdByIndex.length() - numRevealed;
    }

    /**
     * @dev Start a reveal action.
     * The hash submitted here must be the keccak256 hash of a secret number that will be submitted to the next function
     */
    function prepReveal(bytes32 seedHash) public onlyContractOwner {
        require(!pendingReveal && seedHash != revealSeedHash && revealCount < 20, "Prep Conditions Not Met");
        revealSeedHash = seedHash;
        revealPrepBlock = block.number;
        pendingReveal = true;
    }

    /**
     * @dev Finalize a reveal action.
     * Must take place at least one block after the `prepReveal` action was taken
     */
    function reveal(uint256 revealSeed) public onlyContractOwner{
        require(pendingReveal
                && block.number > revealPrepBlock
                && keccak256(abi.encodePacked(revealSeed)) == revealSeedHash
                , "Reveal Conditions Not Met");

        if (block.number - revealPrepBlock < 255) {
            bytes32 blockSeed = keccak256(abi.encodePacked(revealSeed, blockhash(revealPrepBlock)));
            revealBlockHashes[revealCount] = blockSeed;
            revealCount++;
        }
        pendingReveal = false;
    }

    /* Minting */

    /**
     * @dev Is the minting of a specific rescueOrder needing payment or is it free?
     */
    function paidMint(uint256 rescueOrder) public view returns (bool) {
        uint256 wordIndex = rescueOrder / 256;
        uint256 bitIndex = rescueOrder % 256;
        return (uint(NoChargeList[wordIndex] >> (255 - bitIndex)) & 1) == 0;
    }

    /**
     * @dev Create the token
     * Checks that the address minting is the current owner of the MoonCat, and ensures that MoonCat is Acclimated
     */
    function handleMint(uint256 rescueOrder, address to) private {
        require(mintingWindowOpen, "Minting Window Closed");
        require(MCR.catOwners(MCR.rescueOrder(rescueOrder)) == 0xc3f733ca98E0daD0386979Eb96fb1722A1A05E69,
                "Not Acclimated");
        address moonCatOwner = MCA.ownerOf(rescueOrder);
        require((msg.sender == moonCatOwner)
            || (msg.sender == MCA.getApproved(rescueOrder))
            || (MCA.isApprovedForAll(moonCatOwner, msg.sender)),
            "Not AMC Owner or Approved"
        );

        require(!LootprintIdByIndex.contains(rescueOrder), "Already Minted");
        Lootprints[rescueOrder] = Lootprint(uint16(LootprintIdByIndex.length()), to);
        LootprintIdByIndex.add(rescueOrder);
        LootprintsByOwner[to].add(rescueOrder);
        emit Transfer(address(0), to, rescueOrder);
    }

    /**
     * @dev Mint a lootprint, and give it to a specific address
     */
    function mint(uint256 rescueOrder, address to) public payable notFrozen {
        if (paidMint(rescueOrder)) {
            require(address(this).balance >= price, "Insufficient Value");
            contractOwner.transfer(price);
        }
        handleMint(rescueOrder, to);
        if (address(this).balance > 0) {
            // The buyer over-paid; transfer their funds back to them
            payable(msg.sender).transfer(address(this).balance);
        }
    }

    /**
     * @dev Mint a lootprint, and give it to the address making the transaction
     */
    function mint(uint256 rescueOrder) public payable {
        mint(rescueOrder, msg.sender);
    }

    /**
     * @dev Mint multiple lootprints, sending them all to a specific address
     */
    function mintMultiple(uint256[] calldata rescueOrders, address to) public payable notFrozen {
        uint256 totalPrice = 0;
        for (uint i = 0; i < rescueOrders.length; i++) {
            if (paidMint(rescueOrders[i])) {
                totalPrice += price;
            }
            handleMint(rescueOrders[i], to);
        }
        require(address(this).balance >= totalPrice, "Insufficient Value");
        if (totalPrice > 0) {
            contractOwner.transfer(totalPrice);
        }
        if (address(this).balance > 0) {
            // The buyer over-paid; transfer their funds back to them
            payable(msg.sender).transfer(address(this).balance);
        }
    }

    /**
     * @dev Mint multiple lootprints, sending them all to the address making the transaction
     */
    function mintMultiple(uint256[] calldata rescueOrders) public payable {
        mintMultiple(rescueOrders, msg.sender);
    }

    /* Contract Owner */

    constructor(address metadataContract) {
        contractOwner = payable(msg.sender);

        Metadata = IMoonCatLootprintsMetadata(metadataContract);

        // https://docs.ens.domains/contract-api-reference/reverseregistrar#claim-address
        IReverseResolver(0x084b1c3C81545d370f3634392De611CaaBFf8148)
            .claim(msg.sender);
    }

    /**
     * @dev Mint the 160 Hero lootprint tokens, and give them to the contract owner
     */
    function setupHeroShips(bool groupTwo) public onlyContractOwner {
        uint startIndex = 25440;
        if (groupTwo) {
             startIndex = 25520;
        }
        require(Lootprints[startIndex].owner == address(0), "Already Set Up");
        for (uint i = startIndex; i < (startIndex+80); i++) {
            Lootprints[i] = Lootprint(uint16(LootprintIdByIndex.length()), contractOwner);
            LootprintIdByIndex.add(i);
            LootprintsByOwner[contractOwner].add(i);
            emit Transfer(address(0), contractOwner, i);
        }
    }

    /**
     * @dev Update the contract used for image/JSON rendering
     */
    function setMetadataContract(address metadataContract) public onlyContractOwner{
        Metadata = IMoonCatLootprintsMetadata(metadataContract);
    }

    /**
     * @dev Set configuration values for which MoonCat creates which color lootprint when minted
     */
    function setColorTable(bytes32[] calldata table, uint startAt) public onlyContractOwner {
        for (uint i = 0; i < table.length; i++) {
            ColorTable[startAt + i] = table[i];
        }
    }

    /**
     * @dev Set configuration values for which MoonCats need to pay for minting a lootprint
     */
    function setNoChargeList (bytes32[100] calldata noChargeList) public onlyContractOwner {
        NoChargeList = noChargeList;
    }

    /**
     * @dev Set configuration values for how much a paid lootprint costs
     */
    function setPrice(uint256 priceWei) public onlyContractOwner {
        price = priceWei;
    }

    /**
     * @dev Allow current `owner` to transfer ownership to another address
     */
    function transferOwnership (address payable newOwner) public onlyContractOwner {
        contractOwner = newOwner;
    }

    /**
     * @dev Prevent creating lootprints
     */
    function freeze () public onlyContractOwner notFrozen {
        frozen = true;
    }

    /**
     * @dev Enable creating lootprints
     */
    function unfreeze () public onlyContractOwner {
        frozen = false;
    }

    /**
     * @dev Prevent any further minting from happening
     * Checks to ensure all have been revealed before allowing locking down the minting process
     */
    function permanentlyCloseMintingWindow() public onlyContractOwner {
        require(revealCount >= 20, "Reveal Pending");
        mintingWindowOpen = false;
    }

    /* Property Decoders */

    function decodeColor(uint256 rescueOrder) public view returns (uint8) {
        uint256 wordIndex = rescueOrder / 64;
        uint256 nibbleIndex = rescueOrder % 64;
        bytes32 word = ColorTable[wordIndex];
        return uint8(uint(word >> (252 - nibbleIndex * 4)) & 15);
    }

    function decodeName(uint32 seed) internal view returns (string memory) {
        seed = seed >> 8;
        uint index;
        string[9] memory parts;
        //honorific
        index = seed & 15;
        if (index < 8) {
            parts[0] = "The ";
            if (index < 4) {
                parts[1] = honorifics[index];
                parts[2] = " ";
            }
        }
        seed >>= 4;
        //adjective
        if ((seed & 1) == 1) {
            index = (seed >> 1) & 31;
            parts[3] = adjectives[index];
            parts[4] = " ";
        }
        seed >>= 6;
        //mod
        index = seed & 15;
        if (index < 15) {
            parts[5] = mods[index];
        }
        seed >>= 4;
        //main
        index = seed & 31;
        parts[6] = mains[index];
        seed >>= 5;
        //designation
        if ((seed & 1) == 1) {
            index = (seed >> 1) & 15;
            parts[7] = " ";
            parts[8] = designations[index];
        }

        return string(abi.encodePacked(parts[0], parts[1], parts[2],
                                       parts[3], parts[4], parts[5],
                                       parts[6], parts[7], parts[8]));

    }

    function decodeClass(uint32 seed) internal pure returns (uint8) {
        uint class_determiner = seed & 15;
        if (class_determiner < 2) {
            return 0;
        } else if (class_determiner < 5) {
            return 1;
        } else if (class_determiner < 9) {
            return 2;
        } else {
            return 3;
        }
    }

    function decodeBays(uint32 seed) internal pure returns (uint8) {
        uint bay_determiner = (seed >> 4) & 15;

        if (bay_determiner < 3) {
            return 5;
        } else if (bay_determiner < 8) {
            return 4;
        } else {
            return 3;
        }
    }

    uint8 constant internal STATUS_NOT_MINTED = 0;
    uint8 constant internal STATUS_NOT_MINTED_FREE = 1;
    uint8 constant internal STATUS_PENDING = 2;
    uint8 constant internal STATUS_MINTED = 3;

    /**
     * @dev Get detailed traits about a lootprint token
     * Provides trait values in native contract return values, which can be used by other contracts
     */
    function getDetails (uint256 lootprintId)
        public
        view
        returns (uint8 status, string memory class, uint8 bays, string memory colorName, string memory shipName, address tokenOwner, uint32 seed)
    {
        Lootprint memory lootprint = Lootprints[lootprintId];
        colorName = Metadata.getColorName(decodeColor(lootprintId));
        tokenOwner = address(0);
        if (LootprintIdByIndex.contains(lootprintId)) {
            if (revealBlockHashes[lootprint.index / 1280] > 0) {
                seed = uint32(uint256(keccak256(abi.encodePacked(lootprintId, revealBlockHashes[lootprint.index / 1280]))));
                return (STATUS_MINTED,
                        Metadata.getClassName(decodeClass(seed)),
                        decodeBays(seed),
                        colorName,
                        decodeName(seed),
                        lootprint.owner,
                        seed);
            }
            status = STATUS_PENDING;
            tokenOwner = lootprint.owner;
        } else if (paidMint(lootprintId)) {
            status = STATUS_NOT_MINTED;
        } else {
            status = STATUS_NOT_MINTED_FREE;
        }
        return (status, "Unknown", 0, colorName, "?", tokenOwner, 0);
    }

    /* ERC-721 Metadata */

    function name() public pure override returns (string memory) {
        return "MoonCatLootprint";
    }

    function symbol() public pure override returns (string memory) {
        return unicode"📜";
    }

    function tokenURI(uint256 lootprintId) public view override lootprintExists(lootprintId) returns (string memory) {
        Lootprint memory lootprint = Lootprints[lootprintId];
        uint8 colorId = decodeColor(lootprintId);
        if (revealBlockHashes[lootprint.index / 1280] > 0) {
            uint32 seed = uint32(uint256(keccak256(abi.encodePacked(lootprintId, revealBlockHashes[lootprint.index / 1280]))));
            uint8 classId = decodeClass(seed);
            string memory shipName = decodeName(seed);
            uint8 bays = decodeBays(seed);
            return Metadata.getJSON(lootprintId, classId, colorId, bays, shipName);
        } else {
            return Metadata.getJSON(lootprintId, 4, colorId, 0, "?");
        }
    }

    function imageURI(uint256 lootprintId) public view lootprintExists(lootprintId) returns (string memory) {
        Lootprint memory lootprint = Lootprints[lootprintId];
        uint8 colorId = decodeColor(lootprintId);
        if (revealBlockHashes[lootprint.index / 1280] > 0) {
            uint32 seed = uint32(uint256(keccak256(abi.encodePacked(lootprintId, revealBlockHashes[lootprint.index / 1280]))));
            uint8 classId = decodeClass(seed);
            string memory shipName = decodeName(seed);
            uint8 bays = decodeBays(seed);
            return Metadata.getImage(lootprintId, classId, colorId, bays, shipName);
        } else {
            return Metadata.getImage(lootprintId, 4, colorId, 0, "?");
        }
    }

    /* Rescue Tokens */

    /**
     * @dev Rescue ERC20 assets sent directly to this contract.
     */
    function withdrawForeignERC20(address tokenContract)
        public
        onlyContractOwner
    {
        IERC20 token = IERC20(tokenContract);
        token.transfer(contractOwner, token.balanceOf(address(this)));
    }

    /**
     * @dev Rescue ERC721 assets sent directly to this contract.
     */
    function withdrawForeignERC721(address tokenContract, uint256 lootprintId)
        public
        onlyContractOwner
    {
        IERC721(tokenContract).safeTransferFrom(address(this), contractOwner, lootprintId);
    }

}