// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./BaseVault.sol";

contract ERC20DefaultVault is BaseVault {
    using SafeERC20 for ERC20Burnable;

    struct LockRecord {
        address tokenAddress;
        uint8 destinationChainId;
        bytes32 assetId;
        bytes destinationRecipientAddress;
        address user;
        uint256 amount;
    }

    // chain id => lock nonce => Lock Record
    mapping(uint8 => mapping(uint64 => LockRecord)) public lockRecords;

    constructor(
        address _bridge,
        bytes32[] memory _assetIds,
        address[] memory _tokenAddresses,
        address[] memory _burnListAddresses
    ) {
        uint256 assetIdsLength = _assetIds.length;
        uint256 burnListAddressesLength = _burnListAddresses.length;

        require(assetIdsLength == _tokenAddresses.length, "Vault: _assetIds and _tokenAddresses invalid length");

        bridge = _bridge;

        for (uint256 i = 0; i < assetIdsLength; i++) {
            _setAsset(_assetIds[i], _tokenAddresses[i]);
        }

        for (uint256 i = 0; i < burnListAddressesLength; i++) {
            _setBurnable(_burnListAddresses[i]);
        }
    }

    function getLockRecord(uint8 _destinationChainId, uint64 _depositCount) external view returns (LockRecord memory) {
        return lockRecords[_destinationChainId][_depositCount];
    }

    function lock(
        bytes32 _assetId,
        uint8 _destinationChainId,
        uint64 _depositCount,
        address _user,
        bytes calldata _data
    ) external payable override onlyBridge {
        bytes memory recipientAddress;

        (uint256 amount, uint256 recipientAddressLength) = abi.decode(_data, (uint256, uint256));
        recipientAddress = bytes(_data[64:64 + recipientAddressLength]);

        address tokenAddress = assetIdToTokenAddress[_assetId];
        require(tokenAllowlist[tokenAddress], "Vault: token is not in the allowlist");

        if (tokenBurnList[tokenAddress]) {
            // burn on destination chain
            ERC20Burnable(tokenAddress).burnFrom(_user, amount);
        } else {
            // lock on source chain
            ERC20Burnable(tokenAddress).safeTransferFrom(_user, address(this), amount);
        }

        lockRecords[_destinationChainId][_depositCount] = LockRecord(
            tokenAddress,
            _destinationChainId,
            _assetId,
            recipientAddress,
            _user,
            amount
        );
    }

    function execute(bytes32 _assetId, bytes calldata _data) external override onlyBridge {
        bytes memory destinationRecipientAddress;

        (uint256 amount, uint256 lenDestinationRecipientAddress) = abi.decode(_data, (uint256, uint256));
        destinationRecipientAddress = bytes(_data[64:64 + lenDestinationRecipientAddress]);

        bytes20 recipientAddress;
        address tokenAddress = assetIdToTokenAddress[_assetId];

        // solhint-disable-next-line
        assembly {
            recipientAddress := mload(add(destinationRecipientAddress, 0x20))
        }

        require(tokenAllowlist[tokenAddress], "Vault: token is not in the allowlist");

        if (tokenBurnList[tokenAddress]) {
            // mint on destination chain
            ERC20PresetMinterPauser(tokenAddress).mint(address(recipientAddress), amount);
        } else {
            // release on source chain
            ERC20Burnable(tokenAddress).safeTransfer(address(recipientAddress), amount);
        }
    }
}