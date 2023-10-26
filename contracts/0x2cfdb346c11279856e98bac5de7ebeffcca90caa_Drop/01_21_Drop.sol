// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "../erc721a/ERC721AQueryable.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {PhaseType, Phase, PhaseState} from "./DropLibrary.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Drop is
    DefaultOperatorFilterer,
    ERC721AQueryable,
    Ownable,
    ReentrancyGuard,
    Pausable,
    IERC2981
{
    using Strings for uint256;
    using MerkleProof for bytes32[];

    mapping(uint256 => Phase) public phases;
    mapping(uint256 => PhaseState) public phaseStates;

    uint256 private phaseCount;

    /*
     * Collection settings
     */
    string private _contractBaseURI;
    string private _contractURI;

    /*
     * Royalty settings
     */
    uint256 private royaltyBps;
    address public splits;

    uint256 public maxSupply;

    uint256 private publicMintDuration;

    event PhasesChanged(Phase[] newPhases);
    event MaxSupplyChanged(uint256 maxSupply);
    event PublicPhaseEndChanged(uint256 phaseEnd);

    constructor(
        string memory name,
        string memory symbol,
        uint256 _royaltyBps,
        address _splits,
        uint256 _maxSupply,
        uint256 _publicMintDuration,
        string memory contractBaseURI,
        string memory contractUri
    )
        ERC721A(name, symbol)
    {
        royaltyBps = _royaltyBps;
        splits = _splits;
        maxSupply = _maxSupply;
        publicMintDuration = _publicMintDuration;
        _contractBaseURI = contractBaseURI;
        _contractURI = contractUri;
    }

    function whitelistedMint(
        uint256 phaseIndex,
        address to,
        bytes32[] calldata proof,
        uint256 quantity
    ) external payable nonReentrant whenNotPaused {
        Phase memory phase = phases[phaseIndex];
        require(msg.value == quantity * phase.price, "Wrong price");

        _validateWhitelistMint(phaseIndex, to, proof, quantity);

        _safeMint(to, quantity);

        phaseStates[phaseIndex].totalMinted += quantity;
        phaseStates[phaseIndex].userMinted[to] += quantity;
    }

    function publicMint(
        uint256 phaseIndex,
        address to,
        uint256 quantity
    ) external payable nonReentrant whenNotPaused {
        Phase memory phase = phases[phaseIndex];
        require(msg.value == quantity * phase.price, "Wrong price");

        _validatePublicMint(phaseIndex, to, quantity);

        _safeMint(to, quantity);

        uint256 preMintQuantity = phaseStates[phaseIndex].totalMinted;

        phaseStates[phaseIndex].totalMinted += quantity;
        phaseStates[phaseIndex].userMinted[to] += quantity;

        if (
            phaseStates[phaseIndex].totalMinted >= phase.minAmount &&
            preMintQuantity < phase.minAmount &&
            phase.isMinEnabled
        ) {
            phases[phaseIndex].phaseEnd = block.timestamp + publicMintDuration;
            emit PublicPhaseEndChanged(phases[phaseIndex].phaseEnd);
        }
    }

    function adminMint(address to, uint256 qty) external onlyOwner {
        require(_totalMinted() + qty <= maxSupply, "Exceeds supply");
        _safeMint(to, qty);
    }

    /*
     * Token functions
     */
    function exists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    function tokenURI(uint256 _tokenId) public view override(ERC721A, IERC721A) returns (string memory) {
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

    /*
     * Sale and collection settings
     */
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setPhases(Phase[] calldata newPhases) external onlyOwner {
        for (uint256 i = 0; i < newPhases.length; i++) {
            Phase memory current = newPhases[i];
            phases[i].phaseType = current.phaseType;
            phases[i].maxPerWallet = current.maxPerWallet;
            phases[i].maxPerMint = current.maxPerMint;
            phases[i].root = current.root;
            phases[i].maxPerPhase = current.maxPerPhase;
            phases[i].price = current.price;
            phases[i].minAmount = current.minAmount;
            phases[i].isMinEnabled = current.isMinEnabled;
            phases[i].phaseStart = current.phaseStart;
            phases[i].phaseEnd = current.phaseEnd;
        }

        phaseCount = newPhases.length;

        emit PhasesChanged(newPhases);
    }

    function getAllPhases() external view returns (Phase[] memory, uint256[] memory) {
        Phase[] memory phasesList = new Phase[](phaseCount);
        uint256[] memory totalMinted = new uint256[](phaseCount);
        for (uint256 i = 0; i < phaseCount; i++) {
            phasesList[i] = phases[i];
            totalMinted[i] = phaseStates[i].totalMinted;
        }
        return (phasesList, totalMinted);
    }

    /*
     * Utility functions
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function isMintValid(
        address _to,
        bytes32[] memory _proof,
        bytes32 root
    ) internal pure returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_to));

        return _proof.verify(root, leaf);
    }

    function _validateWhitelistMint(
        uint256 phaseIndex,
        address to,
        bytes32[] calldata proof,
        uint256 quantity
    ) internal view {
        require(
            block.timestamp > phases[phaseIndex].phaseStart &&
                ((block.timestamp <= phases[phaseIndex].phaseEnd &&
                    phases[phaseIndex].phaseEnd != 0) || phases[phaseIndex].phaseEnd == 0),
            "Phase invalid"
        );

        require(
            phases[phaseIndex].phaseType == PhaseType.Whitelist,
            "Incorrect phase type"
        );

        require(
            isMintValid(to, proof, phases[phaseIndex].root),
            "Not in phase whitelist"
        );
        require(
            quantity <= phases[phaseIndex].maxPerMint,
            "Max amount exceeded"
        );
        require(
            phaseStates[phaseIndex].userMinted[to] + quantity <=
                phases[phaseIndex].maxPerWallet,
            "Wallet limit exceeded"
        );
        require(
            phaseStates[phaseIndex].totalMinted + quantity <=
                phases[phaseIndex].maxPerPhase,
            "Exceeds phase supply"
        );
    }

    function validateWhitelistMint(
        uint256 phaseIndex,
        address to,
        bytes32[] calldata proof,
        uint256 quantity
    ) public view returns (string memory) {
        if (
            block.timestamp < phases[phaseIndex].phaseStart ||
            (block.timestamp > phases[phaseIndex].phaseEnd &&
                phases[phaseIndex].phaseEnd != 0)
        ) return "Phase invalid";
        
        if (phases[phaseIndex].phaseType != PhaseType.Whitelist)
            return "Incorrect phase type";

        if (!isMintValid(to, proof, phases[phaseIndex].root))
            return "Not in phase whitelist";

        if (quantity > phases[phaseIndex].maxPerMint)
            return "Max amount exceeded";

        if (
            phaseStates[phaseIndex].userMinted[to] + quantity >
            phases[phaseIndex].maxPerWallet
        ) return "Wallet limit exceeded";

        if (
            phaseStates[phaseIndex].totalMinted + quantity >
            phases[phaseIndex].maxPerPhase
        ) return "Exceeds phase supply";

        return "";
    }

    function _validatePublicMint(
        uint256 phaseIndex,
        address to,
        uint256 quantity
    ) internal view {
        require(
            block.timestamp > phases[phaseIndex].phaseStart &&
                ((block.timestamp <= phases[phaseIndex].phaseEnd &&
                    phases[phaseIndex].phaseEnd != 0) || phases[phaseIndex].phaseEnd == 0),
            "Phase invalid"
        );

        require(
            phases[phaseIndex].phaseType == PhaseType.Public,
            "Incorrect phase type"
        );

        require(
            quantity <= phases[phaseIndex].maxPerMint,
            "Max amount exceeded"
        );
        require(
            phaseStates[phaseIndex].userMinted[to] + quantity <=
                phases[phaseIndex].maxPerWallet,
            "Wallet limit exceeded"
        );
        require(_totalMinted() + quantity <= maxSupply, "Exceeds phase supply");

        if (
            phases[phaseIndex].isMinEnabled &&
            phaseStates[phaseIndex].totalMinted >= phases[phaseIndex].minAmount
        ) {
            require(
                block.timestamp <= phases[phaseIndex].phaseEnd,
                "Public mint has ended"
            );
        }
    }

    function validatePublicMint(
        uint256 phaseIndex,
        address to,
        uint256 quantity
    ) public view returns (string memory) {
        if (
            block.timestamp < phases[phaseIndex].phaseStart ||
            (block.timestamp > phases[phaseIndex].phaseEnd &&
                phases[phaseIndex].phaseEnd != 0)
        ) return "Phase invalid";

        if (phases[phaseIndex].phaseType != PhaseType.Public)
            return "Incorrect phase type";

        if (quantity > phases[phaseIndex].maxPerMint)
            return "Max amount exceeded";

        if (
            phaseStates[phaseIndex].userMinted[to] + quantity >
            phases[phaseIndex].maxPerWallet
        ) return "Wallet limit exceeded";

        if (_totalMinted() + quantity > maxSupply)
            return "Exceeds phase supply";

        if (
            (phases[phaseIndex].isMinEnabled &&
                phaseStates[phaseIndex].totalMinted >=
                phases[phaseIndex].minAmount) &&
            block.timestamp > phases[phaseIndex].phaseEnd
        ) return "Public mint has ended";

        return "";
    }

    /*
     * Royalties
     */
    function setSplits(address _splits) external onlyOwner {
        splits = _splits;
    }

    function setRoyaltyBps(uint256 _royaltyBps) external onlyOwner {
        royaltyBps = _royaltyBps;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
        emit MaxSupplyChanged(maxSupply);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, IERC721A, IERC165)
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
        return (splits, royaltyAmount);
    }

    /*
     * Withdrawal functions
     */
    function withdrawETH() external onlyOwner {
        payable(splits).transfer(address(this).balance);
    }

    function withdrawERC20(IERC20 erc20Token) external onlyOwner {
        erc20Token.transfer(splits, erc20Token.balanceOf(address(this)));
    }

    function withdrawERC721(IERC721 erc721Token, uint256 id)
        external
        onlyOwner
    {
        erc721Token.safeTransferFrom(address(this), msg.sender, id);
    }

    function withdrawERC1155(
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

    /**
     * Operator filter related
     */
    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721A, IERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}