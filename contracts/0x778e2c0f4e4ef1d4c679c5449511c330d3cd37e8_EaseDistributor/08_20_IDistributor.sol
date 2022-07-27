// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts-upgradeable/introspection/IERC165Upgradeable.sol";

interface IDistributor is IERC165Upgradeable {
    struct Cover {
        bytes32 coverType;
        uint256 productId;
        bytes32 contractName;
        uint256 coverAmount;
        uint256 premium;
        address currency;
        address contractAddress;
        uint256 expiration;
        uint256 status;
        address refAddress;
    }

    struct CoverQuote {
        uint256 prop1;
        uint256 prop2;
        uint256 prop3;
        uint256 prop4;
        uint256 prop5;
        uint256 prop6;
        uint256 prop7;
    }

    struct BuyInsuraceQuote {
        uint16[] products;
        uint16[] durationInDays;
        uint256[] amounts;
        address currency;
        uint256 premium;
        address owner;
        uint256 refCode;
        uint256[] helperParameters;
        uint256[] securityParameters;
        uint8[] v;
        bytes32[] r;
        bytes32[] s;
    }

    function getCoverCount(address _userAddr, bool _isActive)
        external
        view
        returns (uint256);

    function getCover(
        address _owner,
        uint256 _coverId,
        bool _isActive,
        uint256 _loopLimit
    ) external view returns (IDistributor.Cover memory);

    function getQuote(
        uint256 _sumAssured,
        uint256 _coverPeriod,
        address _contractAddress,
        address _coverAsset,
        address _nexusCoverable,
        bytes calldata _data
    ) external view returns (IDistributor.CoverQuote memory);
}