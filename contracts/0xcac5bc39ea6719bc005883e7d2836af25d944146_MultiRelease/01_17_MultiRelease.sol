//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;
pragma abicoder v2;

/*----------------------------------------------------------\
|                             _                 _           |
|        /\                  | |     /\        | |          |
|       /  \__   ____ _ _ __ | |_   /  \   _ __| |_ ___     |
|      / /\ \ \ / / _` | '_ \| __| / /\ \ | '__| __/ _ \    |
|     / ____ \ V / (_| | | | | |_ / ____ \| |  | ||  __/    |
|    /_/    \_\_/ \__,_|_| |_|\__/_/    \_\_|   \__\___|    |
|                                                           |
|    https://avantarte.com/careers                          |
|    https://avantarte.com/support/contact                  |
|                                                           |
\----------------------------------------------------------*/

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {TimerLib} from "../libraries/Timer/TimerLib.sol";
import {IERC721CreatorMintPermissions} from "@manifoldxyz/creator-core-solidity/contracts/permissions/ERC721/IERC721CreatorMintPermissions.sol";
import {IERC721CreatorCore} from "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ISpecifiedMinter} from "./Erc721/ISpecifiedMinter.sol";

/// @notice Represents the settings for an auction
struct NftAuctionSettings {
    // the time at which the auction would close (will be updating)
    uint256 initialAuctionSeconds;
    // the time at which the auction would close (will be updating)
    uint256 floor;
    // The minimum amount of time left in an auction after a new bid is created
    uint256 timeBufferSeconds;
    // the token id for this auction
    uint256 tokenId;
    // The minimum percentage difference between the last bid amount and the current bid. (1-100)
    uint256 minBidIncrementPercentage;
}

/// @notice Represents an auction project
struct NftAuction {
    NftAuctionSettings settings;
    // the token id for this auction
    uint256 startTime;
    // the time at which the auction would close (will be updating)
    uint256 closeTime;
    // the highest bid, used specifically for auctions
    uint256 highBid;
    // the highest bidder, used specifically for auctions
    address highBidder;
}

/// @notice Represents a ranged project
struct NftRangedProjectState {
    // used for ranged release to specify the start of the range
    uint256 rangeStart;
    // used for ranged release to specify the end of the range
    uint256 rangeEnd;
    // used specifically for ranged release
    uint256 pointer;
}

/// @notice Represents an input to create/update a project
struct NftProjectInput {
    // the id of the project (should use product id from storyblok)
    uint256 id;
    // the wallet of the project
    address wallet;
    // the nft contract of the project
    address nftContract;
    // the time at which the contract would be closed
    uint256 closeTime;
    // allows us to pause the project if needed
    bool paused;
    // the custodial for the tokens in this project, if applicable
    address custodial;
    // we can limit items to be claimed from a release by specifying a limit.
    uint256 countLimit;
}

/// @notice Represents an NFT project
struct NftProject {
    // the curator who created the project
    address curator;
    // the time the project was created
    uint256 timestamp;
    // the type of the project
    uint256 projectType;
    // the id of the project (should use product id from storyblok)
    uint256 id;
    // the wallet of the project
    address wallet;
    // the nft contract of the project
    address nftContract;
    // the time at which the contract would be closed
    uint256 closeTime;
    // allows us to pause the project if needed
    bool paused;
    // the custodial for the tokens in this project, if applicable
    address custodial;
    // counts the items claimed from this release.
    uint256 count;
    // we can limit items to be claimed from a release by specifying a limit.
    uint256 countLimit;
}

/// @notice Represents a voucher with definitions that allows the holder to claim an NFT
struct NFTVoucher {
    /// @notice the id of the project, allows us to scope projects.
    uint256 projectId;
    /// @notice (optional) used to lock voucher usage to specific wallet address.
    address walletAddress;
    /// @notice the identifier of the voucher, used to prevent double usage.
    uint256 voucherId;
    /// @notice (optional) The minimum price (in wei) that the NFT creator is willing to accept for the initial sale of this NFT.
    uint256 price;
    /// @notice (optional) allows us to restrict voucher usage.
    uint256 validUntil;
    /// @notice (optional) allows us to restrict voucher usage.
    uint256 tokenId;
    /// @notice the EIP-712 signature of all other fields in the NFTVoucher struct. For a voucher to be valid, it must be signed by an account with the SIGNER_ROLE.
    bytes signature;
}

/// @notice Represents the state of a project
struct ProjectStateOutput {
    uint256 time;
    NftProject project;
    NftAuction auction;
    NftRangedProjectState ranged;
}

/// @title a multi release contract supporting multiple release formats
/// @author Liron Navon
/// @notice this contract has a complicated access system, please contact owner for support
/// @dev This contract heavily relies on vouchers with valid signatures.
contract MultiRelease is
    Ownable,
    ReentrancyGuard,
    EIP712,
    AccessControl,
    IERC721CreatorMintPermissions
{
    /// @dev roles for access control
    bytes32 private constant SIGNER_ROLE = keccak256("SIGNER_ROLE");
    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 private constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");

    /// @dev release types for project types
    uint256 private constant AUCTION_PROJECT = 1;
    uint256 private constant SPECIFIED_PROJECT = 2;
    uint256 private constant RANGED_PROJECT = 3;
    uint256 private constant LAZY_MINT_PROJECT = 4;
    uint256 private constant SPECIFIED_LAZY_MINT_PROJECT = 5;

    /// @dev for domain separation (EIP712)
    string private constant SIGNING_DOMAIN = "AvantArte NFT Voucher";
    string private constant SIGNATURE_VERSION = "1";

    /// @notice vouchers which are already used
    mapping(uint256 => address) public usedVouchers;
    /// @notice mapping of projectId => project
    mapping(uint256 => NftProject) private projects;
    /// @notice mapping of projectId => auction info - used only for auctions
    mapping(uint256 => NftAuction) private auctions;
    /// @notice mapping of projectId => auction project - used only for auctions
    mapping(uint256 => NftRangedProjectState) private rangedProjects;
    /// @notice mapping of address => address - used to verify minting using manifold
    mapping(address => address) private pendingMints;

    /// @notice an event that represents when funds have been withdrawn from the contract
    event OnWithdraw(
        uint256 indexed projectId,
        address indexed account,
        uint256 value
    );

    /// @notice an event that represents when a token is claimed
    event OnTokenClaim(
        uint256 indexed projectId,
        address indexed account,
        uint256 tokenId,
        uint256 value,
        bool minted
    );

    /// @notice an event that represents when a bid happens
    event OnAuctionBid(
        uint256 indexed projectId,
        address indexed account,
        uint256 tokenId,
        uint256 value
    );

    /// @notice an event that represents when an auction start
    event OnAuctionStart(
        uint256 indexed projectId,
        address indexed account,
        uint256 tokenId
    );

    /// @notice an event to call when the auction is closed manually
    event OnAuctionClose(uint256 indexed projectId, address indexed account);

    /// @notice an event to call when a user dropped from the auction
    event OnAuctionOutBid(
        uint256 indexed projectId,
        address indexed account,
        uint256 tokenId,
        uint256 value
    );

    /// @notice an event that happens when a project is created
    event OnProjectCreated(
        uint256 indexed projectId,
        address indexed account,
        uint256 indexed projectType
    );

    /// @notice an event that happens when a voucher is used
    event OnVoucherUsed(
        uint256 indexed projectId,
        address indexed account,
        uint256 voucherId
    );

    // solhint-disable-next-line no-empty-blocks
    constructor() ReentrancyGuard() EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {}

    /// @notice creates a project in which we give a range of tokens
    /// @param project the input to create this project
    /// @param rangeStart the first token in the range
    /// @param rangeEnd the last token in the range
    /// @param pointer where we start counting from, in a new project it should be same as rangeStart
    function setRangedProject(
        NftProjectInput calldata project,
        uint256 rangeStart,
        uint256 rangeEnd,
        uint256 pointer
    ) external onlyRole(ADMIN_ROLE) {
        _setProject(project, RANGED_PROJECT);
        rangedProjects[project.id].rangeStart = rangeStart;
        rangedProjects[project.id].rangeEnd = rangeEnd;
        rangedProjects[project.id].pointer = pointer;
    }

    /// @notice creates a project in which we expect to be given a contract of type manifold creator
    /// @param project the input to create this project
    function setLazyMintProject(NftProjectInput calldata project)
        external
        onlyRole(ADMIN_ROLE)
    {
        _setProject(project, LAZY_MINT_PROJECT);
    }

    /// @notice creates a project in which we expect to be given a contract that implements the ISpecifiedMinter interface
    /// @param project the input to create this project
    function setSpecifiedLazyMintProject(NftProjectInput calldata project)
        external
        onlyRole(ADMIN_ROLE)
    {
        _setProject(project, SPECIFIED_LAZY_MINT_PROJECT);
    }

    /// @notice creates a project in which we expect to be given a tokenId from the voucher
    /// @param project the input to create this project
    function setSpecifiedProject(NftProjectInput calldata project)
        external
        onlyRole(ADMIN_ROLE)
    {
        _setProject(project, SPECIFIED_PROJECT);
    }

    /// @notice creates a project which is an auction
    /// @param project the input to create this project
    /// @param auctionSettings extra settings, releated to the auction
    function setAuctionProject(
        NftProjectInput calldata project,
        NftAuctionSettings memory auctionSettings
    ) external onlyRole(ADMIN_ROLE) {
        _setProject(project, AUCTION_PROJECT);
        // settings specific to auction project
        auctions[project.id].settings = auctionSettings;
    }

    /// @notice allows an admin to withdraw funds from the contract, be careful as this can break functionality
    /// @dev extra care was taken to make sure the contract has only the funds reqired to function
    /// @param to the address to get the funds
    /// @param value the amount of funds to withdraw
    /// @param projectId the project id this withdrawal is based off
    function withdraw(
        address to,
        uint256 value,
        uint256 projectId
    ) external onlyRole(WITHDRAWER_ROLE) {
        _withdraw(to, value, projectId);
    }

    /// @dev makes sure the project exists
    /// @param projectId the id of the project
    modifier onlyExistingProject(uint256 projectId) {
        require(projects[projectId].timestamp != 0, "Nonexisting project");
        _;
    }

    /// @dev makes sure the project is of the right type
    /// @param projectId the id of the project
    /// @param projectType type id of the project
    modifier onlyProjectOfType(uint256 projectId, uint256 projectType) {
        require(projects[projectId].timestamp != 0, "Nonexisting project");
        require(
            projects[projectId].projectType == projectType,
            "Wrong project type"
        );
        _;
    }

    /// @dev makes sure the project is active
    /// @param projectId the id of the project
    modifier onlyActiveProjects(uint256 projectId) {
        // check if the project is paused
        require(!projects[projectId].paused, "Project is paused");
        // check if the project has a closeTime, and if so check if it passed
        if (projects[projectId].closeTime > 0) {
            require(
                projects[projectId].closeTime >= TimerLib._now(),
                "Project is over"
            );
        }
        // check if the project has a countLimit, and if it's reached
        if (projects[projectId].countLimit > 0) {
            require(
                projects[projectId].countLimit > projects[projectId].count,
                "Project at count limit"
            );
        }
        _;
    }

    /// @dev makes sure voucher was never used
    /// @param voucherId the id of the voucher
    modifier onlyUnusedVouchers(uint256 voucherId) {
        require(usedVouchers[voucherId] == address(0), "Used voucher");
        _;
    }

    /// @dev makes sure the voucher is verified
    /// @param voucher the voucher to validates
    modifier onlyVerifiedVouchers(NFTVoucher calldata voucher) {
        // check authorized signer
        require(
            hasRole(SIGNER_ROLE, _recoverVoucherSigner(voucher)),
            "Unauthorized signer"
        );

        // check payment
        if (voucher.price > 0) {
            require(msg.value >= voucher.price, "Insufficient funds");
        }

        if (voucher.validUntil > 0) {
            require(voucher.validUntil >= TimerLib._now(), "Voucher expired");
        }

        // check wallet restriction
        if (voucher.walletAddress != address(0)) {
            require(voucher.walletAddress == msg.sender, "Unauthorized wallet");
        }
        _;
    }

    /// @notice sets the project as paused
    /// @param projectId the id of the project
    /// @param paused is the project paused
    function setPaused(uint256 projectId, bool paused)
        external
        onlyExistingProject(projectId)
        onlyRole(ADMIN_ROLE)
    {
        projects[projectId].paused = paused;
    }

    /// @dev starts the auction
    /// @param projectId the id of the project
    function _startAuction(uint256 projectId) private {
        // set start time
        auctions[projectId].startTime = TimerLib._now();
        // set end time
        auctions[projectId].closeTime =
            TimerLib._now() +
            auctions[projectId].settings.initialAuctionSeconds;

        emit OnAuctionStart(
            projectId,
            msg.sender,
            auctions[projectId].settings.tokenId
        );
    }

    /// @notice starts the auction manualy
    /// @param projectId the id of the project
    function startAuction(uint256 projectId)
        external
        onlyProjectOfType(projectId, AUCTION_PROJECT)
        onlyRole(ADMIN_ROLE)
    {
        _startAuction(projectId);
    }

    /// @notice close the auction manually
    /// @param projectId the id of the project
    function closeAuction(uint256 projectId)
        external
        onlyProjectOfType(projectId, AUCTION_PROJECT)
        onlyRole(ADMIN_ROLE)
    {
        auctions[projectId].closeTime = TimerLib._now();
        emit OnAuctionClose({projectId: projectId, account: msg.sender});
    }

    /// @notice start the project with a given time
    /// @param projectId the id of the project
    /// @param timeSeconds the time, in seconds
    function startWithTime(uint256 projectId, uint256 timeSeconds)
        external
        onlyExistingProject(projectId)
        onlyRole(ADMIN_ROLE)
    {
        projects[projectId].paused = false;
        projects[projectId].closeTime = TimerLib._now() + timeSeconds;
    }

    function getProjectState(uint256 projectId)
        external
        view
        returns (ProjectStateOutput memory state)
    {
        return
            ProjectStateOutput({
                time: TimerLib._now(),
                project: projects[projectId],
                auction: auctions[projectId],
                ranged: rangedProjects[projectId]
            });
    }

    /// @dev in order to make a bid in an auction, a user must pass a certain threshhold, this function calculates it
    /// @param projectId the id of the auction project
    function _getAuctionThreshHold(uint256 projectId)
        private
        view
        returns (uint256)
    {
        return
            auctions[projectId].highBid +
            (auctions[projectId].highBid *
                auctions[projectId].settings.minBidIncrementPercentage) /
            100;
    }

    /// @notice validates and marks voucher as used
    /// @param voucher the voucher to use
    function _useVoucher(NFTVoucher calldata voucher)
        private
        onlyUnusedVouchers(voucher.voucherId)
        onlyVerifiedVouchers(voucher)
    {
        usedVouchers[voucher.voucherId] = msg.sender;
        projects[voucher.projectId].count += 1;
        emit OnVoucherUsed(voucher.projectId, msg.sender, voucher.voucherId);
    }

    /// @dev take the funds if required, validate required payments before calling this
    /// @param to the wallet to get the funds
    /// @param amount the amount of funds to withdraw
    /// @param projectId the project id related to the funds
    function _withdraw(
        address to,
        uint256 amount,
        uint256 projectId
    ) private {
        emit OnWithdraw(projectId, to, amount);
        /// solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = payable(to).call{value: amount}("");
        require(success, "Failed to withdraw");
    }

    /// @notice claim a token from a ranged project
    /// @param voucher the voucher to use
    function claimRanged(NFTVoucher calldata voucher)
        external
        payable
        nonReentrant
        onlyProjectOfType(voucher.projectId, RANGED_PROJECT)
        onlyActiveProjects(voucher.projectId)
    {
        require(
            rangedProjects[voucher.projectId].pointer <=
                rangedProjects[voucher.projectId].rangeEnd,
            "Project out of tokens"
        );
        _useVoucher(voucher);

        // get token id and increase pointer
        uint256 tokenId = rangedProjects[voucher.projectId].pointer;
        rangedProjects[voucher.projectId].pointer += 1;

        // transfer the NFT
        _transferToken(voucher.projectId, tokenId, msg.sender);
        if (msg.value > 0) {
            _withdraw(
                projects[voucher.projectId].wallet,
                msg.value,
                voucher.projectId
            );
        }
    }

    function claimSpecifiedLazyMint(NFTVoucher calldata voucher)
        external
        payable
        nonReentrant
        onlyProjectOfType(voucher.projectId, SPECIFIED_LAZY_MINT_PROJECT)
        onlyActiveProjects(voucher.projectId)
    {
        _useVoucher(voucher);

        ISpecifiedMinter minter = ISpecifiedMinter(
            projects[voucher.projectId].nftContract
        );
        uint256 createdToken = minter.mint(msg.sender, voucher.tokenId);

        emit OnTokenClaim(
            voucher.projectId,
            msg.sender,
            createdToken,
            msg.value,
            true
        );

        if (msg.value > 0) {
            _withdraw(
                projects[voucher.projectId].wallet,
                msg.value,
                voucher.projectId
            );
        }
    }

    /// @notice claim a token from a lazy mint project
    /// @param voucher the voucher to use
    function claimLazyMint(NFTVoucher calldata voucher)
        external
        payable
        nonReentrant
        onlyProjectOfType(voucher.projectId, LAZY_MINT_PROJECT)
        onlyActiveProjects(voucher.projectId)
    {
        _useVoucher(voucher);

        pendingMints[msg.sender] = projects[voucher.projectId].nftContract;

        IERC721CreatorCore erc721 = IERC721CreatorCore(
            projects[voucher.projectId].nftContract
        );
        uint256 createdToken = erc721.mintExtension(msg.sender);

        emit OnTokenClaim(
            voucher.projectId,
            msg.sender,
            createdToken,
            msg.value,
            true
        );

        if (msg.value > 0) {
            _withdraw(
                projects[voucher.projectId].wallet,
                msg.value,
                voucher.projectId
            );
        }
    }

    /// @notice claim a token from a specified project
    /// @param voucher the voucher to use
    function claimSpecified(NFTVoucher calldata voucher)
        external
        payable
        nonReentrant
        onlyProjectOfType(voucher.projectId, SPECIFIED_PROJECT)
        onlyActiveProjects(voucher.projectId)
    {
        _useVoucher(voucher);
        _transferToken(voucher.projectId, voucher.tokenId, msg.sender);

        if (msg.value > 0) {
            _withdraw(
                projects[voucher.projectId].wallet,
                msg.value,
                voucher.projectId
            );
        }
    }

    /// @notice claim a token from an auction project
    /// @param projectId the id of the auction
    function claimAuction(uint256 projectId)
        external
        payable
        nonReentrant
        onlyProjectOfType(projectId, AUCTION_PROJECT)
        onlyActiveProjects(projectId)
    {
        require(
            TimerLib._now() >= auctions[projectId].closeTime,
            "Auction: still running"
        );
        require(
            msg.sender == auctions[projectId].highBidder,
            "Auction: not winner"
        );
        projects[projectId].count += 1;
        _transferToken(
            projectId,
            auctions[projectId].settings.tokenId,
            msg.sender
        );
        _withdraw(
            projects[projectId].wallet,
            auctions[projectId].highBid,
            projectId
        );
    }

    /// @notice make a bid for an auction
    /// @param projectId the id of the auction
    function bidAuction(uint256 projectId)
        external
        payable
        onlyProjectOfType(projectId, AUCTION_PROJECT)
        onlyActiveProjects(projectId)
    {
        // setup the auction if it's not started yet
        if (auctions[projectId].startTime == 0) {
            _startAuction(projectId);
        } else {
            // auction needs to be running
            require(
                TimerLib._now() < auctions[projectId].closeTime,
                "Auction: is over"
            );
        }

        // check the bid value
        if (auctions[projectId].highBid == 0) {
            // needs to be above floor price
            require(
                msg.value >= auctions[projectId].settings.floor,
                "Auction: lower than floor"
            );
        } else {
            require(
                msg.value >= _getAuctionThreshHold(projectId),
                "Auction: lower than threshold"
            );
            // emit the event for outbid
            emit OnAuctionOutBid(
                projectId,
                auctions[projectId].highBidder,
                auctions[projectId].settings.tokenId,
                auctions[projectId].highBid
            );
        }

        // emit the event for the bid
        emit OnAuctionBid(
            projectId,
            msg.sender,
            auctions[projectId].settings.tokenId,
            msg.value
        );

        // increase the time if needed
        uint256 timeLeft = auctions[projectId].closeTime - TimerLib._now();
        if (timeLeft < auctions[projectId].settings.timeBufferSeconds) {
            auctions[projectId].closeTime +=
                auctions[projectId].settings.timeBufferSeconds -
                timeLeft;
        }

        // info to refund the last high bidder
        uint256 refundBid = auctions[projectId].highBid;
        address refundBidder = auctions[projectId].highBidder;

        // set the new high bidder
        auctions[projectId].highBid = msg.value;
        auctions[projectId].highBidder = msg.sender;

        // refund the last bidder
        if (refundBid > 0 && refundBidder != address(0)) {
            _withdraw(refundBidder, refundBid, projectId);
        }
    }

    /// @dev setup a project
    /// @param project the input for the project
    /// @param projectType the type of the project to create/update
    function _setProject(NftProjectInput calldata project, uint256 projectType)
        private
    {
        // check if exists, if so check if the same project type
        if (projects[project.id].timestamp != 0) {
            require(
                projects[project.id].projectType == projectType,
                "Wrong project type"
            );
        } else {
            // setup for new project, these cannot be edited after creation
            projects[project.id].id = project.id;
            projects[project.id].timestamp = TimerLib._now();
            projects[project.id].curator = msg.sender;
            projects[project.id].count = 0;
            projects[project.id].projectType = projectType;
            emit OnProjectCreated(project.id, msg.sender, projectType);
        }

        // general project settings
        projects[project.id].custodial = project.custodial;
        projects[project.id].wallet = project.wallet;
        projects[project.id].nftContract = project.nftContract;
        projects[project.id].paused = project.paused;
        projects[project.id].closeTime = project.closeTime;
        projects[project.id].countLimit = project.countLimit;
    }

    /// @notice Returns a hash of the given NFTVoucher, prepared using EIP712 typed data hashing rules.
    /// @param voucher An NFTVoucher to hash.
    function _hashVoucher(NFTVoucher calldata voucher)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "NFTVoucher(uint256 projectId,address walletAddress,uint256 voucherId,uint256 price,uint256 validUntil,uint256 tokenId)"
                        ),
                        voucher.projectId,
                        voucher.walletAddress,
                        voucher.voucherId,
                        voucher.price,
                        voucher.validUntil,
                        voucher.tokenId
                    )
                )
            );
    }

    /// @notice Verifies the signature for a given NFTVoucher, returning the address of the signer.
    /// @dev Will revert if the signature is invalid. Does not verify that the signer is authorized to mint NFTs.
    /// @param voucher An NFTVoucher describing an unminted NFT.
    function _recoverVoucherSigner(NFTVoucher calldata voucher)
        internal
        view
        returns (address)
    {
        // take data, hash it
        bytes32 digest = _hashVoucher(voucher);
        // take hash + signature, and get public key
        return ECDSA.recover(digest, voucher.signature);
    }

    /// @notice Transfers a token from a custodial wallet to a user wallet
    /// @param projectId the id of the related project
    /// @param tokenId the id of the token to transfer
    /// @param to the wallet who would recieve the token
    function _transferToken(
        uint256 projectId,
        uint256 tokenId,
        address to
    ) private {
        emit OnTokenClaim(projectId, msg.sender, tokenId, msg.value, false);
        IERC721 nft = IERC721(projects[projectId].nftContract);
        nft.transferFrom(projects[projectId].custodial, to, tokenId);
    }

    /// @notice approve minting for manifold contract (ERC721)
    /// @dev it is verified by setting pendingMints for a wallet address and approving only the specified wallet
    /// @param to the wallet which is expected to recieve the token
    function approveMint(
        address, /* extension */
        address to,
        uint256 /* tokenId */
    ) external virtual override {
        require(msg.sender == pendingMints[to], "Not manifold creator");
        delete pendingMints[to];
    }

    /// @notice derived from ERC165, checks support for interfaces
    /// @param interfaceId the interface id to check
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, IERC165)
        returns (bool)
    {
        return
            // supports open zepplin's access control
            AccessControl.supportsInterface(interfaceId) ||
            // supports maniford mint permissions (erc721)
            interfaceId == type(IERC721CreatorMintPermissions).interfaceId;
    }

    /// @notice overriding check role (from AccessControl) to treat the owner as a super user
    /// @param role the id of the role
    function _checkRole(bytes32 role) internal view virtual override {
        if (msg.sender != owner()) {
            _checkRole(role, msg.sender);
        }
    }
}