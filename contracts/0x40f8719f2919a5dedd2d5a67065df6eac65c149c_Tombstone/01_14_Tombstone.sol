// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface IKlub {
    function burnFrom(address account, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
}

/// @title Tombstone
/// @author Burn0ut#8868 [email protected]
/// @notice https://www.thedeadarmyskeletonklub.army/ https://twitter.com/The_DASK
contract Tombstone is ERC721A, Ownable {

    uint public constant MAX_TOKENS = 6969;
    uint public constant MAX_PER_MINT = 100;
    IKlub public klub = IKlub(0xa0DB234a35AaF919b51E1F6Dc21c395EeF2F959d);

    mapping(address => bool) public tombClaimed;
    uint public KLUBS_PER_TOMB = 250 * 1 ether;

    string public baseURI = "https://theklubrises.mypinata.cloud/ipfs/QmP2ULbYpfaFWBtJVuTPeN3yWACVdXayM8Gi4Kvs3kCj7t/";
    bytes32 public merkleRoot = 0xc82b540414903df41b0dfd84b4b704f9e14836befdc8f5d30ba6cc5cb241671c;

    constructor() ERC721A("Tombstone", "TOMB", 100) {
    }

    function setKlubsPerTomb(uint _KLUBS_PER_TOMB) external onlyOwner {
        KLUBS_PER_TOMB = _KLUBS_PER_TOMB * 1 ether;
    }

    function setKlubAddress(address _klub) external onlyOwner {
        klub = IKlub(_klub);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint tokenId) public view virtual override returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function claim(uint tokens, bytes32[] calldata merkleProof) external {
        require(tokens <= MAX_PER_MINT, "TOMB: Invalid number of tombs");
        require(totalSupply() + tokens <= MAX_TOKENS, "TOMB: Minting would exceed max supply");
        require(!tombClaimed[_msgSender()], "TOMB: already claimed");
        require(MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encode(msg.sender, tokens))), "TOMB: not eligible to claim");
        tombClaimed[_msgSender()] = true;
        _safeMint(_msgSender(), tokens);
    }

    function mintWithKLUB(uint tokens) external {
        require(tokens <= MAX_PER_MINT, "TOMB: Invalid number of tombs");
        require(totalSupply() + tokens <= MAX_TOKENS, "TOMB: Minting would exceed max supply");
        require(klub.balanceOf(_msgSender()) >= tokens * KLUBS_PER_TOMB, "TOMB: Insufficent KLUB balance");
        klub.burnFrom(_msgSender(), tokens * KLUBS_PER_TOMB);
        _safeMint(_msgSender(), tokens);
    }


    function ownerMint(address to, uint tokens) external onlyOwner {
        require(totalSupply() + tokens <= MAX_TOKENS, "TOMB: Minting would exceed max supply");
        require(tokens > 0, "TOMB: Must mint at least one token");

        _safeMint(to, tokens);
    }

}