// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "../../interfaces/aave/IAaveLendingPoolV2.sol";
import "../../interfaces/IReinvestment.sol";
import "../../libraries/math/MathUtils.sol";

contract AaveReinvestmentLogic is Initializable, Ownable, IERC165, IReinvestmentLogic {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using MathUtils for uint256;

    uint256 public constant VERSION = 1;

    bytes32 internal constant ASSET = 0x0bd4060688a1800ae986e4840aebc924bb40b5bf44de4583df2257220b54b77c; // keccak256(abi.encodePacked("asset"))
    bytes32 internal constant TREASURY = 0xcbd818ad4dd6f1ff9338c2bb62480241424dd9a65f9f3284101a01cd099ad8ac; // keccak256(abi.encodePacked("treasury"))
    bytes32 internal constant LEDGER = 0x2c0e8db8fb1343f00f1c6b57af1cf6bf785c6b487e5c99ae90a4e98907f27011; // keccak256(abi.encodePacked("ledger"))
    bytes32 internal constant FEE_MANTISSA = 0xb438cbc7dd7438566e91798623a0acb324f70180fcab8f4a7f87eec183969271; // keccak256(abi.encodePacked("feeMantissa"))
    bytes32 internal constant RECEIPT = 0x8ad7c532f0538a191f1e436b6ca6710d0a78a349291c8b8f31962a26fb22e7e8; // keccak256(abi.encodePacked("receipt"))
    bytes32 internal constant PLATFORM = 0x3cb058642d3f17bc460bdd6eab42c21564f6b5228beab6a905a2eb32727c49d1; // keccak256(abi.encodePacked("platform"))

    // ====================== STORAGE ======================

    mapping(bytes32 => uint256) internal uintStorage;
    mapping(bytes32 => address) internal addressStorage;
    mapping(bytes32 => bytes) internal bytesStorage;
    mapping(bytes32 => bool) internal boolStorage;

    // ====================== STORAGE ======================

    function initialize(
        address asset_,
        address receipt_,
        address platform_,
        address[] memory,
        address treasury_,
        address ledger_,
        uint256,
        bytes memory
    ) external initializer onlyOwner {
        addressStorage[ASSET] = asset_;
        addressStorage[TREASURY] = treasury_;
        addressStorage[LEDGER] = ledger_;
        // Fees does not applied to this type of reinvestment (auto-accruing reward).
        uintStorage[FEE_MANTISSA] = 0;

        addressStorage[RECEIPT] = receipt_;
        addressStorage[PLATFORM] = platform_;
    }

    function setTreasury(address treasury_) external override onlyOwner {
        emit UpdatedTreasury(treasury(), treasury_);
        addressStorage[TREASURY] = treasury_;
    }

    function setFeeMantissa(uint256) external view override onlyOwner {
        revert('Not applicable');
    }

    /**
     * @notice Investing
     * @param amount Amount
    */
    function invest(uint256 amount) external override onlyLedger {

        IERC20Upgradeable(asset()).safeTransferFrom(msg.sender, address(this), amount);

        require(IERC20Upgradeable(asset()).balanceOf(address(this)) >= amount, "not enough underlying");

        IERC20Upgradeable(asset()).safeApprove(platform(), 0);
        IERC20Upgradeable(asset()).safeApprove(platform(), amount);
        IAaveLendingPoolV2(platform()).deposit(asset(), amount, address(this), 0);
    }

    /**
     * @notice Divesting
     * @param amount Amount
    */
    function divest(uint256 amount) external override onlyLedger {
        IAaveLendingPoolV2(platform()).withdraw(asset(), amount, msg.sender);
    }

    /**
     * @notice Supply Totality
     * @return totalSupply
    */
    function totalSupply() public view override returns (uint256) {
        return poolAmount();
    }

    /**
     * @notice Pool total amount
     * @return pool amount
    */
    function poolAmount() public view returns (uint256) {
        return IERC20Upgradeable(receipt()).balanceOf(address(this));
    }

    function asset() public view override returns (address) {
        return addressStorage[ASSET];
    }

    function treasury() public view override returns (address) {
        return addressStorage[TREASURY];
    }

    function ledger() public view override returns (address) {
        return addressStorage[LEDGER];
    }

    function feeMantissa() public view override returns (uint256) {
        return uintStorage[FEE_MANTISSA];
    }

    /**
     * @notice Reinvestment Address
     * @return reinvestment address
    */
    function platform() public view override returns (address) {
        return addressStorage[PLATFORM];
    }

    /**
     * @notice Receipt Address
    */
    function receipt() public view override returns (address) {
        return addressStorage[RECEIPT];
    }

    /**
     * @notice supports Interface
     * @param interfaceId bytes data
     * @return interfaceId
    */
    function supportsInterface(bytes4 interfaceId) public pure virtual override returns (bool) {
        return interfaceId == type(IReinvestmentLogic).interfaceId;
    }

    /**
     * @notice Emergency divesting of investment funds
     * @return amount of investment
    */
    function emergencyWithdraw() external override onlyLedger returns (uint256) {
        return IAaveLendingPoolV2(platform()).withdraw(asset(), type(uint256).max, msg.sender);
    }

    /**
     * @notice Transferring to treasury
     * @param otherAsset Address
    */
    function sweep(address otherAsset) external override onlyTreasury {
        require(otherAsset != asset(), "cannot sweep registered asset");
        IERC20Upgradeable(otherAsset).safeTransfer(treasury(), IERC20Upgradeable(otherAsset).balanceOf(address(this)));
    }

    /// @dev Not applicable, default 0
    function rewardLength() external pure override returns (uint256){
        return 0;
    }

    /**
     * @dev Not applicable
     * @return rewards data
    */
    function rewardOf(address, uint256) external pure override returns (Reward[] memory) {
        Reward[] memory rewards;
        return rewards;
    }

    /// @dev Not applicable
    function claim(address, uint256) external pure override {
        return;
    }

    /// @dev Not applicable
    function checkpoint(address, uint256) external pure override {
        return;
    }

    modifier onlyLedger() {
        require(ledger() == msg.sender, "only ledger");
        _;
    }

    modifier onlyTreasury() {
        require(treasury() == msg.sender, "only treasury");
        _;
    }
}