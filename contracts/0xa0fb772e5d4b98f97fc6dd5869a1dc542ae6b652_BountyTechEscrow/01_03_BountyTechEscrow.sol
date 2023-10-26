// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

// Import ownable
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

interface IERC20 {
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract BountyTechEscrow is Ownable {
    mapping(address => bool) public isOperator;
    mapping(address => bool) public isBlacklisted;
    mapping(address => bool) public whitelistedTokenAddress;

    struct Listing {
        uint256 id;
        string metadataURL;
        address poster;
        address tokenAddress; // if tokenAddress == address(0) then payout is in ETH
        uint256 amount;
        uint256 deadline;
        bool isCancelled;
        bool isCompleted;
    }

    struct Submission {
        uint256 id;
        uint256 listingId;
        string metadataURL;
        address poster;
        bool isApproved;
    }

    Listing[] public listings;

    mapping(uint256 => Submission[]) public listingSubmissions;

    uint256 _listingIdCounter = 0;
    uint256 _submissionIdCounter = 0;

    // Events

    event ListingCreated(
        uint256 indexed listingId,
        string metadataURL,
        address indexed poster,
        address indexed tokenAddress,
        uint256 amount,
        uint256 deadline
    );

    event ListingCancelled(
        uint256 indexed listingId,
        string metadataURL,
        address indexed poster,
        address indexed tokenAddress,
        uint256 amount,
        uint256 deadline
    );

    event ListingCompleted(
        uint256 indexed listingId,
        string metadataURL,
        string submissionMetadataURL,
        address indexed poster,
        address indexed tokenAddress,
        uint256 amount,
        uint256 deadline,
        address winnerSubmissionOwner
    );

    event SubmissionCreated(
        uint256 indexed submissionId,
        uint256 indexed listingId,
        address indexed poster
    );

    event SubmissionApproved(
        uint256 indexed submissionId,
        uint256 indexed listingId,
        address indexed poster
    );

    event OperatorAccessChanged(address indexed operator, bool hasAccess);
    event Blacklisted(address indexed account, bool isBlacklisted);
    event WhitelistedTokenAddress(
        address indexed tokenAddress,
        bool isWhitelisted
    );

    constructor() {}

    // Internal functions
    function _sendEtherUsingCall(
        address payable _to,
        uint256 _amount,
        string memory _errorMessage
    ) internal {
        (bool success, ) = _to.call{value: _amount}("");
        require(success, _errorMessage);
    }

    // Only operator functions

    modifier onlyOperator() {
        require(
            isOperator[msg.sender] == true || msg.sender == owner(),
            "BTE: caller is not the operator"
        );
        _;
    }

    modifier notBlacklisted() {
        require(
            isBlacklisted[msg.sender] == false || msg.sender == owner(),
            "BTE: address is blacklisted"
        );
        _;
    }

    // Only owner functions

    function setOperatorAccess(
        address _operator,
        bool _hasAccess
    ) public onlyOwner {
        isOperator[_operator] = _hasAccess;

        emit OperatorAccessChanged(_operator, _hasAccess);
    }

    function setBlacklisted(
        address _address,
        bool _isBlacklisted
    ) public onlyOwner {
        isBlacklisted[_address] = _isBlacklisted;

        emit Blacklisted(_address, _isBlacklisted);
    }

    function setWhitelistedTokenAddress(
        address _tokenAddress,
        bool _isWhitelisted
    ) public onlyOwner {
        whitelistedTokenAddress[_tokenAddress] = _isWhitelisted;

        emit WhitelistedTokenAddress(_tokenAddress, _isWhitelisted);
    }

    // Getter functions

    function getListings() public view returns (Listing[] memory) {
        return listings;
    }

    function getListingSubmissions(
        uint256 _listingId
    ) public view returns (Submission[] memory) {
        return listingSubmissions[_listingId];
    }

    // Listing functions

    function createListing(
        string memory _metadataURL,
        address _tokenAddress,
        uint256 _amount,
        uint256 _deadline
    ) public payable notBlacklisted returns (uint256) {
        if (_tokenAddress != address(0))
            require(
                whitelistedTokenAddress[_tokenAddress] == true,
                "BTE: token address is not whitelisted"
            );

        if (_tokenAddress != address(0))
            require(_amount > 0, "BTE: amount mbgt 0");

        require(_deadline > block.timestamp, "BTE: deadline must be future");

        // Payout is in ETH
        if (_tokenAddress == address(0)) {
            require(msg.value >= _amount, "BTE: not enough ETH sent");
        } else {
            IERC20 token = IERC20(_tokenAddress);

            require(
                token.balanceOf(msg.sender) >= _amount,
                "BTE: not enough tokens"
            );

            require(
                token.transferFrom(msg.sender, address(this), _amount),
                "BTE: token transfer failed"
            );
        }

        uint256 listingId = _listingIdCounter;

        listings.push(
            Listing({
                id: listingId,
                metadataURL: _metadataURL,
                poster: msg.sender,
                tokenAddress: _tokenAddress,
                amount: _amount,
                deadline: _deadline,
                isCancelled: false,
                isCompleted: false
            })
        );

        unchecked {
            ++_listingIdCounter;
        }

        emit ListingCreated(
            listingId,
            _metadataURL,
            msg.sender,
            _tokenAddress,
            _amount,
            _deadline
        );

        return listingId;
    }

    function createSubmission(
        uint256 _listingId,
        string memory _metadataURL
    ) public notBlacklisted returns (uint256) {
        require(_listingId < listings.length, "BTE: listing does not exist");

        Listing memory listing = listings[_listingId];

        require(
            listing.poster != msg.sender,
            "BTE: cannot create submission on own listing"
        );

        require(listing.isCancelled == false, "BTE: listing is cancelled");

        require(listing.isCompleted == false, "BTE: listing is completed");

        require(
            block.timestamp < listing.deadline,
            "BTE: listing deadline has passed"
        );

        uint256 submissionId = _submissionIdCounter;

        Submission memory submission = Submission({
            id: submissionId,
            metadataURL: _metadataURL,
            listingId: _listingId,
            poster: msg.sender,
            isApproved: false
        });

        listingSubmissions[_listingId].push(submission);

        unchecked {
            ++_submissionIdCounter;
        }

        emit SubmissionCreated(submissionId, _listingId, msg.sender);

        return submissionId;
    }

    function approveSubmission(
        uint256 _listingId,
        uint256 _submissionId
    ) public onlyOperator {
        require(
            _submissionId < listingSubmissions[_listingId].length,
            "BTE: submission does not exist"
        );

        Submission storage submission = listingSubmissions[_listingId][
            _submissionId
        ];

        require(
            submission.isApproved == false,
            "BTE: submission is already approved"
        );

        submission.isApproved = true;

        emit SubmissionApproved(
            _submissionId,
            submission.listingId,
            submission.poster
        );

        Listing storage listing = listings[submission.listingId];

        require(
            listing.isCompleted == false,
            "BTE: listing is already completed"
        );

        require(listing.isCancelled == false, "BTE: listing is  cancelled");

        listing.isCompleted = true;

        if (listing.tokenAddress == address(0)) {
            _sendEtherUsingCall(
                payable(submission.poster),
                listing.amount,
                "BTE: ETH transfer failed"
            );
        } else {
            IERC20 token = IERC20(listing.tokenAddress);

            require(
                token.transfer(submission.poster, listing.amount),
                "BTE: token transfer failed"
            );
        }

        emit ListingCompleted(
            listing.id,
            listing.metadataURL,
            submission.metadataURL,
            listing.poster,
            listing.tokenAddress,
            listing.amount,
            listing.deadline,
            submission.poster
        );
    }

    function cancelListing(uint256 _listingId) public notBlacklisted {
        require(_listingId < listings.length, "BTE: listing does not exist");

        Listing storage listing = listings[_listingId];

        require(
            listing.poster == msg.sender || msg.sender == owner(),
            "BTE: caller is not the listing poster"
        );

        require(
            listing.isCancelled == false,
            "BTE: listing is already cancelled"
        );

        require(
            listing.isCompleted == false,
            "BTE: listing is already completed"
        );

        listing.isCancelled = true;

        emit ListingCancelled(
            listing.id,
            listing.metadataURL,
            listing.poster,
            listing.tokenAddress,
            listing.amount,
            listing.deadline
        );

        if (listing.tokenAddress == address(0)) {
            _sendEtherUsingCall(
                payable(listing.poster),
                listing.amount,
                "BTE: ETH transfer failed"
            );
        } else {
            IERC20 token = IERC20(listing.tokenAddress);

            require(
                token.transfer(listing.poster, listing.amount),
                "BTE: token transfer failed"
            );
        }
    }
}