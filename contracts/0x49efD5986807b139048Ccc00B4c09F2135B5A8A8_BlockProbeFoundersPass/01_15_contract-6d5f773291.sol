// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract BlockProbeFoundersPass is ERC721Enumerable, Ownable {

    enum MintState { CLOSED, PRESALE, PUBLIC }

    /**
     * Constants
     */
    uint256 public constant PUBLIC_PRICE = 0.3 ether; // Price
    uint256 public constant PASS_PRICE = 0.25 ether; // Price
    uint256 public constant MAX_MINTS_PER_ADDRESS = 1; // Max mint
    uint256 public constant MAX_SUPPLY = 555; // Max supply
    uint256 public constant MAX_TEAM = 20; // Allocated for team to partnerships and marketing

    MintState public mintState = MintState.CLOSED;     // Mint state

    bytes32 public merkleRoot;    // Merkle root for founders pass list

    mapping(address => bool) public presalePassClaimed; // Pass List
    mapping(address => uint256) public mintedByAddress; // Mint count

    string private _tokenBaseURI = "https://blockprobe.io/api/v1/tokens/";

    constructor() ERC721("BlockProbe Founders Pass", "BPFP") {
    }

    function presaleMint(bytes32[] calldata _merkleProof) external payable {
        require(mintState == MintState.PRESALE, "Presale is not live");
        require(!presalePassClaimed[msg.sender], "Already claimed");
        require(msg.value >= PASS_PRICE, "Incorrect amount of funds");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Not on the Founders Pass List");

        uint256 currentTokenId = totalSupply() + 1;
        require(
            currentTokenId <= MAX_SUPPLY,
            "Max supply reached"
        );

        presalePassClaimed[msg.sender] = true;

        _mintTo(msg.sender, currentTokenId);
    } 


    function publicMint() external payable {
        require(mintState == MintState.PUBLIC, "Public mint is not live");
        require(
            mintedByAddress[msg.sender] + 1 <= MAX_MINTS_PER_ADDRESS,
            "Max allowed tokens reached"
        );
        require(msg.value >= PUBLIC_PRICE, "Incorrect amount of funds");
        
        uint256 currentTokenId = totalSupply() + 1;
        require(
            currentTokenId <= MAX_SUPPLY,
            "Max supply reached"
        );

        _mintTo(msg.sender, currentTokenId);
    } 

    function _mintTo(address to, uint256 tokenId) internal {
        mintedByAddress[to] += 1;
        _safeMint(to, tokenId);
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _tokenBaseURI;
    }

    function isFoundersOwner(address wallet) public view returns (bool) {
        return balanceOf(wallet) > 0;
    }

    function currentState() external view returns (MintState) {
        return mintState;
    }

    function presaleClaimed(address addr) external view returns (bool) {
        return presalePassClaimed[addr];
    }

    function mintedCount(address addr) external view returns (uint256) {
        return mintedByAddress[addr];
    }


    /*
    Admin
    */
    function teamMint() external onlyOwner {
        
        for (uint256 i = 0; i < MAX_TEAM; i++) {
            _mint(msg.sender, i + 1);
        }
    

        mintState = MintState.PRESALE;
    }

    function setState(uint8 _state) external onlyOwner {
        mintState = MintState(_state);
    }

    function drain(address payable to) external onlyOwner {
        to.transfer(address(this).balance);
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }
}