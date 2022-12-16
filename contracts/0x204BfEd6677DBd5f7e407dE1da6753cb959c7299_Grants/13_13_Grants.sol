// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Grants is
    Initializable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    IERC721ReceiverUpgradeable
{
    uint256 public grantsCount;
    address payable public DAOWallet;
    bytes32 public constant CURATOR_ROLE = keccak256("CURATOR_ROLE");

    // -------------------------------------------------------------
    // STORAGE
    // --------------------------------------------------------------
    struct Grant {
        address nftContract; // address of NFT contract
        address nftOwner;
        address nftAuthor;
        uint256 tokenID1;
        uint256 tokenID2;
        uint256 tokenID3;
        uint256 startTime;
        uint256 endTime;
        uint256 topDonatedAmount;
        address topDonor;
        uint64 minimumDonationAmount;
    }

    mapping(uint256 => Grant) public grants;

    mapping(uint256 => mapping(address => uint256))
        public totalDonationPerAddressPerCycle;

    mapping(uint256 => uint256) public totalDonationsPerGrant;
    //grantID => bool
    mapping(uint256 => bool) public cancelled;

    //grantID => bool
    mapping(uint256 => bool) public donationsPaid;

    bool private isShutdown;
    // --------------------------------------------------------------
    // EVENTS
    // --------------------------------------------------------------

    event GrantCreated(
        address nftOwner,
        uint256 tokenID1,
        uint256 tokenID2,
        uint256 tokenID3,
        uint256 startTime,
        uint256 endTime,
        uint256 minimumDonationAmount
    );
    event DonationPlaced(address from, uint256 grantID, uint256 amount);
    event DAOWalletAddressSet(address walletAddress);
    event NFTsentToWinner(uint256 grantID, address winner);
    event DonationSentToWinner(
        address account,
        uint256 grantID,
        uint256 winnerAmount
    );

    event FundsWithdrawnFromContract(uint256 amount, address to);
    event Shutdown(bool _isShutdown);

    // --------------------------------------------------------------
    // CUSTOM ERRORS
    // --------------------------------------------------------------
    error IncorrectTimesGiven(string message);
    error ZeroAddressNotAllowed(string message);
    error GrantHasEnded(string message, uint256 grantID);
    error DonationTooLow(string message);
    error GrantHasNotEnded(string message, uint256 grantID);
    error InsufficientAmount(string message);
    error GrantCancelled(string message, uint256 grantID);
    error AmountsNotEqual(string message);
    error InitialAmountHasToBeZero(string message);
    error MinimumDonationCantBeZero(string message);
    error DonationsPaid(string message, uint256 grantID);
    error ContractShutdown(string message);

    // --------------------------------------------------------------
    // CONSTRUCTOR
    // --------------------------------------------------------------

    function initialize() public initializer {
        // Sets deployer as DEFAULT_ADMIN_ROLE
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // --------------------------------------------------------------
    // STATE-MODIFYING FUNCTIONS
    // --------------------------------------------------------------

    /**
        @notice sets curator address for curator role
        @param  curator address of curator wallet
    */
    function setCuratorRole(address curator)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _grantRole(CURATOR_ROLE, curator);
    }

    function revokeCuratorRole(address curator)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        revokeRole(CURATOR_ROLE, curator);
    }

    /**
        @notice sets DAO wallet address for transfering funds
        @param _DAOWallet address of DAO wallet
    */
    function setDAOWalletAddress(address payable _DAOWallet)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (_DAOWallet == address(0))
            revert ZeroAddressNotAllowed("Cannot set zero address");
        DAOWallet = _DAOWallet;
        emit DAOWalletAddressSet(_DAOWallet);
    }

    /**
        @notice creates a grants
        @param _grants object contains parameters for grants created
    */
    function createGrant(Grant memory _grants)
        public
        onlyRole(CURATOR_ROLE)
        returns (uint256)
    {
        address nftContractAddress = _grants.nftContract;
        if (_grants.startTime > _grants.endTime)
            revert IncorrectTimesGiven("Incorrect times given");
        if (_grants.topDonatedAmount > 0)
            revert InitialAmountHasToBeZero("Initial amount has to be zero");
        if (_grants.minimumDonationAmount <= 0)
            revert MinimumDonationCantBeZero(
                "Amout has to be higher than zero"
            );
        if (isShutdown) revert ContractShutdown("Contract has been shut down");

        grantsCount++;
        // Set the id of the grants in the grants struct
        // _grants.grantID = grantsCount;
        grants[grantsCount] = _grants;

        IERC721Upgradeable(nftContractAddress).safeTransferFrom(
            _grants.nftOwner,
            address(this),
            _grants.tokenID1,
            ""
        );

        IERC721Upgradeable(nftContractAddress).safeTransferFrom(
            _grants.nftOwner,
            address(this),
            _grants.tokenID2,
            ""
        );

        IERC721Upgradeable(nftContractAddress).safeTransferFrom(
            _grants.nftOwner,
            address(this),
            _grants.tokenID3,
            ""
        );

        emit GrantCreated(
            _grants.nftOwner,
            _grants.tokenID1,
            _grants.tokenID2,
            _grants.tokenID3,
            _grants.startTime,
            _grants.endTime,
            _grants.minimumDonationAmount
        );

        return grantsCount;
    }

    /**
        @notice cancels an existing grants, refunds donors and sends NFT back to artist
        @param grantID id of grants
    */
    function cancelGrant(uint256 grantID) public onlyRole(CURATOR_ROLE) {
        if (
            (grants[grantID].topDonatedAmount > 0 &&
                grants[grantID].endTime < block.timestamp)
        ) revert GrantHasEnded("Grant already ended", grantID); // check this logic
        cancelled[grantID] = true;

        address nftContractAddress = grants[grantID].nftContract;

        // send NFTs back to owner
        IERC721Upgradeable(nftContractAddress).safeTransferFrom(
            address(this),
            grants[grantID].nftOwner,
            grants[grantID].tokenID1,
            ""
        );

        IERC721Upgradeable(nftContractAddress).safeTransferFrom(
            address(this),
            grants[grantID].nftOwner,
            grants[grantID].tokenID2,
            ""
        );

        IERC721Upgradeable(nftContractAddress).safeTransferFrom(
            address(this),
            grants[grantID].nftOwner,
            grants[grantID].tokenID3,
            ""
        );

        // Send Grant total donations to DAOWallet
        DAOWallet.transfer(address(this).balance);
    }

    /**
        @notice creates a donation on an grants
        @param _grantID grants ID
        @param _amount amount to donate
    */
    function donate(uint256 _grantID, uint256 _amount)
        public
        payable
        nonReentrant
    {
        if (_amount != msg.value) revert AmountsNotEqual("Value mismatch");

        // Loading Grant obj into memory for top donor calc
        if (grants[_grantID].endTime < block.timestamp)
            revert GrantHasEnded("Grant already ended", _grantID);
        if (_amount < grants[_grantID].minimumDonationAmount)
            revert DonationTooLow("Donation has to be higher");
        if (isShutdown) revert ContractShutdown("Contract has been shut down");

        totalDonationPerAddressPerCycle[_grantID][msg.sender] += _amount;
        totalDonationsPerGrant[_grantID] += _amount;

        if (
            grants[_grantID].topDonatedAmount <
            totalDonationPerAddressPerCycle[_grantID][msg.sender]
        ) {
            grants[_grantID].topDonor = msg.sender;
            grants[_grantID].topDonatedAmount = totalDonationPerAddressPerCycle[
                _grantID
            ][msg.sender];
        }

        emit DonationPlaced(msg.sender, _grantID, _amount);
    }

    function emergencyWithdraw(uint256 amount, address payable account)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (account == address(0))
            revert ZeroAddressNotAllowed("Cannot set zero address");
        if (address(this).balance < amount)
            revert InsufficientAmount(
                "Insufficient balance to withdraw amount"
            );
        if (isShutdown) revert ContractShutdown("Contract has been shut down");

        account.transfer(amount);

        emit FundsWithdrawnFromContract(amount, account);
    }

    /**
        @notice distributes NFTs to winners at the end of a grants cycle
        @param grantID id of grants
    */
    function sendRewards(uint256 grantID, address payable winnerAccount)
        public
        onlyRole(CURATOR_ROLE)
    {
        if (grants[grantID].endTime > block.timestamp)
            revert GrantHasNotEnded("Grant is still running", grantID);
        if (cancelled[grantID] == true)
            revert GrantCancelled("Grant has been cancelled", grantID);
        if (isShutdown) revert ContractShutdown("Contract has been shut down");
        if (donationsPaid[grantID])
            revert DonationsPaid("Donations paid already", grantID);

        // get topDonor

        address nftContractAddress = grants[grantID].nftContract;

        // transfer to random donor
        IERC721Upgradeable(nftContractAddress).safeTransferFrom(
            address(this),
            grants[grantID].topDonor,
            grants[grantID].tokenID1,
            ""
        );

        emit NFTsentToWinner(grantID, grants[grantID].topDonor);

        // transfer to DAO Wallet
        IERC721Upgradeable(nftContractAddress).safeTransferFrom(
            address(this),
            DAOWallet,
            grants[grantID].tokenID2,
            ""
        );
        emit NFTsentToWinner(grantID, DAOWallet);
        // transfer to NFT author
        IERC721Upgradeable(nftContractAddress).safeTransferFrom(
            address(this),
            grants[grantID].nftAuthor,
            grants[grantID].tokenID3,
            ""
        );

        _payDonationsToGrantWinner(winnerAccount, grantID);
        emit NFTsentToWinner(grantID, grants[grantID].nftAuthor);
    }

    function shutdown(bool _isShutdown) external onlyRole(DEFAULT_ADMIN_ROLE) {
        isShutdown = _isShutdown;
        emit Shutdown(_isShutdown);
    }

    // --------------------------------------------------------------
    // INTERNAL FUNCTIONS
    // --------------------------------------------------------------
    /**
        @notice function pays donations to winner and artizen wallet
         @param  account address to withdraw tokens to
        @param  grantID ID of grant
       
    */
    function _payDonationsToGrantWinner(
        address payable account,
        uint256 grantID
    ) internal {
        if (account == address(0))
            revert ZeroAddressNotAllowed("Cannot set zero address");
        if (grants[grantID].endTime > block.timestamp)
            revert GrantHasNotEnded("Grant is still running", grantID);
        if (donationsPaid[grantID] == true)
            revert DonationsPaid("Donations paid already", grantID);
        if (isShutdown) revert ContractShutdown("Contract has been shut down");

        uint256 totalDonations = totalDonationsPerGrant[grantID];
        uint256 winnerAmount = (totalDonations / 100) * 95;
        uint256 donationFees = (totalDonations / 100) * 5;

        donationsPaid[grantID] = true;

        // transfer fees to winner
        account.transfer(winnerAmount);
        //transfer donation fees
        DAOWallet.transfer(donationFees);

        emit DonationSentToWinner(account, grantID, winnerAmount);
    }

    // --------------------------------------------------------------
    // VIEW FUNCTIONS
    // --------------------------------------------------------------

    function getGrant(uint256 grantID) public view returns (Grant memory) {
        return grants[grantID];
    }

    // --------------------------------------------------------------
    // EXTERNAL FUNCTIONS
    // --------------------------------------------------------------

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }
}