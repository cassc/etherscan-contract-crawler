// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import "./IBTRST.sol";

contract BraintrustMembershipNFT is
    Initializable,
    ERC721Upgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;

    /**
     * @notice The relayer. Is an EOA that holds ETH which is used to pay gas for certain method calls.e.g `safeMint()`.
     */
    address public relayer;

    /**
     * @notice The Membership NFT base URI`.
     */
    string public baseURI;

    /**
     * @notice The Braintrust ERC-20 token.
     */

    IBTRST btrstErc20;

    /**
     * @notice Keyed by beneficiary wallet address, the associated Profile data.
     */
    mapping(address => Profile) public unlockedDeposits;

    /**
     * @notice Keyed by beneficiary wallet address, the associated Profiles.
     * Each call to lockDeposit() function will add a new item in the Profile[] array for the given beneficiary.
     */
    mapping(address => Profile[]) public lockedDeposits;

    /**
     * @notice The details of a beneficiary's deposit.
     * @param nftTokenId The braintrust membership NFT of the beneficiary.
     * @param btrstAmount The amount of $BTRST.
     * @param available The time which deposit amount becomes unlocked in the case of a locked deposit.
     */
    struct Profile {
        uint256 nftTokenId;
        uint256 btrstAmount;
        uint256 available;
    }

    //errors
    error OnlyRelayerAllowed();
    error NftDoesNotBelongToBeneficiary(
        uint256 nftTokenId,
        address beneficiary
    );
    error NoMembershipNftInWallet(address beneficiary);
    error LockPeriodNotReached();
    error InsufficientBalance();
    error TransferNotAllowed();
    error UserAlreadyMintedNFT(address to);
    error ZeroDeposit();
    error InsufficientLockPeriod();
    error AddressZero();

    //events
    event NftMinted(address indexed sender, uint256 amount);
    event Deposited(address indexed sender, uint256 amount);
    event DepositLocked(
        address indexed sender,
        uint256 amount
    );
    event UnlockedDepositWithdrawn(address indexed sender, uint256 amount);
    event LockedDepositWithdrawn(
        address indexed sender,
        uint256 amount,
        uint256 index
    );
    event RelayerChanged(address oldRelayer, address newRelayer);

    /**
     * @notice Used when only the relayer address is allowed to perform a call.
     */
    modifier onlyRelayer() {
        if (msg.sender != relayer) {
            revert OnlyRelayerAllowed();
        }
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // standard oz function
    function initialize(
        address _relayer,
        address _btrstErc20,
        string memory _baseURL
    ) public initializer {
        __ERC721_init("Braintrust Membership NFT", "BNFT");
        __Ownable_init();
        __UUPSUpgradeable_init();

        setRelayer(_relayer);
        btrstErc20 = IBTRST(_btrstErc20);
        setBaseURI(_baseURL);

        // NFT tokenID starts from 1
        _tokenIdCounter.increment();
    }

    // standard oz function
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    /**
     * @notice Business Rule. Prevent NFT transfers across wallet.
     * @param from The source address.
     * @param to The destination address.
     * @param tokenId The braintrust membership NFT.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        // NFT cannot be transferred across wallets. Only mint is enabled.
        if (from != address(0)) {
            revert TransferNotAllowed();
        }

        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @notice Changes the NFT base URL to a new value.
     * @param newURI The new base URL value.
     */
    function setBaseURI(string memory newURI) public onlyOwner {
        baseURI = newURI;
    }

    /**
     * @notice Returns the baseURI string.
     * @return The base URI.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @notice Changes the relayer address to a new one.
     * @param newRelayer The new relayer address value.
     */
    function setRelayer(address newRelayer) public onlyOwner {
        if (newRelayer == address(0)) {
            revert AddressZero();
        }
        address oldRelayer = relayer;
        relayer = newRelayer;
        emit RelayerChanged(oldRelayer, newRelayer);
    }

    /**
     * @notice Mints a new NFT to a specified address.
     * @param to The beneficiary address to mint to.
     */
    function safeMint(address to) public onlyRelayer {
        if (balanceOf(to) > 0) {
            revert UserAlreadyMintedNFT(to);
        }
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        emit NftMinted(to, tokenId);
    }

    /**
     * @notice Enables a deposit of $BTRST ERC20 to this contract on behalf of a beneficiary.
     * The cumulative deposit is used off-chain to determine a user's level. A deposit is only
     * successful if the beneficiary's wallet already contains a braintrust membership NFT.
     * This function is ideally called by the beneficiary, but ultimately anyone who calls it
     * should have enough $BTRST, and should have already approved this contract to spend it.
     * Business Rule? A deposit will only succeed if a beneficiary already has a membership NFT.
     * @param amount The amount of $BTRST being deposited.
     * @param nftTokenId The braintrust membership NFT token ID of the beneficiary.
     * @param beneficiary The beneficiary address.
     */
    function deposit(
        uint256 amount,
        uint256 nftTokenId,
        address beneficiary
    ) external {
        if (amount == 0) {
            revert ZeroDeposit();
        }

        if (balanceOf(beneficiary) <= 0) {
            revert NoMembershipNftInWallet(beneficiary);
        }

        if (ownerOf(nftTokenId) != beneficiary) {
            revert NftDoesNotBelongToBeneficiary(nftTokenId, beneficiary);
        }

        // we only set nft id once, but increment deposit amount every time.
        // available is always left as 0, since there is no unlock time for unlocked deposits.
        if (unlockedDeposits[beneficiary].nftTokenId == 0) {
            unlockedDeposits[beneficiary].nftTokenId = nftTokenId;
        }

        unlockedDeposits[beneficiary].btrstAmount += amount;

        btrstErc20.transferFrom(msg.sender, address(this), amount);
        emit Deposited(beneficiary, amount);
    }

    /**
     * @notice Enables a locked deposit of $BTRST ERC20 to this contract on behalf of a beneficiary.
     * A locked deposit is different from an ordinary deposit mainly because it is frozen on this contract
     * until the available time has elapsed.
     * The cumulative deposit is used off-chain to determine a user's level. A locked deposit is only
     * successful if a beneficiary's wallet already contains a braintrust membership NFT.
     * @param amount The amount of $BTRST being deposited.
     * @param nftTokenId The braintrust membership NFT token ID of the beneficiary.
     * @param beneficiary The beneficiary address.
     */
    function lock(
        uint256 amount,
        uint256 nftTokenId,
        address beneficiary,
        uint256 availableTimeInSeconds
    ) external {
        // availableTimeInSeconds must be greater than 30 days.
        if (availableTimeInSeconds < 30 * 24 * 3600) {
            revert InsufficientLockPeriod();
        }

        if (amount == 0) {
            revert ZeroDeposit();
        }

        if (balanceOf(beneficiary) <= 0) {
            revert NoMembershipNftInWallet(beneficiary);
        }

        // check that nft belongs to beneficiary
        if (ownerOf(nftTokenId) != beneficiary) {
            revert NftDoesNotBelongToBeneficiary(nftTokenId, beneficiary);
        }

        uint256 available = availableTimeInSeconds + block.timestamp;

        lockedDeposits[beneficiary].push(
            Profile(nftTokenId, amount, available)
        );
        btrstErc20.transferFrom(msg.sender, address(this), amount);
        emit DepositLocked(beneficiary, amount);
    }

    /**
     * @notice Enables a user to transfer their $BTRST deposit to their wallet.
     * @param amount The amount of $BTRST being withdrawn.
     */
    function withdrawUnlockedDeposit(uint256 amount) external {
        // check if user has enough deposit, then they can withdraw
        if (amount > unlockedDeposits[msg.sender].btrstAmount) {
            revert InsufficientBalance();
        }

        unlockedDeposits[msg.sender].btrstAmount -= amount;
        btrstErc20.transferFrom(address(this), msg.sender, amount);

        emit UnlockedDepositWithdrawn(msg.sender, amount);
    }

    /**
     * @notice Enables a user to transfer their locked $BTRST deposit to their wallet. This is only possible if available time has elapsed.
     * @param amount The amount of $BTRST being withdrawn.
     * @param withdrawalIndex The index in the array within `lockedDeposits`.
     */
    function withdrawLockedDeposit(uint256 amount, uint256 withdrawalIndex)
        external
    {
        // check that available time has reached for that withdrawal index
        if (
            block.timestamp <
            lockedDeposits[msg.sender][withdrawalIndex].available
        ) {
            revert LockPeriodNotReached();
        }
        // check if user has enough deposit, they can withdraw
        if (amount > lockedDeposits[msg.sender][withdrawalIndex].btrstAmount) {
            revert InsufficientBalance();
        }

        lockedDeposits[msg.sender][withdrawalIndex].btrstAmount -= amount;
        uint256 len = lockedDeposits[msg.sender].length;
        // if btrstAmount is now zero, then delete it from mapping
        if (lockedDeposits[msg.sender][withdrawalIndex].btrstAmount == 0) {
            lockedDeposits[msg.sender][withdrawalIndex] = lockedDeposits[
                msg.sender
            ][len - 1];
            lockedDeposits[msg.sender].pop();
        }

        btrstErc20.transferFrom(address(this), msg.sender, amount);

        emit LockedDepositWithdrawn(msg.sender, amount, withdrawalIndex);
    }

    /**
     * @notice Returns the total unlocked deposits for a given wallet.
     * @param _address The address to check.
     * @return The total unlocked deposit.
     */
    function getTotalUnlockedDeposit(address _address)
        public
        view
        returns (uint256)
    {
        return unlockedDeposits[_address].btrstAmount;
    }

    /**
     * @notice Returns the locked deposit for a given wallet at a given index.
     * @param _address The address to check.
     * @param index The index in the array within `lockedDeposits`.
     * @return The corresponding `nftTokenId`.
     * @return The corresponding `btrstAmount`.
     * @return The corresponding `available`.
     */
    function getLockedDepositByIndex(address _address, uint256 index)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        Profile memory _lockedDeposit = lockedDeposits[_address][index];
        return (
            _lockedDeposit.nftTokenId,
            _lockedDeposit.btrstAmount,
            _lockedDeposit.available
        );
    }

    /**
     * @notice Returns the total locked deposits for a given wallet.
     *  @notice NOTE: intented for off-chain.
     * @param _address The address to check.
     * @return total The total locked deposits amount.
     */
    function getTotalLockedDepositAmount(address _address)
        public
        view
        returns (uint256 total)
    {
        uint256 len = lockedDeposits[_address].length;

        for (uint256 i = 0; i < len; i++) {
            Profile memory _lockedDeposit = lockedDeposits[_address][i];
            total += _lockedDeposit.btrstAmount;
        }

        return total;
    }

    /**
     * @notice Returns the total locked deposits for a given wallet.
     *  @notice NOTE: intented for off-chain.
     * @param _address The address to check.
     * @return nftTokenTokenIds The corresponding `nftTokenId`s.
     * @return btrstAmounts The corresponding `btrstAmount`s.
     * @return availableTimes The corresponding `available`s.
     */
    function getTotalLockedDepositByAddress(address _address)
        public
        view
        returns (
            uint256[] memory nftTokenTokenIds,
            uint256[] memory btrstAmounts,
            uint256[] memory availableTimes
        )
    {
        uint256 len = lockedDeposits[_address].length;
        nftTokenTokenIds = new uint256[](len);
        btrstAmounts = new uint256[](len);
        availableTimes = new uint256[](len);

        for (uint256 i = 0; i < len; i++) {
            Profile memory _lockedDeposit = lockedDeposits[_address][i];
            nftTokenTokenIds[i] = _lockedDeposit.nftTokenId;
            btrstAmounts[i] = _lockedDeposit.btrstAmount;
            availableTimes[i] = _lockedDeposit.available;
        }

        return (nftTokenTokenIds, btrstAmounts, availableTimes);
    }
}