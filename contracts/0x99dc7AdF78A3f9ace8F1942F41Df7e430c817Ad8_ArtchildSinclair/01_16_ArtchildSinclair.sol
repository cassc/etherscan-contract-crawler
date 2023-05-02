// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// Contract by @backseats_eth for Artchild

/*
     #%%%-    :%%%%%%%%*= -%%%%%%%%%%%  -*%@@@%+:  *%%-    -%%% %%%=#%%#      +%%%%%%#+-
    *@@@@@.   [email protected]@@*++*%@@%:***%@@@***[email protected]@@@#*#@@@# *@@=    [email protected]@@ @@@=%@@%      *@@@++*@@@@:
   [email protected]@@*@@%   [email protected]@@.   [email protected]@@.   [email protected]@@   [email protected]@@#    :@@@+*@@+::::[email protected]@@ @@@=%@@%      *@@@    #@@%
  [email protected]@@:.%@@#  [email protected]@@%%%%@@@=    [email protected]@@   :@@@-     :--.*@@@@@@@@@@@ @@@=%@@%      *@@@    [email protected]@@
 [email protected]@@@@@@@@@* [email protected]@@[email protected]@%      [email protected]@@    @@@%:   [email protected]@@-*@@=    [email protected]@@ @@@=%@@%      *@@@   :%@@#
[email protected]@@*[email protected]@@[email protected]@@.  [email protected]@%.    [email protected]@@    .#@@@@%@@@@= *@@=    [email protected]@@ @@@=%@@@%%%%%**@@@%%@@@@#
*/

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { ERC721 } from "solmate/tokens/ERC721.sol";
import { MerkleProofLib } from "solmate/utils/MerkleProofLib.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ERC2981 } from "@openzeppelin/contracts/token/common/ERC2981.sol";
import { DefaultOperatorFilterer } from "operator-filter-registry/DefaultOperatorFilterer.sol";

contract ArtchildSinclair is ERC721, ERC2981, Ownable, DefaultOperatorFilterer {
    using ECDSA for bytes32;
    using Strings for uint256;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error AllowlistClosed();
    error BadMintState();
    error InvalidSignature();
    error MissingSystemAddress();
    error NotOnAllowlist();
    error PublicSaleClosed();
    error TokenAlreadyExists();
    error TokenDoesntExist();
    error WrongPrice(uint expected, uint actual);

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    // The state of the contract: 0 is closed, 1 is allowlist, 2 is public
    enum MintState {
        CLOSED,
        ALLOWLIST,
        PUBLIC
    }
    MintState public mintState;

    // The price of the mint
    uint public price = 0.069 ether;

    // The total supply of the collection
    uint public totalSupply;

    // The Merkle Root for the allowlist
    bytes32 public merkleRoot;

    // The address of the artist for payment
    address public artistAddress = 0x4F9B8A31c0986fA44cD386b1610F54a56eC8dc70;

    // The address of Artchild for payment
    address public artChildAddress = 0x511e71C3A5CaB41ebfD36794946065F1fb37D5cC;

    // The public address that corresponds to the private key that signs
    // the transaction
    address public systemAddress = 0x6f6dbD73Df7470E8166e84c3e91A88150918EeC8;

    // The _baseTokenURI for the collection
    string public _baseTokenURI;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory baseTokenURI) ERC721("Artchild Sinclair", "ACSINCLAIR") {
        _baseTokenURI = baseTokenURI;
    }

    /*//////////////////////////////////////////////////////////////
                                MODIFIER
    //////////////////////////////////////////////////////////////*/

    modifier premintChecks(uint _idToMint, string calldata _nonce, bytes calldata _signature) {
        // Ensures the id to mint is unowned
        if (_ownerOf[_idToMint] != address(0)) revert TokenAlreadyExists();

        // Ensures the minter is paying the correct price
        if (msg.value != price) revert WrongPrice(price, msg.value);

        // Ensures the signature coming from the server is valid
        if (!isValidSignature(systemAddress, keccak256(abi.encodePacked(msg.sender, _nonce, _idToMint)), _signature))
            revert InvalidSignature();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                MINTING
    //////////////////////////////////////////////////////////////*/

    // The allowlist mint function
    // Note: Requires a valid signature from the minting site
    function allowlistMint(
        uint _idToMint,
        bytes32[] calldata _merkleProof,
        string calldata _nonce,
        bytes calldata _signature
    ) external payable premintChecks(_idToMint, _nonce, _signature) {
        if (mintState != MintState.ALLOWLIST) revert AllowlistClosed();

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProofLib.verify(_merkleProof, merkleRoot, leaf))
            revert NotOnAllowlist();

        mint(_idToMint);
    }

    // The public mint function
    // Note: Requires a valid signature from the minting site
    function publicMint(
        uint _idToMint,
        string calldata _nonce,
        bytes calldata _signature
    ) external payable premintChecks(_idToMint, _nonce, _signature) {
        if (mintState != MintState.PUBLIC) revert PublicSaleClosed();

        mint(_idToMint);
    }

    // A function to mint the tokens
    function mint(uint _id) internal {
        unchecked { ++totalSupply; }
        _mint(msg.sender, _id);
    }

    /*//////////////////////////////////////////////////////////////
                             VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    // A function that returns a link to the metadata needed to display the token
    function tokenURI(uint _tokenId) public view virtual override returns (string memory) {
        if (_ownerOf[_tokenId] == address(0)) revert TokenDoesntExist();

        string memory baseURI = _baseURI();

        return bytes(baseURI).length > 0 ? string.concat(baseURI, _tokenId.toString()) : "";
    }

    // Checks if the signature from our server is valid
    function isValidSignature(address _systemAddress, bytes32 hash, bytes calldata signature) internal pure returns (bool) {
        if (_systemAddress == address(0)) revert MissingSystemAddress();

        bytes32 signedHash = hash.toEthSignedMessageHash();
        return signedHash.recover(signature) == _systemAddress;
    }

    // Returns the base URI
    function _baseURI() internal view virtual returns (string memory) {
        return _baseTokenURI;
    }

    /*//////////////////////////////////////////////////////////////
                                SETTERS
    //////////////////////////////////////////////////////////////*/

    // Sets the _baseTokenURI
    function setBaseURI(string calldata _baseURI) external onlyOwner {
        _baseTokenURI = _baseURI;
    }

    // Sets the Merkle root
    function setMerkleRoot(bytes32 _newMerkleRoot) public  onlyOwner {
        merkleRoot = _newMerkleRoot;
    }

    // Sets the price of the mint
    function setPrice(uint _newPriceInWei) public onlyOwner {
        price = _newPriceInWei;
    }

    // Sets the contract mint state
    function setMintState(uint _mintState) external onlyOwner {
        if (_mintState > 2) revert BadMintState();
        mintState = MintState(_mintState);
    }

    // Sets the Artist's payment address
    function setArtistAddress(address _artistAddress) external onlyOwner {
        artistAddress = _artistAddress;
    }

    // Sets the ArtChild payment address
    function setArtChildAddress(address _artChildAddress) external onlyOwner {
        artChildAddress = _artChildAddress;
    }

    // Sets the system address that corresponds to the signing wallet
    function setSystemAddress(address _systemAddress) external onlyOwner {
        systemAddress = _systemAddress;
    }

    /*//////////////////////////////////////////////////////////////
                               TRANSFERS
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /*//////////////////////////////////////////////////////////////
                                ERC-2981
    //////////////////////////////////////////////////////////////*/

    // Sets the royalty info for the collection
    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints) external onlyOwner {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    // Conformance boilerplate
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /*//////////////////////////////////////////////////////////////
                                WITHDRAW
    //////////////////////////////////////////////////////////////*/

    // Withdraws funds from the contract
    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        uint acPayment = balance * 4/10;
        uint artPayment = balance * 6/10;

        // 40% to ArtChild
        (bool artChildPayment, ) = payable(artChildAddress).call{ value: acPayment }("");
        require(artChildPayment, "ArtChild Payment Send failed");

        // 60% to the Artist
        (bool artistPayment, ) = payable(artistAddress).call{ value: artPayment }("");
        require(artistPayment, "Art Child Send failed");
    }

}