// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {ERC721 as ERC721S} from "@rari-capital/solmate/src/tokens/ERC721.sol";
import "@rari-capital/solmate/src/auth/Auth.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC2981V2.sol";


/// @title The Quantum Unlocked. Speciality drops for the quantum keys are released here
/// @author jcbdev
contract QuantumUnlocked is ERC721S, ERC2981, Auth {
    using Strings for uint256;
    using BitMaps for BitMaps.BitMap;

    /// >>>>>>>>>>>>>>>>>>>>>>>  EVENTS  <<<<<<<<<<<<<<<<<<<<<<<<<< ///

    event DropMint(address indexed to, uint256 indexed dropId, uint256 indexed variant, uint256 id);

    /// >>>>>>>>>>>>>>>>>>>>>>>  STATE  <<<<<<<<<<<<<<<<<<<<<<<<<< ///

    mapping (uint128 => string) public dropCID;
    mapping (uint128 => uint128) public dropSupply;
    mapping (uint256 => uint256) public tokenVariant;

    string private _baseURI = "https://core-api.quantum.art/v1/metadata/unlocked/";
    string private _ipfsURI = "ipfs://";
    address private _minter;

    /// >>>>>>>>>>>>>>>>>>>>>  CONSTRUCTOR  <<<<<<<<<<<<<<<<<<<<<< ///

	/// @notice Deploys QuantumUnlocked
    /// @dev Initiates the Auth module with no authority and the sender as the owner
    /// @param owner The owner of the contract
    /// @param authority address of the deployed authority
    constructor(address owner, address authority) ERC721S("QuantumUnlocked", "QKU") Auth(owner, Authority(authority)) {
        _baseURI = "https://core-api.quantum.art/v1/metadata/unlocked/";
        _ipfsURI = "ipfs://";
    }

    /// >>>>>>>>>>>>>>>>>>>>>  INTERNAL  <<<<<<<<<<<<<<<<<<<<<< ///
    /// @notice get the token id from the drop id and sequence number
    /// @param dropId The drop id
    /// @param sequence the sequence number of the minted token within the drop 
    /// @return tokenId the combined token id 
    function _tokenId(uint128 dropId, uint128 sequence) internal pure returns (uint256 tokenId) {
        tokenId |= uint256(dropId) << 128;
        tokenId |= uint256(sequence);
        return tokenId;
    }

    /// @notice extract the drop id and the sequence number from the token id
    /// @param tokenId The token id to extract the values from
    /// @return uint128 the drop id
    /// @return uint128 the sequence number
    function _splitTokenId(uint256 tokenId) internal pure returns (uint128, uint128) {
        return (uint128(tokenId >> 128), uint128(tokenId));
    }

    /// >>>>>>>>>>>>>>>>>>>>>  RESTRICTED  <<<<<<<<<<<<<<<<<<<<<< ///

    /// @notice set address of the minter
    /// @param minter The address of the minter - should be Sales Platform
    function setMinter(address minter) public requiresAuth {
        _minter = minter;
    }

    /// @notice set the baseURI
    /// @param baseURI new base
    function setBaseURI(string calldata baseURI) public requiresAuth {
        _baseURI = baseURI;
    }

    /// @notice set the base ipfs URI
    /// @param ipfsURI new base
    function setIpfsURI(string calldata ipfsURI) public requiresAuth {
        _ipfsURI = ipfsURI;
    }

    /// @notice set the IPFS CID
    /// @param dropId The drop id
    /// @param cid cid
    function setCID(uint128 dropId, string calldata cid) public requiresAuth {
        dropCID[dropId] = cid;
    }

    /// @notice sets the recipient of the royalties
    /// @param recipient address of the recipient
    function setRoyaltyRecipient(address recipient) public requiresAuth {
        _royaltyRecipient = recipient;
    }

    /// @notice sets the fee of royalties
    /// @dev The fee denominator is 10000 in BPS.
    /// @param fee fee
    /*
        Example

        This would set the fee at 5%
        ```
        KeyUnlocks.setRoyaltyFee(500)
        ```
    */
    function setRoyaltyFee(uint256 fee) public requiresAuth {
        _royaltyFee = fee;
    }

    /// @notice Mints new tokens
    /// @dev there is no check regarding limiting supply
    /// @param to recipient of newly minted tokens
    /// @param dropId id of the key
    function mint(address to, uint128 dropId, uint256 variant) public returns (uint256) {
        require(msg.sender == owner || msg.sender == _minter, "NOT_AUTHORIZED");

        dropSupply[dropId] += 1;
        uint256 tokenId = _tokenId(dropId, uint128(dropSupply[dropId]));
        _safeMint(to, tokenId);
        if (variant > 0) {
            tokenVariant[tokenId] = variant;
        }
        emit DropMint(to, dropId, variant, tokenId);
        return tokenId;
    }

    /// @notice Burns token that has been redeemed for something else
    /// @dev Sales platform only
    /// @param tokenId id of the tokens
    function redeemBurn(uint256 tokenId) public requiresAuth {
        _burn(tokenId);
    }

    /// >>>>>>>>>>>>>>>>>>>>>  VIEW  <<<<<<<<<<<<<<<<<<<<<< ///

    /// @notice Returns the URI of the token
    /// @param tokenId id of the token
    /// @return URI for the token ; expected to be ipfs://<cid>
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        (uint128 dropId, uint128 sequenceNumber) = _splitTokenId(tokenId);
        uint256 actualSequence = tokenVariant[tokenId] > 0 ? tokenVariant[tokenId] : sequenceNumber;
        if (bytes(dropCID[dropId]).length > 0)
            return string(abi.encodePacked(_ipfsURI, dropCID[dropId], "/" , actualSequence.toString()));
        else
            return string(abi.encodePacked(_baseURI, uint256(dropId).toString(), "/" , actualSequence.toString()));
    }

    /// >>>>>>>>>>>>>>>>>>>>>  EXTERNAL  <<<<<<<<<<<<<<<<<<<<<< ///

    /// @notice Burns token
    /// @dev Can be called by the owner or approved operator
    /// @param tokenId id of the tokens
    function burn(uint256 tokenId) public {
        address owner = ownerOf[tokenId];
        require(
            msg.sender == owner || msg.sender == getApproved[tokenId] || isApprovedForAll[owner][msg.sender],
            "NOT_AUTHORIZED"
        );
        _burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public pure virtual override(ERC721S, ERC2981) returns (bool) {
        return ERC721S.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
}