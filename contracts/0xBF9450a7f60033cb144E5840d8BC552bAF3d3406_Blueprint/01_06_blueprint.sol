// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.14;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Blueprint is ERC721A, Ownable {
    
    string public baseURI = "ipfs://QmXJ3Ne3DpXeFto89uHKFtqLRnv8rsetzD9GkDLrqafPSd";
    
    bytes32 public merkleRoot = 0x8a9003cc6417c0c5fe9e34b69ae570bdbe4b70d5d8f0a4683c26978a4a2d984c;

    uint MAX_BLUEPRINTS = 450;
    
    mapping(address => bool) public used;

    bool public WHITELIST_STARTED = false;
    bool public PUBLIC_STARTED = false;

    uint public totalBlueprints = 0;

    constructor() ERC721A("Blueprint", "BP") {}

    function setBaseURI(string memory base) public onlyOwner {
        baseURI = base;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A) returns (string memory) {
        return baseURI;
    }

    function flipWhitelist() public onlyOwner {
        WHITELIST_STARTED = !WHITELIST_STARTED;
    }

    function flipPublic() public onlyOwner {
        PUBLIC_STARTED = !PUBLIC_STARTED;
    }

    function setMerkleRoot(bytes32 _root) public onlyOwner {
        merkleRoot = _root;
    }

    function whitelistMint(bytes32[] calldata _proof) public payable{
        require(WHITELIST_STARTED, "Sale is not started");
        require(msg.value == 0.1 ether, "Mint price is 0.1 ETH");

        require(totalBlueprints + 1 < MAX_BLUEPRINTS, "All blueprints have already been minted!");
        require(MerkleProof.verify(_proof,merkleRoot,keccak256(abi.encodePacked(msg.sender))),"Invalid proof.");
        require(!used[msg.sender],"Proof already used");
        _safeMint(msg.sender, 1);

        used[msg.sender] = true;
        totalBlueprints++;
    }


    function mint() public payable{
        require(PUBLIC_STARTED, "Sale is not started");
        require(msg.value == 0.1 ether, "Mint price is 0.1 ETH");
        require(msg.sender == tx.origin);

        require(totalBlueprints + 1 < MAX_BLUEPRINTS, "All blueprints have already been minted!");
        require(!used[msg.sender],"Max per wallet (1) reached");
        _safeMint(msg.sender, 1);

        used[msg.sender] = true;
        totalBlueprints++;
    }

    function ownerMint(uint amount) public onlyOwner {
        require(totalBlueprints + amount < MAX_BLUEPRINTS, "All blueprints have already been minted!");
        _safeMint(msg.sender,amount);
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function addSupply(uint amount) public onlyOwner{
        MAX_BLUEPRINTS = MAX_BLUEPRINTS + amount;
    }
}