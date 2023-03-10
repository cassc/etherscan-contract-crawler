// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
// import "operator-filter-registry/DefaultOperatorFilterer.sol";
import {OperatorFilterer} from "closedsea/src/OperatorFilterer.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";

contract SoraPFP is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    ERC721AUpgradeable,
    OperatorFilterer,
    ERC2981Upgradeable
{
    uint256 public constant MAX_SUPPLY = 9999;

    string public baseUrl;
    bytes32 private _merkleRoot;
    phase public currentPhase;
    mapping(address => uint256) public walletMinted;
    phaseInfo[4] public phases;
    bool public operatorFilteringEnabled;

    enum phase {
        paused,
        preSale1,
        preSale2,
        publicSale
    }

    struct phaseInfo {
        uint256 price;
        uint256 supply;
        uint8 maxPerWallet;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializerERC721A initializer {
        __ERC721A_init("Sora PFP", "SORA");
        __Ownable_init();
        __UUPSUpgradeable_init();
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;

        // Set royalty receiver to the contract creator,
        // at 5% (default denominator is 10000).
        _setDefaultRoyalty(msg.sender, 500);
        currentPhase = phase.paused;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }



    // view function

    function tokenURI(uint256 id) public view override returns (string memory) {
        return string(abi.encodePacked(baseUrl, StringsUpgradeable.toString(id), ".json"));
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
    // public function

    function presaleMint(bytes32[] calldata _merkleProof, uint256 quantity) external payable {
        require(currentPhase == phase.preSale1 || currentPhase == phase.preSale2, "Presale not started");
        require(msg.value == quantity * phases[uint256(currentPhase)].price, "Incorrect value");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProofUpgradeable.verifyCalldata(_merkleProof, _merkleRoot, leaf), "not in whitelist!");
        require(
            walletMinted[msg.sender] + quantity <= phases[uint256(currentPhase)].maxPerWallet, "Exceeds max per wallet"
        );
        require(totalSupply() + quantity <= phases[uint256(currentPhase)].supply, "Exceeds phase supply");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Exceeds max supply");
        walletMinted[msg.sender] += quantity;
        _mint(msg.sender, quantity);
    }

    function publicMint(uint256 quantity) external payable {
        require(currentPhase == phase.publicSale, "Public sale not started");
        require(msg.value == quantity * phases[uint256(currentPhase)].price, "Incorrect value");
        require(
            walletMinted[msg.sender] + quantity <= phases[uint256(currentPhase)].maxPerWallet, "Exceeds max per wallet"
        );
        require(totalSupply() + quantity <= phases[uint256(currentPhase)].supply, "Exceeds phase supply");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Exceeds max supply");
        walletMinted[msg.sender] += quantity;
        _mint(msg.sender, quantity);
    }

    // admin function

    function adminMint(address _to, uint256 quantity) external onlyOwner {
        require(quantity + totalSupply() <= MAX_SUPPLY, "Exceeds max supply");
        _mint(_to, quantity);
    }

    function setSalePhase(uint8 _phase) external onlyOwner {
        currentPhase = phase(_phase);
    }

    function setSalePhaseInfo(uint8 _phase, uint256 _price, uint256 _supply, uint8 _maxPerWallet) external onlyOwner {
        phases[_phase].price = _price;
        phases[_phase].supply = _supply;
        phases[_phase].maxPerWallet = _maxPerWallet;
    }

    function setMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
        _merkleRoot = _newMerkleRoot;
    }

    function burn(uint256 _tokenId) external onlyOwner {
        _burn(_tokenId);
    }

    function setBaseUrl(string memory _baseUrl) external onlyOwner {
        baseUrl = _baseUrl;
    }

    function withdraw() external payable onlyOwner {
        (bool succ,) = payable(msg.sender).call{value: address(this).balance}("");
        require(succ, "Withdraw failed");
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override(ERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override(ERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override(ERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override(ERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721AUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return ERC721AUpgradeable.supportsInterface(interfaceId) || ERC2981Upgradeable.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }
}