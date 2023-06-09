//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/// @title SixthRéseau Lucidia Dreams Contract
/// @author SphericonIO
contract SixthReseauLucidiaDreams is ERC1155Supply, Ownable {
    using SafeMath for uint256;
    using ECDSA for bytes32;

    string public _baseTokenUri;

    string public name = "Sixth Reseau Lucidia Dream";
    string public symbol = "SRLD";

    address public signer;

    uint public maxSupply = 1000;

    mapping(address => bool) private _minted;

    constructor(string memory _uri) 
    ERC1155(_uri){
        setSigner(0x34527c295252C2cdF8F760E09CC37db7759F1b4C);
        setBaseTokenURI(_uri);
    }

    /// @notice Claim Lucidia Dreams tokens, caller must be whitelisted
    /// @param _signature Signature to verify is eligible to claim
    function claim(bytes memory _signature) public {
        require(totalSupply(1).add(1) < maxSupply, "Lucidia Dreams: Max supply is reached");
        require(!_minted[msg.sender], "Lucidia Dreams: You have already minted your Lucidia Dreams token");
        require(canClaim(_signature), "Lucidia Dreams: You are not elgible to claim a Lucidia Dreams token");
        _minted[msg.sender] = true;
        _mint(msg.sender, 1, 1, "");
    }

    /// @notice Verify provided signature
    /// @param _signature Signature to verify is eligible to claim
    function canClaim(bytes memory _signature) public view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(msg.sender));
        bytes32 messageHash = hash.toEthSignedMessageHash();
        return messageHash.recover(_signature) == signer;
    }

    /// @notice Mint Lucidia Dream tokens to an address
    /// @param _to Address tokens get minted to
    /// @param _amount Amount of tokens to mint
    function reserveMint(address _to, uint _amount) external onlyOwner {
        _mint(_to, _amount, 1, "");
    }

    /// @notice Set the URI of the metadata
    /// @param _uri New metadata URI
    function setBaseTokenURI(string memory _uri) public onlyOwner {
        _baseTokenUri = _uri;
    }

    /// @notice Set the signer for eligible signature verification
    /// @param _signer New signer's address
    function setSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    /// @notice Metadata of each token
    /// @param _tokenId Token id to get metadata of
    /// @return Metadata URI of the token
    function uri(uint256 _tokenId) public view override returns (string memory) {
        require(exists(_tokenId), "URI: nonexistent token");
        return string(abi.encodePacked(abi.encodePacked(_baseTokenUri, Strings.toString(_tokenId)), ".json"));
    }
}