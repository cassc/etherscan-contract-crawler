pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./Interfaces/ITickets.sol";
import "./Interfaces/ITicketStaking.sol";

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
 * @title   Maestro - Genesis
 * @notice  The Concert begins!
 * @author  BowTiedPickle
 */
contract MaestrosGenesis is ERC721, ERC721Enumerable, ERC2981, Ownable {
    using SafeERC20 for IERC20;
    using Strings for uint256;

    // ----- Events -----

    event NewRoot(bytes32 oldRoot, bytes32 newRoot);
    event NewPrice(uint256 oldPrice, uint256 newPrice);
    event NewMaxPerWallet(uint256 oldMax, uint256 newMax);
    event NewURI(string oldURI, string newURI);
    event NewRoyalty(uint96 newRoyalty);
    event NewOffset(uint256 offset);
    event NewHash(bytes32 oldHash, bytes32 newHash);
    event PhaseStatus(uint256 indexed phase, bool oldStatus, bool newStatus);
    event BoostStatus(bool oldStatus, bool newStatus);
    event Withdrawal(uint256 amount);
    event URIFrozen(string finalURI);
    event Composing(uint256 indexed token, bool status);
    event Notified(address indexed user, bool status, uint8 tier);

    // ----- Minting State Variables -----

    uint8 public constant TICKET_DIAMOND = 1;
    uint8 public constant TICKET_GOLD = 2;
    uint8 public constant TICKET_SILVER = 3;
    uint8 public constant TICKET_BRONZE = 4;

    uint8 internal constant TYPE_PUBLIC = 0;
    uint8 internal constant TYPE_TREASURY = 1;

    uint256 public maxPerWallet = 1;

    uint256 public constant maxSupply = 1555;
    uint256 public constant reservedSupply_Tickets = 1152;
    uint256 public constant reservedSupply_Founders = 5;
    uint256 public constant reservedSupply_Treasury = 250;
    uint256 public constant reservedSupply_Public = 148;
    uint256 public available_Public = reservedSupply_Public;
    uint256 public available_Treasury = reservedSupply_Treasury - 1;
    uint256 public available_Tickets = reservedSupply_Tickets;

    uint256 internal nextTicket = 1; // 1-5 for founders, 6 for super legendary, 7-1306 for ticket holders and OGs
    uint256 internal nextTreasury = 1307; // 1307-1555 for treasury NFTs

    bytes32 public whitelistMerkleRoot;

    bool public claimActive;
    bool public mintActive;
    bool public publicActive;

    /// @notice Whether a ticket token ID has claimed its maestros
    mapping(uint256 => bool) public claimed;

    /// @notice How many NFTs an address has minted
    mapping(address => uint256) public minted;

    /// @notice Mint price in USDC
    uint256 public mintPrice;

    // ----- Permanent State Variables -----

    string public unrevealedURI;
    string public baseURI;
    uint256 public offset;
    bool public frozen;
    bytes32 public provenanceHash;

    uint256 internal constant offsetMinId = 7; // Lowest ID to apply offset for
    uint256 internal constant offsetMaxId = 1306; // Highest ID to apply offset for

    IERC20 public immutable USDC;
    ITickets public immutable maestroTickets;
    ITicketStaking public immutable ticketStaking;

    // ----- Composition -----

    mapping(uint256 => uint256) public tokenToComposeTime;
    mapping(uint256 => uint256) public tokenToBoost;
    mapping(address => uint256) public stakedBalance;

    uint256 composingLock = 1;

    mapping(uint8 => uint256) public tierToWeight;
    mapping(address => mapping(uint8 => uint256)) userToTierToAvailableBoosts;
    uint256 public constant WEIGHT_DENOMINATOR = 10_000;

    bool public boostEnabled = true;

    // ----- Construction and Initialization -----

    /**
     * @param   _USDC             Address of USDC implementation
     * @param   _maestroTickets   Address of Maestro - Tickets contract
     * @param   _ticketStaking    Address of Ticket staking contract
     * @param   _founders         Addresses to receive founder NFTs
     * @param   _treasury         Address to receive 1/1 tokenId 6
     * @param   _mintPrice        Mint price in USDC
     */
    constructor(
        IERC20 _USDC,
        ITickets _maestroTickets,
        ITicketStaking _ticketStaking,
        address[] memory _founders,
        address _treasury,
        uint256 _mintPrice
    ) ERC721("Maestro - Genesis", "MGEN") {
        require(_founders.length == reservedSupply_Founders, "!length");

        // Mint Founders
        for (uint256 i; i < reservedSupply_Founders; ) {
            // TYPE_PUBLIC
            mintInternal(_founders[i], 1, TYPE_PUBLIC);
            unchecked {
                ++i;
            }
        }

        // Mint Treasury
        mintInternal(_treasury, 1, TYPE_PUBLIC);

        USDC = _USDC;
        maestroTickets = _maestroTickets;
        ticketStaking = _ticketStaking;
        mintPrice = _mintPrice;

        // Manual override to prevent a lost ticket from claiming Maestros if it resurfaces
        claimed[25] = true;

        tierToWeight[TICKET_DIAMOND] = 20_000;
        tierToWeight[TICKET_GOLD] = 15_000;
        tierToWeight[TICKET_SILVER] = 12_500;
        tierToWeight[TICKET_BRONZE] = 11_000;

        _setDefaultRoyalty(msg.sender, 500);
    }

    // ----- Minting Functions -----

    /**
     * @notice  Purchase Maestros
     * @dev     Approve this contract for the desired amount of USDC first
     * @param   _to     NFT destination address
     * @param   _qty    Number of Maestros to mint
     * @param   _proof  Merkle proof of whitelist
     */
    function mint(
        address _to,
        uint8 _qty,
        bytes32[] calldata _proof
    ) external {
        require(mintActive, "!active");
        require(_qty > 0, "!zeroQty");
        require(minted[_to] + _qty <= maxPerWallet, "!userMax");
        require(available_Public >= _qty, "!supply");

        if (!publicActive) {
            bytes32 leaf = keccak256(abi.encodePacked(_to));
            require(
                MerkleProof.verify(_proof, whitelistMerkleRoot, leaf),
                "!proof"
            );
        }

        USDC.safeTransferFrom(msg.sender, address(this), mintPrice * _qty);

        unchecked {
            available_Public -= _qty; // Already checked
            minted[_to] += _qty; // Adding uint8 capped at available_Public will never overflow uint256
        }

        mintInternal(_to, _qty, TYPE_PUBLIC);
    }

    /**
     * @notice  Claim the Maestros associated with your Maestro - Tickets NFT
     * @param   _token  Ticket ID
     */
    function claim(uint256 _token) external {
        require(msg.sender == maestroTickets.ownerOf(_token), "!ticketOwner");

        claimInternal(msg.sender, _token);
    }

    // ----- Staking -----

    /**
     * @notice  Stake a Maestro to start generating Notes
     * @param   _token  Token ID of the Maestro to stake
     */
    function compose(uint256 _token) external {
        composeInternal(_token);
    }

    /**
     * @notice  Stake multiple Maestros to start generating Notes
     * @param   _tokens     Token IDs of the Maestros to stake
     */
    function composeMultiple(uint256[] calldata _tokens) external {
        uint256 len = _tokens.length;
        for (uint256 i; i < len; ) {
            composeInternal(_tokens[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice  Unstake a Maestro to stop generating Notes
     * @param   _token  Token ID of the Maestro to unstake
     */
    function retire(uint256 _token) external {
        retireInternal(msg.sender, _token);
    }

    /**
     * @notice  Unstake multiple Maestros to stop generating Notes
     * @param   _tokens     Token IDs of the Maestros to unstake
     */
    function retireMultiple(uint256[] calldata _tokens) external {
        uint256 len = _tokens.length;
        for (uint256 i; i < len; ) {
            retireInternal(msg.sender, _tokens[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice  Transfer a Maestro safely while it is still composing
     * @dev     May only be called by the token owner
     * @param   _from   From address
     * @param   _to     Destination address
     * @param   _token  Token ID
     */
    function transferWhileComposing(
        address _from,
        address _to,
        uint256 _token
    ) external {
        require(msg.sender == ownerOf(_token), "!owner");
        composingLock = 2;
        _safeTransfer(_from, _to, _token, "");
        composingLock = 1;
    }

    /**
     * @notice  Update the Maestro - Genesis contract when a ticket is staked or unstaked
     * @dev     May only be called by the ticket staking contract
     */
    function notifyTicketStaked(
        bool _status,
        address _user,
        uint8 _tier
    ) external {
        require(msg.sender == address(ticketStaking), "!stakingContract");
        uint256 qty = tierToQty(_tier);
        if (_status) {
            userToTierToAvailableBoosts[_user][_tier] += qty;
        } else {
            userToTierToAvailableBoosts[_user][_tier] -= qty;
        }
        updateBoosts(_user);
        emit Notified(_user, _status, _tier);
    }

    // ----- Internal Functions -----

    function claimInternal(address _to, uint256 _token) internal {
        require(claimActive, "!active");
        require(!claimed[_token], "!claimed");

        uint8 tier = maestroTickets.ticketTier(_token);
        uint256 qty = tierToQty(tier);

        require(available_Tickets >= qty, "!ticketsSupply");
        unchecked {
            available_Tickets -= qty; // Already checked
        }
        claimed[_token] = true;
        mintInternal(_to, qty, TYPE_PUBLIC);
    }

    function tierToQty(uint8 _tier) internal pure returns (uint256) {
        uint256 qty;
        if (_tier == TICKET_DIAMOND) {
            qty = 5;
        } else if (_tier == TICKET_GOLD) {
            qty = 3;
        } else if (_tier == TICKET_SILVER) {
            qty = 2;
        } else if (_tier == TICKET_BRONZE) {
            qty = 1;
        } else {
            revert("!tier");
        }

        return qty;
    }

    function mintInternal(
        address _to,
        uint256 _qty,
        uint8 _type
    ) internal {
        uint256 tokenId;
        if (_type == TYPE_PUBLIC) {
            for (uint256 i; i < _qty; ++i) {
                tokenId = nextTicket;
                unchecked {
                    ++nextTicket;
                }
                _mint(_to, tokenId);
            }
        } else if (_type == TYPE_TREASURY) {
            for (uint256 i; i < _qty; ++i) {
                tokenId = nextTreasury;
                unchecked {
                    ++nextTreasury;
                }
                _mint(_to, tokenId);
            }
        } else {
            revert("!type");
        }
    }

    function composeInternal(uint256 _token) internal {
        require(tokenToComposeTime[_token] == 0, "composing");
        require(msg.sender == ownerOf(_token), "!owner");
        tokenToComposeTime[_token] = block.timestamp;
        ++stakedBalance[msg.sender];
        updateBoosts(msg.sender);
        emit Composing(_token, true);
    }

    function retireInternal(address _user, uint256 _token) internal {
        require(_user == ownerOf(_token), "!owner");
        require(tokenToComposeTime[_token] != 0, "!composing");
        tokenToComposeTime[_token] = 0;
        --stakedBalance[_user];
        updateBoosts(_user);
        emit Composing(_token, false);
    }

    /// @dev    Update the ticket boosts
    function updateBoosts(address _user) internal {
        uint256 balance = balanceOf(_user);
        uint256[4] memory boosts = viewAvailableBoosts(_user);
        uint256[4] memory used;

        uint256 tokenId;
        for (uint256 i; i < balance; ++i) {
            tokenId = tokenOfOwnerByIndex(_user, i);
            tokenToBoost[tokenId] = 0;
            if (tokenToComposeTime[tokenId] != 0 && boostEnabled) {
                for (
                    uint8 tier = TICKET_DIAMOND;
                    tier <= TICKET_BRONZE;
                    ++tier
                ) {
                    if (boosts[tier - 1] > used[tier - 1]) {
                        tokenToBoost[tokenId] = tierToWeight[tier];
                        ++used[tier - 1];
                        break;
                    }
                }
            }
        }
    }

    // ----- View Functions -----

    /**
     * @notice  View the time an Maestro has been composing
     * @param   _token  Token ID of the Maestro
     * @return  Duration in seconds
     */
    function timeComposing(uint256 _token) public view returns (uint256) {
        uint256 composeTime = tokenToComposeTime[_token];
        return composeTime > 0 ? block.timestamp - composeTime : 0;
    }

    /**
     * @notice  View the Notes balance a Maestro has accumulated
     * @param   _token  Token ID of the Maestro
     * @return  Notes balance
     */
    function notesBalance(uint256 _token) public view returns (uint256) {
        return
            (timeComposing(_token) *
                (WEIGHT_DENOMINATOR + tokenToBoost[_token])) /
            WEIGHT_DENOMINATOR;
    }

    /**
     * @notice  View the Notes balance a user has accumulated across all staked Maestros
     * @param   _user   Address of the user
     * @return  Total notes balance
     */
    function notesBalanceByUser(address _user) external view returns (uint256) {
        uint256 balance = balanceOf(_user);
        uint256 totalNotes;
        for (uint256 i; i < balance; ++i) {
            totalNotes += notesBalance(tokenOfOwnerByIndex(_user, i));
        }
        return totalNotes;
    }

    /**
     * @notice  View if a Maestro is currently staked
     * @param   _token  Token ID of the Maestro
     * @return  True if staked, false if not staked
     */
    function isStaked(uint256 _token) external view returns (bool) {
        return tokenToComposeTime[_token] > 0;
    }

    /**
     * @notice  View the token ID with offset calculation for metadata purposes
     * @param   _tokenId    Raw token ID
     * @return  Metadata token ID
     */
    function getShuffledTokenId(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        if (_tokenId < offsetMinId || _tokenId > offsetMaxId) return _tokenId;

        uint256 newId = _tokenId + offset;
        if (newId > offsetMaxId) {
            // If min is 1 and max is 1000, newId 1001 should wrap to 1
            // newId = 1 + 1001 - 1000 - 1 = 1
            newId = offsetMinId + newId - offsetMaxId - 1;
        }
        return newId;
    }

    /**
     * @notice  View the boosts a user is eligible for
     * @param   _user   Address of the Maestro holder
     * @return  Available boosts by tier, [diamond, gold, silver, bronze]
     */
    function viewAvailableBoosts(address _user)
        public
        view
        returns (uint256[4] memory)
    {
        uint256[4] memory boosts;
        for (uint8 i = TICKET_DIAMOND; i <= TICKET_BRONZE; ) {
            boosts[i - 1] = userToTierToAvailableBoosts[_user][i];
            unchecked {
                ++i;
            }
        }
        return boosts;
    }

    /**
     * @notice  View the boosts a user is eligible for, for a specific tier of ticket
     * @param   _user   Address of the Maestro holder
     * @param   _tier   Ticket tier to query
     * @return  Available boosts for that tier
     */
    function viewAvailableBoostsByTier(address _user, uint8 _tier)
        public
        view
        returns (uint256)
    {
        return userToTierToAvailableBoosts[_user][_tier];
    }

    // ----- Admin Functions -----

    /**
     * @notice  Claim the Maestros associated with any Maestro - Tickets NFT
     * @dev     Permissioned
     * @param   _to     Destination address
     * @param   _token  Ticket ID
     */
    function claimFor(address _to, uint256 _token) external onlyOwner {
        require(_to == maestroTickets.ownerOf(_token), "!ticketOwner");

        claimInternal(_to, _token);
    }

    /**
     * @notice  Force unstake a user in case staking's transfer blocking is being used for malicious means
     * @dev     Permissioned
     * @param   _owner  Token owner of the Maestro
     * @param   _token  Token ID of the Maestro
     */
    function retireFor(address _owner, uint256 _token) external onlyOwner {
        retireInternal(_owner, _token);
    }

    /**
     * @notice  Permissioned mint function
     * @dev     Does not count against per-wallet maximums
     * @param   _to             NFT destination address
     * @param   _qty            Number of tickets to mint
     * @param   _useTreasury    True to mint from treasury allocation, false to mint from public allocation
     */
    function adminMint(
        address _to,
        uint256 _qty,
        bool _useTreasury
    ) external onlyOwner {
        adminMintInternal(_to, _qty, _useTreasury);
    }

    /**
     * @notice  Permissioned multiple mint function
     * @dev     Does not count against per-wallet maximums
     * @param   _to             NFT destination addresses
     * @param   _qty            Number of tickets to mint
     * @param   _useTreasury    True to mint from treasury allocation, false to mint from public allocation
     */
    function adminMintMultiple(
        address[] calldata _to,
        uint256[] calldata _qty,
        bool[] calldata _useTreasury
    ) external onlyOwner {
        uint256 len = _to.length;
        require(_qty.length == len && _useTreasury.length == len, "!lengths");
        for (uint256 i; i < len; ) {
            adminMintInternal(_to[i], _qty[i], _useTreasury[i]);
            unchecked {
                ++i;
            }
        }
    }

    function adminMintInternal(
        address _to,
        uint256 _qty,
        bool _useTreasury
    ) internal {
        require(_qty > 0, "!zeroQty");

        if (_useTreasury) {
            require(available_Treasury >= _qty, "!treasurySupply");
            unchecked {
                available_Treasury -= _qty; // Already checked
            }
            mintInternal(_to, _qty, TYPE_TREASURY);
        } else {
            require(available_Public >= _qty, "!publicSupply");
            unchecked {
                available_Public -= _qty; // Already checked
            }
            mintInternal(_to, _qty, TYPE_PUBLIC);
        }
    }

    /**
     * @notice  Withdraw USDC profits from the contract
     */
    function withdraw() external onlyOwner {
        uint256 balance = USDC.balanceOf(address(this));
        USDC.safeTransfer(owner(), balance);
        emit Withdrawal(balance);
    }

    /**
     * @notice  Set a new mint price
     * @param   _newPrice    New price of the Maestro in USDC
     */
    function setPrice(uint256 _newPrice) external onlyOwner {
        emit NewPrice(mintPrice, _newPrice);
        mintPrice = _newPrice;
    }

    /**
     * @notice  Set a new maximum per wallet
     * @param   _newMax     New maximum per wallet
     */
    function setMaxPerWallet(uint256 _newMax) external onlyOwner {
        emit NewMaxPerWallet(maxPerWallet, _newMax);
        maxPerWallet = _newMax;
    }

    /**
     * @notice  Set the merkle root
     * @param   _newRoot    New Merkle tree root
     */
    function setMerkleRoot(bytes32 _newRoot) external onlyOwner {
        emit NewRoot(whitelistMerkleRoot, _newRoot);
        whitelistMerkleRoot = _newRoot;
    }

    /**
     * @notice  Set ticket boost enabled or disabled
     * @param   _newStatus  True for enable, false for
     */
    function setBoostEnabled(bool _newStatus) external onlyOwner {
        emit BoostStatus(boostEnabled, _newStatus);
        boostEnabled = _newStatus;
    }

    /**
     * @notice  Set the sale activity status of a mint phase
     * @param   _ID         0 for claim, 1 for mint, 2 for public mint
     * @param   _newStatus  true for phase active, false for inactive
     */
    function setPhaseStatus(uint256 _ID, bool _newStatus) external onlyOwner {
        require(_ID < 3, "!id");
        if (_ID == 0) {
            emit PhaseStatus(_ID, claimActive, _newStatus);
            claimActive = _newStatus;
        } else if (_ID == 1) {
            emit PhaseStatus(_ID, mintActive, _newStatus);
            mintActive = _newStatus;
        } else {
            emit PhaseStatus(_ID, publicActive, _newStatus);
            publicActive = _newStatus;
        }
    }

    /**
     * @notice  Sets a new royalty numerator
     * @dev     Cannot exceed 10%
     * @param   _royaltyBPS   New royalty, denominated in BPS (10000 = 100%)
     */
    function setRoyalty(uint96 _royaltyBPS) external onlyOwner {
        require(_royaltyBPS <= 1000, "!bps");

        _setDefaultRoyalty(owner(), _royaltyBPS);

        emit NewRoyalty(_royaltyBPS);
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
     * @notice  Set a new unrevealed URI
     * @param   _newURI     new URI string
     */
    function setUnrevealedURI(string memory _newURI) external onlyOwner {
        require(!frozen, "!frozen");
        emit NewURI(unrevealedURI, _newURI);
        unrevealedURI = _newURI;
    }

    /**
     * @notice  Set a new provenance hash
     * @param   _newHash    New hash
     */
    function setProvenanceHash(bytes32 _newHash) external onlyOwner {
        require(!frozen, "!frozen");
        emit NewHash(provenanceHash, _newHash);
        provenanceHash = _newHash;
    }

    // ----- Irreversible Admin Functions -----

    /**
     * @notice  Freeze the URI, preventing further changes
     * @dev     May only be called once
     */
    function freezeURI() external onlyOwner {
        require(!frozen, "!frozen");
        frozen = true;
        emit URIFrozen(baseURI);
    }

    /**
     * @notice  Irreversibly set the offset for fair reveal
     * @dev     May only be called once
     * @param   _seed   Randomness seed
     */
    function setOffset(uint256 _seed) external onlyOwner {
        require(offset == 0, "!set");
        uint256 randomness = uint256(
            keccak256(abi.encodePacked(block.timestamp, _seed))
        );
        offset =
            (randomness % (reservedSupply_Public + reservedSupply_Tickets)) +
            1;
        emit NewOffset(offset);
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

        string memory uri;
        if (offset > 0) {
            if (bytes(baseURI).length == 0) return "";
            uint256 newId = getShuffledTokenId(tokenId);
            uri = string(abi.encodePacked(baseURI, newId.toString(), ".json"));
        } else {
            uri = unrevealedURI;
        }

        return uri;
    }

    /**
     * @dev Prohibits transfer of composing tokens by normal transfer
     * @inheritdoc ERC721
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        require(
            tokenToComposeTime[tokenId] == 0 || composingLock == 2,
            "composing"
        );
        ERC721Enumerable._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Support transfer of composing tokens
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721) {
        if (tokenToComposeTime[tokenId] != 0) {
            if (from != address(0)) updateBoosts(from);
            if (to != address(0)) updateBoosts(to);
        }
    }

    /// @inheritdoc ERC721
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return
            interfaceId == type(ERC2981).interfaceId ||
            ERC721Enumerable.supportsInterface(interfaceId);
    }
}