// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract NVS is ERC721A, Ownable {
    using Strings for uint256;

    enum Mode { NOT_LIVE, PRESALE_DAY_ONE, PRESALE_GENERAL_LIVE, PUBLIC_LIVE }

    uint256 public constant JF_SUPPLY = 1440;
    uint256 public constant JF_PRICE = 0.5 ether;

    bytes32 public merkleRootForDayOne;
    bytes32 public merkleRootForGeneral;
    
    Mode public mode;
    string public baseURI;
    bool public revealed;
    mapping(bytes32 => bool) _nonceUsed;
 
    constructor() ERC721A("Night Vision Series", "NVS") {
        _safeMint(address(this), 1);
        _burn(0);
    }

    function mint(uint256 amount, bytes32[] calldata _merkleProof) external payable {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(mode != Mode.NOT_LIVE, "AOI//NOT_LIVE");
        require(msg.sender == tx.origin, "AOI//ONLY_EOA_WALLETS");

        if(mode != Mode.PUBLIC_LIVE) {
            require(MerkleProof.verify(_merkleProof, mode == Mode.PRESALE_DAY_ONE ? merkleRootForDayOne : merkleRootForGeneral, leaf), "AOI//INCORRECT_PROOF");
        }

        require(totalSupply() + amount <= JF_SUPPLY, "AOI//SOLD_OUT");
        require(amount <= (mode == Mode.PRESALE_GENERAL_LIVE ? 2 : 3), "AOI//MAX_PER_TX_HIT");
        require(msg.value >= JF_PRICE * amount, "AOI//INSUFFICIENT_ETH_SENT");

        if(mode == Mode.PRESALE_DAY_ONE) {
            require(totalSupply() <= 1000, "AOI//DAY_ONE_SOLD_OUT");
            require(_numberMinted(msg.sender) + amount <= 3, "AOI//Exceeds Max Per Wallet");
        }

        if(mode == Mode.PRESALE_GENERAL_LIVE) {
            require(_numberMinted(msg.sender) + amount <= 2, "AOI//Exceeds Max Per Wallet");
        }
        
        _safeMint(msg.sender, amount);
    }

    function setSaleState(Mode _mode) external onlyOwner {
        mode = _mode;
    }

    function setBaseURI(string memory _newURI) external onlyOwner {
        baseURI = _newURI;
    }

    function withdraw() external onlyOwner {
        payable(0x2ae6fb08730f15143Ac17b0020b7d85d25A1E780).transfer(address(this).balance);
    }

    function toggleReveal() external onlyOwner {
        revealed = true;
    }

    function setMerkleRootDayOne(bytes32 _root) external onlyOwner {
        merkleRootForDayOne = _root;
    }

    function setMerkleRootGeneral(bytes32 _root) external onlyOwner {
        merkleRootForGeneral = _root;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory)
    {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        if(!revealed) {
            return _baseURI();
        }

        return string(abi.encodePacked(_baseURI(), "/", _tokenId.toString()));
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}