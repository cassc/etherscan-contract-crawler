// SPDX-License-Identifier: SPWPL
pragma solidity 0.8.15;

import "openzeppelin-solidity/contracts/proxy/Clones.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/security/Pausable.sol";

import "@opengsn/contracts/src/ERC2771Recipient.sol";
import "./RevenuePathV2.sol";

contract ReveelMainV2 is ERC2771Recipient, Ownable, Pausable {
    uint32 public constant BASE = 1e7;
    //@notice Fee percentage that will be applicable for additional tiers
    uint32 private platformFee;
    //@notice Address of platform wallet to collect fees
    address private platformWallet;

    //@notice The revenue path contract address who's bytecode will be used for cloning
    address private libraryAddress;

    /********************************
     *           EVENTS              *
     ********************************/
    /** @notice Emits when a new revenue path is created
     * @param path The address of the new revenue path
     * @param name The name of the revenue path
     */
    event RevenuePathCreated(RevenuePathV2 indexed path, string name);

    /** @notice Updates the libaray contract address
     * @param newLibrary The address of the library contract
     */
    event UpdatedLibraryAddress(address newLibrary);

    /** @notice Updates the platform fee percentage
     * @param newFeePercentage The new fee percentage
     */
    event UpdatedPlatformFee(uint32 newFeePercentage);

    /** @notice Updates the platform fee collecting wallet
     * @param newWallet The new fee collecting wallet
     */
    event UpdatedPlatformWallet(address newWallet);

    /********************************
     *           ERRORS              *
     ********************************/
    /** @dev Reverts when zero address is assigned
     */
    error ZeroAddressProvided();

    /**
     * @dev Reverts when platform fee out of bound i.e greater than BASE
     */

    error PlatformFeeNotAppropriate();

    /** @notice Intialize the Revenue main contract
     * @param _libraryAddress The revenue path contract address who's bytecode will be used for cloning
     * @param _platformFee The platform fee percentage
     * @param _platformWallet The platform fee collector wallet
     */

     /********************************
     *           FUNCTIONS              *
     ********************************/
    constructor(
        address _libraryAddress,
        uint32 _platformFee,
        address _platformWallet,
        address _forwarder
    ) {
        if (_libraryAddress == address(0) || _platformWallet == address(0)) {
            revert ZeroAddressProvided();
        }

        if (_platformFee > BASE) {
            revert PlatformFeeNotAppropriate();
        }
        libraryAddress = _libraryAddress;
        platformFee = _platformFee;
        platformWallet = _platformWallet;
        _setTrustedForwarder(_forwarder);
    }

    /** @notice Creating new revenue path
     *
     */
    function createRevenuePath(
        address[][] calldata _walletList,
        uint256[][] calldata _distribution,
        address[] memory _tokenList,
        uint256[][] memory _limitSequence,
        string memory _name,
        bool isImmutable
    ) external whenNotPaused {
        RevenuePathV2.PathInfo memory pathInfo;
        pathInfo.platformFee = platformFee;
        pathInfo.isImmutable = isImmutable;
        pathInfo.factory = address(this);
        pathInfo.forwarder = getTrustedForwarder();

        RevenuePathV2 path = RevenuePathV2(payable(Clones.clone(libraryAddress)));
        path.initialize(_walletList, _distribution, _tokenList, _limitSequence, pathInfo, _msgSender());
        emit RevenuePathCreated(path, _name);
    }

    /** @notice Sets the libaray contract address
     * @param _libraryAddress The address of the library contract
     */
    function setLibraryAddress(address _libraryAddress) external onlyOwner {
        if (_libraryAddress == address(0)) {
            revert ZeroAddressProvided();
        }
        libraryAddress = _libraryAddress;
        emit UpdatedLibraryAddress(libraryAddress);
    }

    /** @notice Set the platform fee percentage
     * @param newFeePercentage The new fee percentage
     */
    function setPlatformFee(uint32 newFeePercentage) external onlyOwner {
        if (newFeePercentage > BASE) {
            revert PlatformFeeNotAppropriate();
        }
        platformFee = newFeePercentage;
        emit UpdatedPlatformFee(platformFee);
    }

    /** @notice Set the platform fee collecting wallet
     * @param newWallet The new fee collecting wallet
     */
    function setPlatformWallet(address newWallet) external onlyOwner {
        if (newWallet == address(0)) {
            revert ZeroAddressProvided();
        }
        platformWallet = newWallet;
        emit UpdatedPlatformWallet(platformWallet);
    }

    /**
     * @notice Owner can toggle & pause contract
     * @dev emits relevant Pausable events
     */
    function toggleContractState() external onlyOwner {
        if (!paused()) {
            _pause();
        } else {
            _unpause();
        }
    }

    /** @notice Gets the libaray contract address
     */
    function getLibraryAddress() external view returns (address) {
        return libraryAddress;
    }

    /** @notice Gets the platform fee percentage
     */
    function getPlatformFee() external view returns (uint32) {
        return platformFee;
    }

    /** @notice Gets the platform fee percentage
     */
    function getPlatformWallet() external view returns (address) {
        return platformWallet;
    }

    function setTrustedForwarder(address forwarder) external onlyOwner {
        _setTrustedForwarder(forwarder);
    }

    /**
     * @notice Owner can not renounce ownership of this contract
     */
    function renounceOwnership() public virtual override onlyOwner {
        revert();
    }

    function _msgSender() internal view virtual override(Context, ERC2771Recipient) returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            assembly {
                ret := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    function _msgData() internal view virtual override(Context, ERC2771Recipient) returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }
}