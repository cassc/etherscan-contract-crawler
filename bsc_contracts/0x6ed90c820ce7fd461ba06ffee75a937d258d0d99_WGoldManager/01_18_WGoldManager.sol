// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./openzeppelin/ERC20Upgradeable.sol";
import "./openzeppelin/utils/draft-EIP712Upgradeable.sol";
import "./openzeppelin/AccessControlUpgradeable.sol";
import "./openzeppelin/utils/Initializable.sol";
import "./openzeppelin/PausableUpgradeable.sol";
import "./interfaces/IWGoldManager.sol";
import "./interfaces/IWGold.sol";

contract WGoldManager is
    Initializable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    IWGoldManager,
    EIP712Upgradeable
{
    /**
     * @notice Address of token, that will be used for minting/burning.
     */
    address public wGold;

    event MintInfo(address indexed to, uint256 amount, uint256 indexed orderId);
    event BurnInfo(
        address indexed from,
        uint256 amount,
        uint256 indexed orderId
    );
    event SetWGold(address wGold);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Pausable_init();
        __AccessControl_init();
        __EIP712_init_unchained("manager", "1.0.0");

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Mint new tokens from given info. Checks user signature.
     *
     * @param _mintInfo A struct, that has info on user address, amount and orderId.
     * @param _signature  Bytes to check the user.
     */
    function mintGold(TaskInfo memory _mintInfo, bytes memory _signature)
        external
        override
        whenNotPaused
    {
        require(_verify(_signature, _mintInfo), "Signature do not match");
        IWGold(wGold).mint(_mintInfo.from, _mintInfo.amount);
        emit MintInfo(_mintInfo.from, _mintInfo.amount, _mintInfo.orderId);
    }

    /**
     * @dev Burn tokens from given info. Checks user signature.
     *
     * @param _burnInfo A struct, that has info on user address, amount and orderId.
     * @param _signature  Bytes to check the user.
     */
    function burnGold(TaskInfo memory _burnInfo, bytes memory _signature)
        external
        override
        whenNotPaused
    {
        require(_verify(_signature, _burnInfo), "Signature do not match");
        IWGold(wGold).burn(_burnInfo.from, _burnInfo.amount);
        emit BurnInfo(_burnInfo.from, _burnInfo.amount, _burnInfo.orderId);
    }

    /**
     * @dev Sets new WGold address.
     *
     * @param _wGold Address of WGold contract.
     */
    function setWgold(address _wGold) external onlyRole(DEFAULT_ADMIN_ROLE) {
        wGold = _wGold;
        emit SetWGold(_wGold);
    }

    function _verify(bytes memory signature, TaskInfo memory taskInfo)
        private
        view
        returns (bool result)
    {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "TaskInfo(address from,uint256 amount,uint256 orderId)"
                    ),
                    taskInfo.from,
                    taskInfo.amount,
                    taskInfo.orderId
                )
            )
        );
        address recoveredSigner = ECDSAUpgradeable.recover(digest, signature);
        require(recoveredSigner == taskInfo.from, "Wrong signature");
        return true;
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
}