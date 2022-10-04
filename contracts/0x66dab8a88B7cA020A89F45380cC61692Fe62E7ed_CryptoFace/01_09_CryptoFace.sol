// SPDX-License-Identifier: MIT

/*
    By owning this NFT you are agreeing to CryptoFace Terms of Services and Privacy Policy. 
    1. CryptoFace Terms of Services [https://cryptoface.me/terms.pdf]
    2. CryptoFace Privacy Policy [https://cryptoface.me/policy.pdf]
*/

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface Avatars {
    function register(string calldata shapes, string calldata colorsPrimary, string calldata colorsSecondary, string calldata positions) external returns (bytes32 avatarHash);
    function get(bytes32 avatarHash) external view returns (bytes32 shapes, bytes32 colorsPrimary, bytes32 colorsSecondary, bytes32 positions);
}

interface RoyaltyContract {
    function setLastTokenTransferred(uint256 token, address artist) external;
}

interface AlternateURI {
    function getURI(uint256 token) external view returns (string memory);
}

contract CryptoFace is Ownable, ERC721A {

    //Events
    event TokenClaimed(address owner, uint256 tokenId, bytes32 avatarHash, string shapes);
    event IlluminatiTokenUsed(address _contract, uint256 tokenId);
    event GoblinUsed(uint256 token);
    event DaoMinted(uint256 token);
    event PreMint(uint256 token);

    //Enums
    enum ClaimStatus { CLOSED, ALLOWLIST }

    //Mint data
    ClaimStatus public claimStatus = ClaimStatus.CLOSED;

    bool alternateURI = false;
    address alternateAddress;

    uint256 constant MAX_SUPPLY = 10000;

    //Original contract
    Avatars avatars = Avatars(0x5e49Ec3fBD55e7b86A5a5b1a32C73AA44b42B4AF); 

    //Maps
    mapping(uint256 => bytes32) public tokenToAvatar;
    mapping(bytes32 => bool) private usedHash;
    mapping(address => bool) private usedHashPremint;
    mapping(address => mapping(uint256 => bool)) public usedIlluminati;
    mapping(address => bool) private addressMinted;
    mapping(bytes32 => TokenData) public tokenToArtist;
    mapping(address => uint256) public allowlist;

    //Addresses
    address private signer = 0xFD66dd3c6c47bad030f4B93212711A3367E4f44B;
    address private daoWallet;
    address private illuminatiNFT;
    address private the187NFT;
    address private royaltyContract;

    string private URI;

    struct TokenData {
        uint32 tokenId;
        address artist;
    }

    constructor() ERC721A("CryptoFace", "FACE") {}

    function verify(bytes32 hash, bytes memory signature) internal view returns (bool) {
        return ECDSA.recover(hash, signature) == signer;
    }

    /// @notice Checks inputs are valid before minting
    /// @param shapes shapes of the avatar
    /// @param colorsPrimary primary colors of the avatar
    /// @param colorsSecondary secondary colors of the avatar
    /// @param positions positions of the shapes (Not used for this collection)
    function _checkValid(
        string calldata shapes,
        string calldata colorsPrimary,
        string calldata colorsSecondary,
        string calldata positions,
        bytes memory signature
    ) internal {
        bytes32 hash = ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(msg.sender, shapes, colorsPrimary, colorsSecondary, positions)));
        require(!usedHash[hash], "Already used hash");
        require(verify(hash, signature), "Invalid Signature");
        usedHash[hash] = true;
    }

    /// @notice Mint for an avatar for illuminati holders
    /// @param shapes shapes of the avatar
    /// @param colorsPrimary primary colors of the avatar
    /// @param colorsSecondary secondary colors of the avatar
    /// @param positions positions of the shapes (Not used for this collection)
    /// @param tokenId tokenId of the illuminati NFT used for mint
    /// @param isIlluminati true if using Illuminati NFT false if using The187 NFT
    function illuminatiMint(
        string calldata shapes,
        string calldata colorsPrimary,
        string calldata colorsSecondary,
        string calldata positions,
        bytes memory signature,
        uint256 tokenId,
        bool isIlluminati
    ) public {
        if(msg.sender != daoWallet && msg.sender != owner()) {
        require(claimStatus != ClaimStatus.CLOSED, "Illuminati Mint Closed");
        }
        require(_totalMinted() + 1 <= MAX_SUPPLY, "Mint is over");
        require(tx.origin == msg.sender, "No contracts");

        address requiredNFTAddress = isIlluminati ? illuminatiNFT : the187NFT;
        require(msg.sender == IERC721(requiredNFTAddress).ownerOf(tokenId), "Not owner");
        require(!usedIlluminati[requiredNFTAddress][tokenId], "Already used token");
        
        usedIlluminati[requiredNFTAddress][tokenId] = true;

        emit IlluminatiTokenUsed(requiredNFTAddress, tokenId);

        _checkValid(shapes, colorsPrimary, colorsSecondary, positions, signature);

        _mintAvatar(shapes, colorsPrimary, colorsSecondary, positions);
    }

    /// @notice Premint mint for an avatar
    /// @param shapes shapes of the avatar
    /// @param colorsPrimary primary colors of the avatar
    /// @param colorsSecondary secondary colors of the avatar
    /// @param positions positions of the shapes (Not used for this collection)
    function premintMint(
        string calldata shapes,
        string calldata colorsPrimary,
        string calldata colorsSecondary,
        string calldata positions,
        bytes memory signature,
        bytes calldata _voucher
    ) public {
        require(claimStatus != ClaimStatus.CLOSED, "Allowlist closed");
        require(_totalMinted() + 1 <= MAX_SUPPLY, "Mint is over");
        require(tx.origin == msg.sender, "No contracts");
        
        bytes32 hashAllowed = ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(msg.sender)));
        require(verify(hashAllowed, _voucher), "Not on allowlist");

        require(!usedHashPremint[msg.sender],"Already Minted");

        emit PreMint(_totalMinted());

        _checkValid(shapes, colorsPrimary, colorsSecondary, positions, signature);

        usedHashPremint[msg.sender] = true;

        _mintAvatar(shapes, colorsPrimary, colorsSecondary, positions);

    }


    /// @notice allowlist mint for an avatar
    /// @param shapes shapes of the avatar
    /// @param colorsPrimary primary colors of the avatar
    /// @param colorsSecondary secondary colors of the avatar
    /// @param positions positions of the shapes (Not used for this collection)
    function allowlistMint(
        string calldata shapes,
        string calldata colorsPrimary,
        string calldata colorsSecondary,
        string calldata positions,
        bytes memory signature
    ) public {
        require(_totalMinted() + 1 <= MAX_SUPPLY, "Mint is over");

        if(msg.sender != daoWallet && msg.sender != owner()) {
            require(tx.origin == msg.sender, "No contracts");
            require(claimStatus != ClaimStatus.CLOSED, "Allowlist closed");
            require(allowlist[msg.sender] > 0, "Not on allowlist");
            allowlist[msg.sender] -= 1;

            emit GoblinUsed(_totalMinted());
        } else {
            emit DaoMinted(_totalMinted());
        }

        _checkValid(shapes, colorsPrimary, colorsSecondary, positions, signature);

        _mintAvatar(shapes, colorsPrimary, colorsSecondary, positions);
    }

    /// @notice Mints the avatar on the original contract and mints a proof of ownership for it
    /// @param shapes shapes of the avatar
    /// @param colorsPrimary primary colors of the avatar
    /// @param colorsSecondary secondary colors of the avatar
    /// @param positions positions of the shapes (Not used for this collection)
    function _mintAvatar(
        string calldata shapes,
        string calldata colorsPrimary,
        string calldata colorsSecondary,
        string calldata positions
    ) internal {

        bytes32 avatarHash = avatars.register(shapes, colorsPrimary, colorsSecondary, positions);

        uint256 tokenId = _totalMinted();

        tokenToAvatar[tokenId] = avatarHash;

        bytes32 shapesBytes;

        (shapesBytes, , , ) = avatars.get(avatarHash);

        tokenToArtist[shapesBytes] = TokenData({
            artist: msg.sender,
            tokenId: uint32(tokenId)
        });

        _safeMint(msg.sender, 1);

        emit TokenClaimed(msg.sender, tokenId, avatarHash, shapes);
    }

    function getTokenData(string calldata shapes) external view returns (address, uint32) {

        bytes32 shapesBytes = bytes32(bytes(shapes));

        TokenData memory data = tokenToArtist[shapesBytes];

        return (data.artist, data.tokenId);
    }

    function hasPreMinted(address _address) external view returns (bool) {
        return usedHashPremint[_address];
    }

    /// @notice Grabs data from original avatar contract based on ownership of token to hash
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {

        if(alternateURI) return AlternateURI(alternateAddress).getURI(tokenId);

        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        bytes32 avatarHash = tokenToAvatar[tokenId];
        
        bytes32 shapes;

        (shapes, , , ) = avatars.get(avatarHash);

        return string(abi.encodePacked(URI, shapes));
    }

    function setClaimStatus(ClaimStatus status) public onlyOwner {
        claimStatus = status;
    }

    function setAlternateURI(address _contract, bool _state) public onlyOwner {
        alternateURI = _state;
        alternateAddress = _contract;
    }

    function setBaseURI(string memory base) public onlyOwner {
        URI = base;
    }

    function setSigner(address _address) public onlyOwner {
        signer = _address;
    }

    function setDAOWallet(address _address) public onlyOwner {
        daoWallet = _address;
    }

    function setAvatarContract(address _address) public onlyOwner {
        avatars = Avatars(_address);
    }

    function setNFTContracts(address _illuminatiNFT, address _the187NFT) public onlyOwner {
        illuminatiNFT = _illuminatiNFT;
        the187NFT = _the187NFT;
    }

    function setRoyaltyContract(address _address) public onlyOwner {
        royaltyContract = _address;
    }

    function addAllowlist(address[] calldata addresses, uint256 allowedMints) public onlyOwner {
        for(uint i = 0; i < addresses.length; i++)
            allowlist[addresses[i]] += allowedMints;
    }

    function setNewArtistAddress(uint256 token, address newArtist) public {
        require(newArtist != address(0), "Ooops");
        
        bytes32 avatarHash = tokenToAvatar[token];
        (bytes32 shapes, , , ) = avatars.get(avatarHash);
        TokenData storage data = tokenToArtist[shapes];

        require(msg.sender == data.artist, "Not artist");

        data.artist = newArtist;
    }

    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {

        if(royaltyContract != address(0) && from != address(0)) {
            bytes32 avatarHash = tokenToAvatar[startTokenId];
    
            (bytes32 shapes, , , ) = avatars.get(avatarHash);

            TokenData memory data = tokenToArtist[shapes];

            //Low level call so no possibility of future reverts on transfers
            (bool t,) = royaltyContract.call(abi.encodeWithSignature("setLastTokenTransferred(uint256,address)", data.tokenId, data.artist));

            if(t) { /* Contract called */ }
        }

        super._afterTokenTransfers(from, to, startTokenId, quantity);
    }

}