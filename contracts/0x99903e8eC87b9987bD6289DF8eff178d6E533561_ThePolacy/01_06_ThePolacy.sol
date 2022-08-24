pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract ThePolacy is Ownable, ERC721A("ThePolacy", "TPL") {

    uint256 constant public TOTAL_SUPPLY = 2137;
    uint256 constant public PRICE = 0.02 ether;

    uint256 constant public MAX_TOKENS_PER_ADDRESS_WHITELIST = 2;
    uint256 constant public SUPPLY_WHITELIST = 540;
    uint256 constant public DURATION_WHITELIST = 8 hours;
    
    uint256 constant public MAX_TOKENS_PER_ADDRESS_PUBLIC_FREE_MINT = 5;
    uint256 constant public SUPPLY_PUBLIC_FREE_MINT = 997;
    uint256 constant public DURATION_PUBLIC_FREE_MINT = 24 hours;

    uint256 constant public SUPPLY_TEAM = 100;

    uint256 immutable public mintStartTime;
    bytes32 immutable private merkleRoot;

    string private _baseTokenURI = "";



    constructor(bytes32 root, uint256 mintStart)
    {
        merkleRoot = root;
        mintStartTime = mintStart;
        for (uint i = 0; i < SUPPLY_TEAM / 5; i++) {
            _safeMint(owner(), 5); // Opensea doesn't catch NFTs minted in batches larger than 8, 5 is for nice division
        }
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory _tokenURI = super.tokenURI(tokenId);
        return
            bytes(_tokenURI).length > 0
                ? string(abi.encodePacked(_tokenURI, ".json"))
                : "";
    }

    function verify(bytes32[] memory proof) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    function isMintingPhaseWL() public view returns(bool) {
        return block.timestamp < mintStartTime + DURATION_WHITELIST && _totalMinted() < SUPPLY_TEAM + SUPPLY_WHITELIST;
    }

    function isMintingPhaseFreePublic() public view returns(bool) {
        return !isMintingPhaseWL() && block.timestamp < mintStartTime + DURATION_WHITELIST + DURATION_PUBLIC_FREE_MINT && _totalMinted() < SUPPLY_TEAM + SUPPLY_WHITELIST + SUPPLY_PUBLIC_FREE_MINT;
    }

    function mint(uint256 quantity, bytes32[] memory proof) external payable {
        require(block.timestamp >= mintStartTime, "Mint not started yet.");
        require(quantity > 0, "Quantity must be a positive number.");
        require(totalSupply() + quantity <= TOTAL_SUPPLY, "Requested amount over total supply.");
        if (isMintingPhaseWL()) {
            // Whitelist phase
            require(verify(proof), "Address not whitelisted.");
            require(numberMinted(msg.sender) + quantity <= MAX_TOKENS_PER_ADDRESS_WHITELIST, "Token limit reached for this address.");
            _safeMint(msg.sender, quantity);
        } else if (isMintingPhaseFreePublic()) {
            // Free public mint phase
            require(numberMinted(msg.sender) + quantity <= MAX_TOKENS_PER_ADDRESS_PUBLIC_FREE_MINT, "Token limit reached for this address.");
            _safeMint(msg.sender, quantity);
        } else {
            // Paid public mint phase
            require(quantity <= 8, "Can't mint more than 8 tokens at once.");
            require(msg.value >= PRICE * quantity, "Invalid ETH amount.");
            _safeMint(msg.sender, quantity);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }


    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}