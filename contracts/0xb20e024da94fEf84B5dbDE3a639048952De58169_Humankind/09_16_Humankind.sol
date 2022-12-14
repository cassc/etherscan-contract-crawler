// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

error KindIsAdventuring();
error AdventuringNotActive();
error NotOwnerOfToken();
error InvalidSignerAddress();
error InvalidSignature();
error InvalidLunchboxContract();
error InvalidRange();
error InvalidTokenId();
error MaxPerTransaction();

struct AdventureData {
    bool isAdventuring;
    uint48 adventureStartTime;
    uint48 totalAdventureTime;
    uint48 ownershipTime;
}

struct TokenData {
    uint48 adventureStart;
    uint48 totalAdventureTime;
    /// @dev max ID of a Lunchbox is 10k, so 16 bits is enough
    uint16 lunchboxId;
}

contract Humankind is
    ERC721AQueryable,
    Ownable,
    ERC2981,
    DefaultOperatorFilterer
{
    using ECDSA for bytes32;

    string public _baseTokenURI;

    mapping(uint256 => TokenData) private tokenDataById;

    bool private _allowAdventuring = false;

    address private signer = address(0);

    event Adventuring(uint16 indexed tokenId);
    event ReturnedFromAdventure(uint16 indexed tokenId);
    event TokensMinted(
        address indexed minter,
        uint256 fromIndex,
        uint256 toIndex
    );

    LunchboxContract public lunchboxContract;

    constructor(
        address _lunchboxContract,
        string memory _baseUri,
        address _royaltyAddress,
        uint96 _royaltyAmount,
        address _signer
    ) ERC721A("Humankind", "HMNKND") {
        if (_signer == address(0)) {
            revert InvalidSignerAddress();
        }

        lunchboxContract = LunchboxContract(_lunchboxContract);
        _baseTokenURI = _baseUri;
        signer = _signer;

        _setDefaultRoyalty(_royaltyAddress, _royaltyAmount);
    }

    /**
     * @dev Calls the Lunchbox contract to burn the token, and redeem an HK token
     */
    function lunchTime(
        uint16[] calldata tokenIds,
        bytes calldata signature
    ) external {
        if (
            !_verify(
                keccak256(abi.encodePacked(msg.sender, tokenIds)),
                signature
            )
        ) revert InvalidSignature();

        uint256 tokenIdsLength = tokenIds.length;
        uint256 from = _nextTokenId();
        uint256 nextToken = from;

        for (uint256 i; i < tokenIdsLength; ) {
            uint16 tokenId = tokenIds[i];

            // track the lunchbox used to mint the HK
            // since HK minting is sequential, nextToken will start at the next available token to be minted
            // and then is incremented as we loop through each Lunchbox
            tokenDataById[nextToken].lunchboxId = tokenId;

            // lunchboxContract makes the following assertions:
            // - burning is active (timestamp check)
            // - the caller is _this_ contract
            // - the token exists and is not already burned
            // - the sender is the owner of the token
            lunchboxContract.openLunchbox(msg.sender, tokenId);

            // these are safe from overflow as any tokens outside of the minted range (1-8359)
            // will revert in the openLunchbox check
            unchecked {
                ++i;
                ++nextToken;
            }
        }

        _mint(msg.sender, tokenIdsLength);

        emit TokensMinted(msg.sender, from, nextToken - 1);
    }

    /**
     * @dev Locks the token from being transferred & tracks the adventure time
     */
    function toggleAdventure(uint16[] calldata tokenIds) external {
        uint256 tokenIdsLength = tokenIds.length;

        if (tokenIdsLength > 400) {
            // set a reasonable upper bound on this to avoid hitting block gas limits
            revert MaxPerTransaction();
        }

        for (uint256 i; i < tokenIdsLength; ) {
            uint16 tokenId = tokenIds[i];

            // you cannot adventure with a token you don't own
            if (ownerOf(tokenId) != msg.sender) {
                revert NotOwnerOfToken();
            }

            TokenData storage tokenData = tokenDataById[tokenId];
            uint48 start = tokenData.adventureStart;
            uint48 timeNow = uint48(block.timestamp);

            if (start == 0) {
                // if the token is not adventuring, and adventuring is allowed, start adventuring at current timestamp
                if (!_allowAdventuring) {
                    revert AdventuringNotActive();
                }

                tokenData.adventureStart = timeNow;
                emit Adventuring(tokenId);
            } else {
                // otherwise, stop the adventure. Calculate the total adventure time and unset adventureStart
                tokenData.totalAdventureTime += timeNow - start;
                tokenData.adventureStart = 0;

                emit ReturnedFromAdventure(tokenId);
            }

            // safe from overflow, as the ownerOf check will revert if out of bounds
            unchecked {
                ++i;
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                             VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @dev See {ERC721-_baseURI}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function adventuringData(
        uint256 tokenId
    ) external view returns (AdventureData memory) {
        TokenOwnership memory ownershipData = explicitOwnershipOf(tokenId);
        TokenData memory tokenData = tokenDataById[tokenId];

        uint48 adventureStart = tokenData.adventureStart;

        return
            AdventureData({
                isAdventuring: adventureStart != 0,
                adventureStartTime: adventureStart,
                totalAdventureTime: tokenData.totalAdventureTime,
                ownershipTime: uint48(ownershipData.startTimestamp)
            });
    }

    function getLunchboxForToken(
        uint256 tokenId
    ) external view returns (uint256) {
        uint256 lunchboxId = tokenDataById[tokenId].lunchboxId;
        if (lunchboxId == 0) revert InvalidTokenId();

        return lunchboxId;
    }

    function getLunchboxesForTokens(
        uint256[] calldata tokenIds
    ) external view returns (uint256[] memory) {
        uint256 tokenIdsLength = tokenIds.length;
        uint256[] memory lunchboxIds = new uint256[](tokenIdsLength);

        for (uint256 i; i < tokenIdsLength; ++i) {
            uint256 lunchboxId = tokenDataById[tokenIds[i]].lunchboxId;
            if (lunchboxId == 0) revert InvalidTokenId();
            lunchboxIds[i] = lunchboxId;
        }

        return lunchboxIds;
    }

    function isAdventuringEnabled() external view returns (bool) {
        return _allowAdventuring;
    }

    function _verify(
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        bytes32 signedHash = hash.toEthSignedMessageHash();

        return signedHash.recover(signature) == signer;
    }

    /**
     * @dev Kind cannot be transferred while adventuring
     */
    function _beforeTokenTransfers(
        address,
        address,
        uint256 startTokenId,
        uint256 quantity
    ) internal view override {
        uint256 tokenId = startTokenId;
        for (uint256 end = tokenId + quantity; tokenId < end; ++tokenId) {
            if (tokenDataById[tokenId].adventureStart != 0) {
                // the token cannot be transferred if it's adventuring
                revert KindIsAdventuring();
            }
        }
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC721A, ERC721A, ERC2981) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    /*//////////////////////////////////////////////////////////////
                            OWNER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function adminToggleAdventuring() external onlyOwner {
        _allowAdventuring = !_allowAdventuring;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setSigner(address _signer) external onlyOwner {
        if (_signer == address(0)) {
            revert InvalidSignerAddress();
        }

        signer = _signer;
    }

    function setLunchboxContract(address _lunchboxContract) external onlyOwner {
        if (_lunchboxContract == address(0)) {
            revert InvalidLunchboxContract();
        }

        lunchboxContract = LunchboxContract(_lunchboxContract);
    }

    function setRoyaltyInfo(
        address receiver,
        uint96 feeBasisPoints
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    /**
     * @dev If for some reason a user is unable to return from an adventure, this is to manually force it.
     */
    function adminEndAdventure(uint16 tokenId) external onlyOwner {
        uint48 adventureStartForToken = tokenDataById[tokenId].adventureStart;

        if (adventureStartForToken != 0) {
            // accumulate any adventure time, as in the case where the user returned themselves
            tokenDataById[tokenId].totalAdventureTime +=
                uint48(block.timestamp) -
                adventureStartForToken;
            // reset adventure timer
            tokenDataById[tokenId].adventureStart = 0;

            emit ReturnedFromAdventure(tokenId);
        }
    }

    /*//////////////////////////////////////////////////////////////
                        OPERATORFILTER OVERRIDES
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(IERC721A, ERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    )
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}

interface LunchboxContract {
    function openLunchbox(address minter, uint256 tokenId) external;

    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256);
}