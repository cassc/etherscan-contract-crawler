//SPDX-License-Identifier: BSD 
pragma solidity ^0.8.0;

import "@ERC721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/////////////////////////////////////

contract ShlongTards is ERC721A, Ownable, ReentrancyGuard {
    // will be replaced before deploy
    address public constant splitterContract = 0x439FF71847D6Ec184A09CF93d45461Df56B84302;
    uint16 private max_total_mints = 8000;

    // tard
    mapping (address => uint16) private user_num_tard_claimed;
    uint16 public constant MAX_TARDS_PER_USER = 25;
    bytes32 private merkle_tard = 0x20f824e8a47af1a7abd4e098cec1a02a98e50c7587c861607004d37b32d965ce;

    // whitelist/free claim
    uint16 private MAX_FREE_CLAIMS = 2000;
    uint16 public constant MAX_CLAIMS_PER_USER = 2;
    uint16 private num_free_claims;
    mapping (address => uint16) private user_num_free_claimed;
    bytes32 private merkle_free = 0x37a3c642a53bede31f9cee0d31aa9be04ab8610dde5b7f3e4e5b5a9f6d45a3fa;

    // public
    uint16 public constant MAX_MINTS_PER_USER = 15;
    uint16 private num_minted;
    mapping (address => uint16) private user_num_minted;
    uint256 private mint_price_public = 0.0152 ether; // ~20USD per (on Sat)

    bool private halt_mint = true;
    bool private is_revealed;
    string private URI = "ipfs://QmYTVf1NKZDoauedNrRdo3iZaySbm3jFqNPii8RotFfnyF";

    constructor() public ERC721A("ShlongTards", "STD") {}

    // seperate functions easier on FE
    // could collapse into one and do an if check based on an enum
    function claimTard(uint256 quantity, bytes32[] memory proof) external nonReentrant {
        require(halt_mint == false, "halted");
        require(MerkleProof.verify(proof, merkle_tard, keccak256(abi.encodePacked(msg.sender))), "not on PL"); 
        require((num_free_claims + uint16(quantity)) <= MAX_FREE_CLAIMS, "no free claims left");
        require((user_num_tard_claimed[msg.sender] + uint16(quantity)) <= MAX_TARDS_PER_USER, "User claiming too many");

        unchecked{
            user_num_tard_claimed[msg.sender] += uint16(quantity);
            num_free_claims += uint16(quantity);
        }

        _safeMint(msg.sender, quantity);
    }

    // Could prob do unchecked in more spots or use <0.8 so no safe math but 
    // marginal benefit and xero said he dgaf about costs
    function claimFree(uint256 quantity, bytes32[] memory proof) external nonReentrant {
        require(halt_mint == false, "halted");
        require(MerkleProof.verify(proof, merkle_free, keccak256(abi.encodePacked(msg.sender))), "not on WL"); 
        require((num_free_claims + uint16(quantity)) <= MAX_FREE_CLAIMS, "no free claims left");
        require((user_num_free_claimed[msg.sender] + uint16(quantity)) <= MAX_CLAIMS_PER_USER, "User claiming too many");

        unchecked{
            user_num_free_claimed[msg.sender] += uint16(quantity);
            num_free_claims += uint16(quantity);
        }

        _safeMint(msg.sender, quantity);
    }

    function mintPublic(uint256 quantity) external payable nonReentrant {
        require(halt_mint == false, "halted");
        require((user_num_minted[msg.sender] + uint16(quantity)) <= MAX_MINTS_PER_USER, "user minting too many.");
        require((num_minted + uint16(quantity)) <= (max_total_mints-MAX_FREE_CLAIMS), "minting over supply");
        require((quantity * mint_price_public) == msg.value, "incorrect value");

        unchecked{
            user_num_minted[msg.sender] += uint16(quantity);
            num_minted += uint16(quantity);
        }

        _safeMint(msg.sender, quantity);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        // Include the token index if revealed
        if (is_revealed) {
            require(_exists(tokenId), 'tokenId not found');
            return string(abi.encodePacked(URI, toString(tokenId), ".json"));
        } 

        // Otherwise return the URI
        return string(URI);
    }

    // admin fns
    function mintSelf(uint256 quantity) public onlyOwner() {
        _safeMint(msg.sender, quantity);
    }

    function mintTo(uint256 quantity, address to) public onlyOwner() {
        _safeMint(to, quantity);
    }

    // @ otherdev: splitterContract will be a 0xsplit's contract instance with an 
    // immutable split %. OS will use it as well.
    function withdrawSplit() public onlyOwner() {
        uint balance = address(this).balance;
        payable(splitterContract).transfer(balance);
    }

    // Setters 
    function setMaxTotalMints(uint16 v) public onlyOwner() {
        require(halt_mint, "must halt minting before setting");
        require(v > MAX_FREE_CLAIMS, "must be greater than free claims");
        max_total_mints = v;
    }

    function setMintPricePublic(uint256 v) public onlyOwner() {
        require(halt_mint, "must halt minting before setting");
        mint_price_public = v;
    }

    function setHaltMint(bool v) public onlyOwner() {
        halt_mint = v;
    }

    function setMerkleTard(bytes32 v) public onlyOwner() {
        require(halt_mint, "must halt minting before setting");
        merkle_tard = v;
    }

    function setMerkleFree(bytes32 v) public onlyOwner() {
        require(halt_mint, "must halt minting before setting");
        merkle_free = v;
    }

    function setURI(string memory v) public onlyOwner() {
        URI = v;
    }

    function setIsReveal(bool v) public onlyOwner() {
        is_revealed = v;
    }

    function numFreeInfo(address user) public view virtual returns (uint16, uint16) {
        return (user_num_free_claimed[user], MAX_CLAIMS_PER_USER);
    }

    function numTardInfo(address user) public view virtual returns (uint16, uint16) {
        return (user_num_tard_claimed[user], MAX_TARDS_PER_USER);
    }

    function getDisplayInfo() public view virtual returns (bool, bool, uint16, uint16, uint16, uint16, uint256) {
        return (halt_mint, is_revealed, num_free_claims, num_minted, MAX_FREE_CLAIMS, max_total_mints, mint_price_public);
    }

	function toString(uint256 value) internal pure returns (string memory) {
		// Inspired by OraclizeAPI's implementation - MIT licence
		// https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

		if (value == 0) {
			return "0";
		}
		uint256 temp = value;
		uint256 digits;
		while (temp != 0) {
			digits++;
			temp /= 10;
		}
		bytes memory buffer = new bytes(digits);
		while (value != 0) {
			digits -= 1;
			buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
			value /= 10;
		}
		return string(buffer);
	}
}