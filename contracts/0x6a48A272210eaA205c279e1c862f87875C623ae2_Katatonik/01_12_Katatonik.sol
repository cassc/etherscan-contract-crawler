// SPDX-License-Identifier: MIT
// Creator: Serozense

pragma solidity 0.8.15;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

//                     ▄▄████
//                 ▄▄█▀▀ ▄██▀
//              ▄██▀    ▄██▀                                     ▄
//           ▄██▀      ███                                   ▄▄███▌
//         ▄█▀        ███                              ▄   ▄█▀ ███
//        ▀█▄▄▄     ▄███         ▄▄       ▄▄  ▄▄▄▄▄▄▄ ▐█ ▄█▀  ███
//                 ▄██▀ ▄▄▀▀▀▀▀▀███▀▀▀▀▀▀███▀▀        ██ ▀   ▐██    ▄
//                ███▌▄▄▄▄█▀▀   ██       ██          ██ ▄▄   ██▌ ▄▄▄█▀
//               ████▌     ▄██ ▐█▌  ▄▄█ ▐█▌▄███▌ ██ ▄██▐█▌  ████▀
//             ▄██▀███  ▀█▀▀██ ▐█ ▄█▀██ ██ ██▄█▌██████ ██  ▐████▄      ▄▄▄▄
//            ▄██▀  ███ ▀ ▀███ ██▄▀████ █▌ ▀▀▀▀ ▀  ▀▀▀ █   ██  ███         ▀▀█▄
//           ███     ▀██▄      █▌   ▀▀  █   ▄▄▄▄▄▀▀▀▀▀    ██    ▀██▄           ▀█▄
//          ███        ▀██▄             ▀                 █▌      ▀██▄          ▐██
//         ██▀            ▀██▄▄▄▀                                    ▀██▄       ██▀
//        ██                                                             ▀▀███▀▀▀

/**
 * This contract uses a ECDSA signed off-chain to control mint.
 * This way, whether the sale is launched or whether it is pre-sale or public is controlled off-chain.
 * This reduces a lot of on-chain requirements (thus reducing gas fees).
 */

    error IncorrectSignature();
    error SoldOut();
    error MaxMinted();
    error CallerIsNotOwner();
    error CannotSetZeroAddress();
    error NonExistentToken();
    error CollectionTooSmall();
    error CanOnlyBeDecreased();

contract Katatonik is ERC721A, ERC2981, Ownable {

    using Address for address;
    using ECDSA for bytes32;

    uint256 public collectionSize = 9999;
    string public staticBaseURI;
    string public animatedBaseURI;
    string public preRevealBaseURI;
    mapping(uint256 => bool) private _isAnimated;

    // fairness properties
    string public provenanceHash = "bb1a8ca3e785b7dd8d50a2f1d4f094b9215cedb0de52b0af5898e08c47451295";
    uint256 public startingIndex;
    uint256 public startingIndexTimestamp;
    bool public isStartingIndexLocked;

    // ECDSA signing address
    address public signingAddress;

    // Sets Treasury Address for withdraw() and ERC2981 royaltyInfo
    address public treasuryAddress;

    // Sets Crossmint Address for accepting credit cards mint
    address public crossmint;

    constructor(
        address defaultTreasury,
        uint256 defaultCollectionSize,
        uint256 toTreasury,
        string memory defaultPreRevealBaseURI,
        address signer
    ) ERC721A("Katatonik", "KATS") {
        setTreasuryAddress(payable(defaultTreasury));
        setRoyaltyInfo(750);
        setCollectionSize(defaultCollectionSize);
        setPreRevealBaseURI(defaultPreRevealBaseURI);
        setSigningAddress(signer);
        _mintERC2309(msg.sender, toTreasury);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier requireCrossmint() {
        require(msg.sender == crossmint, "Crossmint only");
        _;
    }

    function mint(bytes calldata signature, uint256 quantity, uint256 maxMintable) external payable callerIsUser {
        if(!verifySig(maxMintable, msg.value/quantity, signature)) revert IncorrectSignature();
        if(totalSupply() + quantity > collectionSize) revert SoldOut();
        if(_numberMinted(msg.sender) + quantity > maxMintable) revert MaxMinted();

        _mint(msg.sender, quantity);
    }

    function privateMint(bytes calldata signature, uint256 quantity, uint256 maxMintable) external payable {
        if(!verifySigPrivate(msg.sender, maxMintable, msg.value/quantity, signature)) revert IncorrectSignature();
        if(totalSupply() + quantity > collectionSize) revert SoldOut();
        if(_numberMinted(msg.sender) + quantity > maxMintable) revert MaxMinted();

        _mint(msg.sender, quantity);
    }

    function crossMint(bytes calldata signature, uint256 quantity, uint256 maxMintable, address to) external payable requireCrossmint {
        if(!verifySig(maxMintable, msg.value/quantity, signature)) revert IncorrectSignature();
        if(totalSupply() + quantity > collectionSize) revert SoldOut();
        if(_numberMinted(msg.sender) + quantity > maxMintable) revert MaxMinted();

        _mint(to, quantity);
    }

    function privateCrossMint(bytes calldata signature, uint256 quantity, uint256 maxMintable, address to) external payable requireCrossmint {
        if(!verifySigPrivate(to, maxMintable, msg.value/quantity, signature)) revert IncorrectSignature();
        if(totalSupply() + quantity > collectionSize) revert SoldOut();
        if(_numberMinted(msg.sender) + quantity > maxMintable) revert MaxMinted();

        _mint(to, quantity);
    }

    function devMint(address to, uint256 quantity) external onlyOwner {
        if(totalSupply() + quantity > collectionSize) revert SoldOut();
        _mint(to, quantity);
    }

    function getMinted() external view returns (uint256) {
        return _numberMinted(msg.sender);
    }

    /**
     * @dev Set the metadata to Animated or Static State
     */
    function setIsAnimated(bytes calldata signature, uint256 tokenID, bool isAnimated) external {
        if (!_exists(tokenID)) revert NonExistentToken();
        if (ownerOf(tokenID) != msg.sender) revert CallerIsNotOwner();
        if(!verifySigAnimated(msg.sender, tokenID, signature)) revert IncorrectSignature();

        _isAnimated[tokenID] = isAnimated;
    }

    /**
     * @dev Verify the ECDSA signature for Mint
     */
    function verifySig(uint256 maxMintable, uint256 valueSent, bytes memory signature) internal view returns(bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(maxMintable, valueSent));
        return signingAddress == messageHash.toEthSignedMessageHash().recover(signature);
    }

    /**
     * @dev Verify the ECDSA signature for Private Mint
     */
    function verifySigPrivate(address sender, uint256 maxMintable, uint256 valueSent, bytes memory signature) internal view returns(bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(sender, maxMintable, valueSent));
        return signingAddress == messageHash.toEthSignedMessageHash().recover(signature);
    }

    /**
     * @dev Verify the ECDSA signature for Animated State
     */
    function verifySigAnimated(address sender, uint256 tokenID, bytes memory signature) internal view returns(bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(sender, tokenID));
        return signingAddress == messageHash.toEthSignedMessageHash().recover(signature);
    }

    // OWNER FUNCTIONS ---------
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        staticBaseURI = newBaseURI;
    }

    function setAnimatedBaseURI(string memory newBaseURI) public onlyOwner {
        animatedBaseURI = newBaseURI;
    }

    /**
     * @dev Just in case there is a bug and we need to update the uri
     */
    function setPreRevealBaseURI(string memory newBaseURI) public onlyOwner {
        preRevealBaseURI = newBaseURI;
    }

    /**
     * @dev To decrypt ECDSA sigs or invalidate signed but not claimed tokens
     */
    function setSigningAddress(address newSigningAddress) public onlyOwner {
        if (newSigningAddress == address(0)) revert CannotSetZeroAddress();
        signingAddress = newSigningAddress;
    }

    /**
     * @notice Creates a random starting index to offset pregenerated tokens by for fairness
     */
    function setStartingIndex() public onlyOwner {
        require(!isStartingIndexLocked, "STARTING_INDEX_ALREADY_SET");
        isStartingIndexLocked = true;
        startingIndex = uint(blockhash(block.number - 1)) % totalSupply();
        startingIndexTimestamp = block.timestamp;
    }

    /**
     * @dev Update the royalty percentage (500 = 5%)
     */
    function setRoyaltyInfo(uint96 newRoyaltyPercentage) public onlyOwner {
        _setDefaultRoyalty(treasuryAddress, newRoyaltyPercentage);
    }

    /**
     * @dev Update the Crossmint wallet address
     */
    function setCrossmint(address _crossmint) public onlyOwner {
        if (_crossmint == address(0)) revert CannotSetZeroAddress();
        crossmint = _crossmint;
    }

    /**
     * @dev Update the royalty wallet address
     */
    function setTreasuryAddress(address payable newAddress) public onlyOwner {
        if (newAddress == address(0)) revert CannotSetZeroAddress();
        treasuryAddress = newAddress;
    }

    /**
     * @dev Useful for unit tests to test minting out logic. No plan to use in production.
     */
    function setCollectionSize(uint256 size) public onlyOwner {
        if (size > collectionSize) revert CanOnlyBeDecreased();
        if (size < _nextTokenId()) revert CollectionTooSmall();
        collectionSize = size;
    }

    /**
     * @dev Withdraw funds to treasuryAddress
     */
    function withdraw() external onlyOwner {
        Address.sendValue(payable(treasuryAddress), address(this).balance);
    }

    // OVERRIDES ---------

    /**
     * @dev Change starting tokenId to 1 (from erc721A)
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @dev Variation of {ERC721Metadata-tokenURI}.
     * Returns different token uri depending on blessed or possessed.
     */
    function tokenURI(uint256 tokenID) public view override returns (string memory) {
        require(_exists(tokenID), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _isAnimated[tokenID] ? animatedBaseURI : staticBaseURI;
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _toString(tokenID), ".json")) : string(abi.encodePacked(preRevealBaseURI, _toString(tokenID), ".json"));
    }

    /**
     * @dev {ERC165-supportsInterface} Adding IERC2981
     */
    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721A, ERC2981)
    returns (bool)
    {
        return
        interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
        interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
        interfaceId == 0x5b5e139f || // ERC165 interface ID for ERC721Metadata.
        interfaceId == 0x2a55205a || // ERC165 interface ID for ERC2981.
        super.supportsInterface(interfaceId);
    }

}