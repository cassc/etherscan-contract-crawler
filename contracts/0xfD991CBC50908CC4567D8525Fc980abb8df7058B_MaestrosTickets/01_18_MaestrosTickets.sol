pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

//////////*////@&////////////(((&   ((@( ((//////////*//////////*///////////////
//////****/////@/////////////(**/**#*  ,*%///////////*/////////**///////////////
//////////////@@////**///////#/(       ./*/////(////////////////////////////////
//////////////@//////*///////#/*.*/*,&@%((*////(/(/(//*/////////////////////////
////////////(&&//////////////#*(*@%*,   *&/(//*///(*//////////*/*///////////////
////////////*@////////*/*/////(*/  (/*  /#*//////////////////(/(**//////////////
///////////(&@(//////////*//////(/#/#./ (#*//////////////////((*////////*///////
////////////@#///////////////////(#.  *( *#//////////////////(*/////////////////
////////#/%****/*//////////////(/%/#(*@@@@/*#*/////////////////////*/*//////////
///////*//*((/*/*////////////((/@@@%@@@((**@#@(((///////////////////////////////
///////*@@%@@* ,(//////(((#@@@@*@/,*/#&(*@@/&@@@@*(#/*/////////////*//(/////////
///////*&@@*(, *(/*((@@@@@@@@&/* /    */@@/#@@@@@/(*(///////////////////////////
///*////(*/* *#//(@@@@((@@#@@(. *    *@@@/(@@@@/((*@((//////////*/(/////////////
///////(/ /#@#@(@@@#@@/@@%@@/*      *#@@((@@@@/(%@@@@/(//////////(//////////////
///////(@@%%@@@@@@(@@@@%/@@#*  ,    /@@((@@@@&#(@@@@@#(*/////////*(/#///////*///
//***///(@@@@@@%/@@@@@@/(@@/*    * (@@/(@@@@@((@@@@@@@/(////////////////////*/*/
////*///(@@@@@@@@@@@@@//(@@(, *   *@@&(%@@@@((((@@@@@@@(#////////////////////*//
///*////(@@@@@@@@@@#***(%@@@( ,.*/(@@(/@@@@(/@%(/@@@@@@((////(/((  *(*//////////
//////////@@@@@@(*/**/**@@@@@@#((@@@@(@@@@%/@@((#(@@@@@@/(#@@%(/*./*(*//////////
///////*/*(/((*/*//////*#@@@@@@##@@@@/@@@@@(/@#((((@@@@@@@@@@@@#/  ,@@#((%*/#(//
//////////////((/////////@@@@@#@@@@@%/@@@@@@(#(((//(*/@@@@@@@&#(&*****//*///////
////////////*((/*///////*@@@@@%@@@@@@/@@@@@@((((@#////(########@(@##////////////
//////////////(/*///////*%@@@@@&@%(@@(@@@@@@(#@/@#(/////////////////////////////
//////////////*(///////(/%@@@@@@@@@@@#/@@@@&(*#/&@&#//////*/////////////*///**//
/////////*////*/////*/*(#@@@@@@@@&@@@@/@@@@(@@/(*%/@#(//////**////*/*//(/*//***/
////////////////**///////@@@@@@@@#&@@@(@@@@(@@*&@@@@((/*/*//////////////****////
///////*////*///*//////*/@@@@@@@@#(@@@@/@@@((@((@@@@@(//(((////////////(**//////
/////////////////////////@@@@@@@@@%/@@@%/@@@((&(@@@@@((/**((/////////***////////
////////*///////////////(@@@@@@@@@((/@@@@/%#&/((@@@@@##/////(///////*///////////
/////////////////////////%@@@@@@@@%/**@@@@@@@@/(@@@@@&(///(/////////////////////
/////////////////////////(@@@@@@@@@((//@@@@@@@@/(@@@@@(/////////////////////////
///////////////////////////@@@@@@@@(////#@@@@@@@(#@@@@(#////////////////////////

/**
 * https://opus-labs.io/
 * @title   Maestro - Tickets
 * @notice  ADMIT ONE to Maestro - Genesis mint
 * @author  BowTiedPickle
 */
contract MaestrosTickets is ERC721, ERC2981, Ownable {
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;
    using Strings for uint256;

    event Mint(uint256 tokenId, uint8 tier);
    event NewRoot(bytes32 oldRoot, bytes32 newRoot);
    event NewURI(string oldURI, string newURI);
    event NewRoyalty(uint96 _newRoyalty);
    event PhaseStatus(uint256 phase, bool oldStatus, bool newStatus);
    event TierInfoUpdated(
        uint256 indexed tier,
        uint16 newSupply,
        uint64 newPrice,
        uint16 newWeight
    );
    event Withdrawal(uint256 _balance);
    event SoulbindReleased();
    event URIFrozen(string _finalURI);

    Counters.Counter internal nextId;

    uint8 public constant TICKET_DIAMOND = 1;
    uint8 public constant TICKET_GOLD = 2;
    uint8 public constant TICKET_SILVER = 3;
    uint8 public constant TICKET_BRONZE = 4;

    uint8 public constant MAX_WEIGHT_PER_USER = 12;

    struct TierInfo {
        uint16 maxSupply;
        uint16 minted;
        uint64 price;
        uint16 ticketWeight;
    }

    mapping(uint256 => TierInfo) public tiers;

    bytes32 public whitelistMerkleRoot;
    bytes32 public claimlistMerkleRoot;

    mapping(address => uint256) public userToWeight;
    mapping(address => bool) public claimed;

    mapping(uint256 => uint8) public ticketTier;

    string public baseURI;
    bool public frozen;

    IERC20 public immutable USDC;

    bool public claimActive;
    bool public whitelistActive;
    bool public soulbound = true;

    /**
     * @param _USDC     Address of USDC implementation
     * @param _weights  Array of ticket weights
     * @param _prices   Array of ticket prices denominated in USDC (6 decimals)
     * @param _supplies Array of max supplies of each ticket tier
     */
    constructor(
        IERC20 _USDC,
        uint16[] memory _weights,
        uint64[] memory _prices,
        uint16[] memory _supplies
    ) ERC721("Maestro - Tickets", "MTKT") {
        uint256 len = _weights.length;
        require(
            _prices.length == len && _supplies.length == len && len == 4,
            "!len"
        );

        nextId.increment();
        USDC = _USDC;

        _setDefaultRoyalty(msg.sender, 500);

        for (uint256 i; i < len; ++i) {
            TierInfo storage tier = tiers[i + 1];
            tier.ticketWeight = _weights[i];
            tier.price = _prices[i];
            tier.maxSupply = _supplies[i];
            emit TierInfoUpdated(i, _supplies[i], _prices[i], _weights[i]);
        }
    }

    // ----- Public Functions -----

    /**
     * @notice  Purchase an NFT
     * @dev     Approve this contract for the desired amount of USDC first
     * @param   _to     NFT destination address
     * @param   _tier   Ticket tier
     * @param   _qty    Number of tickets to mint
     * @param   _proof  Merkle proof of whitelist
     */
    function mint(
        address _to,
        uint8 _tier,
        uint8 _qty,
        bytes32[] calldata _proof
    ) external {
        require(whitelistActive, "!active");
        require(_tier <= TICKET_BRONZE && _tier > 0, "!tier");
        require(_qty > 0, "!zeroQty");

        TierInfo storage tier = tiers[_tier];
        uint256 weight = tier.ticketWeight * _qty;
        require(userToWeight[_to] + weight <= MAX_WEIGHT_PER_USER, "!userMax");

        require(tier.minted + _qty <= tier.maxSupply, "!supply");

        bytes32 leaf = keccak256(abi.encodePacked(_to));
        require(
            MerkleProof.verify(_proof, whitelistMerkleRoot, leaf),
            "!proof"
        );

        USDC.safeTransferFrom(msg.sender, address(this), tier.price * _qty);

        tier.minted += _qty;
        userToWeight[_to] += weight;
        mintInternal(_to, _qty, _tier);
    }

    /**
     * @notice  Claim a free NFT
     * @param   _to     NFT destination address
     * @param   _tier   Ticket tier
     * @param   _proof  Merkle proof of whitelist
     */
    function claim(
        address _to,
        uint8 _tier,
        bytes32[] calldata _proof
    ) external {
        require(claimActive, "!active");
        require(_tier <= TICKET_BRONZE && _tier > 0, "!tier");
        require(!claimed[_to], "!claimed");

        TierInfo storage tier = tiers[_tier];

        require(tier.minted + 1 <= tier.maxSupply, "!supply");

        bytes32 leaf = keccak256(abi.encodePacked(_to, _tier));
        require(
            MerkleProof.verify(_proof, claimlistMerkleRoot, leaf),
            "!proof"
        );

        tier.minted += 1;
        claimed[_to] = true;
        mintInternal(_to, 1, _tier);
    }

    // ----- Internal Functions -----

    function mintInternal(
        address _to,
        uint256 _qty,
        uint8 _tier
    ) internal {
        for (uint256 i; i < _qty; ++i) {
            uint256 tokenId = nextId.current();
            nextId.increment();

            ticketTier[tokenId] = _tier;
            _mint(_to, tokenId);

            emit Mint(tokenId, _tier);
        }
    }

    // ----- View Functions -----

    /**
     * @notice  View the total number of NFTs minted
     * @return  Total number of NFTs minted
     */
    function totalSupply() external view returns (uint256) {
        return nextId.current() - 1;
    }

    /**
     * @notice  View the number of NFTs minted in each tier
     * @return  Array of the number of NFTs minted in each tier
     */
    function mintedByTier() external view returns (uint256[] memory) {
        uint256[] memory minted = new uint256[](4);

        for (uint256 i; i < 4; ++i) {
            minted[i] = tiers[i + 1].minted;
        }

        return minted;
    }

    /**
     * @notice  View the number of NFTs remaining in each tier
     * @return  Array of the number of NFTs remaining in each tier
     */
    function remainingByTier() external view returns (uint256[] memory) {
        uint256[] memory remaining = new uint256[](4);

        for (uint256 i; i < 4; ++i) {
            remaining[i] = tiers[i + 1].maxSupply - tiers[i + 1].minted;
        }

        return remaining;
    }

    // ----- Admin Functions -----

    /**
     * @notice  Edit the parameters of a tier
     * @param   _tier           The tier ID to modify
     * @param   _newMaxSupply   New maximum supply of the ticket tier
     * @param   _newPrice       New price of the ticket tier
     * @param   _newWeight      New weight cost of the ticket tier
     */
    function editTier(
        uint8 _tier,
        uint16 _newMaxSupply,
        uint16 _newPrice,
        uint16 _newWeight
    ) external onlyOwner {
        require(_tier <= TICKET_BRONZE && _tier > 0, "!tier");
        TierInfo storage tier = tiers[_tier];
        require(_newMaxSupply >= tier.minted, "!newSupply");

        tier.maxSupply = _newMaxSupply;
        tier.price = _newPrice;
        tier.ticketWeight = _newWeight;

        emit TierInfoUpdated(_tier, _newMaxSupply, _newPrice, _newWeight);
    }

    /**
     * @notice  Set one of the merkle roots
     * @param   _ID         0 for whitelist root, 1 for claimlist root
     * @param   _newRoot    New Merkle tree root
     */
    function setMerkleRoot(uint256 _ID, bytes32 _newRoot) external onlyOwner {
        require(_ID < 2, "!id");
        if (_ID == 0) {
            emit NewRoot(whitelistMerkleRoot, _newRoot);
            whitelistMerkleRoot = _newRoot;
        } else {
            emit NewRoot(claimlistMerkleRoot, _newRoot);
            claimlistMerkleRoot = _newRoot;
        }
    }

    /**
     * @notice  Set the sale activity status of whitelist or claimlist
     * @param   _ID         0 for whitelist, 1 for claimlist
     * @param   _newStatus  true for phase active, false for inactive
     */
    function setPhaseStatus(uint256 _ID, bool _newStatus) external onlyOwner {
        require(_ID < 2, "!id");
        if (_ID == 0) {
            emit PhaseStatus(_ID, whitelistActive, _newStatus);
            whitelistActive = _newStatus;
        } else {
            emit PhaseStatus(_ID, claimActive, _newStatus);
            claimActive = _newStatus;
        }
    }

    /**
     * @notice  Withdraw profits from the contract
     */
    function withdraw() external onlyOwner {
        uint256 balance = USDC.balanceOf(address(this));
        USDC.transfer(owner(), balance);
        emit Withdrawal(balance);
    }

    /**
     * @notice  Sets a new royalty numerator
     * @dev     Cannot exceed 10%
     * @param   _royaltyBPS   New royalty, denominated in BPS (10000 = 100%)
     * @return  True on success
     */
    function setRoyalty(uint96 _royaltyBPS) external onlyOwner returns (bool) {
        require(_royaltyBPS <= 1000, "!bps");

        _setDefaultRoyalty(owner(), _royaltyBPS);

        emit NewRoyalty(_royaltyBPS);
        return true;
    }

    /**
     * @notice  Set a new base URI
     * @param   _newURI     new URI string
     */
    function setURI(string memory _newURI) external onlyOwner {
        require(!frozen, "!frozen");
        emit NewURI(baseURI, _newURI);
        baseURI = _newURI;
    }

    /**
     * @notice  Freeze the URI, preventing further changes
     */
    function freezeURI() external onlyOwner {
        require(!frozen, "!frozen");
        frozen = true;
        emit URIFrozen(baseURI);
    }

    /**
     * @notice  Release the soulbind, allowing token transfers
     * @dev     Irreversible, double check before calling!
     */
    function releaseSoulbind() external onlyOwner {
        require(soulbound, "!soulbound");
        soulbound = false;
        emit SoulbindReleased();
    }

    // ----- Overrides -----

    /// @inheritdoc ERC721
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /// @inheritdoc ERC721
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _requireMinted(tokenId);

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    /// @inheritdoc ERC721
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        require(!soulbound, "!soulbound");
        super._transfer(from, to, tokenId);
    }

    /// @inheritdoc ERC721
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981)
        returns (bool)
    {
        return
            interfaceId == type(ERC2981).interfaceId ||
            ERC721.supportsInterface(interfaceId);
    }
}