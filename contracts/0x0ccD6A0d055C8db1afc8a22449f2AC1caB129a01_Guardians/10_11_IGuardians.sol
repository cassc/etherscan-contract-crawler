// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./IERC11554K.sol";
import "./IERC11554KController.sol";
import "./IFeesManager.sol";

/**
 * @dev {IGuardians} interface:
 */
interface IGuardians {
    enum GuardianFeeRatePeriods {
        SECONDS,
        MINUTES,
        HOURS,
        DAYS
    }

    function controllerStoreItem(
        IERC11554K collection,
        address mintAddress,
        uint256 id,
        address guardian,
        uint256 guardianClassIndex,
        uint256 guardianFeeAmount,
        uint256 numItems,
        address feePayer,
        IERC20Upgradeable paymentAsset
    ) external;

    function controllerTakeItemOut(
        address guardian,
        IERC11554K collection,
        uint256 id,
        uint256 numItems,
        address from
    ) external;

    function shiftGuardianFeesOnTokenMove(
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) external;

    function setController(IERC11554KController controller_) external;

    function setFeesManager(IFeesManager feesManager_) external;

    function setMinStorageTime(uint256 minStorageTime_) external;

    function setMinimumRequestFee(uint256 minimumRequestFee_) external;

    function setMaximumGuardianFeeSet(uint256 maximumGuardianFeeSet_) external;

    function setGuardianFeeSetWindow(uint256 guardianFeeSetWindow_) external;

    function moveItems(
        IERC11554K collection,
        uint256[] calldata ids,
        address oldGuardian,
        address newGuardian,
        uint256[] calldata newGuardianClassIndeces
    ) external;

    function copyGuardianClasses(
        address oldGuardian,
        address newGuardian
    ) external;

    function setActivity(address guardian, bool activity) external;

    function setPrivacy(address guardian, bool privacy) external;

    function setLogo(address guardian, string calldata logo) external;

    function setName(address guardian, string calldata name) external;

    function setPhysicalAddressHash(
        address guardian,
        bytes32 physicalAddressHash
    ) external;

    function setPolicy(address guardian, string calldata policy) external;

    function setRedirect(address guardian, string calldata redirect) external;

    function changeWhitelistUsersStatus(
        address guardian,
        address[] calldata users,
        bool whitelistStatus
    ) external;

    function removeGuardian(address guardian) external;

    function setGuardianClassMintingFee(
        address guardian,
        uint256 classID,
        uint256 mintingFee
    ) external;

    function setGuardianClassRedemptionFee(
        address guardian,
        uint256 classID,
        uint256 redemptionFee
    ) external;

    function setGuardianClassGuardianFeeRate(
        address guardian,
        uint256 classID,
        uint256 guardianFeeRate
    ) external;

    function setGuardianClassGuardianFeePeriodAndRate(
        address guardian,
        uint256 classID,
        GuardianFeeRatePeriods guardianFeeRatePeriod,
        uint256 guardianFeeRate
    ) external;

    function setGuardianClassURI(
        address guardian,
        uint256 classID,
        string calldata uri
    ) external;

    function setGuardianClassActiveStatus(
        address guardian,
        uint256 classID,
        bool activeStatus
    ) external;

    function setGuardianClassMaximumCoverage(
        address guardian,
        uint256 classID,
        uint256 maximumCoverage
    ) external;

    function addGuardianClass(
        address guardian,
        uint256 maximumCoverage,
        uint256 mintingFee,
        uint256 redemptionFee,
        uint256 guardianFeeRate,
        GuardianFeeRatePeriods guardianFeeRatePeriod,
        string calldata uri
    ) external;

    function registerGuardian(
        address guardian,
        string calldata name,
        string calldata logo,
        string calldata policy,
        string calldata redirect,
        bytes32 physicalAddressHash,
        bool privacy
    ) external;

    function transferOwnership(address newOwner) external;

    function setVersion(bytes32 version_) external;

    function isAvailable(address guardian) external view returns (bool);

    function guardianInfo(
        address guardian
    )
        external
        view
        returns (
            bytes32,
            string memory,
            string memory,
            string memory,
            string memory,
            bool,
            bool
        );

    function guardianWhitelist(
        address guardian,
        address user
    ) external view returns (bool);

    function delegated(address guardian) external view returns (address);

    function getRedemptionFee(
        address guardian,
        uint256 classID
    ) external view returns (uint256);

    function getMintingFee(
        address guardian,
        uint256 classID
    ) external view returns (uint256);

    function isClassActive(
        address guardian,
        uint256 classID
    ) external view returns (bool);

    function minStorageTime() external view returns (uint256);

    function feesManager() external view returns (address);

    function stored(
        address guardian,
        IERC11554K collection,
        uint256 id
    ) external view returns (uint256);

    function whereItemStored(
        IERC11554K collection,
        uint256 id
    ) external view returns (address);

    function itemGuardianClass(
        IERC11554K collection,
        uint256 id
    ) external view returns (uint256);

    function guardianFeePaidUntil(
        address user,
        address collection,
        uint256 id
    ) external view returns (uint256);

    function isFeeAboveMinimum(
        uint256 guardianFeeAmount,
        uint256 numItems,
        address guardian,
        uint256 guardianClassIndex
    ) external view returns (bool);

    function getGuardianFeeRateByCollectionItem(
        IERC11554K collection,
        uint256 itemId
    ) external view returns (uint256);

    function getGuardianFeeRate(
        address guardian,
        uint256 guardianClassIndex
    ) external view returns (uint256);

    function isWhitelisted(address guardian) external view returns (bool);

    function inRepossession(
        address user,
        IERC11554K collection,
        uint256 id
    ) external view returns (uint256);

    function isDelegated(
        address guardian,
        address delegatee,
        IERC11554K collection
    ) external view returns (bool);
}