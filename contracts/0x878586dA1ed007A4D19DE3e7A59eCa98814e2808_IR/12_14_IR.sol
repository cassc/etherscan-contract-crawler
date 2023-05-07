// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "closedsea/src/OperatorFilterer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract IR is ERC721A, ERC2981, Ownable, ReentrancyGuard, OperatorFilterer {
    using EnumerableSet for EnumerableSet.AddressSet;

    enum MerkleRootType {
        VIP,
        FCFS
    }

    enum DepositType {
        VIPGuaranteed,
        FCFSGuaranteed,
        NonGuaranteed
    }

    enum RefundStatus {
        NotRefunded,
        Refunded
    }

    enum AirdropType {
        Leaderboard,
        Treasury,
        Gift,
        Holder,
        Deposit
    }

    struct AddressInfo {
        MerkleRootType userType;
        /// @dev 0 -> not refunded; 1 -> refunded
        RefundStatus refundStatus;
        uint64 guaranteedQty;
        uint64 nonGuaranteedQty;
    }

    mapping(address => AddressInfo) public addressesInfo;

    EnumerableSet.AddressSet vipGuaranteedOwners;
    EnumerableSet.AddressSet fcfsGuaranteedOwners;
    EnumerableSet.AddressSet nonGuaranteedOwners;

    bool public operatorFilteringEnabled;
    string public baseTokenURI;
    bytes32 public vipMerkleRoot;
    bytes32 public fcfsMerkleRoot;

    /// @notice Supply list
    uint256 public constant MAX_SUPPLY = 20000;
    uint256 public constant TOP_50_LEADERBOARD_SUPPLY = 57;
    uint256 public constant TREASURY_SUPPLY = 200;
    uint256 public constant GIFT_SUPPLY = 349;
    uint256 public constant HOLDER_SUPPLY = 8815;
    uint256 public constant DEPOSIT_SUPPLY =
        MAX_SUPPLY -
            TOP_50_LEADERBOARD_SUPPLY -
            TREASURY_SUPPLY -
            GIFT_SUPPLY -
            HOLDER_SUPPLY;

    /// @notice DEPOSIT_SUPPLY breakdown
    uint256 public constant VIP_GUARANTEED_SUPPLY = 9579;
    uint256 public constant FCFS_GUARANTEED_SUPPLY = 1000;

    /// @notice Wallets for treasury airdrop and proceeds withdrawal
    address public constant TREASURY_WALLET =
        0x84eB8d02819bD90C766d23370C8926D857ce1505;
    address public constant WITHDRAW_WALLET =
        0xbB36a2fBDeA5E30F73693aEda596749200dd2496;

    /// @notice Deposit variables
    uint256 public constant DEPOSIT_PRICE = 0.13 ether;
    uint256 public constant REFUND_PRICE = 0.15 ether;
    uint64 public constant FCFS_DEPOSIT_QUANTIY = 1;

    bool public isDepositActive;

    uint256 public vipGuaranteedDeposited;
    uint256 public fcfsGuaranteedDeposited;
    uint256 public nonGuaranteedDeposited;
    uint256 public nonGuaranteedRefunded;

    /// @notice Airdrop variables
    uint256 public top50LeaderboardQtyAirdropped;
    uint256 public treasuryQtyAirdropped;
    uint256 public giftQtyAirdropped;
    uint256 public holderQtyAirdropped;

    mapping(address => uint256) public top50LeaderboardAirdrops;
    mapping(address => uint256) public giftAirdrops;
    mapping(address => uint256) public holderAirdrops;

    error DepositInactive();
    error NotInAllowlist();
    error InvalidGuaranteedQuantity();
    error InsufficientETHSent();
    error ExceedsMaxSupply();
    error ExceedsAllocationForDeposit();
    error ExceedsAllocationForAirdropType(AirdropType _airdropType);
    error ExceedsVIPSupply();
    error NonGuaranteedCapped();
    error AlreadyDeposited();
    error UnequalArrayLength();
    error IncorrectLeaderboardLeaders();
    error LeaderboardLeaderAirdropped();
    error GiftAirdropped();
    error HolderAirdropped();
    error DepositAirdropped();
    error WithdrawalFailed();
    error RefundFailed(address _to, uint256 _amount);
    error InsufficientBalance();

    event VIPDeposited(
        address indexed _from,
        uint256 _amount,
        uint256 _guaranteedQty,
        uint256 _nonGuaranteedQty,
        uint256 _nonGuaranteedRemainingSupply,
        uint256 _vipGuaranteedRemainingSupply
    );
    event FCFSDeposited(
        address indexed _from,
        uint256 _amount,
        uint256 _qty,
        uint256 _nonGuaranteedRemainingSupply,
        uint256 _fcfsGuaranteedRemainingSupply
    );
    event Refunded(address indexed _to, uint256 _amount);
    event Airdropped(address indexed _to, uint256 _qty);

    modifier withinSupplies(AirdropType _airdropType, uint256 _toMint) {
        if (_totalMinted() + _toMint > MAX_SUPPLY) revert ExceedsMaxSupply();

        if (
            _airdropType == AirdropType.Leaderboard &&
            top50LeaderboardQtyAirdropped + _toMint > TOP_50_LEADERBOARD_SUPPLY
        ) revert ExceedsAllocationForAirdropType(_airdropType);
        else if (
            _airdropType == AirdropType.Treasury &&
            treasuryQtyAirdropped + _toMint > TREASURY_SUPPLY
        ) revert ExceedsAllocationForAirdropType(_airdropType);
        else if (
            _airdropType == AirdropType.Gift &&
            giftQtyAirdropped + _toMint > GIFT_SUPPLY
        ) revert ExceedsAllocationForAirdropType(_airdropType);
        else if (
            _airdropType == AirdropType.Holder &&
            holderQtyAirdropped + _toMint > HOLDER_SUPPLY
        ) revert ExceedsAllocationForAirdropType(_airdropType);
        _;
    }

    modifier equalArrayLength(
        address[] calldata _to,
        uint64[] calldata _airdropQty
    ) {
        if (_to.length != _airdropQty.length) revert UnequalArrayLength();
        _;
    }

    modifier depositActive() {
        if (!isDepositActive) revert DepositInactive();
        _;
    }

    modifier hasNotDeposited(address _depositor) {
        /// @notice VIP only have one chance make the decision whether to deposit the optional
        // Prevent same address to deposit on FCFS and VIP
        if (
            addressesInfo[_depositor].guaranteedQty > 0 ||
            addressesInfo[_depositor].nonGuaranteedQty > 0
        ) revert AlreadyDeposited();
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI
    ) ERC721A(_name, _symbol) {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        _setDefaultRoyalty(msg.sender, 500);
        baseTokenURI = _baseTokenURI;
    }

    /// @dev Helper function to get the sum of array (reduce)
    function _reduce(uint64[] calldata _arr) internal pure returns (uint256) {
        uint256 result = 0;

        for (uint256 i = 0; i < _arr.length; ) {
            result += _arr[i];

            unchecked {
                ++i;
            }
        }

        return result;
    }

    /// @dev Helper function to send ETH or revert if insufficient
    function _sendETH(address _to, uint256 _amount) private returns (bool) {
        if (_amount > address(this).balance) revert InsufficientBalance();

        (bool success, ) = payable(_to).call{value: _amount}("");
        return success;
    }

    /// @dev Helper function to mint and emit
    function _mintAndEmit(address _to, uint256 _qty) private {
        _mint(_to, _qty);
        emit Airdropped(_to, _qty);
    }

    /// @dev Helper function to airdrop to leaderboard leaders
    function _leaderboardLeadersAirdrop(
        address[] calldata _to,
        uint256 _topX
    ) private {
        uint256 airdropQty = 1;

        for (uint256 i; i < _topX; ) {
            /// @dev Only top 7 should have 2 quantity
            if (
                (i < 7 && top50LeaderboardAirdrops[_to[i]] + airdropQty > 2) ||
                (i > 6 && top50LeaderboardAirdrops[_to[i]] + airdropQty > 1)
            ) revert LeaderboardLeaderAirdropped();

            _mintAndEmit(_to[i], airdropQty);

            unchecked {
                top50LeaderboardQtyAirdropped += airdropQty;
                top50LeaderboardAirdrops[_to[i]] += airdropQty;
                ++i;
            }
        }
    }

    /// @dev Helper function to check if non-guaranteed list is full
    function _isNonGuaranteedFull(
        uint256 _nonGuaranteedDeposit
    ) private view returns (bool) {
        return
            vipGuaranteedDeposited +
                fcfsGuaranteedDeposited +
                nonGuaranteedDeposited +
                _nonGuaranteedDeposit >
            DEPOSIT_SUPPLY;
    }

    function depositVIP(
        bytes32[] calldata _merkleProof,
        uint256 _allowedQty,
        uint64 _guaranteedDeposit,
        uint64 _nonGuaranteedDeposit
    ) external payable nonReentrant depositActive hasNotDeposited(msg.sender) {
        // Check if in whitelist
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _allowedQty));
        if (!MerkleProof.verifyCalldata(_merkleProof, vipMerkleRoot, leaf))
            revert NotInAllowlist();

        if (_guaranteedDeposit == 0) revert InvalidGuaranteedQuantity();

        // Check if enough ETH sent
        if (
            msg.value <
            DEPOSIT_PRICE * (_guaranteedDeposit + _nonGuaranteedDeposit)
        ) revert InsufficientETHSent();

        // Check if exceeding allocated
        if (
            _guaranteedDeposit > _allowedQty ||
            _nonGuaranteedDeposit > _allowedQty
        ) revert ExceedsAllocationForDeposit();

        // Check if VIP exceeding guaranteed supply
        if (vipGuaranteedDeposited + _guaranteedDeposit > VIP_GUARANTEED_SUPPLY)
            revert ExceedsVIPSupply();

        // Assign user type VIP to the address
        addressesInfo[msg.sender].userType = MerkleRootType.VIP;
        unchecked {
            vipGuaranteedDeposited += _guaranteedDeposit;
            addressesInfo[msg.sender].guaranteedQty += _guaranteedDeposit;
            vipGuaranteedOwners.add(msg.sender);
        }

        // Check if non-guaranteed list is full and address deposit the non-guaranteed spot
        if (_nonGuaranteedDeposit > 0) {
            if (!_isNonGuaranteedFull(_nonGuaranteedDeposit)) {
                unchecked {
                    nonGuaranteedDeposited += _nonGuaranteedDeposit;
                    addressesInfo[msg.sender]
                        .nonGuaranteedQty += _nonGuaranteedDeposit;
                    nonGuaranteedOwners.add(msg.sender);
                }
            } else {
                revert NonGuaranteedCapped();
            }
        }

        emit VIPDeposited(
            msg.sender,
            msg.value,
            _guaranteedDeposit,
            _nonGuaranteedDeposit,
            getNonGuaranteedRemainingSupply(),
            getVIPGuaranteedRemainingSupply()
        );
    }

    function depositFCFS(
        bytes32[] calldata _merkleProof
    ) external payable nonReentrant depositActive hasNotDeposited(msg.sender) {
        // Check if in whitelist
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verifyCalldata(_merkleProof, fcfsMerkleRoot, leaf))
            revert NotInAllowlist();

        // Check if enough ETH sent
        if (msg.value < DEPOSIT_PRICE) revert InsufficientETHSent();

        /// @notice Not checking if exceeding FCFS supply as they they could still go into the non-guaranteed list

        // Assign user type FCFS to the address
        addressesInfo[msg.sender].userType = MerkleRootType.FCFS;

        // If exceeds guaranteed supply, go into non-guaranteed list
        if (
            fcfsGuaranteedDeposited + FCFS_DEPOSIT_QUANTIY >
            FCFS_GUARANTEED_SUPPLY
        ) {
            // Check if non-guaranteed list is full
            if (!_isNonGuaranteedFull(FCFS_DEPOSIT_QUANTIY)) {
                unchecked {
                    nonGuaranteedDeposited += FCFS_DEPOSIT_QUANTIY;
                    addressesInfo[msg.sender]
                        .nonGuaranteedQty += FCFS_DEPOSIT_QUANTIY;
                    nonGuaranteedOwners.add(msg.sender);
                }
            } else {
                revert NonGuaranteedCapped();
            }
        } else {
            unchecked {
                fcfsGuaranteedDeposited += FCFS_DEPOSIT_QUANTIY;
                addressesInfo[msg.sender].guaranteedQty += FCFS_DEPOSIT_QUANTIY;
                fcfsGuaranteedOwners.add(msg.sender);
            }
        }

        emit FCFSDeposited(
            msg.sender,
            msg.value,
            FCFS_DEPOSIT_QUANTIY,
            getNonGuaranteedRemainingSupply(),
            getFCFSGuaranteedRemainingSupply()
        );
    }

    /// @notice This function does not allow multiple executions - Do it once, do it right.
    function top50LeaderboardAirdrop(
        address[] calldata _to
    )
        external
        onlyOwner
        nonReentrant
        withinSupplies(AirdropType.Leaderboard, 57)
    {
        /// @notice Top 7 will be airdropped twice (ids 1-7 + 8-14)
        if (_to.length != 50) revert IncorrectLeaderboardLeaders();

        // @dev Airdrop first for top 7
        _leaderboardLeadersAirdrop(_to, 7);

        // @dev Airdrop first for top 50
        _leaderboardLeadersAirdrop(_to, 50);
    }

    function batchAirdrop(
        address[] calldata _to,
        uint64[] calldata _airdropQty
    ) external onlyOwner nonReentrant equalArrayLength(_to, _airdropQty) {
        for (uint256 i; i < _to.length; ) {
            if (_totalMinted() + _airdropQty[i] > MAX_SUPPLY)
                revert ExceedsMaxSupply();

            // Check if already airdropped
            if (_getAux(_to[i]) != 0) revert DepositAirdropped();

            _mintAndEmit(_to[i], _airdropQty[i]);
            _setAux(_to[i], _airdropQty[i]);

            unchecked {
                ++i;
            }
        }
    }

    function treasuryAirdrop()
        external
        onlyOwner
        nonReentrant
        withinSupplies(AirdropType.Treasury, TREASURY_SUPPLY)
    {
        _mintAndEmit(TREASURY_WALLET, TREASURY_SUPPLY);

        unchecked {
            treasuryQtyAirdropped += TREASURY_SUPPLY;
        }
    }

    function giftAirdrop(
        address[] calldata _to,
        uint64[] calldata _airdropQty
    )
        external
        onlyOwner
        nonReentrant
        withinSupplies(AirdropType.Gift, _reduce(_airdropQty))
        equalArrayLength(_to, _airdropQty)
    {
        for (uint256 i; i < _to.length; ) {
            if (giftAirdrops[_to[i]] > 0) revert GiftAirdropped();

            _mintAndEmit(_to[i], _airdropQty[i]);

            unchecked {
                giftQtyAirdropped += _airdropQty[i];
                giftAirdrops[_to[i]] = _airdropQty[i];
                ++i;
            }
        }
    }

    function holderAirdrop(
        address[] calldata _to,
        uint64[] calldata _airdropQty
    )
        external
        onlyOwner
        nonReentrant
        withinSupplies(AirdropType.Holder, _reduce(_airdropQty))
        equalArrayLength(_to, _airdropQty)
    {
        for (uint256 i; i < _to.length; ) {
            if (holderAirdrops[_to[i]] > 0) revert HolderAirdropped();

            _mintAndEmit(_to[i], _airdropQty[i]);

            unchecked {
                holderQtyAirdropped += _airdropQty[i];
                holderAirdrops[_to[i]] = _airdropQty[i];
                ++i;
            }
        }
    }

    function batchRefund(
        address[] calldata _to,
        uint64[] calldata _refundQty
    ) external onlyOwner nonReentrant equalArrayLength(_to, _refundQty) {
        for (uint256 i; i < _to.length; ) {
            AddressInfo memory addressInfo = addressesInfo[_to[i]];

            // Addressess won't appear in both lists; Only VIPs can make 1x optional deposit

            // Check if the address has already been refunded
            // Check that address made a non-guaranteed deposit
            if (
                addressInfo.refundStatus == RefundStatus.NotRefunded &&
                addressInfo.nonGuaranteedQty > 0
            ) {
                uint256 refundAmount = REFUND_PRICE * _refundQty[i];

                bool sent = _sendETH(_to[i], refundAmount);
                if (!sent) revert RefundFailed(_to[i], refundAmount);

                addressInfo.refundStatus = RefundStatus.Refunded;

                unchecked {
                    addressInfo.nonGuaranteedQty -= _refundQty[i];
                    nonGuaranteedRefunded += _refundQty[i];
                }
                emit Refunded(_to[i], refundAmount);
            }
            unchecked {
                ++i;
            }
        }
    }

    function withdraw() external onlyOwner nonReentrant {
        bool sent = _sendETH(WITHDRAW_WALLET, address(this).balance);
        if (!sent) revert WithdrawalFailed();
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    function setMerkleRoot(
        MerkleRootType _type,
        bytes32 _merkleRoot
    ) external onlyOwner {
        if (_type == MerkleRootType.VIP) vipMerkleRoot = _merkleRoot;
        else if (_type == MerkleRootType.FCFS) fcfsMerkleRoot = _merkleRoot;
    }

    function toggleDepositState() external onlyOwner {
        isDepositActive = !isDepositActive;
    }

    function getDepositAddressesCount(
        DepositType _depositType
    ) public view returns (uint256) {
        /// @notice _depositType: 0 - VIPGuaranteed; 1 - FCFSGuaranteed; 2 - NonGuaranteed
        if (_depositType == DepositType.VIPGuaranteed)
            return vipGuaranteedOwners.length();
        else if (_depositType == DepositType.FCFSGuaranteed)
            return fcfsGuaranteedOwners.length();

        return nonGuaranteedOwners.length();
    }

    /// @notice View for list of guaranteed and non-guaranteed deposits addresses
    function getDepositedAddresses(
        DepositType _depositType,
        uint256 fromIdx,
        uint256 toIdx
    ) external view returns (address[] memory) {
        /// @notice _depositType: 0 - VIPGuaranteed; 1 - FCFSGuaranteed; 2 - NonGuaranteed
        uint256 length = getDepositAddressesCount(_depositType);

        toIdx = Math.min(toIdx, length);
        uint256 addressesRange = toIdx - fromIdx;
        address[] memory addresses = new address[](addressesRange);

        for (uint256 i = 0; i < addressesRange; ) {
            if (_depositType == DepositType.VIPGuaranteed)
                addresses[i] = vipGuaranteedOwners.at(i + fromIdx);
            else if (_depositType == DepositType.FCFSGuaranteed)
                addresses[i] = fcfsGuaranteedOwners.at(i + fromIdx);
            else if (_depositType == DepositType.NonGuaranteed)
                addresses[i] = nonGuaranteedOwners.at(i + fromIdx);

            unchecked {
                ++i;
            }
        }

        return addresses;
    }

    /// @notice View for VIP guaranteed remaining supply
    function getVIPGuaranteedRemainingSupply() public view returns (uint256) {
        unchecked {
            return VIP_GUARANTEED_SUPPLY - vipGuaranteedDeposited;
        }
    }

    /// @notice View for FCFS guaranteed remaining supply
    function getFCFSGuaranteedRemainingSupply() public view returns (uint256) {
        unchecked {
            return FCFS_GUARANTEED_SUPPLY - fcfsGuaranteedDeposited;
        }
    }

    /// @notice View for non-guaranteed remaining supply
    function getNonGuaranteedRemainingSupply() public view returns (uint256) {
        unchecked {
            return
                _isNonGuaranteedFull(0)
                    ? 0
                    : DEPOSIT_SUPPLY -
                        vipGuaranteedDeposited -
                        fcfsGuaranteedDeposited -
                        nonGuaranteedDeposited;
        }
    }

    /// @notice View for list of guaranteed and non-guaranteed deposits addresses
    function getAirdropQtyPerAddress(
        DepositType _depositType,
        address[] calldata addresses
    ) external view returns (uint256[] memory) {
        /// @notice _depositType: 0 - VIPGuaranteed; 1 - FCFSGuaranteed; 2 - NonGuaranteed
        uint256[] memory depositQty = new uint256[](addresses.length);

        for (uint256 i = 0; i < addresses.length; ) {
            if (
                _depositType == DepositType.VIPGuaranteed &&
                addressesInfo[addresses[i]].userType == MerkleRootType.VIP
            ) depositQty[i] = addressesInfo[addresses[i]].guaranteedQty;
            else if (
                _depositType == DepositType.FCFSGuaranteed &&
                addressesInfo[addresses[i]].userType == MerkleRootType.FCFS
            ) depositQty[i] = addressesInfo[addresses[i]].guaranteedQty;
            else if (_depositType == DepositType.NonGuaranteed)
                depositQty[i] = addressesInfo[addresses[i]].nonGuaranteedQty;

            unchecked {
                ++i;
            }
        }

        return depositQty;
    }

    /**
        @notice Override to start token id at 1
    **/
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /**
        @notice Override for DefaultOperatorFilterer, which automatically registers the token and subscribes it to OpenSea's curated filters.
        @dev Makes use of Vectorized/closedsea (https://github.com/Vectorized/closedsea) package
    **/
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
        @notice Override for DefaultOperatorFilterer, which automatically registers the token and subscribes it to OpenSea's curated filters.
        @dev Makes use of Vectorized/closedsea (https://github.com/Vectorized/closedsea) package
    **/
    function approve(
        address operator,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    /**
        @notice Override for DefaultOperatorFilterer, which automatically registers the token and subscribes it to OpenSea's curated filters.
        @dev Makes use of Vectorized/closedsea (https://github.com/Vectorized/closedsea) package
    **/
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
        @notice Override for DefaultOperatorFilterer, which automatically registers the token and subscribes it to OpenSea's curated filters.
        @dev Makes use of Vectorized/closedsea (https://github.com/Vectorized/closedsea) package
    **/
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721A, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    /**
        @notice Override for DefaultOperatorFilterer, which automatically registers the token and subscribes it to OpenSea's curated filters.
        @dev Makes use of Vectorized/closedsea (https://github.com/Vectorized/closedsea) package
    **/
    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
        @notice Override for DefaultOperatorFilterer, which automatically registers the token and subscribes it to OpenSea's curated filters.
        @dev Makes use of Vectorized/closedsea (https://github.com/Vectorized/closedsea) package
    **/
    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    /**
        @notice Override for DefaultOperatorFilterer, which automatically registers the token and subscribes it to OpenSea's curated filters.
        @dev Makes use of Vectorized/closedsea (https://github.com/Vectorized/closedsea) package
    **/
    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    /**
        @notice Override for DefaultOperatorFilterer, which automatically registers the token and subscribes it to OpenSea's curated filters.
        @dev Makes use of Vectorized/closedsea (https://github.com/Vectorized/closedsea) package
    **/
    function _isPriorityOperator(
        address operator
    ) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }
}