//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BMYC is ERC721A, Ownable {
    uint public constant TOTAL_SUPPLY = 5555;
    uint public constant MINT_PRICE = 6 ether / 100;
    bytes32 public MERKLE_ROOT;
    string public BASE_URI;

    uint64 public s_started_mint;
    uint public s_mint_quantity = 10 + 1;
    // whether an address already used up their whitelist
    mapping(address => bool) public s_used_whitelists;

    constructor(bytes32 merkleRoot, string memory _baseUri)
        ERC721A("Bear Market Yacht Club", "BMYC")
    {
        MERKLE_ROOT = merkleRoot;
        BASE_URI = _baseUri;
    }

    function mint(uint256 quantity, bytes32[] calldata _merkleProof)
        external
        payable
    {
        require(s_started_mint > 0, "Cannot mint yet");
        require(
            _totalMinted() + quantity < TOTAL_SUPPLY + 1,
            "All NFTs have been minted"
        );
        require(quantity < s_mint_quantity, "Can only mint up to 10 at a time");
        require(quantity != 0, "Can't mint 0");

        bool whitelisted = false;

        // if whitelisted you can mint one free
        // if quantity > 1, rest is paid in eth
        if (!s_used_whitelists[msg.sender]) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            if (MerkleProof.verify(_merkleProof, MERKLE_ROOT, leaf)) {
                whitelisted = true;
                s_used_whitelists[msg.sender] = true;
            }
        }

        // must pay up
        require(
            msg.value == MINT_PRICE * (quantity - (whitelisted ? 1 : 0)),
            "not enough eth to mint"
        );

        _safeMint(msg.sender, quantity);
    }

    // check whether a user has already used up their whitelist
    function usedWhitelist(address user) external view returns (bool) {
        return s_used_whitelists[user];
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
    }

    function changeBaseURI(string memory newBaseURI) external onlyOwner {
        BASE_URI = newBaseURI;
    }

    function teamMint() external onlyOwner {
        _mint(owner(), 55);
    }

    function startMint() external onlyOwner {
        s_started_mint = uint64(block.timestamp);
    }

    function changeMintQuantity(uint newQuantity) external onlyOwner {
        s_mint_quantity = newQuantity;
    }

    function changeMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        MERKLE_ROOT = newMerkleRoot;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override
        returns (bool)
    {
        return
            interfaceId == 0x7f5828d0 || // ERC165 Interface ID for ERC173
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC165
            interfaceId == 0x01ffc9a7; // ERC165 Interface ID for ERC721Metadata
    }

    function withdrawToken(address token) public onlyOwner {
        uint amount = IERC20(token).balanceOf(address(this));
        IERC20(token).approve(address(this), amount);
        IERC20(token).transferFrom(address(this), owner(), amount);
    }

    function withdrawEth() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}