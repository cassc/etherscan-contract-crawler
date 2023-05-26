// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface EtherID {
    function getDomain(uint domain) external view returns (address owner, uint expires, uint price, address transfer, uint next_domain, uint root_id);
    function changeDomain(uint domain, uint expires, uint price, address transfer) external;
}

contract WrappedEtherID is ERC721, ERC721Enumerable, Ownable {

    event Wrapped(address indexed owner, uint indexed domain);
    event Unwrapped(address indexed owner, uint indexed domain);
    event Renewed(address indexed owner, uint indexed domain);

    EtherID eidInt = EtherID(0x3589d05a1ec4Af9f65b0E5554e645707775Ee43C);

    uint public constant MAX_SUPPLY = 32591;
    uint constant MAX_PROLONG = 2000000;
    bytes32 constant MERKLE_ROOT = 0x6746d1020f165f020b00cc1e00041419c8d6ea28c88d403da7d6dbcc54d6ac97;

    constructor() ERC721("Wrapped Ether ID", "WEID") {}

    // Checks whether an existing token is in a degenerate state.
    function isDegenerate(uint tokenId) public view returns (bool) {
        require(_exists(tokenId), "Token does not exist.");

        (address owner, uint expires, uint price, address transfer, ,) = eidInt.getDomain(tokenId);

        return owner != address(this) || block.number > expires || price > 0 || transfer != address(0);
    }

    // Returns blocks until expiration for a nondegenerate token.
    function blocksUntilExpiration(uint tokenId) public view returns (uint) {
        require(!isDegenerate(tokenId), "Token is in degenerate state.");

        (, uint expires, , , ,) = eidInt.getDomain(tokenId);
        return expires - block.number + 1;
    }

    function wrap(uint domain, bytes32[] calldata merkleProof) external {
        (address owner, uint expires, uint price, address transfer, ,) = eidInt.getDomain(domain);
        require(owner == msg.sender, "You are not the owner.");
        require(block.number <= expires, "Domain has expired.");
        require(price == 0, "Price should be set to zero before wrapping.");
        require(transfer == address(this), "Wrapper contract has not been set as the transfer address.");

        // Make sure the domain is among those registered in 2015-16.
        bytes32 node = keccak256(abi.encode(domain));
        require(MerkleProof.verifyCalldata(merkleProof, MERKLE_ROOT, node), "Domain is not one of the OG domains.");

        eidInt.changeDomain(domain, MAX_PROLONG, 0, address(0));
        if (_exists(domain)) {
            // In case the domain has a corresponding degenerate token.
            _burn(domain);
        }
        _mint(msg.sender, domain);

        emit Wrapped(msg.sender, domain);
    }

    function unwrap(uint tokenId) external {
        require(!isDegenerate(tokenId), "Token is in degenerate state.");
        require(msg.sender == ownerOf(tokenId), "You are not the owner.");

        eidInt.changeDomain(tokenId, MAX_PROLONG, 0, msg.sender);
        _burn(tokenId);

        emit Unwrapped(msg.sender, tokenId);
    }

    // Anyone is allowed to renew any domain, as long as a token exists and is not degenerate.
    function renew(uint tokenId) external {
        require(!isDegenerate(tokenId), "Token is in degenerate state.");

        eidInt.changeDomain(tokenId, MAX_PROLONG, 0, address(0));

        emit Renewed(msg.sender, tokenId);
    }

    // This override prevents degenerate domains from being transferred.
    function _transfer(address from, address to, uint256 tokenId) internal override {
        require(!isDegenerate(tokenId), "Token is in degenerate state.");

        super._transfer(from, to, tokenId);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://eid.ethyearone.com/";
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}