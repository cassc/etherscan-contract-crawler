// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./interfaces/IFlashStrategySushiSwapFactory.sol";
import "./FlashStrategySushiSwap.sol";

interface IFlashProtocol {
    function registerStrategy(
        address _strategyAddress,
        address _principalTokenAddress,
        string calldata _fTokenName,
        string calldata _fTokenSymbol
    ) external;
}

contract FlashStrategySushiSwapFactory is Ownable, IFlashStrategySushiSwapFactory {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";

    /**
     * @notice address of FlashProtocol
     */
    address public immutable override flashProtocol;
    /**
     * @notice address of FarmingLPTokenFactory
     */
    address public immutable override flpTokenFactory;

    address internal immutable _implementation;

    /**
     * @notice fee recipient
     */
    address public override feeRecipient;

    mapping(uint256 => address) public override getFlashStrategySushiSwap;

    constructor(
        address _flashProtocol,
        address _flpTokenFactory,
        address _feeRecipient
    ) {
        flashProtocol = _flashProtocol;
        flpTokenFactory = _flpTokenFactory;
        updateFeeRecipient(_feeRecipient);

        FlashStrategySushiSwap strategy = new FlashStrategySushiSwap();
        strategy.initialize(address(0), address(0));
        _implementation = address(strategy);
    }

    function predictFlashStrategySushiSwapAddress(uint256 pid) external view override returns (address token) {
        token = Clones.predictDeterministicAddress(_implementation, bytes32(pid));
    }

    function updateFeeRecipient(address _feeRecipient) public override onlyOwner {
        if (_feeRecipient == address(0)) revert InvalidFeeRecipient();

        feeRecipient = _feeRecipient;

        emit UpdateFeeRecipient(_feeRecipient);
    }

    function createFlashStrategySushiSwap(uint256 pid) external override returns (address strategy) {
        if (getFlashStrategySushiSwap[pid] != address(0)) revert FlashStrategySushiSwapCreated();

        address flpToken = IFarmingLPTokenFactory(flpTokenFactory).getFarmingLPToken(pid);
        if (flpToken == address(0)) flpToken = IFarmingLPTokenFactory(flpTokenFactory).createFarmingLPToken(pid);

        strategy = Clones.cloneDeterministic(_implementation, bytes32(pid));
        FlashStrategySushiSwap(strategy).initialize(flashProtocol, flpToken);

        getFlashStrategySushiSwap[pid] = strategy;

        string memory name = string.concat("fToken for ", IERC20Metadata(flpToken).name());
        string memory symbol = string.concat(
            "f",
            IERC20Metadata(flpToken).symbol(),
            "-",
            _toHexString(uint160(flpToken) >> 144, 4)
        );
        IFlashProtocol(flashProtocol).registerStrategy(strategy, flpToken, name, symbol);

        emit CreateFlashStrategySushiSwap(pid, strategy);
    }

    function _toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(length);
        for (uint256 i = 0; i < length; ) {
            buffer[length - i - 1] = _SYMBOLS[value & 0xf];
            value >>= 4;
            unchecked {
                ++i;
            }
        }
        return string(buffer);
    }
}