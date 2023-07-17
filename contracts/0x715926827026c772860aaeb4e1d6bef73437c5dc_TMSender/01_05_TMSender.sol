// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.18;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

interface ITruStake {
    function sharePrice() external view returns (uint256, uint256);
}

interface IFxRoot {
    function sendMessageToChild(address receiver, bytes calldata data) external;
}

/// @notice Price sender contract to be deployed on Ethereum.
contract TMSender is OwnableUpgradeable {
    // Global state

    address public staker; // Goerli: 0x0ce41d234f5E3000a38c5EEF115bB4D14C9E1c89 | Mainnet: 0xA43A7c62D56dF036C187E1966c03E2799d8987ed
    address public fxRoot; // Goerli: 0x3d1d3E34f7fB6D26245E6640E1c50710eFFf15bA | Mainnet: 0xfe5e5D361b2ad62c541bAb87C45a0B9B018389a2
    address public tmReceiver;

    // Setup

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _staker, address _fxRoot, address _tmReceiver) external initializer {
        __Ownable_init();
        
        staker = _staker;
        fxRoot = _fxRoot;
        tmReceiver = _tmReceiver;
    }

    // Events

    event PriceUpdate(uint256 num, uint256 denom, bytes data);

    // Main

    function updatePrice() external {
        (uint256 num, uint256 denom) = ITruStake(staker).sharePrice();

        bytes memory price = _convertPriceToBytes(num, denom);

        IFxRoot(fxRoot).sendMessageToChild(tmReceiver, price);

        emit PriceUpdate(num, denom, price);
    }

    // Helpers

    function _convertPriceToBytes(uint256 num, uint256 denom) private pure returns (bytes memory) {
        return abi.encodePacked(num, denom);
    }

    // Setters

    function setStaker(address _staker) external onlyOwner {
        staker = _staker;
    }

    function setFxRoot(address _fxRoot) external onlyOwner {
        fxRoot = _fxRoot;
    }

    function setReceiver(address _tmReceiver) external onlyOwner {
        tmReceiver = _tmReceiver;
    }
}