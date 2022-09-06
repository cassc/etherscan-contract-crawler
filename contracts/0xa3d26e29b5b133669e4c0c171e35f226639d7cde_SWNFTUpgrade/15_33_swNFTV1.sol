//SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";

import "./interfaces/ISWNFT.sol";

interface IDepositContract {
    /// @notice Submit a Phase 0 DepositData object.
    /// @param pubKey A BLS12-381 public key.
    /// @param withdrawalCredentials Commitment to a public key for withdrawals.
    /// @param signature A BLS12-381 signature.
    /// @param depositDataRoot The SHA-256 hash of the SSZ-encoded DepositData object.
    /// Used as a protection against malformed input.
    function deposit(
        bytes calldata pubKey,
        bytes calldata withdrawalCredentials,
        bytes calldata signature,
        bytes32 depositDataRoot
    ) external payable;
}

abstract contract swNFTV1 is
    ERC721EnumerableUpgradeable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ISWNFT
{
    uint256 public GWEI; // Not used

    using CountersUpgradeable for CountersUpgradeable.Counter;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    CountersUpgradeable.Counter public tokenIds;
    address public swETHAddress;
    string constant swETHSymbol = "swETH";
    string constant swNFTName = "Swell NFT";
    string constant swNFTSymbol = "swNFT";
    string public swETHSymbolOld; // Not used
    address public swellAddress;
    uint256 public ETHER; // Not used
    address public feePool;
    uint256 public fee;
    IDepositContract public depositContract;
    bytes[] public validators;
    mapping(bytes => uint256) public validatorDeposits;
    mapping(bytes => bool) public whiteList;
    /// @dev The token ID position data
    mapping(uint256 => Position) public positions;
    address[] public deprecatedStrategies; // deprecated
    mapping(bytes => uint256) public opRate;
    address public botAddress;
    mapping(bytes => bool) public isValidatorActive;
    EnumerableSetUpgradeable.AddressSet private strategiesSet; // ??
    mapping(bytes => bool) public superWhiteList;

    /// @notice Add a new strategy
    /// @param strategy The strategy address to add
    function _addStrategy(address strategy) internal returns (bool added) {
        require(strategy != address(0), "InvalidAddress");
        added = strategiesSet.add(strategy);
        if (added) {
            emit LogAddStrategy(strategy);
        }
    }

    /// @notice Remove a strategy
    /// @param strategy The strategy address to remove
    function _removeStrategy(address strategy) internal returns (bool removed) {
        removed = strategiesSet.remove(strategy);
        if (removed) {
            emit LogRemoveStrategy(strategy);
        }
    }

    function _checkStrategy(address strategy) internal view {
        require(strategiesSet.contains(strategy), "Inv strategy");
    }

    function _getNumberOfStrategies() internal view returns (uint256 length) {
        return strategiesSet.length();
    }

    function _checkStrategyIndex(uint256 strategyIndex) internal view {
        require(strategyIndex < strategiesSet.length(), "Index out");
    }

    function _getStrategyIndex(uint256 strategyIndex)
        internal
        view
        returns (address strategy)
    {
        return strategiesSet.at(strategyIndex);
    }

    function _getAllStrategies() internal view returns (address[] memory) {
        return strategiesSet.values();
    }
}