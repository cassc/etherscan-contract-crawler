// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// An interface to interact with USDC token
interface USDC {
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

// OptionDAO contract that extends ERC20 and has an admin
contract OptionDAO is ERC20 {

    // Boolean value to keep track if the contract is halted or not
    bool public halted = false;

    // Address of USDC contract to interact with
    USDC public USDc = USDC(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    // Price of an OptionDAO token
    uint256 public price;

    // Admin address: contract admin and where funds are transferred to
    address payable public admin;

    // Merkle root for an allowlist of addresses
    bytes32 private root;

    // Constructor for initializing the contract
    constructor(bytes32 _root, uint256 _price, address _admin) ERC20("OptionDAO", "OptDAO") {
        root = _root;
        price = _price;
        admin = payable(_admin);
    }

    // Modifier to check if an address is in the allowlist
    modifier isAllowlisted(bytes32[] calldata proof) {
        require(MerkleProof.verify(proof, root, keccak256(abi.encodePacked(msg.sender))));
        _;
    }

    // Modifier to check if msg.sender is admin
    modifier isAdmin() {
        require(msg.sender == address(admin), "Only contract admin can call this method");
        _;
    }

    // Function to fund the contract
    function fund(uint256 quantity, bytes32[] calldata proof) external isAllowlisted(proof) {
        // Check if funding is not permanently halted
        require(halted == false, "Funding is permanently halted.");
        // Check if the sender has enough USDC allowance to fund the contract
        require(USDc.allowance(msg.sender, address(this)) >= quantity * price * 10 ** 6, "USDC allowance too low");
        // Transfer USDC tokens from sender to admin
        USDc.transferFrom(msg.sender, admin, quantity * price * 10 ** 6);
        // Mint OptionDAO tokens to the sender
        _mint(msg.sender, quantity);
    }

    // Function to get the number of decimals in the token
    function decimals() public pure override returns (uint8) {
        return 0;
    }

    // Function to set the price of an OptionDAO token
    function setPrice(uint256 _price) external isAdmin {
        price = _price;
    }

    // Function to set the root of the allowlist
    function setRoot(bytes32 _root) external isAdmin {
        root = _root;
    }

    // Function to halt the contract (can only be called by admin)
    function halt() external isAdmin {
        halted = true;
    }

}