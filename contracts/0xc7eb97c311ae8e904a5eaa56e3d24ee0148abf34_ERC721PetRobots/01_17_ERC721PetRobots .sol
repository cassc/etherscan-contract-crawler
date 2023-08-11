// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./interfaces/IERC1155.sol";

// =============================================================
//                       ERRORS
// =============================================================

/// When minting has not yet started
error MintIsPaused();

/// Zero NFTs mint. Wallet can mint at least one NFT.
error ZeroTokensMint();

/// For price check. msg.value should be greater than or equal to mint price
error LowPrice();

/// Max supply limit exceed error
error PetsExceeded();

/// mint limit exceed error
error WalletLimitExceeded();

contract ERC721PetRobots is
    DefaultOperatorFilterer,
    ERC721AQueryable,
    Ownable,
    IERC2981
{
    using Strings for uint256;

    IERC1155 public DROE_ERC1155;
    uint8 public constant ERC1155_KEY_CARD_Id = 1; // ERC1155's Token Id 1 is only accepted to be burn and mint new NFTs

    uint256 private _totalPublicPets; // number of tokens minted from public supply
    uint256 public totalPetsRedeem; // amount of NFTs redeem through ERC1155 burn
    uint256 public mintPrice = 0.088 ether; // mint price per token

    uint16 public constant maxPetsSupply = 4444; // maxPetsSupply =  + reservePets + publicPetsSupply
    uint16 private immutable _publicPetsSupply; // tokens avaiable for public
    uint16 public reservePets = 150; // tokens reserve for the owner
    uint16 private _royalties = 750; // royalties in bps 1% = (1 *100) = 100 bps

    uint16 public walletLimit = 5; // max NFTs per wallet allowed to mint

    bool public isMintActive;
    bool public isRedeemActive;

    address public royaltiesReciver; // EOA for as royalties receiver for collection
    string public baseURI; // token base uri

    // =============================================================
    //                       MODIFIERS
    // =============================================================

    // =============================================================
    //                       FUNCTIONS
    // =============================================================

    /**
     * @dev  It will mint from tokens allocated for public
     * @param volume is the quantity of tokens to be mint
     */
    function mint(uint16 volume) external payable {
        if (!isMintActive) revert MintIsPaused();
        if (volume == 0) revert ZeroTokensMint();
        if (msg.value < (mintPrice * volume)) revert LowPrice();

        uint256 requestedVolume = _numberMinted(_msgSender()) + volume;
        if (requestedVolume > walletLimit) revert WalletLimitExceeded();

        _mintPets(volume);
    }

    function redeemKeyCards() external {
        if (!isRedeemActive) revert MintIsPaused();

        uint256 volume = DROE_ERC1155.balanceOf(
            _msgSender(),
            ERC1155_KEY_CARD_Id
        );

        if (volume == 0) revert ZeroTokensMint();
        uint256[] memory tokenIds = new uint256[](1);
        uint256[] memory amount = new uint256[](1);

        tokenIds[0] = ERC1155_KEY_CARD_Id;
        amount[0] = volume;

        totalPetsRedeem += volume; // update redeem counter
        // burn keycards
        DROE_ERC1155.burn(_msgSender(), tokenIds, amount);

        _mintPets(volume);
    }

    /**
     * @dev mint function only callable by the Contract owner. It will mint from reserve tokens for owner
     * @param to is the address to which the tokens will be mint
     * @param volume is the quantity of tokens to be mint
     */
    function mintFromReserve(address to, uint16 volume) external onlyOwner {
        if (volume > reservePets) revert PetsExceeded();
        reservePets -= volume;
        _safeMint(to, volume);
    }

    /**
     * @dev private function to compute max supply and mint NFTs
     */
    function _mintPets(uint volume) private {
        // max supply check
        uint totalPets = _totalPublicPets + volume;
        if (totalPets > _publicPetsSupply) revert PetsExceeded();
        _totalPublicPets = totalPets;

        // mint NFTs
        _safeMint(_msgSender(), volume);
    }

    // =============================================================
    //                      ADMIN FUNCTIONS
    // =============================================================

    function updateKeyCardsAddress(
        address _keyCardsContract
    ) external onlyOwner {
        DROE_ERC1155 = IERC1155(_keyCardsContract);
    }

    /**
     * @dev it is only callable by Contract owner. it will toggle mint status
     */
    function toggleMintStatus() external onlyOwner {
        isMintActive = !isMintActive;
    }

    /**
     * @dev it is only callable by Contract owner. it will toggle redeem status
     */
    function toggleRedeemStatus() external onlyOwner {
        isRedeemActive = !isRedeemActive;
    }

    /**
     * @dev it is only callable by Contract owner. it will update max mint limit per wallet
     */
    function setWalletLimit(uint16 _limit) external onlyOwner {
        walletLimit = _limit;
    }

    /**
     * @dev it will update mint price
     * @param _mintPrice is new value for mint
     */
    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    /**
     * @dev it will update baseURI for tokens
     * @param _uri is new URI for tokens
     */
    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    /**
     * @dev it will update the address for royalties receiver
     * @param _account is new royalty receiver
     */
    function setRoyaltiesReciver(address _account) external onlyOwner {
        require(_account != address(0));
        royaltiesReciver = _account;
    }

    /**
     * @dev it will update the royalties for token
     * @param royalties_ new percentage of royalties. it should be  in bps (1% = 1 *100 = 100). 6.9% => 6.9 * 100 = 690
     */
    function setRoyalties(uint16 royalties_) external onlyOwner {
        require(royalties_ > 0, "should be > 0");
        _royalties = royalties_;
    }

    /**
     * @dev it is only callable by Contract owner. it will withdraw balace of contract
     */
    function withdraw() external onlyOwner {
        bool success = payable(msg.sender).send(address(this).balance);
        require(success, "Transfer failed!");
    }

    // =============================================================
    //                       VIEW FUNCTIONS
    // =============================================================

    /**
     * @dev it will return tokenURI for given tokenIdToOwner
     * @param tokenId is valid token id mint in this contract
     */
    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721A, IERC721A) returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual override(IERC721A, ERC721A, IERC165) returns (bool) {
        return
            _interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(_interfaceId);
    }

    /**
     *  @dev it retruns the amount of royalty the owner will receive for given tokenId
     *  @param tokenId is valid token number
     *  @param value is amount for which token will be traded
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 value
    ) external view override returns (address receiver, uint256 royaltyAmount) {
        require(
            _exists(tokenId),
            "ERC2981RoyaltyStandard: Royalty info for nonexistent token"
        );
        return (royaltiesReciver, (value * _royalties) / 10000);
    }

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    // =============================================================
    //                 ON-CHAIN ROYALTY ENFORCEMENT
    // =============================================================

    /**
     * @dev override  {ERC721-setApprovalForAll} to enforce onchain royalty
     * See {ERC721-setApprovalForAll}.
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(IERC721A, ERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev override  {ERC721-approve} to enforce onchain royalty
     * See {ERC721-approve}.
     */
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

    /**
     * @dev override  {ERC721-transferFrom} to enforce onchain royalty
     * See {ERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev override  {ERC721-safeTransferFrom} to enforce onchain royalty
     * See {ERC721-transferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev override  {ERC721-safeTransferFrom} to enforce onchain royalty
     * See {ERC721-transferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // =============================================================
    //                      CONSTRUCTOR
    // =============================================================

    constructor(
        string memory _uri,
        address address_DROE_ERC1155
    ) ERC721A("Pet Robots", "PT") {
        baseURI = _uri;
        DROE_ERC1155 = IERC1155(address_DROE_ERC1155);
        royaltiesReciver = msg.sender;

        _publicPetsSupply = maxPetsSupply - reservePets;
    }
}