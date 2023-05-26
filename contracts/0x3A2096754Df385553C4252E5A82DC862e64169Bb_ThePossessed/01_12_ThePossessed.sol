// SPDX-License-Identifier: MIT
// Creator: P4SD Labs

pragma solidity 0.8.15;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

error IncorrectSignature();
error SoldOut();
error MaxMinted();
error CallerIsNotOwner();
error CannotSetZeroAddress();
error NonExistentToken();
error CollectionTooSmall();

/**
 * This contract uses a ECDSA signed off-chain to control mint.
 * This way, whether the sale is launched or whether it is pre-sale or public is controlled off-chain.
 * This reduces a lot of on-chain requirements (thus reducing gas fees).
 */
contract ThePossessed is ERC721A, ERC2981, Ownable {
    using Address for address;
    using ECDSA for bytes32;

    uint256 public collectionSize = 10000;
    string public blessedBaseURI;
    string public possessedBaseURI;
    string public preRevealBaseURI;
    mapping(uint256 => bool) private _isPossessed;

    // ECDSA signing address
    address public signingAddress;

    // Sets Treasury Address for withdraw() and ERC2981 royaltyInfo
    address public treasuryAddress;

    constructor(
        address defaultTreasury, 
        uint256 defaultCollectionSize,
        string memory defaultPreRevealBaseURI,
        address signer
    ) ERC721A("The Possessed", "PSSSSD") {
        setTreasuryAddress(payable(defaultTreasury));
        setRoyaltyInfo(500);
        setCollectionSize(defaultCollectionSize);
        setPreRevealBaseURI(defaultPreRevealBaseURI);
        setSigningAddress(signer);
    }
    
    function mint(bytes calldata signature, uint256 quantity, uint256 maxMintable) external payable {
        if(!verifySig(msg.sender, maxMintable, msg.value/quantity, signature)) revert IncorrectSignature();
        if(totalSupply() + quantity > collectionSize) revert SoldOut();
        if(_numberMinted(msg.sender) + quantity > maxMintable) revert MaxMinted();

        _mint(msg.sender, quantity);
    }

    function getMinted() external view returns (uint256) {
        return _numberMinted(msg.sender);
    }

    /**
     * @dev Set the metadata to Possessed or Blessed State
     */
    function setIsPossessed(uint256 tokenID, bool isPssssd) external {
        if (!_exists(tokenID)) revert NonExistentToken();
        if (ownerOf(tokenID) != msg.sender) revert CallerIsNotOwner();
        _isPossessed[tokenID] = isPssssd;
    }

    /**
     * @dev Verify the ECDSA signature
     */
    function verifySig(address sender, uint256 maxMintable, uint256 valueSent, bytes memory signature) internal view returns(bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(sender, maxMintable, valueSent));
        return signingAddress == messageHash.toEthSignedMessageHash().recover(signature);
    }

    // OWNER FUNCTIONS ---------
    function setBaseURIs(string memory blessed, string memory possessed) public onlyOwner {
        blessedBaseURI = blessed;
        possessedBaseURI = possessed;
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
     * @dev Update the royalty percentage (500 = 5%)
     */
    function setRoyaltyInfo(uint96 newRoyaltyPercentage) public onlyOwner {
        _setDefaultRoyalty(treasuryAddress, newRoyaltyPercentage);
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
     * @dev Variation of {ERC721Metadata-tokenURI}.
     * Returns different token uri depending on blessed or possessed.
     */
    function tokenURI(uint256 tokenID) public view override returns (string memory) {
        require(_exists(tokenID), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _isPossessed[tokenID] ? possessedBaseURI : blessedBaseURI;
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _toString(tokenID))) : preRevealBaseURI;
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
            ERC2981.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

}