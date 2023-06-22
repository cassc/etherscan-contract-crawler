// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./GenArtAccess.sol";
import "./MintStateReserveGold.sol";
import "./IGenArtMembership.sol";
import "./IGenArtPaymentSplitterV2.sol";
import "./IGenArtInterfaceV3.sol";

/**
 * @dev GEN.ART ERC721 V2
 * Implements the extentions {IERC721Enumerable} and {IERC2981}.
 * Inherits access control from {GenArtAccess}.
 * Sends all ETH to a {PaymentSplitter} contract.
 * Restricts minting to GEN.ART Membership holders.
 * IMPORTANT: This implementation requires the royalties to be send to the contracts address
 * in order to split the funds between payees automatically.
 */
contract GenArtERC721Closer is ERC721Enumerable, GenArtAccess, IERC2981 {
    using Strings for uint256;
    using MintStateReserveGold for MintStateReserveGold.State;

    uint256 public _mintPrice;
    uint256 public _mintSupply;
    address public _royaltyReceiver = address(this);
    uint256 public _collectionId;
    bool private _reservedMinted;
    address public _genartInterface;
    address public _paymentSplitter;
    address public _wethAddress;
    string private _uri;
    bool public _paused = true;

    MintStateReserveGold.State public _mintstate;

    /**
     *@dev Emitted on mint
     */
    event Mint(
        uint256 tokenId,
        uint256 collectionId,
        uint256 membershipId,
        address to
    );

    constructor(
        string memory name_,
        string memory symbol_,
        string memory uri_,
        uint256 collectionId_,
        uint256 mintPrice_,
        uint256 mintSupply_,
        address genartInterface_,
        address paymentSplitter_,
        address wethAddress_
    ) ERC721(name_, symbol_) GenArtAccess() {
        _uri = uri_;
        _collectionId = collectionId_;
        _mintPrice = mintPrice_;
        _mintSupply = mintSupply_;
        _genartInterface = genartInterface_;
        _paymentSplitter = paymentSplitter_;
        _wethAddress = wethAddress_;
        _mintstate.init(mintSupply_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     *@dev Get amount of mints for a membershipId
     */
    function getMembershipMints(uint256 membershipId)
        public
        view
        returns (uint256)
    {
        return _mintstate.getMints(membershipId);
    }

    /**
     *@dev Get available mints for a membershipId
     */
    function getAvailableMintsForMembership(uint256 membershipId)
        public
        view
        returns (uint256)
    {
        return
            _mintstate.getAvailableMints(
                membershipId,
                IGenArtInterfaceV3(_genartInterface).isGoldToken(membershipId),
                _mintSupply,
                totalSupply()
            );
    }

    /**
     *@dev Check if minter has available mint slots and has sent the required amount of ETH
     * Revert in case minting is paused or checks fail.
     */
    function checkMint(uint256 amount, uint256 availableMints) internal view {
        require(!_paused, "GenArtERC721Closer: minting is paused");
        require(availableMints > 0, "GenArtERC721Closer: no mints available");
        require(
            availableMints >= amount,
            "GenArtERC721Closer: amount exceeds availableMints"
        );
        uint256 ethAmount;
        unchecked {
            ethAmount = _mintPrice * amount;
        }
        require(
            ethAmount <= msg.value,
            "GenArtERC721Closer: transaction underpriced"
        );
    }

    /**
     *@dev Public function to mint the desired amount of tokens
     * Requirments:
     * - sender must be GEN.ART Membership owner
     */
    function mint(address to, uint256 amount) public payable {
        // get all available mints for sender
        uint256 availableMints = IGenArtInterfaceV3(_genartInterface)
            .getAvailableMintsForAccount(address(this), _msgSender());
        checkMint(amount, availableMints);
        // get all memberships for sender
        uint256[] memory memberships = IGenArtInterfaceV3(_genartInterface)
            .getMembershipsOf(_msgSender());
        uint256 minted;
        uint256 i;

        // loop until the desired amount of tokens was minted
        while (minted < amount && i < memberships.length) {
            // check if membership is gold
            bool isGold = IGenArtInterfaceV3(_genartInterface).isGoldToken(
                memberships[i]
            );
            // get available mints for membership
            uint256 mints = _mintstate.getAvailableMints(
                memberships[i],
                isGold,
                _mintSupply,
                totalSupply()
            );
            // mint tokens with membership and stop if desired amount reached
            for (uint256 j; j < mints && minted < amount; j++) {
                mintForMembership(to, memberships[i], isGold);
                minted++;
            }
            i++;
        }
        // send funds to PaymentSplitter
        IGenArtPaymentSplitterV2(_paymentSplitter).splitPayment{
            value: msg.value
        }(address(this));
    }

    /**
     *@dev Public function to mint one token for a GEN.ART Membership
     * Requirments:
     * - sender must own the membership
     */
    function mintOne(address to, uint256 membershipId) public payable {
        // check if sender is owner of membership
        require(
            IGenArtInterfaceV3(_genartInterface).ownerOfMembership(
                membershipId
            ) == _msgSender(),
            "GenArtERC721Closer: sender is not membership owner"
        );
        // get available mints for membership
        uint256 availableMints = getAvailableMintsForMembership(membershipId);

        checkMint(1, availableMints);

        bool isGold = IGenArtInterfaceV3(_genartInterface).isGoldToken(
            membershipId
        );
        // mint token
        mintForMembership(to, membershipId, isGold);
        // send funds to PaymentSplitter
        IGenArtPaymentSplitterV2(_paymentSplitter).splitPayment{
            value: msg.value
        }(address(this));
    }

    /**
     *@dev Mint token for membership
     */
    function mintForMembership(
        address to,
        uint256 membershipId,
        bool isGold
    ) internal {
        // update mint state once membership minted a token
        _mintstate.update(membershipId, isGold, 1);
        _mintOne(to, membershipId);
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     * Emits a {Mint} event.
     */
    function _mintOne(address to, uint256 membershipId) internal virtual {
        uint256 tokenId = _collectionId * 100_000 + totalSupply() + 1;
        _safeMint(to, tokenId);
        emit Mint(tokenId, _collectionId, membershipId, to);
    }

    function burn(uint256 tokenId) public {
        address owner = ERC721.ownerOf(tokenId);
        // check if sender is owner of token
        require(
            _msgSender() == owner,
            "GenArtERC721Closer: burn caller is not owner"
        );
        _burn(tokenId);
    }

    /**
     * @dev Get royalty info see {IERC2981}
     */
    function royaltyInfo(uint256, uint256 salePrice_)
        external
        view
        virtual
        override
        returns (address, uint256)
    {
        return (
            _royaltyReceiver,
            ((
                IGenArtPaymentSplitterV2(_paymentSplitter)
                    .getTotalSharesOfCollection(address(this), 1)
            ) * salePrice_) / 10_000
        );
    }

    /**
     *@dev Get all tokens owned by an address
     */
    function getTokensByOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokenIds;
    }

    /**
     *@dev Release WETH royalties and send them to {PaymentSplitter}
     */
    function releaseWETHRoyalties() public {
        IERC20 weth = IERC20(_wethAddress);
        uint256 wethAmount = weth.balanceOf(address(this));
        weth.transfer(_paymentSplitter, wethAmount);
        IGenArtPaymentSplitterV2(_paymentSplitter).splitPaymentRoyaltyWETH(
            address(this),
            wethAmount
        );
    }

    /**
     *@dev Pause and unpause minting
     */
    function setPaused(bool paused) public onlyAdmin {
        _paused = paused;
    }

    /**
     *@dev Set reserved mints for gold members
     */
    function setReservedGold(uint8 reserved) public onlyGenArtAdmin {
        _mintstate.setReservedGold(reserved);
    }

    /**
     *@dev Reserved mints can only be called by admins
     * Only one possible mint.
     */
    function mintReserved() public onlyAdmin {
        require(
            !_reservedMinted,
            "GenArtERC721Closer: reserved already minted"
        );
        _mintOne(genartAdmin, 0);
        _reservedMinted = true;
    }

    /**
     *@dev Set {PaymentSplitter} address
     */
    function setPaymentSplitter(address paymentSplitter)
        public
        onlyGenArtAdmin
    {
        _paymentSplitter = paymentSplitter;
    }

    /**
     *@dev Set receiver of royalties
     */
    function setRoyaltyReceiver(address receiver) public onlyGenArtAdmin {
        _royaltyReceiver = receiver;
    }

    /**
     * @dev Set base uri
     */
    function setBaseURI(string memory uri) public onlyGenArtAdmin {
        _uri = uri;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _uri;
    }

    /**
     *@dev Royalties are forwarded to {PaymentSplitter}
     */
    receive() external payable {
        IGenArtPaymentSplitterV2(_paymentSplitter).splitPaymentRoyalty{
            value: msg.value
        }(address(this));
    }
}