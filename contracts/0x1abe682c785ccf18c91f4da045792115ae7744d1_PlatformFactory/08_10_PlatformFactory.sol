// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import {Owned} from "solmate/auth/Owned.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {Platform, Factory} from "./Platform.sol";
import {Bytes32AddressLib} from "solmate/utils/Bytes32AddressLib.sol";

contract PlatformFactory is Owned, Factory {
    using Bytes32AddressLib for address;
    using Bytes32AddressLib for bytes32;

    uint256 internal constant _DEFAULT_FEE = 2e16; // 2%

    /// @notice Fee recipient.
    address public feeCollector;

    /// @notice Fee percentage per gaugeController.
    mapping(address => uint256) public customFeesPerGaugeController;

    /// @notice Emitted when a new platform is deployed.
    event PlatformDeployed(Platform indexed platform, address indexed gaugeController);

    /// @notice Emitted when a new fee is set.
    event PlatformFeeUpdated(address indexed gaugeController, uint256 fee);

    /// @notice Emitted when a platform is killed.
    event PlatformKilled(Platform indexed platform, address indexed gaugeController);

    /// @notice Thrown if the fee percentage is invalid.
    error INCORRECT_FEE();

    ////////////////////////////////////////////////////////////////
    /// --- CONSTRUCTOR
    ///////////////////////////////////////////////////////////////

    /// @notice Creates a Platform factory.
    /// @param _owner The owner of the factory.
    constructor(address _owner, address _feeCollector) Owned(_owner) {
        feeCollector = _feeCollector;
    }

    function deploy(address _gaugeController) external returns (Platform platform) {
        // Deploy the platform.
        platform = new Platform{salt: address(_gaugeController).fillLast12Bytes()}(_gaugeController, address(this));
        customFeesPerGaugeController[_gaugeController] = _DEFAULT_FEE;

        emit PlatformDeployed(platform, _gaugeController);
    }

    /// @notice Computes a Platform address from its gauge controller.
    function getPlatformFromGaugeController(address gaugeController) external view returns (Platform) {
        return Platform(
            payable(
                keccak256(
                    abi.encodePacked(
                        bytes1(0xFF),
                        address(this),
                        address(gaugeController).fillLast12Bytes(),
                        keccak256(
                            abi.encodePacked(type(Platform).creationCode, abi.encode(gaugeController, address(this)))
                        )
                    )
                ).fromLast20Bytes() // Convert the CREATE2 hash into an address.
            )
        );
    }

    function platformFee(address _gaugeController) external view returns (uint256) {
        return customFeesPerGaugeController[_gaugeController];
    }

    function setPlatformFee(address _gaugeController, uint256 _newCustomFee) external onlyOwner {
        if (_newCustomFee > 1e18) revert INCORRECT_FEE();
        emit PlatformFeeUpdated(_gaugeController, customFeesPerGaugeController[_gaugeController] = _newCustomFee);
    }

    function setFeeCollector(address _feeCollector) external onlyOwner {
        feeCollector = _feeCollector;
    }

    function kill(address platform) external onlyOwner {
        Platform(platform).kill();
        emit PlatformKilled(Platform(platform), address(Platform(platform).gaugeController()));
    }
}