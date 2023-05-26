// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {ERC2981} from "openzeppelin-contracts/contracts/token/common/ERC2981.sol";
import {MerkleProof} from "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";


interface IERC721 {
    function ownerOf(uint tokenId) external view returns (address);
}


contract BoredAndDangerous is ERC721, ERC2981 {
    /// @notice The original writer's room contract
    address public constant WRITERS_ROOM = 0x880644ddF208E471C6f2230d31f9027578FA6FcC;

    /// @notice The grace period for refund claiming
    uint public constant DUTCH_AUCTION_GRACE_PERIOD = 12 hours;
    /// @notice The mint cap in the dutch auction
    uint public constant DUTCH_AUCTION_MINT_CAP = 2;
    /// @notice The first token id that dutch auction minters will receive, inclusive
    uint public immutable DUTCH_AUCTION_START_ID;
    /// @notice The last token id that dutch auction minters will receive, inclusive
    uint public immutable DUTCH_AUCTION_END_ID;

    /// @notice The price for writelist mints
    uint public writelistPrice;

    /// @notice The address which can admin mint for free, set merkle roots, and set auction params
    address public mintingOwner;
    /// @notice The address which can update the metadata uri
    address public metadataOwner;
    /// @notice The address which will be returned for the ERC721 owner() standard for setting royalties
    address public royaltyOwner;

    /// @notice Records the price and time when the final dutch auction token sells out
    struct DutchAuctionFinalization {
        uint128 price;
        uint128 time;
    }
    /// @notice The instantiation of the dutch auction finalization struct
    DutchAuctionFinalization public dutchEnd;

    /// @notice The token id which will be minted next in the dutch auction
    uint public dutchAuctionNextId;
    /// @notice The token id which will be minted next in the writelist mint
    uint public writelistMintNextId;

    /// @notice Records whether a whitelist allocation has been started, and how many are remaining to claim
    struct Writelist {
        uint128 remaining;
        bool used;
    }

    /// @notice Whether free mints for writers' room holders are open
    bool public writelistMintWritersRoomFreeOpen;

    /// @notice Whether paid mints for writers' room holders are open
    bool public writelistMintWritersRoomOpen;

    /// @notice Construct this from (address, amount) tuple elements
    bytes32 public giveawayMerkleRoot;
    /// @notice Caches writelist allocations once they've been used
    mapping(address => Writelist) public giveawayWritelist;

    /// @notice Construct this from (address, tokenId) tuple elements
    bytes32 public apeMerkleRoot;
    /// @notice Maps (address, tokenId) hash to bool, true if token has minted
    mapping(bytes32 => bool) public apeWritelistUsed;

    /// @notice Maps tokenId to bool, true if token has minted
    mapping(uint => bool) public writersroomWritelistUsed;

    /// @notice Total number of tokens which have minted
    uint public totalSupply = 0;

    /// @notice The prefix to attach to the tokenId to get the metadata uri
    string public baseTokenURI;

    /// @notice Struct is packed to fit within a single 256-bit slot
    struct DutchAuctionMintHistory {
        uint128 amount;
        uint128 price;
    }
    /// @notice Store the mint history for an individual address. Used to issue refunds
    mapping(address => DutchAuctionMintHistory) public mintHistory;

    /// @notice Struct is packed to fit within a single 256-bit slot
    /// @dev uint64 has max value 1.8e19, or 18 ether
    /// @dev uint32 has max value 4.2e9, which corresponds to max timestamp of year 2106
    struct DutchAuctionParams {
        uint64 startPrice;
        uint64 endPrice;
        uint64 priceIncrement;
        uint32 startTime;
        uint32 timeIncrement;
    }
    /// @notice The instantiation of dutch auction parameters
    DutchAuctionParams public params;

    /// @notice Emitted when a token is minted
    event Mint(address indexed owner, uint indexed tokenId);
    /// @notice Emitted when an accounts receives its dutch auction refund
    event DutchAuctionRefund(address indexed account);

    /// @notice Raised when an unauthorized user calls a gated function
    error AccessControl();
    /// @notice Raised when a non-EOA account calls a gated function
    error OnlyEOA(address msgSender);
    /// @notice Raised when a user exceeds their mint cap
    error ExceededUserMintCap();
    /// @notice Raised when the mint has not reached the required timestamp
    error MintNotOpen();
    /// @notice Raised when the user attempts to writelist mint on behalf of a token they do not own
    error DoesNotOwnToken(uint tokenId);
    /// @notice Raised when the user attempts to mint after the dutch auction finishes
    error DutchAuctionOver();
    /// @notice Raised when the admin attempts to withdraw funds before the dutch auction grace period has ended
    error DutchAuctionGracePeriod(uint endPrice, uint endTime);
    /// @notice Raised when a user attempts to claim their dutch auction refund before the dutch auction ends
    error DutchAuctionNotOver();
    /// @notice Raised when the admin attempts to mint within the dutch auction range while the auction is still ongoing
    error DutchAuctionNotOverAdmin();
    /// @notice Raised when the admin attempts to set dutch auction parameters that don't make sense
    error DutchAuctionBadParamsAdmin();
    /// @notice Raised when `sender` does not pass the proper ether amount to `recipient`
    error FailedToSendEther(address sender, address recipient);
    /// @notice Raised when a user tries to writelist mint twice
    error WritelistUsed();
    /// @notice Raised when two calldata arrays do not have the same length
    error MismatchedArrays();
    /// @notice Raised when the user attempts to mint zero items
    error MintZero();

    constructor(uint _DUTCH_AUCTION_START_ID, uint _DUTCH_AUCTION_END_ID) ERC721("Bored & Dangerous", "BOOK") {
        DUTCH_AUCTION_START_ID = _DUTCH_AUCTION_START_ID;
        DUTCH_AUCTION_END_ID = _DUTCH_AUCTION_END_ID;
        dutchAuctionNextId = _DUTCH_AUCTION_START_ID;
        writelistMintNextId = _DUTCH_AUCTION_END_ID + 1;
        mintingOwner = msg.sender;
        metadataOwner = msg.sender;
        royaltyOwner = msg.sender;
    }

    /// @notice Admin mint a token
    function ownerMint(address recipient, uint tokenId) external {
        if (msg.sender != mintingOwner) {
            revert AccessControl();
        }

        if (DUTCH_AUCTION_START_ID <= tokenId && tokenId <= DUTCH_AUCTION_END_ID) {
            revert DutchAuctionNotOverAdmin();
        }

        unchecked {
            ++totalSupply;
        }
        _mint(recipient, tokenId);
    }

    /// @notice Admin mint a batch of tokens
    function ownerMintBatch(address[] calldata recipients, uint[] calldata tokenIds) external {
        if (msg.sender != mintingOwner) {
            revert AccessControl();
        }
        
        if (recipients.length != tokenIds.length) {
            revert MismatchedArrays();
        }

        unchecked {
            totalSupply += tokenIds.length;
            for (uint i = 0; i < tokenIds.length; ++i) {
                if (DUTCH_AUCTION_START_ID <= tokenIds[i] && tokenIds[i] <= DUTCH_AUCTION_END_ID) {
                    revert DutchAuctionNotOverAdmin();
                }
                _mint(recipients[i], tokenIds[i]);
            }
        }
    }
    
    ///////////////////
    // DUTCH AUCTION //
    ///////////////////

    /// @notice The current dutch auction price
    /// @dev Reverts if dutch auction has not started yet
    /// @dev Returns the end price even if the dutch auction has sold out
    function dutchAuctionPrice() public view returns (uint) {
        DutchAuctionParams memory _params = params;
        uint numIncrements = (block.timestamp - _params.startTime) / _params.timeIncrement;
        uint price = _params.startPrice - numIncrements * _params.priceIncrement;
        if (price < _params.endPrice) {
            price = _params.endPrice;
        }
        return price;
    }

    /// @notice Dutch auction with refunds
    /// @param amount The number of NFTs to mint, either 1 or 2
    function dutchAuctionMint(uint amount) external payable {
        // Enforce EOA mints
        _onlyEOA(msg.sender);

        if (amount == 0) {
            revert MintZero();
        }

        DutchAuctionMintHistory memory userMintHistory = mintHistory[msg.sender];

        // Enforce per-account mint cap
        if (userMintHistory.amount + amount > DUTCH_AUCTION_MINT_CAP) {
            revert ExceededUserMintCap();
        }

	    uint256 _dutchAuctionNextId = dutchAuctionNextId;
        // Enforce global mint cap
        if (_dutchAuctionNextId + amount > DUTCH_AUCTION_END_ID + 1) {
            revert DutchAuctionOver();
        }

        DutchAuctionParams memory _params = params;

        // Enforce timing
        if (block.timestamp < _params.startTime || _params.startPrice == 0) {
            revert MintNotOpen();
        }
        
        // Calculate dutch auction price
        uint numIncrements = (block.timestamp - _params.startTime) / _params.timeIncrement;
        uint price = _params.startPrice - numIncrements * _params.priceIncrement;
        if (price < _params.endPrice) {
            price = _params.endPrice;
        }

        // Check mint price
        if (msg.value != amount * price) {
            revert FailedToSendEther(msg.sender, address(this));
        }
        unchecked {
            uint128 newPrice = (userMintHistory.amount * userMintHistory.price + uint128(amount * price)) / uint128(userMintHistory.amount + amount);
            mintHistory[msg.sender] = DutchAuctionMintHistory({
                amount: userMintHistory.amount + uint128(amount),
                price: newPrice
            });
            for (uint i = 0; i < amount; ++i) {
                _mint(msg.sender, _dutchAuctionNextId++);
            }
            totalSupply += amount;
            if (_dutchAuctionNextId > DUTCH_AUCTION_END_ID) {
                dutchEnd = DutchAuctionFinalization({
                    price: uint128(price),
                    time: uint128(block.timestamp)
                });
            }
	        dutchAuctionNextId = _dutchAuctionNextId;
        }
    }

    /// @notice Provide dutch auction refunds to people who minted early
    /// @dev Deliberately left unguarded so users can either claim their own, or batch refund others
    function claimDutchAuctionRefund(address[] calldata accounts) external {
        // Check if dutch auction over
        if (dutchEnd.price == 0) {
            revert DutchAuctionNotOver();
        }
        for (uint i = 0; i < accounts.length; ++i) {
            address account = accounts[i];
            DutchAuctionMintHistory memory mint = mintHistory[account];
            // If an account has already been refunded, skip instead of reverting
            // This prevents griefing attacks when performing batch refunds
            if (mint.price > 0) {
                uint refundAmount = mint.amount * (mint.price - dutchEnd.price);
                delete mintHistory[account];
                (bool sent,) = account.call{value: refundAmount}("");
                // Revert if the address has a malicious receive function
                // This is not a griefing vector because the function can be retried
                // without the failing recipient
                if (!sent) {
                    revert FailedToSendEther(address(this), account);
                }
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // WRITELIST MINTS (free writer's room, paid writer's room, paid bored/mutant ape, paid giveaway) //
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Free mint from writelist ticket allocation
    function writelistMintWritersRoomFree(uint[] calldata tokenIds) external {
        if (!writelistMintWritersRoomFreeOpen) {
            revert MintNotOpen();
        }
        for (uint i = 0; i < tokenIds.length; ++i) {
            address tokenOwner = IERC721(WRITERS_ROOM).ownerOf(tokenIds[i]);
            // This will revert is specific tokenId already minted
            _mint(tokenOwner, tokenIds[i]);
        }
        totalSupply += tokenIds.length;
    }

    /// @notice Paid mint for a writer's room NFT
    function writelistMintWritersRoom(uint[] calldata tokenIds) external payable {
        if (!writelistMintWritersRoomOpen) {
            revert MintNotOpen();
        }
        // Check payment
        if (msg.value != tokenIds.length * writelistPrice) {
            revert FailedToSendEther(msg.sender, address(this));
        }

        for (uint i = 0; i < tokenIds.length; ++i) {
            if (writersroomWritelistUsed[tokenIds[i]]) {
                revert WritelistUsed();
            }
            writersroomWritelistUsed[tokenIds[i]] = true;
            address tokenOwner = IERC721(WRITERS_ROOM).ownerOf(tokenIds[i]);
            _mint(tokenOwner, writelistMintNextId++);
        }
        totalSupply += tokenIds.length;
    }

    /// @notice Mint for a licensed bored ape or mutant ape
    function writelistMintApes(address tokenContract, uint tokenId, bytes32 leaf, bytes32[] calldata proof) external payable {
        // Check payment
        if (msg.value != writelistPrice) {
            revert FailedToSendEther(msg.sender, address(this));
        }
        
        bytes32 tokenHash = keccak256(abi.encodePacked(tokenContract, tokenId));
        
        // Create storage element tracking user mints if this is the first mint for them
        if (apeWritelistUsed[tokenHash]) {
            revert WritelistUsed();
        }
        // Verify that (tokenContract, tokenId) correspond to Merkle leaf
        require(tokenHash == leaf, "Token contract and id don't match Merkle leaf");

        // Verify that (leaf, proof) matches the Merkle root
        require(verify(apeMerkleRoot, leaf, proof), "Not a valid leaf in the Merkle tree");

        // Get the current tokenOwner and mint to them
        address tokenOwner = IERC721(tokenContract).ownerOf(tokenId);

        apeWritelistUsed[tokenHash] = true;
        ++totalSupply;

        _mint(tokenOwner, writelistMintNextId++);
    }

    /// @notice Mint from writelist allocation
    function writelistMintGiveaway(address tokenOwner, uint8 amount, uint8 totalAllocation, bytes32 leaf, bytes32[] memory proof) external payable {
        // Check payment
        if (msg.value != amount * writelistPrice) {
            revert FailedToSendEther(msg.sender, address(this));
        }

        Writelist memory writelist = giveawayWritelist[tokenOwner];
        
        // Create storage element tracking user mints if this is the first mint for them
        if (!writelist.used) {    
            // Verify that (tokenOwner, amount) correspond to Merkle leaf
            require(keccak256(abi.encodePacked(tokenOwner, totalAllocation)) == leaf, "Sender and amount don't match Merkle leaf");

            // Verify that (leaf, proof) matches the Merkle root
            require(verify(giveawayMerkleRoot, leaf, proof), "Not a valid leaf in the Merkle tree");

            writelist.used = true;
            // Save some gas by never writing to this slot if it will be reset to zero at method end
            if (amount != totalAllocation) {
                writelist.remaining = totalAllocation - amount;
            }
        }
        else {
            writelist.remaining -= amount;
        }

        giveawayWritelist[tokenOwner] = writelist;
        totalSupply += amount;
        for (uint i = 0; i < amount; ++i) {
            _mint(tokenOwner, writelistMintNextId++);
        }
    }

    /// @notice Ensure the proof and leaf match the merkle root
    function verify(bytes32 root, bytes32 leaf, bytes32[] memory proof) public pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    /////////////////////////
    // ADMIN FUNCTIONALITY //
    /////////////////////////

    /// @notice Set metadata
    function setBaseTokenURI(string memory _baseTokenURI) external {
        if (msg.sender != metadataOwner) {
            revert AccessControl();
        }
        baseTokenURI = _baseTokenURI;
    }

    /// @notice Set merkle root
    function setGiveawayMerkleRoot(bytes32 _giveawayMerkleRoot) external {
        if (msg.sender != mintingOwner) {
            revert AccessControl();
        }
        giveawayMerkleRoot = _giveawayMerkleRoot;
    }

    /// @notice Set merkle root
    function setApeMerkleRoot(bytes32 _apeMerkleRoot) external {
        if (msg.sender != mintingOwner) {
            revert AccessControl();
        }
        apeMerkleRoot = _apeMerkleRoot;
    }

    /// @notice Set parameters
    function setDutchAuctionStruct(DutchAuctionParams calldata _params) external {
        if (msg.sender != mintingOwner) {
            revert AccessControl();
        }
        if (!(_params.startPrice >= _params.endPrice && _params.endPrice > 0 && _params.startTime > 0 && _params.timeIncrement > 0)) {
            revert DutchAuctionBadParamsAdmin();
        }
        params = DutchAuctionParams({
            startPrice: _params.startPrice,
            endPrice: _params.endPrice,
            priceIncrement: _params.priceIncrement,
            startTime: _params.startTime,
            timeIncrement: _params.timeIncrement
        });
    }

    /// @notice Set writelistMintNextId
    /// @dev Should not be used, but failsafe in case the admin accidentally mints a token id in the writelist range too early
    function setWritelistMintNextId(uint _writelistMintNextId) external {
        if (msg.sender != mintingOwner) {
            revert AccessControl();
        }
        writelistMintNextId = _writelistMintNextId;
    }

    /// @notice Set writelistMintWritersRoomFreeOpen
    function setWritelistMintWritersRoomFreeOpen(bool _value) external {
        if (msg.sender != mintingOwner) {
            revert AccessControl();
        }
        writelistMintWritersRoomFreeOpen = _value;
    }

    /// @notice Set writelistMintWritersRoomOpen
    function setWritelistMintWritersRoomOpen(bool _value) external {
        if (msg.sender != mintingOwner) {
            revert AccessControl();
        }
        writelistMintWritersRoomOpen = _value;
    }

    /// @notice Set writelistPrice
    function setWritelistPrice(uint _price) external {
        if (msg.sender != mintingOwner) {
            revert AccessControl();
        }
        writelistPrice = _price;
    }

    /// @notice Claim funds
    function claimFunds(address payable recipient) external {
        if (!(msg.sender == mintingOwner || msg.sender == metadataOwner || msg.sender == royaltyOwner)) {
            revert AccessControl();
        }

        // Wait for the grace period after scheduled end to allow claiming of dutch auction refunds
        if (!(dutchEnd.price > 0 && block.timestamp >= dutchEnd.time + DUTCH_AUCTION_GRACE_PERIOD)) {
            revert DutchAuctionGracePeriod(dutchEnd.price, dutchEnd.time);
        }

        (bool sent,) = recipient.call{value: address(this).balance}("");
        if (!sent) {
            revert FailedToSendEther(address(this), recipient);
        }
    }

    ////////////////////////////////////
    // ACCESS CONTROL ADDRESS UPDATES //
    ////////////////////////////////////

    /// @notice Update the mintingOwner
    /// @dev Can also be used to revoke this power by setting to 0x0
    function setMintingOwner(address _mintingOwner) external {
        if (msg.sender != mintingOwner) {
            revert AccessControl();
        }
        mintingOwner = _mintingOwner;
    }

    /// @notice Update the metadataOwner
    /// @dev Can also be used to revoke this power by setting to 0x0
    /// @dev Should only be revoked after setting an IPFS url so others can pin
    function setMetadataOwner(address _metadataOwner) external {
        if (msg.sender != metadataOwner) {
            revert AccessControl();
        }
        metadataOwner = _metadataOwner;
    }

    /// @notice Update the royaltyOwner
    /// @dev Can also be used to revoke this power by setting to 0x0
    function setRoyaltyOwner(address _royaltyOwner) external {
        if (msg.sender != royaltyOwner) {
            revert AccessControl();
        }
        royaltyOwner = _royaltyOwner;
    }

    /// @notice The address which can set royalties
    function owner() external view returns (address) {
        return royaltyOwner;
    }

    // ROYALTY FUNCTIONALITY

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC2981) returns (bool) {
        return
            interfaceId == 0x2a55205a || // ERC165 Interface ID for ERC2981
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /// @dev See {ERC2981-_setDefaultRoyalty}.
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external {
        if (msg.sender != royaltyOwner) {
            revert AccessControl();
        }
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /// @dev See {ERC2981-_deleteDefaultRoyalty}.
    function deleteDefaultRoyalty() external {
        if (msg.sender != royaltyOwner) {
            revert AccessControl();
        }
        _deleteDefaultRoyalty();
    }

    /// @dev See {ERC2981-_setTokenRoyalty}.
    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external {
        if (msg.sender != royaltyOwner) {
            revert AccessControl();
        }
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /// @dev See {ERC2981-_resetTokenRoyalty}.
    function resetTokenRoyalty(uint256 tokenId) external {
        if (msg.sender != royaltyOwner) {
            revert AccessControl();
        }
        _resetTokenRoyalty(tokenId);
    }

    // METADATA FUNCTIONALITY

    /// @notice Returns the metadata URI for a given token
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(baseTokenURI, Strings.toString(tokenId)));
    }

    // INTERNAL FUNCTIONS

    /// @dev Revert if the account is a smart contract. Does not protect against calls from the constructor.
    /// @param account The account to check
    function _onlyEOA(address account) internal view {
        if (msg.sender != tx.origin || account.code.length > 0) {
            revert OnlyEOA(account);
        }
    }
}