// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";

interface IPassport is IAccessControlUpgradeable {
    event BaseUriUpdated(string uri);
    event MaxSupplyLocked();
    event MaxSupplyUpdated(uint256 maxSupply);
    event PassportInitialized(
        address registryAddress,
        address passportAddress,
        string symbol,
        string name,
        bool transferEnabled,
        uint256 maxSupply
    );
    event TransferEnabledLocked();
    event TransferEnableUpdated(bool transferable);
    event Withdraw(uint256 value, address indexed withdrawnBy);
    event VersionLocked();

    function claim(uint256 _amount) external payable;

    function claimClaimlist(
        bytes32[] calldata proof,
        uint256 _maxAmount,
        uint256 _claimAmount
    ) external payable;

    function eject() external;

    function hasUpgraderRole(address _address) external view returns (bool);

    function initialize(
        address _creator,
        string memory _tokenName,
        string memory _tokenSymbol,
        bool _transferEnabled,
        uint256 _maxSupply
    ) external;

    function lockMaxSupply() external;

    function lockTransferEnabled() external;

    function lockVersion() external;

    function mintPassport(address to) external returns (uint256);

    function mintPassports(address[] memory _addresses) external;

    function passportVersion() external pure returns (uint256 version);

    function setBaseURI(string memory _uri) external;

    function setClaimEnabled(bool _claimStatus) external;

    function setClaimOptions(uint256 _claimFee, uint256 _claimAmount) external;

    function setMaxSupply(uint256 _maxSupply) external;

    function setOwnership(address newOwner) external;

    function setTransferEnabled(bool _transferEnabled) external;

    function setTrustedForwarder(address forwarder) external;

    function setClaimlistClaimEnabled(bool _claimStatus) external;

    function setClaimlistClaimFee(uint256 _claimFee) external;

    function setClaimlistOptions(uint256 _claimFee, bytes32 _claimlistRoot) external;

    function setClaimlistRoot(bytes32 _claimlistRoot) external;

    function upgradeTo(address newImplementation) external;

    function upgradeToAndCall(address newImplementation, bytes memory data) external payable;

    function claimlistClaimFee() external view returns (uint256);

    function claimlistRoot() external view returns (bytes32);

    function withdraw() external;
}