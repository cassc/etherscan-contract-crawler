// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IBombAsset.sol";
import "./interfaces/IBombSender.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/// @custom:security-contact [email protected]
contract BombAssetHandler is
    Initializable,
    PausableUpgradeable,
    AccessControlEnumerableUpgradeable,
    ReentrancyGuardUpgradeable
{
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    address[] public bombAsset;
    mapping(address => uint256) public bombAssetId;

    uint256 public nativeAmount;

    IBombSender public nativeSender;

    event BombProvided(address indexed user, uint256 amount);

    event AssetMinted(
        address indexed asset,
        address indexed user,
        uint256 amount
    );

    event AssetWithdraw(
        address indexed asset,
        address indexed from,
        address indexed to,
        uint256 amount,
        string destinationChain
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _admin,
        address _bombSender
    ) public initializer {
        __Pausable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);

        _grantRole(OPERATOR_ROLE, _admin);

        nativeAmount = 0.01 ether;
        nativeSender = IBombSender(_bombSender);
    }

    function mintAsset(
        address _asset,
        uint256 _amount,
        address _user,
        bool _giveNative
    ) public nonReentrant onlyRole(OPERATOR_ROLE) returns (bool) {
        require(_checkAssetExists(_asset), "Asset must be added first");
        require(!isContract(_user), "User cannot be a contract");
        if (_giveNative) {
            nativeSender.sendBomb(_user, nativeAmount);
        }
        emit AssetMinted(_asset, _user, _amount);
        IBombAsset(_asset).mint(_user, _amount);
        return true;
    }

    function addAsset(address _asset) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!_checkAssetExists(_asset), "Asset already exists");
        bombAsset.push(_asset);
        bombAssetId[_asset] = bombAsset.length - 1;
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function bridgeAsset(
        address _asset,
        uint256 _amount,
        address _to,
        string calldata _destinationChain
    ) external nonReentrant returns (bool) {
        require(_checkAssetExists(_asset), "Asset must be added first");
        require(
            IERC20Upgradeable(_asset).transferFrom(
                _msgSender(),
                address(this),
                _amount
            ),
            "Could not transfer tokens"
        );
        IBombAsset(_asset).burn(_amount);

        emit AssetWithdraw(
            _asset,
            _msgSender(),
            _to,
            _amount,
            _destinationChain
        );
        return true;
    }

    function _checkAssetExists(address _token) internal view returns (bool) {
        uint256 length = bombAsset.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            if (bombAsset[pid] == _token) {
                return true;
            }
        }
        return false;
    }

    function isContract(address addr) private view returns (bool) {
        return addr.code.length > 0;
    }
}