pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SignedPhotoNFT is ERC1155, ReentrancyGuard, Ownable {
    uint256 public constant MAX_MINTABLE = 700;
    uint256 public constant NO_OF_TYPES = 9;
    address public immutable SIGNER;

    bool public mintingPaused = false;
    bool public devMinted = false;
    mapping(address => bool) public claimed;
    uint256 public numberMinted;

    constructor(address signer) ERC1155("ipfs://QmZ2tsEATkcLmz3gkX5TXgqRTdFG674W3A9thP2duEEbAj/{id}.json") {
        SIGNER = signer;
    }

    /**
     * @dev Premints 
     */
    function devMint() external onlyOwner {
        require(devMinted == false, "Already minted");

        uint256 devmintPerType = 4;
        devMinted = true;
        for (uint256 i = 0; i < NO_OF_TYPES; i++) {
            _mint(msg.sender, i, devmintPerType, "");
        }
        numberMinted += NO_OF_TYPES * devmintPerType;
    }

    /**
     * @dev Pauses / Unpauses minting.
     */
    function toggleMinting() external onlyOwner {
        mintingPaused = !mintingPaused;
    }

    /**
     * @dev Mints an NFT of a certain type (Pseudo-randomly determined). 
     * Signature parameters representing signed data comprising the minter's address, by the SIGNER address
     */
    function mint(uint8 v, bytes32 r, bytes32 s) external nonReentrant {
        require(numberMinted < MAX_MINTABLE, "Minting is concluded");
        require(!mintingPaused, "Minting is paused");
        require(!claimed[msg.sender], "You have already claimed");
        require(verify(msg.sender, v, r, s), "Signature is invalid");

        uint256 tokenType = uint(keccak256(abi.encodePacked(msg.sender, block.difficulty, block.timestamp))) % NO_OF_TYPES;
        claimed[msg.sender] = true;
        numberMinted++;
        _mint(msg.sender, tokenType, 1, "");
    }

    /**
     * @dev Verifies if the given signature matches the _sender address and is by the SIGNER.
     */
    function verify(address _sender, uint8 _v, bytes32 _r, bytes32 _s) internal view returns (bool) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n20";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, _sender));
        address signer = ecrecover(prefixedHash, _v, _r, _s);
        return signer == SIGNER;
    }
}