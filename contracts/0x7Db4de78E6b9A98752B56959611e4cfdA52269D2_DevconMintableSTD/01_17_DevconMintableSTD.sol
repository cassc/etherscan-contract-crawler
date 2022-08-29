// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./library/VerifyAttestation.sol";
import "./library/ERC5169.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract DevconMintableSTD is ERC721Enumerable, VerifyAttestation, ERC5169 {
    using Address for address;
    using Strings for uint256;
        
    string private conferenceID = "55";

    string constant JSON_FILE = ".json";
    string constant __baseURI = "https://resources.smarttokenlabs.com/";
    
    address _attestorKey;
    address _issuerKey;

    event ConferenceIDUpdated(string oldID, string newID);

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, ERC5169) returns (bool) {
        return ERC5169.supportsInterface(interfaceId) || ERC721Enumerable.supportsInterface(interfaceId);
    }
    
    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor () 
    ERC721("Devconnect 2022 Co-Work Ticket Stub", "DEVCONNECT2022") {
        _attestorKey = 0x538080305560986811c3c1A2c5BCb4F37670EF7e;
        _issuerKey = 0x09B6cC1cB661d523Db1F8E854cfbfE2A03100d95;
    }

    function contractURI() public view returns(string memory) {
        return string(abi.encodePacked(__baseURI, "contract/", symbol(), JSON_FILE));
    }

    function updateAttestationKeys(address newattestorKey, address newIssuerKey) public onlyOwner {
        _attestorKey = newattestorKey;
        _issuerKey = newIssuerKey;
    }

    function updateConferenceID(string calldata newValue) public onlyOwner {
        emit ConferenceIDUpdated(conferenceID, newValue);
        conferenceID = newValue;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "DevconMintable: invalid token ID");
        return string(abi.encodePacked(__baseURI, "token/" , block.chainid.toString(), "/", contractAddress(), "/", tokenId.toString(), JSON_FILE));
    }

    function verify(bytes memory attestation) public view returns (address attestor, address ticketIssuer, address subject, bytes memory ticketId, bytes memory conferenceId, bool attestationValid){
        ( attestor, ticketIssuer, subject, ticketId, conferenceId, attestationValid) = _verifyTicketAttestation(attestation);
    }

    function mintUsingAttestation(bytes memory attestation) public returns (uint256 tokenId) {
        address subject;
        bytes memory tokenBytes;
        bytes memory conferenceBytes;
        bool timeStampValid;

        (subject, tokenBytes, conferenceBytes, timeStampValid) = verifyTicketAttestation(attestation, _attestorKey, _issuerKey);
        tokenId = bytesToUint(tokenBytes);

        require(subject != address(0) && tokenId != 0 && timeStampValid && compareStrings(conferenceBytes, conferenceID), "Attestation not valid");
        require(tokenBytes.length < 33, "TokenID overflow");
        _mint(subject, tokenId);
    }
    
    function burn(uint256 tokenId) public {
        require(_exists(tokenId), "DevconMintable: invalid token ID");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "DevconMintable: caller is not token owner nor approved");
        _burn(tokenId);
    }

    function contractAddress() internal view returns (string memory) {
        return Strings.toHexString(uint160(address(this)), 20);
    }
    
    function endContract() public payable onlyOwner {
        selfdestruct(payable(_msgSender()));
    }

    function compareStrings(bytes memory s1, string memory s2) private pure returns(bool) {
        return keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }

}