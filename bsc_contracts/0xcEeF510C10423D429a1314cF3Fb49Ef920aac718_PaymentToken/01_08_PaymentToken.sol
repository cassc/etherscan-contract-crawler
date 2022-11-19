// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract PaymentToken is ERC20, Ownable {
    using ECDSA for bytes32;

    address public projectFactory;

    mapping(address => bool) public isProject;
    mapping(address => bool) public blacklist;
    mapping(address => uint256) public nonces;

    event Claim(address user, uint256 amount);
    error TransferForbidden();
    event SetProjectFactory(address projectFactory);
    event SetIsBlocked(address user, bool isBlocked);

    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
    {}

    modifier onlyProjectFactory() {
        require(msg.sender == projectFactory, "only projectFactory");
        _;
    }

    function mint(address recipient, uint256 amount) external onlyOwner {
        _mint(recipient, amount);
    }

    function burn(address from, uint256 amount) external {
        if (msg.sender != owner() && from != msg.sender)
            revert TransferForbidden();

        _burn(from, amount);
    }

    function claim(uint256 amount, bytes memory signature) external {
        bytes32 hash = keccak256(
            abi.encodePacked(msg.sender, amount, nonces[msg.sender])
        );
        require(hash.recover(signature) == owner(), "invalid signature");

        _mint(msg.sender, amount);

        emit Claim(msg.sender, amount);
        nonces[msg.sender]++;
    }

    function addProject(address projectAddress) external onlyProjectFactory {
        isProject[projectAddress] = true;
    }

    function setProjectFactory(address newProjectFactory) external onlyOwner {
        projectFactory = newProjectFactory;
        emit SetProjectFactory(newProjectFactory);
    }

    function setIsBlocked(address user, bool status) external onlyOwner {
        blacklist[user] = status;
        emit SetIsBlocked(user, status);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256
    ) internal override {
        bool notOwner = msg.sender != owner();
        bool notMint = from != address(0);
        bool notBurn = to != address(0);
        bool notAuctionTransfer = !isProject[from] && !isProject[to];

        if (notOwner && notMint && notBurn && notAuctionTransfer)
            revert TransferForbidden();
        if (blacklist[msg.sender]) revert TransferForbidden();
    }
}