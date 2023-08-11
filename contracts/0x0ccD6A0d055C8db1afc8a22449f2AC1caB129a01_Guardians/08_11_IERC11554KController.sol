// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./IERC11554K.sol";
import "./IGuardians.sol";

/**
 * @dev {IERC11554KController} interface:
 */
interface IERC11554KController {
    /// @dev Batch minting request data structure.
    struct BatchRequestMintData {
        /// @dev Collection address.
        IERC11554K collection;
        /// @dev Item id.
        uint256 id;
        /// @dev Guardian address.
        address guardianAddress;
        /// @dev Amount to mint.
        uint256 amount;
        /// @dev Service fee to guardian.
        uint256 serviceFee;
        /// @dev Is item supply expandable.
        bool isExpandable;
        /// @dev Recipient address.
        address mintAddress;
        /// @dev Guardian class index.
        uint256 guardianClassIndex;
        /// @dev Guardian fee amount to pay.
        uint256 guardianFeeAmount;
    }

    function requestMint(
        IERC11554K collection,
        uint256 id,
        address guardian,
        uint256 amount,
        uint256 serviceFee,
        bool expandable,
        address mintAddress,
        uint256 guardianClassIndex,
        uint256 guardianFeeAmount
    ) external returns (uint256);

    function mint(IERC11554K collection, uint256 id) external;

    function owner() external returns (address);

    function originators(
        address collection,
        uint256 tokenId
    ) external returns (address);

    function isActiveCollection(address collection) external returns (bool);

    function isLinkedCollection(address collection) external returns (bool);

    function paymentToken() external returns (IERC20Upgradeable);

    function maxMintPeriod() external returns (uint256);

    function remediationBurn(
        IERC11554K collection,
        address owner,
        uint256 id,
        uint256 amount
    ) external;

    function setMaxMintPeriod(uint256 maxMintPeriod_) external;

    function setRemediator(address _remediator) external;

    function setCollectionFee(uint256 collectionFee_) external;

    function setBeneficiary(address beneficiary_) external;

    function setGuardians(IGuardians guardians_) external;

    function setPaymentToken(IERC20Upgradeable paymentToken_) external;

    function transferOwnership(address newOwner) external;

    function setVersion(bytes32 version_) external;

    function guardians() external view returns (address);
}