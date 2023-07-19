// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@divergencetech/ethier/contracts/erc721/BaseTokenURI.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

//       oIa      'i                         ;??~
//      }Q~       JR`                        ^◎!;                     ~'
//      @A,       Kg`                                                ^Qw
//  ~{yBΞ%n{^     bg`        ;      '!        |'          `;Ξ^.    =;yΞqTi~
//     [email protected]        bg`       !q      zQ~      `B\       ,,SQZ+<Bz     [email protected]
//     [email protected]+        kQ'       zX      kQ_      .Q}      `[email protected]'   [email protected]^    [email protected]
//     [email protected];        [email protected]^       Lg`    [email protected]`      'Qj      '[email protected]=    [email protected]    'QD
//     [email protected];        .8W`       kd;,!jQy.       'Qt      [email protected]'    ^@w     ^Qi'~,
//     ^7,         'jD5|`     '^ꜩL^'          ;~      .Yx     'L;      .<J\;`

interface ITokenURIGenerator {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract Fluint is
    BaseTokenURI,
    ERC721A,
    ERC2981,
    ReentrancyGuard,
    AccessControlEnumerable
{
    uint256 public immutable artistRoyaltyPercentage = 50;
    uint256 public immutable architectRoyaltyPercentage = 50;
    uint256 public immutable maxAccountMints = 5;
    IERC721 public immutable premint;

    constructor(
        string memory name,
        string memory symbol,
        IERC721 _premint
    ) ERC721A(name, symbol) BaseTokenURI("") {
        _setDefaultRoyalty(address(this), 1000);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        premint = _premint;
        royaltyPercentageByArchitect[
            0x3807c0E4ADa47621EB4bD694C813d0abBD28b603
        ] = 25;
        royaltyPercentageByArchitect[
            0xbb553FB3d63Ea7230b46e799FA6969ada1b6b043
        ] = 25;
        royaltyPercentageByArchitect[
            0xF7A9B8D8f6dA2B7f53474c40Dd6597508ED3BaA2
        ] = 25;
        royaltyPercentageByArchitect[
            0x5eE00E3d63a25D934615357b745f95cCAb19645B
        ] = 25;
    }

    /// >>>>>>>>>>>>>>>>>>>>>  STATE  <<<<<<<<<<<<<<<<<<<<<< ///

    /**
    @dev Flag indicating whether minting is open.
     */
    bool public mintingOpen = false;

    /**
    @dev Whether claiming is currently allowed.
     */
    bool public claimingOpen = false;

    /**
    @dev Whether to require sender to be premint holder to perform actions.
     */
    bool public premintGatingEnabled = false;

    /**
    @dev Seconds users are required to wait between mints.
     */
    uint256 private mintTimeoutSeconds = 240;

    /**
    @dev Last mint timestamp.
     */
    uint256 private lastMintTimestamp;

    /**
    @dev Total artists.
     */
    uint256 public totalArtists;

    /**
    @dev Total withdrawn by artists.
     */
    uint256 public totalWithdrawnArtists;

    /**
    @dev Total withdrawn by architects.
     */
    uint256 public totalWithdrawnArchitects;

    /**
    @dev Total mints by account.
     */
    mapping(address => uint256) public accountMints;

    /**
    @dev Artist address and withdrawn amount.
     */
    mapping(address => uint256) public artistWithdrawals;

    /**
    @dev Artist address and timestamp of when became artist.
     */
    mapping(address => uint256) public artistMembership;

    /**
    @dev Architect address and withdrawn amount.
     */
    mapping(address => uint256) public architectWithdrawals;

    /**
    @dev Architect address and royalty split.
     */
    mapping(address => uint256) public royaltyPercentageByArchitect;

    /**
    @dev tokenId to claimed time.
     */
    mapping(uint256 => uint256) public claimed;

    /**
    @dev If set, contract to which tokenURI() calls are proxied.
     */
    ITokenURIGenerator public renderingContract;

    /// >>>>>>>>>>>>>>>>>>>>>  EVENTS  <<<<<<<<<<<<<<<<<<<<<< ///

    /**
    @dev Emitted when minting is enabled or disabled. 
     */
    event MintingOpen(bool indexed open);

    /**
    @dev Emitted when an artist withdraws royalties. 
     */
    event ArtistWithdraw(address indexed account, uint256 amount);

    /**
    @dev Emitted when an architect withdraws royalties. 
     */
    event ArchitectWithdraw(address indexed account, uint256 amount);

    /**
    @dev Emitted when an artist is added to contract. 
     */
    event ArtistAdded(address indexed account);

    /**
    @dev Emitted when an owner claims the physical piece tied to their token. 
     */
    event Claimed(uint256 indexed tokenId);

    /// >>>>>>>>>>>>>>>>>>>>>  WRITE  <<<<<<<<<<<<<<<<<<<<<< ///

    /**
    @notice Mint token.
     */
    function mintPublic(uint256 tokenId)
        external
        payable
        mintingEnabled
        maxMintsUnreached
        afterMintTimeout
        onlyUser
    {
        requirePremintOwner(premint, tokenId, msg.sender);
        _safeMint(msg.sender, 1);
        lastMintTimestamp = block.timestamp;
        accountMints[msg.sender] += 1;
    }

    /**
    @notice Mint token as contract owner.
     */
    function mintAdmin() external payable onlyOwner {
        _safeMint(msg.sender, 1);
        lastMintTimestamp = block.timestamp;
    }

    /**
    @notice Add sender as artist.
     */
    function addArtist(uint256 tokenId)
        external
        payable
        mintingEnabled
        onlyUser
    {
        requirePremintOwner(premint, tokenId, msg.sender);
        require(artistMembership[msg.sender] == 0, "already an artist");
        artistMembership[msg.sender] = block.timestamp;
        totalArtists += 1;
        emit ArtistAdded(msg.sender);
    }

    /**
    @notice Allows artist to withdraw their outstanding balance.
    */
    function withdrawArtistBalance() external onlyArtist nonReentrant {
        uint256 balance = getArtistRoyaltyBalance(msg.sender);
        require(balance > 0, "no royalties to withdraw");
        artistWithdrawals[msg.sender] += balance;
        totalWithdrawnArtists += balance;
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "withdraw failed");
        emit ArtistWithdraw(msg.sender, balance);
    }

    /**
    @notice Allows architect to withdraw their outstanding balance.
    */
    function withdrawArchitectBalance() external onlyArchitect nonReentrant {
        uint256 balance = getArchitectRoyaltyBalance(msg.sender);
        require(balance > 0, "no royalties to withdraw");
        architectWithdrawals[msg.sender] += balance;
        totalWithdrawnArchitects += balance;
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "withdraw failed");
        emit ArchitectWithdraw(msg.sender, balance);
    }

    /**
    @notice Begins physical piece claiming process on behalf of token owner.
    */
    function claimPhysical(uint256 tokenId) internal onlyTokenOwner(tokenId) {
        require(claimingOpen, "claiming closed");
        require(claimed[tokenId] == 0, "already claimed");
        claimed[tokenId] = block.timestamp;
        emit Claimed(tokenId);
    }

    /**
    @notice Toggles the `mintingOpen` flag.
     */
    function setPremintGatingEnabled(bool open) external onlyArchitect {
        require(premintGatingEnabled != open, "cannot change to same status");
        premintGatingEnabled = open;
    }

    /**
    @notice Toggles the `mintingOpen` flag.
     */
    function setMintingOpen(bool open) external onlyArchitect {
        require(mintingOpen != open, "cannot change to same status");
        mintingOpen = open;
        emit MintingOpen(open);
    }

    /**
    @notice Toggles the `claimingOpen` flag.
     */
    function setClaimingOpen(bool open) external onlyArchitect {
        claimingOpen = open;
    }

    /**
    @notice Sets `mintTimeoutSeconds`.
     */
    function setMintTimeout(uint256 secs) external onlyArchitect {
        mintTimeoutSeconds = secs;
    }

    /**
    @notice Sets the optional tokenURI override contract.
     */
    function setRenderingContract(ITokenURIGenerator _contract)
        external
        onlyArchitect
    {
        renderingContract = _contract;
    }

    /**
    @notice Sets the contract-wide royalty info.
     */
    function setRoyaltyInfo(uint96 feeBasisPoints) external onlyOwner {
        _setDefaultRoyalty(address(this), feeBasisPoints);
    }

    /// >>>>>>>>>>>>>>>>>>>>>  READ  <<<<<<<<<<<<<<<<<<<<<< ///

    /**
    @notice Get outstanding royalty balance for artist.
    */
    function getArtistRoyaltyBalance(address receiver)
        public
        view
        returns (uint256 amount)
    {
        if (address(this).balance == 0) {
            return 0;
        }
        require(artistMembership[receiver] != 0, "not artist address");
        uint256 total = address(this).balance +
            totalWithdrawnArtists +
            totalWithdrawnArchitects;
        uint256 artistTotal = (total * artistRoyaltyPercentage) / 100;
        uint256 receiverTotal = artistTotal / totalArtists;
        return receiverTotal - artistWithdrawals[receiver];
    }

    /**
    @notice Get outstanding royalty balance for architect.
    */
    function getArchitectRoyaltyBalance(address receiver)
        public
        view
        returns (uint256 amount)
    {
        if (address(this).balance == 0) {
            return 0;
        }
        require(
            royaltyPercentageByArchitect[receiver] > 0,
            "not architect address"
        );
        uint256 total = address(this).balance +
            totalWithdrawnArtists +
            totalWithdrawnArchitects;
        uint256 architectTotal = (total * architectRoyaltyPercentage) / 100;
        uint256 receiverTotal = (architectTotal *
            royaltyPercentageByArchitect[receiver]) / 100;
        return receiverTotal - architectWithdrawals[receiver];
    }

    /**
    @dev If renderingContract is set then returns its tokenURI(tokenId)
    return value, otherwise returns the standard baseTokenURI + tokenId.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (address(renderingContract) != address(0)) {
            return renderingContract.tokenURI(tokenId);
        }
        return super.tokenURI(tokenId);
    }

    /**
    @dev Required override to select the correct baseTokenURI.
     */
    function _baseURI()
        internal
        view
        override(BaseTokenURI, ERC721A)
        returns (string memory)
    {
        return BaseTokenURI._baseURI();
    }

    /**
    @dev Required override.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, ERC2981, AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
    @dev Reverts if not the owner of the premint tokenId.
     */
    function requirePremintOwner(
        IERC721 token,
        uint256 tokenId,
        address redeemer
    ) private view {
        if (premintGatingEnabled && token.ownerOf(tokenId) != redeemer) {
            revertWithTokenId("Not holder of premint collection", tokenId);
        }
    }

    /**
    @notice Reverts with the concatenation of revertMsg and tokenId.toString().
    @dev Used to save gas by constructing the revert message only as required,
    instead of passing it to require().
     */
    function revertWithTokenId(string memory revertMsg, uint256 tokenId)
        private
        pure
    {
        revert(string(abi.encodePacked(revertMsg, " ", tokenId)));
    }

    /// >>>>>>>>>>>>>>>>>>>>>  MODIFIERS  <<<<<<<<<<<<<<<<<<<<<< ///

    /**
    @dev Ensure that caller is not contract.
     */
    modifier onlyUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    /**
    @dev Ensure that minting is enabled.
     */
    modifier mintingEnabled() {
        require(mintingOpen, "Minting is closed");
        _;
    }

    /**
    @dev Ensure that account is under max mints.
     */
    modifier maxMintsUnreached() {
        require(
            accountMints[msg.sender] < maxAccountMints,
            "Account has reached max mints"
        );
        _;
    }

    /**
    @dev Ensure that mint timeout has passed since last mint.
     */
    modifier afterMintTimeout() {
        require(
            block.timestamp > (lastMintTimestamp + mintTimeoutSeconds),
            "Mint timeout has not passed"
        );
        _;
    }

    /**
    @dev Ensure that sender owns token.
     */
    modifier onlyTokenOwner(uint256 tokenId) {
        require(
            _ownershipOf(tokenId).addr == _msgSender(),
            "Not owner of token"
        );
        _;
    }

    /**
    @dev Ensure that requester is an artist.
     */
    modifier onlyArtist() {
        require(artistMembership[msg.sender] != 0, "Caller is not an artist");
        _;
    }

    /**
    @dev Ensure that requester is an architect.
     */
    modifier onlyArchitect() {
        require(
            royaltyPercentageByArchitect[msg.sender] > 0,
            "Caller is not an architect"
        );
        _;
    }
}