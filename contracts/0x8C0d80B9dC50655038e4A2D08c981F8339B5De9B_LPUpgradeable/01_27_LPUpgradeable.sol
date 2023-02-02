// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "./DefaultOperatorFiltererUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract LPUpgradeable is
    ERC721EnumerableUpgradeable,
    DefaultOperatorFiltererUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    IERC2981
{
    using Strings for uint256;
    using MerkleProof for bytes32[];

    // Whitelists
    bytes32 public phase2Root;

    // Sale settings
    uint256 public airdropPrice;
    uint256 public price;

    uint256 public phase1Start;
    uint256 public phase1End;
    uint256 public phase2Start;
    uint256 public phase3Start;
    uint256 public phase3End;

    // Collection settings
    string private _contractBaseURI;
    string private _contractURI;

    uint256 public maxSupply;

    // Royalty settings
    uint256 private royaltyBps;
    address private royaltyReceiver;

    IERC20 private weth;

    // Phase 2 mapping
    mapping(address => uint256) public userMinted;

    address private minter;

    // Burn lock
    bool public isBurnLocked;
    bool public isTransferLocked;

    function initialize() public initializer {
        __ERC721_init("LoudPunx", "LOUD");
        __ERC721Enumerable_init();
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        __DefaultOperatorFilterer_init();
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        require(!isTransferLocked, "Transfer is locked");
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        require(!isTransferLocked, "Transfer is locked");
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        require(!isTransferLocked, "Transfer is locked");
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // Mint functions
    function airdrop(address[] calldata receivers) external {
        require(msg.sender == minter, "Not minter");
        uint256 newTokenId = totalSupply() + 1;
        for (uint256 i = 0; i < receivers.length; i++) {
            weth.transferFrom(receivers[i], address(this), airdropPrice);
            _safeMint(receivers[i], newTokenId);
            newTokenId += 1;
        }
    }

    function phase2Mint(
        address to,
        bytes32[] calldata proof,
        uint256 quantity
    ) external payable nonReentrant whenNotPaused {
        require(msg.value == quantity * price, "Wrong price");

        validatePhase2Mint(to, proof, quantity);

        _internalMint(to, quantity);

        userMinted[to] += quantity;
    }

    function phase3Mint(address to, uint256 quantity)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        require(msg.value == quantity * price, "Wrong price");

        validatePhase3Mint(quantity);

        _internalMint(to, quantity);
    }

    function adminMint(address to, uint256 qty) external onlyOwner {
        _internalMint(to, qty);
    }

    function _internalMint(address to, uint256 quantity) internal {
        uint256 counter = totalSupply();
        for (uint256 i = 0; i < quantity; i++) {
            counter++;
            _safeMint(to, counter);
        }
    }

    // Token functions
    function exists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721Upgradeable)
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked(_contractBaseURI, _tokenId.toString()));
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _contractBaseURI = newBaseURI;
    }

    function setContractURI(string memory newContractURI) external onlyOwner {
        _contractURI = newContractURI;
    }

    // Reclaim functions
    function reclaimERC20(IERC20 erc20Token) external onlyOwner {
        erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this)));
    }

    function reclaimERC721(IERC721 erc721Token, uint256 id) external onlyOwner {
        erc721Token.safeTransferFrom(address(this), msg.sender, id);
    }

    function reclaimERC1155(
        address erc1155Token,
        uint256 id,
        uint256 amount
    ) public onlyOwner {
        IERC1155(erc1155Token).safeTransferFrom(
            address(this),
            msg.sender,
            id,
            amount,
            ""
        );
    }

    function withdrawEarnings(address to, uint256 balance) external onlyOwner {
        payable(to).transfer(balance);
    }

    // Sale settings
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setPhaseTime(
        uint256 _phase1Start,
        uint256 _phase1End,
        uint256 _phase2Start,
        uint256 _phase3Start,
        uint256 _phase3End
    ) external onlyOwner {
        phase1Start = _phase1Start;
        phase1End = _phase1End;
        phase2Start = _phase2Start;
        phase3Start = _phase3Start;
        phase3End = _phase3End;
    }

    function setPhase2Root(bytes32 root) external onlyOwner {
        phase2Root = root;
    }

    function setMaxSupply(uint256 newSupply) external onlyOwner {
        maxSupply = newSupply;
    }

    function setWethAddress(address _weth) external onlyOwner {
        weth = IERC20(_weth);
    }

    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
    }

    function setPrice(uint256 _price, uint256 _airdropPrice)
        external
        onlyOwner
    {
        price = _price;
        airdropPrice = _airdropPrice;
    }

    function setBurnLocked(bool _isLocked) external onlyOwner {
        isBurnLocked = _isLocked;
    }

    // Utility functions
    function isMintValid(
        address _to,
        bytes32[] memory _proof,
        bytes32 root
    ) internal pure returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_to));

        return _proof.verify(root, leaf);
    }

    function validatePhase2Mint(
        address to,
        bytes32[] calldata proof,
        uint256 quantity
    ) public view {
        require(
            phase2Start <= block.timestamp && block.timestamp < phase3Start,
            "Phase 2 inactive"
        );
        require(isMintValid(to, proof, phase2Root), "Not in phase 2 whitelist");
        require(quantity <= 2, "Max 2 at once");
        require(userMinted[to] + quantity <= 2, "Max 2 per wallet");
        require(totalSupply() + quantity <= maxSupply, "Exceeds supply");
    }

    function validatePhase3Mint(uint256 quantity) public view {
        require(
            phase3Start <= block.timestamp && block.timestamp < phase3End,
            "Phase 3 inactive"
        );
        require(quantity <= 20, "Max 20 at once");
        require(totalSupply() + quantity <= maxSupply, "Exceeds supply");
    }

    // Royalties
    function setRoyaltyReceiver(address _royaltyReceiver) external onlyOwner {
        royaltyReceiver = _royaltyReceiver;
    }

    function setRoyaltyBps(uint256 _royaltyBps) external onlyOwner {
        royaltyBps = _royaltyBps;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(IERC165,ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address, uint256 royaltyAmount)
    {
        royaltyAmount = (_salePrice / 10000) * royaltyBps;
        return (royaltyReceiver, royaltyAmount);
    }

    // Burning
    function burn(uint256 tokenId) public virtual {
        require(!isBurnLocked, "Burn is locked");
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner or approved"
        );
        _burn(tokenId);
    }

    function setTransferLocked(bool _isLocked) external onlyOwner {
        isTransferLocked = _isLocked;
    }

}