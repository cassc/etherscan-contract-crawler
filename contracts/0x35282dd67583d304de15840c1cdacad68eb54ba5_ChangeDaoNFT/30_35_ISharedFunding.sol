// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../PaymentSplitter/PaymentSplitter.sol";
import "./IPaymentSplitter.sol";
import "./IChangeDaoNFT.sol";
import "./IFundingAllocations.sol";

/**
 * @title ISharedFunding
 * @author ChangeDao
 */
interface ISharedFunding {
    /* ============== Events ============== */

    /**
     * @notice Emitted when courtesy minting
     */
    event CourtesyMint(uint256 indexed tokenId, address indexed owner);

    /**
     * @notice Emitted when funding with ETH
     */
    event EthFunding(
        uint256 indexed fundingAmountInEth,
        uint256 indexed tipInEth,
        address indexed funder,
        uint256 fundingAmountInUsd,
        uint256 tipInUsd,
        uint256 refundInEth
    );

    /**
     * @notice Emitted when a new fundingPSClone is set
     */
    event NewFundingPSClone(PaymentSplitter indexed fundingPSClone);

    /**
     * @notice Emitted when setting max amount of mints in public period
     */
    event NewMaxMintAmountPublic(uint32 indexed maxMintAmountPublic);

    /**
     * @notice Emitted when setting max amount of mints in rainbow period
     */
    event NewMaxMintAmountRainbow(uint32 indexed maxMintAmountRainbow);

    /**
     * @notice Emitted when minting with fundPublic()
     */
    event PublicMint(
        uint256 indexed tokenId,
        address indexed owner,
        uint256 indexed mintPrice
    );

    /**
     * @notice Emitted when minting with fundRainbow()
     */
    event RainbowMint(
        uint256 indexed tokenId,
        address indexed owner,
        uint256 indexed mintPrice
    );

    /**
     * @notice Emitted when sharedFundingClone is initialized
     */
    event SharedFundingInitialized(
        ISharedFunding indexed sharedFundingClone,
        IChangeDaoNFT indexed changeDaoNFTClone,
        IFundingAllocations allocations,
        uint256 mintPrice,
        uint64 totalMints,
        uint32 maxMintAmountRainbow,
        uint32 maxMintAmountPublic,
        uint256 rainbowDuration,
        bytes32 rainbowMerkleRoot,
        PaymentSplitter fundingPSClone,
        address indexed changeMaker,
        uint256 deployTime
    );

    /**
     * @notice Emitted when funding type is DAI or USDC
     */
    event StablecoinFunding(
        IERC20 indexed token,
        uint256 indexed fundingAmountInUsd,
        uint256 indexed tipInUsd,
        address funder
    );

    /**
     * @notice Emitted when zero minting
     */
    event ZeroMint(uint256 indexed tokenId, address indexed owner);

    /* ============== State Variable Getter Functions ============== */

    function DAI_ADDRESS() external view returns (IERC20);

    function USDC_ADDRESS() external view returns (IERC20);

    function ETH_USD_DATAFEED() external view returns (address);

    function totalMints() external view returns (uint64);

    function mintPrice() external view returns (uint256);

    function deployTime() external view returns (uint256);

    function rainbowDuration() external view returns (uint256);

    function maxMintAmountRainbow() external view returns (uint32);

    function maxMintAmountPublic() external view returns (uint32);

    function changeMaker() external view returns (address);

    function hasZeroMinted() external view returns (bool);

    function rainbowMerkleRoot() external view returns (bytes32);

    function fundingPSClone() external view returns (PaymentSplitter);

    function changeDaoNFTClone() external view returns (IChangeDaoNFT);

    function allocations() external view returns (IFundingAllocations);

    /* ============== Receive ============== */

    receive() external payable;

    /* ============== Initialize ============== */

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
    ) external;

    /* ============== Mint Functions ============== */

    function zeroMint(address _recipient) external;

    function courtesyMint(address _recipient, uint256 _mintAmount) external;

    function fundRainbow(
        address _token,
        uint256 _tipInUsd,
        uint256 _mintAmount,
        bytes32[] memory _proof
    ) external payable;

    function fundPublic(
        address _token,
        uint256 _tipInUsd,
        uint256 _mintAmount
    ) external payable;

    /* ============== Conversion Function ============== */

    function convertUsdAmountToEth(uint256 _amountInUsd)
        external
        view
        returns (uint256);

    /* ============== Getter Functions ============== */

    function getRainbowExpiration() external view returns (uint256);

    function getMintedTokens() external view returns (uint256);

    /* ============== Pause Functions ============== */

    function pause() external;

    function unpause() external;
}