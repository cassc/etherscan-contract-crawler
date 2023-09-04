// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IWETH9.sol";
import "./BaseVault.sol";

contract WETHVault is BaseVault {
    address payable public constant WETH = payable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

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

    constructor(address _bridge, bytes32 _assetId) {
        bridge = _bridge;
        _setAsset(_assetId, WETH);
    }

    fallback() external payable {}

    receive() external payable {}

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

        require(amount == msg.value, "Vault: value send doesn't match data");

        address tokenAddress = assetIdToTokenAddress[_assetId];
        require(tokenAllowlist[tokenAddress], "Vault: token is not in the allowlist");

        IWETH9(WETH).deposit{ value: amount }();

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

        bytes20 recipient;
        address tokenAddress = assetIdToTokenAddress[_assetId];

        // solhint-disable-next-line
        assembly {
            recipient := mload(add(destinationRecipientAddress, 0x20))
        }

        require(tokenAllowlist[tokenAddress], "Vault: token is not in the allowlist");

        IWETH9(WETH).withdraw(amount);
        payable(address(recipient)).transfer(amount);
    }
}