pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract yourNFTguru is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(
        address defaultAdminRole,
        address defaultMinterRole,
        address[] memory mintToAddresses,
        uint256[] memory mintAmounts,
        address devAddress
    ) ERC20("yourNFTguru", "YNG") {
        require(
            mintToAddresses.length == mintAmounts.length,
            "yourNFTguru: Invalid arguments length"
        );
        _setupRole(DEFAULT_ADMIN_ROLE, defaultAdminRole);
        _setupRole(MINTER_ROLE, defaultMinterRole);

        for (uint256 i = 0; i < mintToAddresses.length; i++) {
            require(
                mintToAddresses[i] != devAddress,
                "yourNFTguru: Dev address not allowed"
            );
            _mint(mintToAddresses[i], mintAmounts[i]);
        }
    }

    function mint(address to, uint256 amount) public {
        require(
            hasRole(MINTER_ROLE, msg.sender),
            "yourNFTguru: must have minter role to mint"
        );
        _mint(to, amount);
    }

    function grantMinterRole(address account) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "yourNFTguru: must have admin role to grant minter role"
        );
        grantRole(MINTER_ROLE, account);
    }

    function revokeMinterRole(address account) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "yourNFTguru: must have admin role to revoke minter role"
        );
        revokeRole(MINTER_ROLE, account);
    }
}