//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "base64-sol/base64.sol";

// Custom errors

error BeaverXNft__AllNftsAlreadyMinted();
error BeaverXNft__AlreadyMintedYourNft();
error BeaverXNft__TokenNonExistent();
error BeaverXNft__TransferFailed();
error BeaverXNft__NoTokensInContract();
error BeaverXNft__NotOwner();

/// @title  BeaverX NFT
/// @author ekiio
/// @notice A simple ERC721 smart contract which lets users mint a limited
///         BeaverX NFT and randomly chooses one minter who will win a
///         certain amount of StrikeX tokens.
contract BeaverXNft is ERC721, VRFConsumerBaseV2 {
    using Counters for Counters.Counter;

    // State variables
    // -BeaverX variables

    VRFCoordinatorV2Interface private immutable i_vrfCoordinatorV2;
    IERC20 immutable i_strx;

    mapping(address => bool) private hasMinted;
    string public constant IMAGE_URI =
        "ipfs://QmSSFb8YH7RSUFSpwjnFS8KzAhRqRzQENAg6CDKgeaMyDd";
    address public immutable i_owner;
    uint256 private immutable i_maxSupply;
    Counters.Counter private s_tokenId;
    address public s_winner;

    // -ChainlinkVRF variables

    bytes32 private immutable i_keyHash;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    // Events

    event AllNftsMinted();
    event WinnerDrawn(address winner);

    // Modifier

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert BeaverXNft__NotOwner();
        }
        _;
    }

    // Functions

    constructor(
        address strxContract,
        uint256 maxSupply,
        address vrfCoordinatorV2,
        bytes32 keyHash,
        uint64 subId,
        uint32 callbackGasLimit
    ) ERC721("BeaverX", "BVX") VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_owner = msg.sender;
        i_strx = IERC20(strxContract);
        i_maxSupply = maxSupply;
        i_vrfCoordinatorV2 = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_keyHash = keyHash;
        i_subscriptionId = subId;
        i_callbackGasLimit = callbackGasLimit;
    }

    /// @notice Function that users call to mint one of 500 limited BeaverX
    ///         NFTs. Checks if an address tries to mint more than one NFT,
    ///         and also if maxSupply is already reached. Only if all 500 NFTs
    ///         have been minted, Chainlink's randomWords will be requested.
    ///         The owner of the drawn tokenId will then receive the prize.
    function mintNft() public {
        uint256 _id = s_tokenId.current();
        if (_id >= i_maxSupply) {
            revert BeaverXNft__AllNftsAlreadyMinted();
        }
        if (hasMinted[msg.sender]) {
            revert BeaverXNft__AlreadyMintedYourNft();
        }
        hasMinted[msg.sender] = true;
        s_tokenId.increment();
        _safeMint(msg.sender, _id);
        if (s_tokenId.current() == i_maxSupply) {
            i_vrfCoordinatorV2.requestRandomWords(
                i_keyHash,
                i_subscriptionId,
                REQUEST_CONFIRMATIONS,
                i_callbackGasLimit,
                NUM_WORDS
            );
            emit AllNftsMinted();
        }
    }

    /// @notice Forms part of the token URI. Will be concatenated with the
    ///         token JSON in the tokenURI() function.
    function _baseURI() internal pure override returns (string memory) {
        return "data:application/json;base64,";
    }

    /// @notice Sets the token URI, so basically the on-chain token metadata.
    function tokenURI(
        uint256 /*tokenId*/
    ) public view virtual override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    _baseURI(),
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name(),
                                '", "description":"The first BeaverX NFT, created by @ekiio6 with Stable Diffusion, as a tribute to the amazing STRX community, commemorating reaching 500 Twitter followers.", ',
                                '"attributes": [{"trait_type": "Species", "value": "Space Beaver"}, ',
                                '{"trait_type": "Occupation", "value": "Space traveler"}, ',
                                '{"trait_type": "Location", "value": "Out of this world"}, ',
                                '{"trait_type": "Status", "value": "OG Legend"}], "image":"',
                                IMAGE_URI,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    /// @notice Function required by ChainlinkVRF. Called by VRFCoordinator
    ///         with a random number between 0 and 499. The address to the
    ///         unique tokenId will then receive every single STRX token this
    ///         contract holds at this time.
    function fulfillRandomWords(
        uint256 /*requestId*/,
        uint256[] memory randomWords
    ) internal override {
        uint256 _winningTokenId = randomWords[0] % i_maxSupply;
        address _winner = ownerOf(_winningTokenId);
        s_winner = _winner;
        uint256 _amount = i_strx.balanceOf(address(this));
        bool _success = i_strx.transfer(_winner, _amount);
        if (!_success) {
            revert BeaverXNft__TransferFailed();
        }
        emit WinnerDrawn(_winner);
    }

    /// @notice In the (unlikely) case that something goes wrong during the
    ///         raffle, this function prevents tokens to be stuck forever in
    ///         the contract.
    function withdrawToOwner() external onlyOwner {
        uint256 _tokenBalance = i_strx.balanceOf(address(this));
        if (_tokenBalance == 0) {
            revert BeaverXNft__NoTokensInContract();
        }
        bool _success = i_strx.transfer(i_owner, _tokenBalance);
        if (!_success) {
            revert BeaverXNft__TransferFailed();
        }
    }

    function getTokenId() public view returns (uint256) {
        return s_tokenId.current();
    }

    function getMaxSupply() public view returns (uint256) {
        return i_maxSupply;
    }

    function getMintedStatus(address owner) public view returns (bool) {
        return hasMinted[owner];
    }
}