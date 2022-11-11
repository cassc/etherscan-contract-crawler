//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./libraries/OperatorFilterer.sol";

contract BMYC is
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC721AUpgradeable,
    OperatorFilterer
{
    uint public TOTAL_SUPPLY;
    bytes32 public MERKLE_ROOT;
    string public BASE_URI;
    uint public MINT_QUANTITY;
    // whether an address already used up their whitelist.
    // deprecated
    mapping(address => bool) public s_used_whitelists;
    // how many whitelists were used up
    mapping(address => uint) public s_used_whitelist_count;

    function initialize(bytes32 merkleRoot, string memory _baseUri)
        external
        initializerERC721A
        initializer
    {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __ERC721A_init("Bear Market Yacht Club", "BMYC");
        __OperatorFilterer_init();
        TOTAL_SUPPLY = 5555;
        MERKLE_ROOT = merkleRoot;
        BASE_URI = _baseUri;
        MINT_QUANTITY = 3 + 1;
        _pause();
    }

    function initialize2() public reinitializer(2) {
        __OperatorFilterer_init();
    }

    function mint(uint256 quantity, bytes32[] calldata _merkleProof)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        require(
            _totalMinted() + quantity < TOTAL_SUPPLY + 1,
            "All NFTs have been minted"
        );
        require(quantity < MINT_QUANTITY, "Can only mint up to 3 at a time");
        require(quantity != 0, "Can't mint 0");

        require(
            s_used_whitelist_count[msg.sender] + quantity < MINT_QUANTITY,
            "Already used whitelist"
        );
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProofUpgradeable.verify(_merkleProof, MERKLE_ROOT, leaf),
            "You weren't whitelisted"
        );
        s_used_whitelist_count[msg.sender] += quantity;

        _safeMint(msg.sender, quantity);
    }

    // check whether a user has already used up their whitelist
    function usedWhitelist(address user) external view returns (uint) {
        return s_used_whitelist_count[user];
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
    }

    function changeBaseURI(string memory newBaseURI) external onlyOwner {
        BASE_URI = newBaseURI;
    }

    function teamMint() external onlyOwner {
        _mint(owner(), 555);
    }

    // airdrop to existing holders
    function airdrop(address[] memory to, uint[] memory amount)
        external
        onlyOwner
        nonReentrant
    {
        require(
            to.length == amount.length,
            "to and amount must be the same length"
        );
        for (uint i = 0; i < to.length; i++) {
            _mint(to[i], amount[i]);
        }
    }

    function changeMintQuantity(uint newQuantity) external onlyOwner {
        MINT_QUANTITY = newQuantity;
    }

    function changeMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        MERKLE_ROOT = newMerkleRoot;
    }

    function withdrawToken(address token) public onlyOwner {
        uint amount = IERC20(token).balanceOf(address(this));
        IERC20(token).approve(address(this), amount);
        IERC20(token).transferFrom(address(this), owner(), amount);
    }

    function withdrawEth() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function togglePause() public onlyOwner {
        if (paused()) _unpause();
        else _pause();
    }

    // opensea
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}