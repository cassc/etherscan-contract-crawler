pragma solidity ^0.8.4;

import "@rari-capital/solmate/src/tokens/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Suck is AccessControl, ERC20("Suck", "$UCK", 18) {
    using ECDSA for bytes32;

    address public signer;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");
    uint256 public constant maxSupply = 88_888_888_888_888 * 10 ** 18;

    mapping(bytes => bool) public claimed;

    constructor(address _signer) {
        signer = _signer;
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function mint(address recipent, uint256 amount) external onlyRole(MINTER_ROLE) {
        require(totalSupply + amount <= maxSupply, "MAX_SUPPLY");
        _mint(recipent, amount);
    }

    function claim(bytes calldata signature, uint256 amount) external {
        require(totalSupply + amount <= maxSupply, "MAX_SUPPLY");
        require(!claimed[signature], "SIGNATURE_USED");
        require(keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(msg.sender, amount))
            )).recover(signature) == signer, "SIG_FAILED");
        claimed[signature] = true;
        _mint(msg.sender, amount);
    }

    function setSigner(address newSigner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        signer = newSigner;
    }
}