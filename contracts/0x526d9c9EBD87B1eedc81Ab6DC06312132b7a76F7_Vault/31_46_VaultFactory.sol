// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {IVaultFactory} from "../interfaces/IVaultFactory.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title Vault Factory
 * @author Immunefi
 * @notice Vault factories deploy min beacon proxies and act as the beacon
 */
contract VaultFactory is UpgradeableBeacon, IVaultFactory {
    using Address for address;

    address public feeTo;
    address private _pendingFeeTo;
    uint256 public fee;
    uint256 public constant FEE_BASIS = 100_00;
    bytes21 private immutable _create2Prefix;

    // These vars form an empty bytes array (0x40 0x0) to pass into constructor of beacon proxy
    bytes32 private constant _BYTES_ARR_0 = bytes32(uint256(64));
    bytes32 private constant _BYTES_ARR_1 = bytes32(0);

    event Deployed(address _proxy, address _sender, bytes32 _salt);
    event FeeToPending(address prevFeeTo, address newFeeTo);
    event FeeToTransferred(address prevFeeTo, address newFeeTo);
    event FeeChanged(uint256 prevFee, uint256 newFee);

    constructor(address _owner, address _implementation) UpgradeableBeacon(_implementation) {
        _create2Prefix = bytes21(uint168((0xff << 160) | uint256(uint160(address(this)))));
        _transferOwnership(_owner);
        feeTo = _owner;
        fee = 10_00;
        emit FeeToTransferred(address(0), feeTo);
        emit FeeChanged(0, fee);
    }

    /**
     * @notice reverts if called by any account other than the pending feeTo
     */
    modifier onlyPendingFeeReceiver() {
        require(_msgSender() == _pendingFeeTo, "VaultFactory: not pending fee receiver");
        _;
    }

    /**
     * @notice reverts if called by any account other than the feeTo
     */
    modifier onlyFeeReceiver() {
        require(_msgSender() == feeTo, "VaultFactory: not fee receiver");
        _;
    }

    /**
     * @notice sets pending feeTo
     * @param newFeeTo address of pending fee owner
     */
    function _setPendingFeeTo(address newFeeTo) private {
        emit FeeToPending(feeTo, newFeeTo);
        _pendingFeeTo = newFeeTo;
    }

    /**
     * @notice hand over feeTo privilege. new feeTo must accept role
     * @dev only callable by current feeTo
     * @param newFeeTo address of new fee owner
     */
    function transferFeeTo(address newFeeTo) public onlyFeeReceiver {
        _setPendingFeeTo(newFeeTo);
    }

    /**
     * @notice accepts role of feeTo
     */
    function acceptFeeTo() public onlyPendingFeeReceiver {
        emit FeeToTransferred(feeTo, _msgSender());
        feeTo = _msgSender();
    }

    /**
     * @notice rejects role of feeTo
     */
    function rejectFeeTo() public onlyPendingFeeReceiver {
        _setPendingFeeTo(address(0));
    }

    /**
     * @notice set fee
     * @dev only callable by current feeTo
     * @param newFee value of the new fee. Must be less than FEE_BASIS
     */
    function setFee(uint256 newFee) public onlyFeeReceiver {
        emit FeeChanged(fee, newFee);

        require(newFee <= FEE_BASIS, "VaultFactory: newFee must be below 100_00");

        fee = newFee;
    }

    /**
     * @notice Deploy a new beacon proxy.
     * @dev Deriving actual salt from msg.sender guards against griefing by frontrunning
     * @param owner Owner of the newly deployed vault
     * @param optionalData The encdoded function data and parameters of the intializer
     * @param salt The salt used for deployment
     */
    function deploy(
        address owner,
        bytes calldata optionalData,
        bytes32 salt
    ) external payable returns (address proxy, bytes memory returnData) {
        address msgSender = _msgSender();
        // constructor takes in address + bytes array
        bytes memory bytecode = bytes.concat(
            type(BeaconProxy).creationCode,
            bytes32(uint256(uint160(address(this)))),
            _BYTES_ARR_0,
            _BYTES_ARR_1
        );
        bytes32 proxySalt = keccak256(abi.encodePacked(msgSender, salt));
        {
            assembly ("memory-safe") {
                proxy := create2(0, add(bytecode, 0x20), mload(bytecode), proxySalt)
            }
        }

        // Rolling the initialization into the construction of the proxy is either
        // very expensive (if the initializer has to be saved to storage and then
        // retrived by the initializer by a callback) (>200 gas per word as of
        // EIP-2929/Berlin) or creates dependence of the deployed address on the
        // contents of the initializer (if it's supplied as part of the
        // initcode). Therefore, we elect to send the initializer as part of a call
        // to the proxy AFTER deployment.
        returnData = proxy.functionCallWithValue(
            abi.encodeWithSignature("initialize(address,bytes)", owner, optionalData),
            msg.value,
            "BeaconCache: initialize failed"
        );

        emit Deployed(proxy, msgSender, salt);
    }

    /**
     * @notice Compute the create2 deterministic address given a deployer and a salt
     * @param deployer The address calling the deploy function
     * @param salt The salt provided by deployer
     * @return address create2 deterministic computed address
     */
    function predict(address deployer, bytes32 salt) external view returns (address) {
        bytes32 proxySalt = keccak256(abi.encodePacked(deployer, salt));
        // constructor takes in address + bytes array
        bytes memory bytecode = bytes.concat(
            type(BeaconProxy).creationCode,
            bytes32(uint256(uint160(address(this)))),
            _BYTES_ARR_0,
            _BYTES_ARR_1
        );
        return address(uint160(uint256(keccak256(abi.encodePacked(_create2Prefix, proxySalt, keccak256(bytecode))))));
    }
}