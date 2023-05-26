pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract NiftyPistol is ERC721("NiftyPistol", "PISTOL"), Ownable {
    address private signer;
    string public baseURI = "http://nifty-island-pistol-drop-public.s3-website.us-east-2.amazonaws.com/";
    string private _contractMetadataURI = "pistolContract.json";

    constructor (address _signer) {
        signer = _signer;
    }

    function updateSigner(address newSigner) external onlyOwner {
        signer = newSigner;
    }

    /**
        in the extraBytes you can pass in a boolean to determine whether this is to
        be dropped or auctioned, and minting logic is hanlded accordingly
     */
    function mint(address to, uint256 tokenId, bytes memory extraBytes)
        external {
        (bool drop, bytes memory signature) = abi.decode(extraBytes, (bool, bytes));

        if (drop) {
            bytes32 hash = ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(to, tokenId)));
            require(ECDSA.recover(hash, signature) == signer, "Signature failed to recover");
        } else {
            require(msg.sender == owner() || super.isApprovedForAll(owner(), msg.sender), "msg.sender is not authorized to mint");
        }

        _safeMint(to, tokenId);
    }

    function updateBaseURI(string memory newURI) external onlyOwner {
        baseURI = newURI;
    }

    function contractURI() public view returns (string memory) {
        string memory base = baseURI;
        return bytes(base).length > 0 ? string(abi.encodePacked(base, _contractMetadataURI)) : ""; 
    }

    function updateContractURI(string memory newURI) external onlyOwner {
        _contractMetadataURI = newURI;
    }

    function exists(uint256 tokenId) public view returns(bool) {
        return _exists(tokenId);
    }
    
    function _baseURI() internal view override returns(string memory) {
        return baseURI;
    }
}