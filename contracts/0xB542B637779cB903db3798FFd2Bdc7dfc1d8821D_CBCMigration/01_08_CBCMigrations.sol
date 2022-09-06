// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract CBCMigration is Ownable {
    using ECDSA for bytes32;

    /// @notice new token to migrate
    ERC20 public newCBC;

    /// @notice old cbc token to be migrated
    ERC20 public oldCBC;

    /// @notice admin wallet to transfer new tokens
    address public adminWallet;

    /// @notice burn wallet address for old token
    address public burnWallet;

    /// @notice store used nonce from backend verification step
    mapping(uint256 => bool) public nonceToValidated;

    /// @notice how much tokens swapped for each user
    mapping(address => uint256) public swapPerAddress;

    /// ECDSA verification recover key
    address private serverKey;

    /// migration event
    event Migration(address indexed recepient, uint256 indexed amount);

    constructor(
        ERC20 _newCBC,
        ERC20 _oldCBC,
        address _adminWallet,
        address _serverKey,
        address _burnWallet
    ) {
        newCBC = _newCBC;
        oldCBC = _oldCBC;
        adminWallet = _adminWallet;
        serverKey = _serverKey;
        burnWallet = _burnWallet;
    }

    /**
     * @dev migrate old cbc tokens into new cbc
     * @param _amount amount of cbc tokens to migrate
     * @param _nonce nonce of backend whitelist
     * @param _totalAmount total amount of user to be allowed
     * @param _signature signed signature from whitelist backend
     */
    function migrate(
        uint256 _amount,
        uint256 _nonce,
        uint256 _totalAmount,
        bytes memory _signature
    ) external {
        require(
            swapPerAddress[msg.sender] + _amount <= _totalAmount,
            "User cannot exceed allowed swap amount"
        );
        require(msg.sender != address(0), "Caller cannot be zero address!");

        require(
            !nonceToValidated[_nonce],
            "migrate: this nonce was already used"
        );

        // ensure that the sender is allowed by the validator
        address recovered = ECDSA.recover(
            keccak256(
                abi.encodePacked(_amount, _totalAmount, _nonce, msg.sender)
            ),
            _signature
        );
        require(recovered == serverKey, "migrate: Verification Failed");

        require(
            oldCBC.allowance(msg.sender, address(this)) >= _amount,
            "User doesn't approve enough amount to transfer on old CBC contract"
        );

        require(
            newCBC.allowance(adminWallet, address(this)) >= _amount,
            "Admin doesn't approve enough amount to transfer on new CBC contract"
        );

        bool sent = oldCBC.transferFrom(msg.sender, burnWallet, _amount);
        require(sent, "Token Transfer failed");

        newCBC.transferFrom(adminWallet, msg.sender, _amount);
        nonceToValidated[_nonce] = true;
        swapPerAddress[msg.sender] += _amount;

        emit Migration(msg.sender, _amount);
    }

    /**
     * @dev update admin wallet which will transfer tokens from
     * @param _newAdminWallet new admin wallet address to update
     */
    function updateAdminWallet(address _newAdminWallet) public onlyOwner {
        adminWallet = _newAdminWallet;
    }

    /**
     * @dev update admin wallet which will transfer tokens from
     * @param _newBurnWallet new admin wallet address to update
     */
    function updateBurnWallet(address _newBurnWallet) public onlyOwner {
        burnWallet = _newBurnWallet;
    }

    /**
     * @dev update admin wallet which will transfer tokens from
     * @param _newServerKey new admin wallet address to update
     */
    function updateServerKey(address _newServerKey) public onlyOwner {
        serverKey = _newServerKey;
    }
}