// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./IMetadataProxy.sol";
import "./utils/DefaultOperatorFilterer.sol";

string constant ErrMaxMint = "Cannot mint more than 1 per address";
string constant ErrMaxSupply = "Exceeds max supply";
string constant ErrNotTheBoss = "Not the boss";
string constant ErrNotSheepOwner = "Not sheep's owner";
string constant ErrNotValidList = "Not a valid list type";
string constant ErrTokenDoesNotExist = "Token does not exist";

/// @title TheSadTimesBirthCertificate
/// @author TrakonXYZ (https://trakon.xyz)
contract TheSadTimesBirthCertificate is
    ERC721A,
    ERC2981,
    Ownable,
    DefaultOperatorFilterer
{
    using MerkleProof for bytes32[];

    //
    // Events
    //
    event GoingToWork(uint256 indexed tokenId);
    event LeaveOfAbsence(uint256 indexed tokenId);
    event Rewarded(uint256 indexed sheep, address indexed human, uint256 karma);
    event TheBossTransferred(
        address indexed thePreviousBoss,
        address indexed theNewBoss
    );

    /// @notice Tracks the working periods of the sheep throughout their career.
    /// @dev 2 uint128 to pack into one word (32 bytes) to reduce the working storage
    ///   costs. A uint128 is ample size for a timestamp and for time saved.
    struct WorkPeriod {
        // Current period start time.
        uint128 currentStartTime;
        // Banked time (in seconds) for every work period other than current.
        uint128 timeBanked;
    }

    ///
    /// Working properties.
    ///
    mapping(uint256 => bool) private swappingSheep;
    mapping(uint256 => WorkPeriod) public sheepWorkPeriods;
    bool public isWorkingOpen = false;

    ///
    /// Minting and token properties.
    ///
    uint256 public constant maxSupply = 3333;
    uint256 private constant mintAmount = 1;

    /// @notice Keeps track of humans who were rewarded during mint
    ///   and the amount of karma given.
    mapping(address => uint256) public rewardedHumans;
    /// @notice Keeps track of sheep that were rewarded during mint
    ///   and the amount of karma given.
    mapping(uint256 => uint256) public rewardedSheep;

    /// @notice A mapping of merkle roots for the different
    ///   list types. There is an allowlist and a guaranteed list.
    mapping(uint8 => bytes32) public merkleRoots;
    uint8 public constant GUARRANTEED_LIST_TYPE = 1;
    uint8 public constant ALLOW_LIST_TYPE = 2;
    uint8 public currentListType;

    ///
    /// Metadata properties.
    ///
    IMetadataProxy public metadataProxy;
    bool private isMetadataLocked;
    string metadataFallbackUrl;

    ///
    /// The Boss.
    ///
    address public theBoss;

    constructor(
        address _regionalManager,
        address _theBoss,
        uint96 feeBasisPoints,
        string memory _fallbackUrl
    ) ERC721A("TheSadTimesBirthCertificate", "STBC") {
        // Regional manager does all the dirty work.
        _transferOwnership(_regionalManager);

        // Set up the boss.
        theBoss = _theBoss;
        _setDefaultRoyalty(theBoss, feeBasisPoints);

        // The Boss always wins.
        _mint(theBoss, 333);

        // Set default metadata url.
        metadataFallbackUrl = _fallbackUrl;
    }

    //
    // Minting methods.
    //

    /// @notice Updates the Merkle root for the given list type.
    function updateListRoot(uint8 listType, bytes32 root) external onlyOwner {
        require(
            listType == GUARRANTEED_LIST_TYPE || listType == ALLOW_LIST_TYPE,
            ErrNotValidList
        );
        merkleRoots[listType] = root;
    }

    /// @notice Updates the current list that is available to mint.
    /// @dev Allows initial list type to turn off minting.
    function updateCurrentListType(uint8 listType) external onlyOwner {
        require(
            listType == 0 ||
                listType == GUARRANTEED_LIST_TYPE ||
                listType == ALLOW_LIST_TYPE,
            ErrNotValidList
        );
        currentListType = listType;
    }

    /// @notice Mint a single token using a given list's proof.
    ///   A human is tracked as rewarded if they provide a non-zero
    ///   value in the transaction.
    function mint(bytes32[] calldata proof, uint8 listType) external payable {
        require(listType <= currentListType, "Mint for list type is closed");
        require(_totalMinted() + mintAmount <= maxSupply, ErrMaxSupply);

        bytes32 listRoot = merkleRoots[listType];
        require(_numberMinted(msg.sender) < mintAmount, ErrMaxMint);

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(proof.verifyCalldata(listRoot, leaf), "Must be in list");

        uint256 tokenId = _nextTokenId();
        _mint(msg.sender, mintAmount);
        if (msg.value > 0) {
            rewardedHumans[msg.sender] = msg.value;
            rewardedSheep[tokenId] = msg.value;
            emit Rewarded({
                human: msg.sender,
                sheep: tokenId,
                karma: msg.value
            });
        }
    }

    /// @dev Starts counting from token ID 1.
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    //
    // Working methods.
    //

    function enableWorking() external onlyOwner {
        isWorkingOpen = true;
    }

    /// @notice Allows working or leave of absence sheep to be transferred by
    ///     owner.
    function transferSheep(address _to, uint256 tokenId) external {
        swappingSheep[tokenId] = true;
        safeTransferFrom(msg.sender, _to, tokenId);
        delete swappingSheep[tokenId];
    }

    /// @dev Ensures that working sheep cannot be transferred unless called
    ///   by the transferSheep method. Note that quantity is unused here
    ///   as quantity > 1 is only possible during mint in ERC721A contract. We
    ///   handle that case by performing a no-op during the mint transfer.
    function _beforeTokenTransfers(
        address _from,
        address,
        uint256 tokenId,
        uint256
    ) internal view override {
        if (_from == address(0)) {
            // noop during mints.
            return;
        }

        WorkPeriod memory workPeriod = sheepWorkPeriods[tokenId];
        require(
            workPeriod.currentStartTime == 0 || swappingSheep[tokenId],
            "Cannot transfer while working"
        );
    }

    /// @notice Toggle sheep working for multiple tokens.
    function toggleSheepWorking(uint256[] calldata tokenIds) external {
        uint256 tokenIdsLength = tokenIds.length;
        for (uint256 i = 0; i < tokenIdsLength; ++i) {
            _toggleSheepWorking(tokenIds[i]);
        }
    }

    /// @notice Toggle sheep working for a single token.
    function toggleSheepWorking(uint256 tokenId) external {
        _toggleSheepWorking(tokenId);
    }

    /// @notice Allows the regional manager to fire a sheep if a sheep's owner
    ///   intentionally lists a sheep on a marketplace while working.
    ///   If sheep are good, then the admin never has to use this.
    function fireSheep(uint256 tokenId) external onlyOwner {
        require(sheepWorkPeriods[tokenId].currentStartTime > 0, "Not working");

        WorkPeriod storage workPeriod = sheepWorkPeriods[tokenId];
        _setSheepToLeaveOfAbsence(tokenId, workPeriod);
    }

    /// @dev Sheep working logic for external methods. Determines the working
    ///   status of a sheep and toggles their status. If moving from
    ///   working to leave of absence, adds the current working time to the overall
    ///   working time.
    function _toggleSheepWorking(uint256 tokenId) private {
        require(isWorkingOpen, "Working not opened");
        require(msg.sender == ownerOf(tokenId), ErrNotSheepOwner);

        WorkPeriod storage workPeriod = sheepWorkPeriods[tokenId];

        // Set sheep to working.
        if (workPeriod.currentStartTime == 0) {
            workPeriod.currentStartTime = uint128(block.timestamp);
            emit GoingToWork(tokenId);
            return;
        }

        _setSheepToLeaveOfAbsence(tokenId, workPeriod);
    }

    /// @dev Helper function extracted out to be used in both the fireSheep
    ///     method and in the _toggleSheepWorking method.
    function _setSheepToLeaveOfAbsence(
        uint256 tokenId,
        WorkPeriod storage workPeriod
    ) private {
        workPeriod.timeBanked +=
            uint128(block.timestamp) -
            workPeriod.currentStartTime;
        workPeriod.currentStartTime = 0;
        emit LeaveOfAbsence(tokenId);
    }

    /// @notice Returns the total working time in seconds (including current working).
    function totalWorkingTime(uint256 tokenId) public view returns (uint128) {
        require(_exists(tokenId), ErrTokenDoesNotExist);
        return
            sheepWorkPeriods[tokenId].timeBanked + currentWorkingTime(tokenId);
    }

    /// @dev Returns the current working time in seconds. A return value of 0
    ///   is equivalent to leave of absence state.
    function currentWorkingTime(uint256 tokenId) public view returns (uint128) {
        require(_exists(tokenId), ErrTokenDoesNotExist);
        return
            sheepWorkPeriods[tokenId].currentStartTime > 0
                ? uint128(block.timestamp) -
                    sheepWorkPeriods[tokenId].currentStartTime
                : 0;
    }

    ///
    /// The Boss methods.
    ///

    modifier onlyTheBoss() {
        require(msg.sender == theBoss, ErrNotTheBoss);
        _;
    }

    /// @notice The Boss is allowed to withdraw balance from contract.
    function withdraw() external onlyTheBoss {
        (bool sent, ) = payable(theBoss).call{value: address(this).balance}("");
        require(sent, "Withdraw failed");
    }

    /// @notice Implements royalty fees.
    /// @dev See ERC2981.
    function updateRoyalty(uint96 feeBasisPoints) external onlyTheBoss {
        _setDefaultRoyalty(theBoss, feeBasisPoints);
    }

    /// @notice Only the boss can transfer to another boss.
    /// @dev Also sets the new default royalty receiver in ERC2981 but keeps
    ///     the royalty fee unchanged.
    function transferTheBoss(address theNewBoss) external onlyTheBoss {
        address thePreviousBoss = theBoss;
        theBoss = theNewBoss;

        // We only use a default royalty.
        // To get the original royalty fee from the public method,
        // we pass in an unused token id as well as the _feeDenominator value.
        // This gets us the royalty fraction which is the royalty fee.
        (, uint256 royaltyFeeInBasisPoints) = royaltyInfo(0, 10000);
        _setDefaultRoyalty(theBoss, uint96(royaltyFeeInBasisPoints));

        emit TheBossTransferred({
            thePreviousBoss: thePreviousBoss,
            theNewBoss: theNewBoss
        });
    }

    /// @notice Set the new metadata proxy contract. Reverts if the metadata
    ///     has been locked.
    function setMetadataProxy(address _contract) external onlyOwner {
        require(
            !isMetadataLocked,
            "Metadata is locked to current proxy contract"
        );
        metadataProxy = IMetadataProxy(_contract);
    }

    /// @dev Locks metadata to proxy contract for good. One way operation.
    function lockMetadata() external onlyOwner {
        isMetadataLocked = true;
    }

    /// @dev Fallback URL for the metadata.
    function setFallbackUrl(string memory _fallbackUrl) external onlyOwner {
        metadataFallbackUrl = _fallbackUrl;
    }

    /// @dev See {ERC721-tokenURI}.
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return
            address(metadataProxy) != address(0)
                ? metadataProxy.tokenURI(
                    tokenId,
                    this.totalWorkingTime(tokenId)
                )
                : metadataFallbackUrl;
    }

    ///
    /// Contract overrides.
    ///

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    ///
    /// OperatorFilterer required overrides.
    /// @dev See {OperatorFilterer}
    ///

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}