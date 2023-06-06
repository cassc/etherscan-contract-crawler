// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "../interfaces/ISharedFunding.sol";
import "../interfaces/IChainlinkOracle.sol";

/**
 * @title SharedFunding
 * @author ChangeDao
 * @dev Implementation contract for sharedFunding clones.
 */
contract SharedFunding is ISharedFunding, Context, Initializable, Pausable {
    /* ============== Libraries ============== */

    using SafeERC20 for IERC20;
    using Address for address payable;
    using Counters for Counters.Counter;

    /* ============== Clone State Variables ============== */

    bytes32 private constant _COURTESY_MINT = "COURTESY_MINT";
    bytes32 private constant _RAINBOW_MINT = "RAINBOW_MINT";
    bytes32 private constant _PUBLIC_MINT = "PUBLIC_MINT";
    address private constant _ETH_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    IERC20 public immutable override DAI_ADDRESS;
    IERC20 public immutable override USDC_ADDRESS;
    address public immutable override ETH_USD_DATAFEED;

    uint64 public override totalMints;
    uint256 public override mintPrice;
    uint256 public override deployTime;
    uint256 public override rainbowDuration;
    uint32 public override maxMintAmountRainbow;
    uint32 public override maxMintAmountPublic;
    address public override changeMaker;
    bool public override hasZeroMinted;
    bytes32 public override rainbowMerkleRoot;
    PaymentSplitter public override fundingPSClone;
    IChangeDaoNFT public override changeDaoNFTClone;
    IFundingAllocations public override allocations;
    Counters.Counter tokenId;

    /* ============== Modifier ============== */

    /**
     * @notice Access control is limited to the changeMaker
     */
    modifier onlyChangeMaker() {
        require(
            changeMaker == _msgSender(),
            "SF: Caller is not the changeMaker"
        );
        _;
    }

    /* ============== Receive ============== */

    /**
     * @notice Forward ETH to fundingPSClone
     */
    receive() external payable override {
        payable(address(fundingPSClone)).sendValue(msg.value);
    }

    /* ============== Constructor ============== */

    /**
     * @param _daiAddress DAI address
     * @param _usdcAddress USDC address
     * @param _ethUsdDatafeed Address of ETH-USD Chainlink data feed
     */
    constructor(
        IERC20 _daiAddress,
        IERC20 _usdcAddress,
        address _ethUsdDatafeed
    ) payable initializer {
        DAI_ADDRESS = _daiAddress;
        USDC_ADDRESS = _usdcAddress;
        ETH_USD_DATAFEED = _ethUsdDatafeed;
    }

    /* ============== Initialize ============== */

    /**
     * @notice A changemaker initializes a SharedFunding clone for a project
     * @param _changeDaoNFTClone changeDaoNFTClone that corresponds to a project
     * @param _allocations Contract that has address of ChangeDao wallet
     * @param _mintPrice Minimum amount of funding in USD required to mint an NFT
     * @param _totalMints Maximum number of NFTs to be minted
     * @param _maxMintAmountRainbow Max number of mints per transaction for rainbow addresses
     * @param _maxMintAmountPublic Max number of mints per transaction for public minting
     * @param _rainbowDuration Time period for rainbow addresses to fund
     * @param _rainbowMerkleRoot Hash of all rainbow recipient addresses
     * @param _fundingPSClone Funding PaymentSplitter clone
     * @param _changeMaker ChangeMaker with access control via onlyChangeMaker.
     * @param _isPaused Initial pause status
     */
    function initialize(
        IChangeDaoNFT _changeDaoNFTClone,
        IFundingAllocations _allocations,
        uint256 _mintPrice,
        uint64 _totalMints,
        uint32 _maxMintAmountRainbow,
        uint32 _maxMintAmountPublic,
        uint256 _rainbowDuration,
        bytes32 _rainbowMerkleRoot,
        PaymentSplitter _fundingPSClone,
        address _changeMaker,
        bool _isPaused
    ) external override initializer {
        changeDaoNFTClone = _changeDaoNFTClone;
        allocations = _allocations;
        mintPrice = _mintPrice;
        totalMints = _totalMints;
        _setMaxMintAmountRainbow(_maxMintAmountRainbow);
        _setMaxMintAmountPublic(_maxMintAmountPublic);
        rainbowDuration = _rainbowDuration;
        rainbowMerkleRoot = _rainbowMerkleRoot;
        _setFundingPSCloneAddress(_fundingPSClone);
        changeMaker = _changeMaker;
        deployTime = block.timestamp;

        if (_isPaused) {
            _pause();
        } 

        emit SharedFundingInitialized(
            ISharedFunding(this),
            _changeDaoNFTClone,
            _allocations,
            _mintPrice,
            _totalMints,
            _maxMintAmountRainbow,
            _maxMintAmountPublic,
            _rainbowDuration,
            _rainbowMerkleRoot,
            _fundingPSClone,
            changeMaker,
            deployTime
        );
    }

    /* ============== Mint Functions ============== */

    /**
     * @notice The changemaker can mint a "zero" token id
     * @param _recipient The address that will be the owner of the token
     */
    function zeroMint(address _recipient)
        public
        override
        onlyChangeMaker
    {
        require(!hasZeroMinted, "SF: Zero token has already been minted");
        hasZeroMinted = true;

        changeDaoNFTClone.mint(0, _recipient);
        emit ZeroMint(0, _recipient);
    }

    /**
     * @notice The changemaker can mint tokens to an address without a fee
     * @param _recipient The address that will be the owner of the token
     * @param _mintAmount The number of mints being created
     */
    function courtesyMint(address _recipient, uint256 _mintAmount)
        public
        override
        onlyChangeMaker
        whenNotPaused
    {
        require(
            _mintAmount > 0 && _mintAmount <= 20,
            "SF: Mint amount not greater than 0 or less than or equal to 20"
        );

        for (uint i; i < _mintAmount; i++) {
            _mintNFT(_recipient, _COURTESY_MINT);
        }
    }

    /**
     * @notice Rainbow addresses fund a project
     * @param _token ETH, DAI or USDC
     * @param _tipInUsd Input as amount * 10**18
     * @param _mintAmount Number of mints in one function call
     * @param _proof Merkle proof to verify a rainbow address
     */
    function fundRainbow(
        address _token,
        uint256 _tipInUsd,
        uint256 _mintAmount,
        bytes32[] memory _proof
    ) external payable override whenNotPaused {
        require(
            block.timestamp <= deployTime + rainbowDuration,
            "SF: Rainbow duration has expired"
        );
        require(
            _verify(_createLeaf(_msgSender()), _proof),
            "SF: Invalid Merkle proof"
        );
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountRainbow,
            "SF: Mint amount not > 0 or <= maxMintAmountRainbow"
        );

        uint256 fundingAmountInUsd = mintPrice * _mintAmount;
        _fund(
            _token,
            _tipInUsd,
            _mintAmount,
            fundingAmountInUsd,
            _RAINBOW_MINT
        );
    }

    /**
     * @notice Public sponsors fund a project
     * @param _token ETH, DAI or USDC
     * @param _tipInUsd Input as amount * 10**18
     * @param _mintAmount Number of mints in one function call
     */
    function fundPublic(
        address _token,
        uint256 _tipInUsd,
        uint256 _mintAmount
    ) external payable override whenNotPaused {
        require(
            block.timestamp > deployTime + rainbowDuration,
            "SF: Public minting not started"
        );
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPublic,
            "SF: Mint amount not > 0 or <= maxMintAmountPublic"
        );

        uint256 fundingAmountInUsd = mintPrice * _mintAmount;
        _fund(_token, _tipInUsd, _mintAmount, fundingAmountInUsd, _PUBLIC_MINT);
    }

    /* ============== Internal Mint Functions ============== */

    /**
     * @dev Handles funding based on type; calls mint function based on mint amount
     * @param _token ETH, DAI OR USDC
     * @param _tipInUsd Tip amount in USD, 10**18
     * @param _mintAmount Number of mints
     * @param _fundingAmountInUsd Number of mints * mint price
     * @param _mintType _RAINBOW_MINT or _PUBLIC_MINT
     */
    function _fund(
        address _token,
        uint256 _tipInUsd,
        uint256 _mintAmount,
        uint256 _fundingAmountInUsd,
        bytes32 _mintType
    ) internal {
        /// Route funding by its type
        if (_token == _ETH_ADDRESS) {
            _handleEthFunding(_fundingAmountInUsd, _tipInUsd);
        } else if (
            IERC20(_token) == DAI_ADDRESS || IERC20(_token) == USDC_ADDRESS
        ) {
            _handleStablecoinFunding(
                IERC20(_token),
                _fundingAmountInUsd,
                _tipInUsd
            );
        } else revert("SF: Token type not supported");

        /// Mint
        for (uint256 i; i < _mintAmount; i++) {
            _mintNFT(_msgSender(), _mintType);
        }
    }

    /**
     * @dev Processes ETH value to determine funding amount, tip and refund
     * @param _fundingAmountInUsd Number of mints * mint price
     * @param _tipInUsd Tip amount in USD
     */
    function _handleEthFunding(uint256 _fundingAmountInUsd, uint256 _tipInUsd)
        internal
    {
        // Check that msg.value is greater than sum of funding and tip
        uint256 fundingAndTipSum = _fundingAmountInUsd + _tipInUsd;
        require(
            msg.value >= convertUsdAmountToEth(fundingAndTipSum),
            "SF: Insufficient ETH"
        );

        uint256 fundingAmountInEth = convertUsdAmountToEth(_fundingAmountInUsd);
        uint256 tipInEth = convertUsdAmountToEth(_tipInUsd);
        uint256 refundInEth = msg.value - fundingAmountInEth - tipInEth;
        // Refund excess ETH to funder
        if (refundInEth > 0) {
            payable(address(_msgSender())).sendValue(refundInEth);
        }
        // Transfer tip to ChangeDao
        if (tipInEth > 0) {
            address payable changeDaoWallet = allocations.changeDaoWallet();
            changeDaoWallet.sendValue(tipInEth);
        }
        // Transfer funding to fundingPSClone
        payable(address(fundingPSClone)).sendValue(fundingAmountInEth);

        emit EthFunding(
            fundingAmountInEth,
            tipInEth,
            _msgSender(),
            _fundingAmountInUsd,
            _tipInUsd,
            refundInEth
        );
    }

    /**
     * @dev Processes DAI and USDC values to determine funding amount and tip
     * @param _token DAI or USDC
     * @param _fundingAmountInUsd Number of mints * mint price
     * @param _tipInUsd Tip amount in USD
     */
    function _handleStablecoinFunding(
        IERC20 _token,
        uint256 _fundingAmountInUsd,
        uint256 _tipInUsd
    ) internal {
        uint256 originalFundingAmountInUsd = _fundingAmountInUsd;
        uint256 originalTipInUsd = _tipInUsd;
        if (_token == USDC_ADDRESS) {
            _fundingAmountInUsd = _fundingAmountInUsd / 10**12;
            _tipInUsd = _tipInUsd / 10**12;
        }
        // Transfer the funding amount to the fundingPSClone
        _token.safeTransferFrom(
            _msgSender(),
            address(fundingPSClone),
            _fundingAmountInUsd
        );
        // Transfer the tip to ChangeDao
        if (_tipInUsd > 0) {
            address payable changeDaoWallet = allocations.changeDaoWallet();
            _token.safeTransferFrom(_msgSender(), changeDaoWallet, _tipInUsd);
        }

        emit StablecoinFunding(
            _token,
            originalFundingAmountInUsd,
            originalTipInUsd,
            _msgSender()
        );
    }

    /**
     * @dev Increments token id counter and calls mint() on changeDaoNFTClone
     * @param _owner Address that will own the minted token id
     * @param _mintType COURTESY, RAINBOW or PUBLIC
     */
    function _mintNFT(address _owner, bytes32 _mintType) internal {
        tokenId.increment();
        // Check that there are still project NFTs remaining to be minted
        require(
            totalMints >= tokenId.current(),
            "SF: All NFTs have already been minted"
        );

        changeDaoNFTClone.mint(tokenId.current(), _owner);

        if (_mintType == _COURTESY_MINT) {
            emit CourtesyMint(tokenId.current(), _owner);
        } else if (_mintType == _RAINBOW_MINT) {
            emit RainbowMint(tokenId.current(), _owner, mintPrice);
        } else if (_mintType == _PUBLIC_MINT) {
            emit PublicMint(tokenId.current(), _owner, mintPrice);
        }
    }

    /* ============== Conversion Function ============== */

    /**
     * @dev Calls Chainlink data feed to return a USD value to ETH
     * @param _amountInUsd Amount in USD
     */
    function convertUsdAmountToEth(uint256 _amountInUsd)
        public
        view
        virtual
        override
        returns (uint256)
    {
        (, int256 eth_to_usd, , , ) = IChainlinkOracle(ETH_USD_DATAFEED)
            .latestRoundData();
        uint256 convertedEth_to_usd = uint256(eth_to_usd) * 10**10; // convert to 18 decimals
        return (_amountInUsd * 10**18) / convertedEth_to_usd;
    }

    /* ============== Getter Functions ============== */

    /**
     * @notice Returns the expiration of the rainbow period
     */
    function getRainbowExpiration() public view override returns (uint256) {
        return deployTime + rainbowDuration;
    }

    /**
     * @notice Returns the latest token id, which represents the total number of tokens already minted
     */
    function getMintedTokens() public view override returns (uint256) {
        return tokenId.current();
    }

    /* ============== Internal Setter Functions ============== */

      /**
     * @dev Internal function that sets fundingPSClone address.
     * @dev Called when sharedFundingClone is initialized
     * @dev _fundingPSClone is of type PaymentSplitter, not IPaymentSplitter.  This is because in Controller.callSharedFundingFactory(), it is possible to enter a variable for the fundingPSClone that is a malicious implementation using IPaymentSplitter.  By using the type PaymentSplitter, it forces the fundingPSClone to be a clone of ChangeDao's PaymentSplitter implementation contract.
     * @param _fundingPSClone New fundingPSClone address
     */
    function _setFundingPSCloneAddress(PaymentSplitter _fundingPSClone)
        internal
    {
        // Check that ChangeDao wallet is 1) included among recipients and 2) has correct shares
        address payable changeDaoWallet = allocations.changeDaoWallet();
        bool includesChangeDaoWallet;

        for (uint256 i; i < _fundingPSClone.payeesLength(); i++) {
            if (_fundingPSClone.getPayee(i) == changeDaoWallet) {
                require(
                    _fundingPSClone.shares(changeDaoWallet) ==
                        allocations.changeDaoFunding(),
                    "SF: ChangeDao funding shares incorrect"
                );
                includesChangeDaoWallet = true;
            }
        }
        require(
            includesChangeDaoWallet,
            "SF: ChangeDao not a funding recipient"
        );
        fundingPSClone = _fundingPSClone;
        emit NewFundingPSClone(_fundingPSClone);
    }

    /**
     * @dev Internal function
     * @dev Sets maxMintAmountRainbow upon clone initialization
     * @param _maxMintAmountRainbow Max number of mints in rainbow period per transaction
     */
    function _setMaxMintAmountRainbow(uint32 _maxMintAmountRainbow)
        internal
    {
        require(
            _maxMintAmountRainbow > 0 && _maxMintAmountRainbow <= 20,
            "SF: Cannot mint less than one or more than 20 tokens"
        );
        maxMintAmountRainbow = _maxMintAmountRainbow;
        emit NewMaxMintAmountRainbow(_maxMintAmountRainbow);
    }

    /**
     * @dev Internal function
     * @dev Sets maxMintAmountPublic upon clone initialization
     * @param _maxMintAmountPublic Max number of public mints per transaction
     */
    function _setMaxMintAmountPublic(uint32 _maxMintAmountPublic)
        internal
    {
        require(
            _maxMintAmountPublic > 0 && _maxMintAmountPublic <= 20,
            "SF: Cannot mint less than one or more than 20 tokens"
        );

        maxMintAmountPublic = _maxMintAmountPublic;
        emit NewMaxMintAmountPublic(_maxMintAmountPublic);
    }

    /* ============== Pause Functions ============== */

    /**
     * @notice Suspends all use of the platform
     */
    function pause() public override onlyChangeMaker {
        _pause();
    }

    /**
     * @notice Resumes possiblity for using the platform
     */
    function unpause() public override onlyChangeMaker {
        _unpause();
    }

    /* ============== Internal Merkle Functions ============== */

    /**
     * @notice Generates a hash of a recipient's address
     * @param _recipientAddress Recipient address
     */
    function _createLeaf(address _recipientAddress)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_recipientAddress));
    }

    /**
     * @notice Verify whether a recipient's address is part of an array used in the merkle proof
     * @param _leaf Hash of a recipient's address
     * @param _proof Array of elements needed to verify if the leaf is valid
     */
    function _verify(bytes32 _leaf, bytes32[] memory _proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(_proof, rainbowMerkleRoot, _leaf);
    }
}