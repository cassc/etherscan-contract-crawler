// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Receiver {
    function isPoolSet() external view returns (bool);

    function onStoneReceived() external returns (bool);
}

contract FeeCollector is
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    IERC20 public stoneFactory;

    address public teamWallet;
    IERC20Receiver public swapper;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _owner) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        teamWallet = address(0x6b3a9B3D50d211278a848F009f921305BaAD749A);

        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(UPGRADER_ROLE, _owner);
    }

    function setStoneFactory(
        address _stoneToken
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        stoneFactory = IERC20(_stoneToken);
    }

    function setTeamWallet(
        address _teamWallet
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        teamWallet = _teamWallet;
    }

    function setSwapper(address _swapper) public onlyRole(DEFAULT_ADMIN_ROLE) {
        swapper = IERC20Receiver(_swapper);
    }

    function distributeFunds() public onlyRole(DEFAULT_ADMIN_ROLE) {
        (, uint256 teamSplit, uint256 swapSplit) = _getTaxableSplits(
            stoneFactory.balanceOf(address(this))
        );
        stoneFactory.transfer(teamWallet, teamSplit);
        stoneFactory.transfer(address(swapper), swapSplit);
        if (address(swapper) != address(0)) {
            if (swapper.isPoolSet()) {
                swapper.onStoneReceived();
            }
        }
    }

    function _getTaxableSplits(
        uint256 taxPart
    )
        internal
        pure
        returns (uint256 _burnSplit, uint256 _teamSplit, uint256 _swapSplit)
    {
        _burnSplit = _getPercentAmt(taxPart, 2500);
        _teamSplit = _getPercentAmt(taxPart, 2500);
        _swapSplit = _getPercentAmt(taxPart, 5000);
    }

    function _getPercentAmt(
        uint256 _amount,
        uint256 _percBPS
    ) internal pure returns (uint256) {
        require((_amount * _percBPS) >= 10_000, "TOO_SMALL");
        return (_amount * _percBPS) / 10_000;
    }

    function stoneBalance() public view returns (uint256) {
        return stoneFactory.balanceOf(address(this));
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {}
}