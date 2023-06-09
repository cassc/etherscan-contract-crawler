// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/// @custom:security-contact [email protected]
contract AwardableOpenEdition is ERC721A, Ownable, AccessControl {
    bool public open = false;
    bool public oneUse = false;
    uint public constant ENDING = 1680321599;
    uint public constant PRICE = 0.004 ether;
    uint public constant MAX_MINT = 100;
    address public rootSigner;
    address public vault;
    string public baseURI;
    mapping(uint => uint) public IdToTokenMinted;

    error wrongPrice();
    error wrongSignature();
    error mintNotStarted();
    error mintEnded();
    error maxClaimed();
    error mintExceedMax();
    error alreadyStarted();

    constructor(
        string memory _uri,
        address _signer,
        address _vault
    ) ERC721A("Awardable Open Edition", "AWRD-OE") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, 0x0a3C1bA258c0E899CF3fdD2505875e6Cc65928a8);
        transferOwnership(0x86a8A293fB94048189F76552eba5EC47bc272223);
        baseURI = _uri;
        rootSigner = _signer;
        vault = _vault;
    }

    // Modifiers
    /// @notice allows minting only if the mint is open
    /// @dev use IsOpen to check if the mint is open based on open, ending and block.timestamp
    modifier onlyIfOpen() {
        require(isOpen());
        _;
    }

    // Admin functions
    /// @notice set the open variable to true
    function startMint() public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (oneUse) revert alreadyStarted();
        oneUse = true;
        open = true;
    }

    function emergencyStopMint() public onlyRole(DEFAULT_ADMIN_ROLE) {
        open = false;
    }

    /// @notice withdraws all ETH from the contract to the vault
    function withdraw() public onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(vault).transfer(address(this).balance);
    }

    // functions
    /// @notice checks if the mint is open
    /// @return a boolean indicating if the mint is open
    function isOpen() public view returns (bool) {
        if (!open) revert mintNotStarted();
        if (block.timestamp > ENDING) revert mintEnded();
        return true;
    }

    /// @notice returns the baseURI
    /// @return the baseURI of the contract
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /// @notice mints qty tokens to the address passed in to only if the mint is open
    /// @param to the address to mint the tokens to
    /// @param qty the number of tokens to mint
    function mint(address to, uint qty) public payable onlyIfOpen {
        if (msg.value != PRICE * qty) revert wrongPrice();
        if (qty > MAX_MINT) revert mintExceedMax();
        _mint(to, qty);
        payable(vault).transfer(msg.value);
    }

    /// @notice allow whitelist to mint tokens
    /// @param to the address to mint the tokens to
    /// @param awrdID the award ID of the user using his whitelist
    /// @param qty the number of tokens to mint
    /// @param max_free_edition the max number of tokens the user can mint
    /// @param signature the signature of the back end
    function claim(
        address to,
        uint awrdID,
        uint qty,
        uint max_free_edition,
        bytes memory signature
    ) public {
        bytes32 dataHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(to, awrdID, max_free_edition))
            )
        );
        if (
            !SignatureChecker.isValidSignatureNow(
                rootSigner,
                dataHash,
                signature
            )
        ) revert wrongSignature();
        if (IdToTokenMinted[awrdID] + qty > max_free_edition)
            revert maxClaimed();
        IdToTokenMinted[awrdID] += qty;
        _mint(to, qty);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721A, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}