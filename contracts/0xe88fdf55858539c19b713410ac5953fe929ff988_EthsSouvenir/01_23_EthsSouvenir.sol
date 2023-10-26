// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";

/**
 * @title SignatureChecker
 * @notice This library allows verification of signatures for both EOAs and contracts.
 */
library SignatureChecker {
    /**
     * @notice Recovers the signer of a signature (for EOA)
     * @param hash the hash containing the signed mesage
     * @param v parameter (27 or 28). This prevents maleability since the public key recovery equation has two possible solutions.
     * @param r parameter
     * @param s parameter
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // https://ethereum.stackexchange.com/questions/83174/is-it-best-practice-to-check-signature-malleability-in-ecrecover
        // https://crypto.iacr.org/2019/affevents/wac/medias/Heninger-BiasedNonceSense.pdf
        require(
            uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "Signature: Invalid s parameter"
        );

        require(v == 27 || v == 28, "Signature: Invalid v parameter");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "Signature: Invalid signer");

        return signer;
    }

    /**
     * @notice Returns whether the signer matches the signed message
     * @param hash the hash containing the signed mesage
     * @param signer the signer address to confirm message validity
     * @param v parameter (27 or 28)
     * @param r parameter
     * @param s parameter
     * @param domainSeparator paramer to prevent signature being executed in other chains and environments
     * @return true --> if valid // false --> if invalid
     */
    function verify(
        bytes32 hash,
        address signer,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 domainSeparator
    ) internal view returns (bool, bytes32) {
        // \x19\x01 is the standardized encoding prefix
        // https://eips.ethereum.org/EIPS/eip-712#specification
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, hash));
        if (Address.isContract(signer)) {
            // 0x1626ba7e is the interfaceId for signature contracts (see IERC1271)
            return (IERC1271(signer).isValidSignature(digest, abi.encodePacked(r, s, v)) == 0x1626ba7e, digest);
        } else {
            return (recover(digest, v, r, s) == signer, digest);
        }
    }
}

contract EthsSouvenir is ERC721Royalty, Ownable, EIP712{
    event EthsSouvenirMinted(uint256 indexed id, address indexed to, string domainHash);

    bytes32 internal constant SIGNATURE_MINT_HASH = keccak256(
            "mint(string[] domainHashes,address minter)"
        );

    address public verifier;

    uint256 public total;

    mapping(uint256 => string) private domainMapping;
    mapping(bytes32 => bool) private records;

    string public baseURI;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_, string memory version_, string memory baseURI_) ERC721(name_, symbol_) EIP712(name_, version_){
        verifier = _msgSender();
        _setDefaultRoyalty(_msgSender(), 500);
        baseURI = baseURI_;
    }

    function updateVerifier(address verifier_) external onlyOwner{
        verifier = verifier_;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner{
        baseURI = baseURI_;
    }

    function mint(string[] memory domainHashes, bytes calldata signature) external{
        // check signature
        {
            bytes32 digest = keccak256(abi.encode(SIGNATURE_MINT_HASH, domainHashes, _msgSender()));
            (bytes32 r, bytes32 s, uint8 v) = _splitSignature(signature);
            (bool isValid, ) = SignatureChecker.verify(digest, verifier, v, r, s, _domainSeparatorV4());
            require(isValid, "InvalidSignature");
        }
        bytes32 domiansHash = keccak256(abi.encode(domainHashes));
        require(!records[domiansHash], "Domains were minted");
        records[domiansHash] = true;
        for(uint i = 0; i < domainHashes.length; i++){
            total++;
            domainMapping[total] = domainHashes[i];
            // _mint
            _safeMint(_msgSender(), total);
            emit EthsSouvenirMinted(total, _msgSender(), domainHashes[i]);
        }
        
    }

    function _splitSignature(bytes memory signature) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(signature.length == 65, "InvalidSignature"); 

        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        return string(abi.encodePacked(baseURI, domainMapping[tokenId], ".json"));
    }
}