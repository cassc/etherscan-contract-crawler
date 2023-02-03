// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./INFTLaunchpad.sol";
import "./NFT.sol";

error MaximumLaunchpadSupplyReached(uint256 maximum);
error ToIsZeroAddress();
error SizeIsZero();
error MsgSenderIsNotLaunchpad();
error MintNotAvailableOutsideLaunchpad();

contract TheHarvestLegendaryBox is NFTBase, INFTLaunchpad {
    address public launchpad;

    event LaunchpadChanged(address indexed previousLaunchpad, address indexed newLaunchpad);

    modifier onlyLaunchpad() {
        if (msg.sender != launchpad) revert MsgSenderIsNotLaunchpad();
        _;
    }

    function initialize(
        string calldata name_,
        string calldata symbol_,
        string calldata baseTokenURI,
        uint256 maxTokenSupply,
        bool burnEnabled,
        address aclContract,
        address _launchpad
    ) external initializer {
        __NFT_init(name_, symbol_, baseTokenURI, maxTokenSupply, burnEnabled, aclContract);
        _setLaunchpad(_launchpad);
    }

    function setLaunchpad(address _launchpad) external onlyOperator {
        _setLaunchpad(_launchpad);
    }

    function mintTo(address to, uint256 size) external onlyLaunchpad {
        if (to == address(0)) revert ToIsZeroAddress();
        if (size == 0) revert SizeIsZero();

        if (super.totalSupply() + size > _maxTokenSupply) {
            revert MaximumLaunchpadSupplyReached(_maxTokenSupply);
        }

        for (uint256 i = 0; i < size; i++) {
            _mintTo(to);
        }
    }

    function getMaxLaunchpadSupply() external view returns (uint256) {
        return _maxTokenSupply;
    }

    function setMaxTokenSupply(uint256 maxTokenSupply) external onlyOperator {
        _maxTokenSupply = maxTokenSupply;
    }

    function name() public pure override returns (string memory) {
        return "The Harvest Legendary Box";
    }

    function symbol() public pure override returns (string memory) {
        return "THLB";
    }

    function getLaunchpadSupply() external view returns (uint256) {
        return super.totalSupply();
    }

    function _setLaunchpad(address _launchpad) internal {
        emit LaunchpadChanged(launchpad, _launchpad);
        launchpad = _launchpad;
    }
}