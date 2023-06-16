//SPDX-License-Identifier: Unlicense
// Creator: Pixel8 Labs
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./lib/ERC721Base.sol";

contract Mandala is
    ERC721Base,
    Ownable,
    AccessControl,
    Pausable,
    ReentrancyGuard
{
    //setup airdropper role
    bytes32 public constant AIRDROPPER_ROLE = keccak256("AIRDROPPER_ROLE");

    uint256 public constant MAX_SUPPLY = 250;

    constructor(string memory tokenURI_, address owner_)
        ERC721Base(tokenURI_, "Mandala", "MANDALA")
        Ownable()
    {
        _setupRole(DEFAULT_ADMIN_ROLE, owner_);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _setupRole(AIRDROPPER_ROLE, owner_);
        _transferOwnership(owner_);
    }

    function mint(address wallet, uint256 amount) external onlyRole(AIRDROPPER_ROLE) {
        uint256 supply = totalSupply();
        require(amount > 0, "amount too little");
        require(msg.sender != address(0), "empty address");
        require(supply + amount <= MAX_SUPPLY, "exceed max supply");

        _safeMint(wallet, amount);
    }

    function airdrop(address wallet, uint256 amount) external onlyRole(AIRDROPPER_ROLE)
    {
        uint256 supply = totalSupply();
        require(amount > 0, "amount too little");
        require(msg.sender != address(0), "empty address");
        require(supply + amount <= MAX_SUPPLY, "exceed max supply");

        _safeMint(wallet, amount);
    }

    function airdrops(
        address[] calldata recipients,
        uint256[] calldata quantities
    ) external onlyRole(AIRDROPPER_ROLE) {
        require(quantities.length == recipients.length, "ERC721Base: Provide equal length");
        uint256 totalQuantity;
        uint256 supply = totalSupply();
        for (uint256 i; i < quantities.length; ++i) {
            require(quantities[i] != 0, "ERC721Base: Can't mint 0 token");
            require(recipients[i] != address(0), "ERC721Base: empty address");
            totalQuantity += quantities[i];
        }
        require(supply + totalQuantity <= MAX_SUPPLY, "ERC721Base: Mint/order exceeds supply");
        delete totalQuantity;

        for (uint256 i; i < recipients.length; ++i) {
            _safeMint(recipients[i], quantities[i]);
        }
    }

    function setTokenURI(string calldata uri_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setTokenURI(uri_);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Base, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // withdraw for emergency
    function withdraw() external payable onlyRole(DEFAULT_ADMIN_ROLE) {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}