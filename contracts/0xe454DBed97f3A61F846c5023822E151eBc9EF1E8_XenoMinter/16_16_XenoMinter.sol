// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./interfaces/IXenoMinter.sol";
import "./interfaces/IXeno.sol";
import "./interfaces/ICouponClipper.sol";

import "./helpers/Errors.sol";
import "./helpers/Permissions.sol";

/**
 * @dev Xeno Mining - Xeno Minter contract
 * @notice Mint Xeno NFTs
 */
contract XenoMinter is IXenoMinter, Errors, AccessControl, ReentrancyGuard, Pausable {
    using ECDSA for bytes32;

    address private _withdrawal; // Dogface owned wallet, used for withdrawing ETHs

    uint16 public constant MAX_SUPPLY = 4018;

    IXeno public xeno_;
    ICouponClipper public couponClipper_;

    uint64[3] private _phasePrice = [
        200000000000000000, // PHASE 1: 0.2 ETH
        300000000000000000, // PHASE 2: 0.3 ETH
        500000000000000000 // PHASE 3: 0.5 ETH
    ];

    address[] private _paperWallets;

    uint256 private _presaleCount;
    uint256 private _presaleMaxAmount = 1000;

    bool private _presaleActive = false;
    bool private _generalSaleActive = false;
    bool private _allowListSaleActive = false;

    event Minted(address indexed to, uint256[] tokenId);
    event ContractUpgraded(uint256 timestamp, string indexed contractName, address oldAddress, address newAddress);
    event SignerUpdated(address indexed manager, address newSigner);
    event Withdraw(address indexed manager, address to, uint256 amount);

    constructor(
        address manager,
        address withdrawal,
        address xeno,
        address couponClipper
    ) {
        if (manager == address(0)) revert InvalidInput(INVALID_MANAGER);
        if (withdrawal == address(0)) revert InvalidInput(INVALID_WITHDRAWAL);
        if (xeno == address(0)) revert InvalidInput(WRONG_XENO_CONTRACT);
        if (couponClipper == address(0)) revert InvalidInput(INVALID_ADDRESS);

        _withdrawal = withdrawal;

        _grantRole(MANAGER_ROLE, manager);
        _grantRole(MULTISIG_ROLE, withdrawal);

        xeno_ = IXeno(xeno);
        couponClipper_ = ICouponClipper(couponClipper);

        if (!xeno_.supportsInterface(type(IXeno).interfaceId)) revert UpgradeError(WRONG_XENO_CONTRACT);
        if (!couponClipper_.supportsInterface(type(ICouponClipper).interfaceId)) revert UpgradeError(WRONG_COUPON_CLIPPER_CONTRACT);

        _pause();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(IERC165, AccessControl)
    returns (bool)
    {
        return
        interfaceId == type(IXenoMinter).interfaceId ||
        interfaceId == type(IERC165).interfaceId ||
        interfaceId == type(AccessControl).interfaceId || 
        super.supportsInterface(interfaceId);
    }

    /** ----------------------------------
     * ! Minting functions
     * ----------------------------------- */

    /**
     * @notice Minting a new Xeno token
     * @dev This function can only be called inside the contract
     * @param to to which address to mint a new token
     * @param count number of tokens to mint
     */
    function mint(
        address to,
        uint256 count
    ) external payable nonZeroAddress(to) whenNotPaused isSaleEnabled(_generalSaleActive) doesNotExceedSupply(count) returns (uint256[] memory){
        uint256 cost = this.calculatePrice(count);
        return _mint(to, count, cost);
    }

    /**
     * @notice Minting a new Xeno token using a coupon
     * @param to to which address to mint a new token
     * @param count number of tokens to mint
     * @param signature signature of the coupon
     * @param coupon coupon data
     */
    function couponMint(
        address to,
        uint256 count,
        Signature memory signature,
        bytes memory coupon
    ) external payable nonZeroAddress(to) whenNotPaused doesNotExceedPresaleSupply(count) returns (uint256[] memory){
        uint256 cost = couponClipper_.clipCoupon(to, count, signature, coupon);

        // If the mint is free then it is a presale
        if(cost == 0) {
            if(!_presaleActive) revert MintingError(MINTING_DISABLED);
            _presaleCount = _presaleCount + count;
        }

        return _mint(to, count, cost);
    }

    /**
     * @notice Minting a new Xeno token using an allow list coupon
     * @param to to which address to mint a new token
     * @param count number of tokens to mint
     * @param signature signature of the coupon
     * @param coupon coupon data
     */
    function allowListMint(
        address to,
        uint256 count,
        Signature memory signature,
        bytes memory coupon
    ) external payable nonZeroAddress(to) whenNotPaused isSaleEnabled(_allowListSaleActive) doesNotExceedSupply(count) returns (uint256[] memory){
        uint256 costCheck = couponClipper_.clipCoupon(to, count, signature, coupon);

        // Allow list coupons will have a cost of 10 ETH per token. Bit of a hack but it works.
        if(costCheck != count * 10000000000000000000) revert MintingError(ALLOW_LIST_COUPON_INVALID);

        uint256 cost = this.calculatePrice(count);

        return _mint(to, count, cost);
    }

    function paperMint(address _to, uint256 _quantity) isPaper external payable {
        uint256 cost = this.calculatePrice(_quantity);
        _mint(_to, _quantity, cost);
    }

    function checkGeneralSaleActive(uint256 quantity, uint256 value) external view whenNotPaused doesNotExceedSupply(quantity) isSaleEnabled(_generalSaleActive) returns (string memory) {
        uint256 cost = this.calculatePrice(quantity);
        if(value < cost) return "INSUFFICIENT_FUNDS";
        return "";
    }

    function checkAllowListSaleActive(uint256 quantity, uint256 value) external view whenNotPaused doesNotExceedSupply(quantity) isSaleEnabled(_allowListSaleActive) returns (string memory) {
        uint256 cost = this.calculatePrice(quantity);
        if(value < cost) return "INSUFFICIENT_FUNDS";
        return "";
    }

    /**
     * @notice Minting a new Xeno token using a coupon
     * @dev This function can only be called inside the contract
     * @param to to which address to mint a new token
     * @param count number of tokens to mint
     * @param cost calculated cost of the mint
     */
    function _mint(
        address to,
        uint256 count,
        uint256 cost
    ) internal returns (uint256[] memory) {
        if(msg.value < cost) revert PaymentError(INSUFFICIENT_FUNDS, msg.value, cost);
        return xeno_.safeMint(to, count);
    }

    /**
     * @notice Calculate the total price for the mint
     * @param count Number of tokens to mint
     */
    function calculatePrice(uint256 count) external view returns (uint256) {
        uint256 price = 0;
        uint256 totalSupply = xeno_.totalSupply();
        for (uint256 i = 0; i < count; i++) {
            if (totalSupply + i < 1003) {
                price += _phasePrice[0];
            } else if (totalSupply + i < 2000) {
                price += _phasePrice[1];
            } else if (totalSupply + i <= 4018) {
                price += _phasePrice[2];
            } else {
                revert MintingError(TOTAL_SUPPLY_EXCEEDED);
            }
        }
        return price;
    }

    /** ----------------------------------
     * ! Sales functions
     * ----------------------------------- */

    function setPhasePrices(uint64[3] calldata prices) external onlyRole(MANAGER_ROLE) {
        _phasePrice = prices;
    }

    function getPhasePrice(uint64 index) external view returns (uint64) {
        return _phasePrice[index];
    }

    function getPresaleCount() external view returns (uint256) {
        return _presaleCount;
    }

    function setPresaleAvailability(uint256 amount) external onlyRole(MANAGER_ROLE) {
        if(amount < _presaleCount || amount > MAX_SUPPLY) revert InvalidInput(INVALID_AMOUNT);
        _presaleMaxAmount = amount;
    }

    function setGeneralSaleActive(bool active) external onlyRole(MANAGER_ROLE) {
        _generalSaleActive = active;
    }

    function setPresaleActive(bool active) external onlyRole(MANAGER_ROLE) {
        _presaleActive = active;
    }

    function setAllowListSaleActive(bool active) external onlyRole(MANAGER_ROLE) {
        _allowListSaleActive = active;
    }

    function generalSaleActive() external view returns (bool) {
        return _generalSaleActive;
    }

    function presaleActive() external view returns (bool) {
        return _presaleActive;
    }

    function allowListSaleActive() external view returns (bool) {
        return _allowListSaleActive;
    }

    /** ----------------------------------
     * ! Manager functions      | UPGRADES
     * ----------------------------------- */

    /**
     * @notice Upgrade Xeno contract address
     * @dev This function can only be called from contracts or wallets with MANAGER_ROLE
     * @param newContract Address of the new contract
     */
    function upgradeXenoContract(address newContract) external onlyRole(MANAGER_ROLE) {
        if (newContract == address(0)) revert InvalidInput(INVALID_ADDRESS);

        address oldContract = address(xeno_);
        xeno_ = IXeno(newContract);
        if (!xeno_.supportsInterface(type(IXeno).interfaceId)) revert UpgradeError(WRONG_XENO_CONTRACT);

        emit ContractUpgraded(block.timestamp, "Xeno", oldContract, newContract);
    }

    /**
     * @notice Upgrade Coupon Clipper contract address
     * @dev This function can only be called from contracts or wallets with MANAGER_ROLE
     * @param newContract Address of the new contract
     */
    function upgradeCouponClipperContract(address newContract) external onlyRole(MANAGER_ROLE) {
        if (newContract == address(0)) revert InvalidInput(INVALID_ADDRESS);

        address oldContract = address(couponClipper_);
        couponClipper_ = ICouponClipper(newContract);
        if (!couponClipper_.supportsInterface(type(ICouponClipper).interfaceId)) revert UpgradeError(WRONG_COUPON_CLIPPER_CONTRACT);

        emit ContractUpgraded(block.timestamp, "CouponClipper", oldContract, newContract);
    }

    /** ----------------------------------
     * ! Admin functions
     * ----------------------------------- */

    /**
     * @notice Add a manager address (contract or wallet) to manage this contract
     * @dev This function can only to called from contracts or wallets with MANAGER_ROLE
     * @param newManager The new manager address to be granted
     */
    function addManager(address newManager) external onlyRole(MANAGER_ROLE) {
        if (newManager == address(0)) revert InvalidInput(INVALID_ADDRESS);
        _grantRole(MANAGER_ROLE, newManager);
    }

    /**
 * @notice Set manager address (contract or wallet) to manage this contract
     * @dev This function can only to called from contracts or wallets with MANAGER_ROLE
     * @param manager The manager address to be revoked, can not be the same as the caller
     */
    function removeManager(address manager) external onlyRole(MANAGER_ROLE) {
        if (manager == address(0)) revert InvalidInput(INVALID_ADDRESS);
        if (manager == msg.sender) revert ManagementError(CANT_REMOVE_SENDER);
        _revokeRole(MANAGER_ROLE, manager);
    }

    /**
     * @notice Set a new withdrawal address
     * @param _newWithdrawal The new withdrawal address
     */
    function setWithdrawalAddress(address _newWithdrawal) external onlyRole(MANAGER_ROLE) {
        if (_newWithdrawal == address(0)) revert InvalidInput(INVALID_ADDRESS);
        _withdrawal = _newWithdrawal;
    }

    /**
     * @notice get the withdrawal address
     */
    function getWithdrawalAddress() external view returns (address) {
        return _withdrawal;
    }

    /**
     * @notice Set paper wallet addresses for minting
     * @param addresses the paper wallet addresses array
     */
    function setPaperAddresses(address[] memory addresses) external onlyRole(MANAGER_ROLE) {
        _paperWallets = addresses;
    }

    /**
     * @notice Pause the minting process
     */
    function pause() external onlyRole(MANAGER_ROLE) {
        _pause();
    }

    /**
     * @notice Pause the minting process
     */
    function unpause() external onlyRole(MANAGER_ROLE) {
        _unpause();
    }

    /**
     * @notice Withdraw ETH from the contract to withdrawal address
     * @dev only MANAGER_ROLE can call this function
     * @param amount Token amount to withdraw
     */
    function withdrawEth(uint256 amount) external onlyRole(MANAGER_ROLE) {
        if (amount == 0) revert InvalidInput(INVALID_AMOUNT);
        (bool sent, ) = _withdrawal.call{value: amount}("");
        if (!sent) revert ManagementError(CANT_SEND);
    }

    /** ----------------------------------
     * ! Modifiers
     * ----------------------------------- */
    modifier nonZeroAddress(address addr) {
        if (addr == address(0)) revert InvalidInput(INVALID_ADDRESS);
        else _;
    }

    modifier doesNotExceedPresaleSupply(uint256 count) {
        if ((_presaleCount + count) > (_presaleMaxAmount)) revert MintingError(PRESALE_SUPPLY_EXCEEDED);
        else _;
    }

    modifier doesNotExceedSupply(uint256 count) {
        if ((xeno_.totalSupply() + count) > (MAX_SUPPLY - _presaleMaxAmount)) revert MintingError(TOTAL_SUPPLY_EXCEEDED);
        else _;
    }

    modifier isSaleEnabled(bool enabled) {
        if(!enabled) revert MintingError(MINTING_DISABLED);
        else _;
    }

    modifier isPaper() {
        bool valid = false;
        for (uint i=0; i < _paperWallets.length; i++) {
            if (msg.sender == _paperWallets[i]) {
                valid = true;
                break;
            }
        }
        if(!valid) revert MintingError(INVALID_MINTER_ADDRESS);
        else _;
    }
}