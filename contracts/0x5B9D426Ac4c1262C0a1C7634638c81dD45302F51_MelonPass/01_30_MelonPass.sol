// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// ███╗   ███╗███████╗██╗      ██████╗ ███╗   ██╗    ██████╗  █████╗ ███████╗███████╗
// ████╗ ████║██╔════╝██║     ██╔═══██╗████╗  ██║    ██╔══██╗██╔══██╗██╔════╝██╔════╝
// ██╔████╔██║█████╗  ██║     ██║   ██║██╔██╗ ██║    ██████╔╝███████║███████╗███████╗
// ██║╚██╔╝██║██╔══╝  ██║     ██║   ██║██║╚██╗██║    ██╔═══╝ ██╔══██║╚════██║╚════██║
// ██║ ╚═╝ ██║███████╗███████╗╚██████╔╝██║ ╚████║    ██║     ██║  ██║███████║███████║
// ╚═╝     ╚═╝╚══════╝╚══════╝ ╚═════╝ ╚═╝  ╚═══╝    ╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝

import "./BaseERC721AUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

enum Edition {
    SILVER,
    GOLD,
    DIAMOND
}

contract MelonPass is BaseERC721AUpgradeable {
    using Strings for uint256;
    using MerkleProof for bytes32[];

    struct SaleSettings {
        uint256 maxSupply;
        uint256 phase1Start;
        uint256 phase2Start;
        uint256 phase2End;
        uint256 ogAllowlistMintPrice;
        uint256 generalAllowlistMintPrice;
        uint256 publicMintPrice;
        uint256 ogAllowlistMaxAccount;
        uint256 allowlistMaxAccount;
        uint256 ogAllowlistMaxPerPhase;
        uint256 generalAllowlistMaxPerPhase;
        bytes32 ogAllowlistRoot;
        bytes32 generalAllowlistRoot;
    }

    SaleSettings public settings;

    string private _contractBaseURI;
    string private _contractURI;

    mapping(address => uint256) public ogMinted;
    mapping(address => uint256) public allowlistMinted;

    uint256 public totalOgMinted;
    uint256 public totalAllowlistMinted;

    bool public transferEnabled;
    bool public approvalEnabled;

    mapping(uint256 => Edition) private idToEdition;

    function initialize() public initializer initializerERC721A {
        __BaseERC721AUpgradeable_init("MelonPass", "MELONPASS");
        _setDefaultRoyalty(0xc51ADfaA4e0D985B4060E33D2c51D3B260f72C39, 690);
    }

    function ogAllowlistMint(
        address to,
        uint256 quantity,
        bytes32[] calldata proof
    ) external payable nonReentrant {
        require(
            msg.value == quantity * settings.ogAllowlistMintPrice,
            "Wrong price"
        );

        validateOgAllowlistMint(to, quantity, proof);

        _safeMint(to, quantity);

        totalOgMinted += quantity;
        ogMinted[to] += quantity;
    }

    function generalAllowlistMint(
        address to,
        uint256 quantity,
        bytes32[] calldata proof
    ) external payable nonReentrant {
        require(
            msg.value == quantity * settings.generalAllowlistMintPrice,
            "Wrong price"
        );

        validateGeneralAllowlistMint(to, quantity, proof);

        _safeMint(to, quantity);

        totalAllowlistMinted += quantity;
        allowlistMinted[to] += quantity;
    }

    function publicMint(
        address to,
        uint256 quantity
    ) external payable nonReentrant {
        require(
            msg.value == quantity * settings.publicMintPrice,
            "Wrong price"
        );

        validatePublicMint(quantity);

        _safeMint(to, quantity);
    }

    function adminMint(address to, uint256 qty) external onlyOwner {
        _safeMint(to, qty);
    }

    function exists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _contractBaseURI;
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

    function setTransferEnabled(bool _enabled) external onlyOwner {
        transferEnabled = _enabled;
    }

    function setApprovalEnabled(bool _enabled) external onlyOwner {
        approvalEnabled = _enabled;
    }

    function setEdition(
        uint256[] calldata ids,
        Edition edition
    ) external onlyOwner {
        for (uint256 i = 0; i < ids.length; i++) {
            idToEdition[ids[i]] = edition;
        }
    }

    function setSaleSettings(
        SaleSettings calldata _settings
    ) external onlyOwner {
        settings.maxSupply = _settings.maxSupply;
        settings.phase1Start = _settings.phase1Start;
        settings.phase2Start = _settings.phase2Start;
        settings.phase2End = _settings.phase2End;
        settings.ogAllowlistMintPrice = _settings.ogAllowlistMintPrice;
        settings.generalAllowlistMintPrice = _settings
            .generalAllowlistMintPrice;
        settings.publicMintPrice = _settings.publicMintPrice;
        settings.ogAllowlistMaxAccount = _settings.ogAllowlistMaxAccount;
        settings.allowlistMaxAccount = _settings.allowlistMaxAccount;
        settings.ogAllowlistMaxPerPhase = _settings.ogAllowlistMaxPerPhase;
        settings.generalAllowlistMaxPerPhase = _settings
            .generalAllowlistMaxPerPhase;
        settings.ogAllowlistRoot = _settings.ogAllowlistRoot;
        settings.generalAllowlistRoot = _settings.generalAllowlistRoot;
    }

    function setMintSchedule(
        uint256 _phase1Start,
        uint256 _phase2Start,
        uint256 _phase2End
    ) external onlyOwner {
        settings.phase1Start = _phase1Start;
        settings.phase2Start = _phase2Start;
        settings.phase2End = _phase2End;
    }

    function setRoots(
        bytes32 _ogAllowlistRoot,
        bytes32 _generalAllowlistRoot
    ) external onlyOwner {
        settings.ogAllowlistRoot = _ogAllowlistRoot;
        settings.generalAllowlistRoot = _generalAllowlistRoot;
    }

    function setMaxSupply(uint256 newSupply) external onlyOwner {
        settings.maxSupply = newSupply;
    }

    function setPrices(
        uint256 _ogAllowlistMintPrice,
        uint256 _generalAllowlistMintPrice,
        uint256 _publicPrice
    ) external onlyOwner {
        settings.ogAllowlistMintPrice = _ogAllowlistMintPrice;
        settings.generalAllowlistMintPrice = _generalAllowlistMintPrice;
        settings.publicMintPrice = _publicPrice;
    }

    function getMintDetails()
        external
        view
        returns (
            SaleSettings memory _settings,
            uint256 _totalOgMinted,
            uint256 _totalAllowlistMinted,
            uint256 _totalSupplyMinted
        )
    {
        return (settings, totalOgMinted, totalAllowlistMinted, _totalMinted());
    }

    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    function getEditionId(uint256 tokenId) external view returns (Edition) {
        return idToEdition[tokenId];
    }

    function isMintValid(
        address _to,
        bytes32[] memory _proof,
        bytes32 root
    ) internal pure returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_to));

        return _proof.verify(root, leaf);
    }

    function validateOgAllowlistMint(
        address to,
        uint256 quantity,
        bytes32[] calldata proof
    ) public view {
        require(
            settings.phase1Start <= block.timestamp &&
                block.timestamp < settings.phase2Start,
            "Allowlist mint not active"
        );
        require(
            isMintValid(to, proof, settings.ogAllowlistRoot),
            "Not whitelisted"
        );
        require(
            ogMinted[to] + quantity <= settings.ogAllowlistMaxAccount,
            "Max per wallet exceeded"
        );

        require(
            totalOgMinted + quantity <= settings.ogAllowlistMaxPerPhase,
            "Max per phase exceeded"
        );
        require(
            _totalMinted() + quantity <= settings.maxSupply,
            "Max supply exceeded"
        );
    }

    function validateGeneralAllowlistMint(
        address to,
        uint256 quantity,
        bytes32[] calldata proof
    ) public view {
        require(
            settings.phase1Start <= block.timestamp &&
                block.timestamp < settings.phase2Start,
            "Allowlist mint not active"
        );
        require(
            isMintValid(to, proof, settings.generalAllowlistRoot),
            "Not whitelisted"
        );
        require(
            allowlistMinted[to] + quantity <= settings.allowlistMaxAccount,
            "Max per wallet exceeded"
        );
        require(
            totalAllowlistMinted + quantity <=
                settings.generalAllowlistMaxPerPhase,
            "Max per phase exceeded"
        );
        require(
            _totalMinted() + quantity <= settings.maxSupply,
            "Max supply exceeded"
        );
    }

    function validatePublicMint(uint256 quantity) public view {
        require(
            settings.phase2Start <= block.timestamp &&
                block.timestamp < settings.phase2End,
            "Public mint not active"
        );
        require(quantity <= 20, "Max per transaction exceeded");
        require(
            _totalMinted() + quantity <= settings.maxSupply,
            "Max supply exceeded"
        );
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(BaseERC721AUpgradeable) {
        require(transferEnabled, "Transfer is disabled");
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(BaseERC721AUpgradeable) {
        require(transferEnabled, "Transfer is disabled");
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(BaseERC721AUpgradeable) {
        require(transferEnabled, "Transfer is disabled");
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721AUpgradeable, IERC721AUpgradeable) {
        require(approvalEnabled, "Approval is disabled");
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override(ERC721AUpgradeable, IERC721AUpgradeable) {
        require(approvalEnabled, "Approval is disabled");
        super.approve(operator, tokenId);
    }
}