pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./Wallet.sol";

contract WalletFactory is Ownable {
    using ECDSA for bytes32;

    uint256 public walletsCounter;
    mapping(uint256 => address) public wallets;
    mapping(address => address) public walletsToOwners;
    mapping(address => address) public ownersToWallets;
    mapping(address => bool) public managers;

    event WalletCreated (uint256 indexed id, address indexed owner, address indexed wallet);

    constructor() {
        managers[msg.sender] = true;
    }

    function changeManagers(address _account, bool _isManager)
        external
        onlyOwner
    {
        require(_account != address(0), "WalletFactory: Invalid address");
        managers[_account] = _isManager;
    }

    function createWallet() external {
        require(ownersToWallets[msg.sender] == address(0), "WalletFactory: Wallet already exists");
        address wallet = address(
            new Wallet{salt: keccak256(abi.encodePacked(msg.sender))}(msg.sender)
        );
        
        walletsCounter++;
        wallets[walletsCounter] = wallet;
        ownersToWallets[msg.sender] = wallet;
        walletsToOwners[wallet] = msg.sender;
        
        emit WalletCreated(walletsCounter, msg.sender, wallet);
    }

    function verify(bytes calldata instructions, bytes calldata signature)
        external
        view
        returns (bool)
    {
        address signer = keccak256(abi.encodePacked(instructions))
            .toEthSignedMessageHash()
            .recover(signature);
        return managers[signer];
    }

    function hash(bytes calldata instructions)
        external
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(instructions));
    }
}