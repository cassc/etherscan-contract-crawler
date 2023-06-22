// SPDX-License-Identifier: MIT

//-------------------------------------
//    Version
//-------------------------------------
pragma solidity 0.8.20;

/**
 * @title Nebuloids NFT
 * @author SemiInvader
 * @notice The Nebuloids NFT contract. This contract is used to mint and manage Nebuloids. Nebuloids will be minted in multiple rounds
 *            First round will be of 85 total Nebuloids. More to come in the future.
 *            For this implementation we'll be adding also ERC2198 support for the NFTs.
 */
// hidden image ipfs://bafybeid5k6qkzb4k2wdqg7ctyp7hrd3dhwrwc7rv3opczxnasahqwb3jea

//-------------------------------------
//    IMPORTS
//-------------------------------------
import "@solmate/tokens/ERC721.sol";
import "@solmate/auth/Owned.sol";
import "@solmate/utils/LibString.sol";

//-------------------------------------
//    Errors
//-------------------------------------
/// @notice Error codes for the Nebuloids NFT contract
/// @param roundId the id of the round that failed
error Nebuloids__URIExists(uint256 roundId);
/// @notice Mint Amount was exceeded
error Nebuloids__MaxMintExceeded();
/// @notice Insufficient funds to mint
error Nebuloids__InsufficientFunds();
/// @notice Max amount of NFTs for the round was exceeded
error Nebuloids__MaxRoundMintExceeded();
/// @notice Reentrant call
error Nebuloids__Reentrant();
/// @notice Round has not ended
error Nebuloids__RoundNotEnded();
error Nebuloids__FailToClaimFunds();

//-------------------------------------
//    Contract
//-------------------------------------
contract NebuloidsNFT is ERC721, Owned {
    using LibString for uint256;
    //-------------------------------------
    //    Type Declarations
    //-------------------------------------
    struct RoundId {
        string uri;
        uint256 start;
        uint256 total;
        uint256 minted;
        uint256 price;
    }

    //-------------------------------------
    //    State Variables
    //-------------------------------------
    mapping(uint256 _id => uint256 _roundId) public roundIdOf;
    mapping(uint256 _roundId => RoundId _round) public rounds;
    // A user can only mint a max of 5 NFTs per round
    mapping(address => mapping(uint256 => uint8)) public userMints;
    string private hiddenURI;
    address private royaltyReceiver;
    uint public currentRound;
    uint public totalSupply;
    uint private reentrant = 1;
    uint private royaltyFee = 7;
    uint private constant ROYALTY_BASE = 100;

    uint8 public constant MAX_MINTS_PER_ROUND = 5;

    //-------------------------------------
    //    Modifers
    //-------------------------------------
    modifier reentrancyGuard() {
        if (reentrant == 2) revert Nebuloids__Reentrant();
        reentrant = 2;
        _;
        reentrant = 1;
    }

    //-------------------------------------
    //    Constructor
    //-------------------------------------
    constructor(
        string memory _hiddenUri
    ) ERC721("Nebuloids", "NEB") Owned(msg.sender) {
        hiddenURI = _hiddenUri;
    }

    //-----------------------------------------
    //    External Functions
    //-----------------------------------------
    function mint(uint256 amount) external payable reentrancyGuard {
        if (
            msg.sender != owner &&
            (amount > MAX_MINTS_PER_ROUND ||
                userMints[msg.sender][currentRound] + amount >
                MAX_MINTS_PER_ROUND ||
                amount == 0)
        ) revert Nebuloids__MaxMintExceeded(); // Can't mint more than max

        RoundId storage round = rounds[currentRound];
        if (msg.sender != owner) {
            uint toCollect = round.price * amount;

            if (msg.value < toCollect) revert Nebuloids__InsufficientFunds();
        }
        if (round.minted + amount > round.total)
            revert Nebuloids__MaxRoundMintExceeded();

        for (uint i = 0; i < amount; i++) {
            uint256 id = round.start + round.minted + i;
            roundIdOf[id] = currentRound;

            _safeMint(msg.sender, id);
        }
        totalSupply += amount;
        // check that amount is added to the minting reward
        userMints[msg.sender][currentRound] += uint8(amount);
        round.minted += amount;
    }

    function startRound(
        uint nftAmount,
        uint price,
        string memory uri
    ) external onlyOwner {
        if (rounds[currentRound].minted != rounds[currentRound].total)
            revert Nebuloids__RoundNotEnded();
        RoundId memory round = RoundId({
            uri: uri,
            start: totalSupply + 1,
            total: nftAmount,
            minted: 0,
            price: price
        });
        currentRound++;
        rounds[currentRound] = round;
    }

    function setUri(uint256 roundId, string memory uri) external onlyOwner {
        if (bytes(rounds[roundId].uri).length != 0)
            revert Nebuloids__URIExists(roundId);
        rounds[roundId].uri = uri;
    }

    function claimFunds() external onlyOwner {
        (bool succ, ) = payable(msg.sender).call{value: address(this).balance}(
            ""
        );
        if (!succ) revert Nebuloids__FailToClaimFunds();
    }

    function setRoyaltyReceiver(address _royaltyReceiver) external onlyOwner {
        royaltyReceiver = _royaltyReceiver;
    }

    //-----------------------------------------
    //    Public Functions
    //-----------------------------------------
    //-----------------------------------------
    //    External and Public View Functions
    //-----------------------------------------
    function tokenURI(uint256 id) public view override returns (string memory) {
        uint256 _roundId = roundIdOf[id];
        if (_roundId == 0 || bytes(rounds[_roundId].uri).length == 0) {
            return hiddenURI;
        }
        return string(abi.encodePacked(rounds[_roundId].uri, id.toString()));
    }

    /**
     *
     * @param interfaceId the id of the interface to check
     * @return true if the interface is supported, false otherwise
     * @dev added the ERC2981 interface
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override returns (bool) {
        return
            interfaceId == 0x2a55205a || super.supportsInterface(interfaceId);
    }

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (address receiver, uint256 royaltyAmount) {
        _tokenId; // silence unused variable warning
        // all IDS are the same royalty
        if (royaltyReceiver == address(0)) receiver = owner;
        else receiver = royaltyReceiver;

        royaltyAmount = (_salePrice * royaltyFee) / ROYALTY_BASE;
    }
}