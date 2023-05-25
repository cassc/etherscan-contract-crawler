// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ERC2981.sol";
import "./Strings.sol";
import "./MerkleProof.sol";
import "./OperatorFilterer.sol";

contract ApexWolfPackGenesis is ERC721A, ERC2981, OperatorFilterer, Ownable {
    using Strings for uint256;

    enum MintState {
        PAUSED,
        PRESALE,
        PUBLIC
    }

    error MintStateError();
    error MaxSupplyReachedError();
    error AlreadyMintedError();
    error InvalidProofError();
    error MaxPerWalletReachedError();
    error IncorrectAmountError();

    MintState public mintState = MintState.PAUSED;

    bytes32 public merkleRoot;
    uint256 public price = 0.08 ether;
    uint256 public maxSupply = 100;
    uint256 public maxPresaleMint = 1;
    uint256 public maxPublicMint = 1;

    string public baseURI;

    bool public operatorFilteringEnabled = true;

    constructor(
        string memory initialBaseURI,
        bytes32 initialMerkleRoot,
        address payable royaltiesReceiver
    ) ERC721A("Apex Wolf Pack Genesis", "ApexGenesis") {
        baseURI = initialBaseURI;
        merkleRoot = initialMerkleRoot;
        setRoyaltyInfo(royaltiesReceiver, 800);
    }

    function withdraw(address payable destination) external onlyOwner {
        destination.transfer(address(this).balance);
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // Modifiers

    modifier verifyMintState(MintState requiredState) {
        if (mintState != requiredState) revert MintStateError();
        _;
    }

    modifier verifyAmount(uint64 amount) {
        if (msg.value != price * amount) revert IncorrectAmountError();
        _;
    }

    modifier verifyAvailableSupply(uint64 amount) {
        if (_totalMinted() + amount > maxSupply) revert MaxSupplyReachedError();
        _;
    }

    // Minting

    function mint(
        uint64 qty
    )
        external
        payable
        verifyMintState(MintState.PUBLIC)
        verifyAvailableSupply(qty)
        verifyAmount(qty)
    {
        if (
            _numberMinted(msg.sender) + qty >
            (
                _getAux(msg.sender) > 0
                    ? maxPublicMint + maxPresaleMint
                    : maxPublicMint
            )
        ) revert MaxPerWalletReachedError();
        _mint(msg.sender, qty);
    }

    function presaleMint(
        uint64 qty,
        bytes32[] calldata merkleProof
    )
        external
        payable
        verifyMintState(MintState.PRESALE)
        verifyAvailableSupply(qty)
        verifyAmount(qty)
    {
        if (_getAux(msg.sender) != 0) revert AlreadyMintedError();
        if (_numberMinted(msg.sender) + qty > maxPresaleMint)
            revert MaxPerWalletReachedError();

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verifyCalldata(merkleProof, merkleRoot, leaf))
            revert InvalidProofError();

        _setAux(msg.sender, qty);
        _mint(msg.sender, qty);
    }

    // ERC721A

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // Setters

    function setMintState(MintState s) external onlyOwner {
        mintState = s;
    }

    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }

    function setMaxSupply(uint256 supply) external onlyOwner {
        maxSupply = supply;
    }

    function setMaxPresaleMint(uint256 max) external onlyOwner {
        maxPresaleMint = max;
    }

    function setMaxPublicMint(uint256 max) external onlyOwner {
        maxPublicMint = max;
    }

    // OperatorFilterer

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled()
        internal
        view
        virtual
        override
        returns (bool)
    {
        return operatorFilteringEnabled;
    }

    // IERC2981

    function setRoyaltyInfo(
        address payable receiver,
        uint96 numerator
    ) public onlyOwner {
        _setDefaultRoyalty(receiver, numerator);
    }

    // ERC165

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }
}
