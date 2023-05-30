// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Psychonautz is ERC721Enumerable, Pausable, Ownable, PaymentSplitter {
    using Strings for uint256;

    string public constant TOKEN_NAME = "PsychonautzNFT";
    string public constant TOKEN_SYMBOL = "PSYCHO";

    address[] payees = [
        0x0d0F15B7FF1F02EDBAF333A0176440cF73A887F0
    ];

    uint256[] payeesShares = [100];

    string public PSYCHONAUTZ_PROVENANCE;

    string private tokenBaseUri;

    uint256 public constant MAX_NAUTZ = 9999;
    uint256 public maxPurchasePerMint = 20;
    uint256 public mintPrice = 0.0666 ether;

    bool public freeEnabled;

    mapping(NautzSalePhase => PresaleParams) public presaleParams;
    mapping(address => mapping(NautzSalePhase => uint256))
        public addressToMints;

    NautzSalePhase public currentPhase = NautzSalePhase.Locked;

    enum NautzSalePhase {
        Locked,     //0
        Free,       //1
        TeamSale,   //2
        OgSale,     //3
        EarlySale,  //4
        PublicSale  //5
    }

    struct PresaleParams {
        string name;
        uint256 mintPrice;
        uint256 limitPerAddress;
        bytes32 merkleRoot;
    }

    event TokenUriBaseSet(string _tokenBaseUri);

    event MaxPurchasePerMintSet(uint256 _maxPurchasePerMint);

    event ProvenanceHashSet(string _provenanceHash);

    event PhaseParamsSet(
        uint256 _phase,
        uint256 _mintPrice,
        uint256 _limitPerAddress
    );

    event PhaseMerkleRootSet(uint256 _phase, bytes32 _merkleRoot);

    event CurrentPhaseSet(uint256 _phase);

    event FreeEnabledStatus(address account, bool freeEnabled);

    constructor()
        ERC721(TOKEN_NAME, TOKEN_SYMBOL)
        PaymentSplitter(payees, payeesShares)
    {
        PresaleParams memory freePhase;
        freePhase.name = "Free";
        freePhase.mintPrice = 0 ether;
        freePhase.limitPerAddress = 1;
        presaleParams[NautzSalePhase.Free] = freePhase;

        PresaleParams memory teamPhase;
        teamPhase.name = "Team sale";
        teamPhase.mintPrice = 0 ether;
        teamPhase.limitPerAddress = 50;
        presaleParams[NautzSalePhase.TeamSale] = teamPhase;

        PresaleParams memory ogPhase;
        ogPhase.name = "OG sale";
        ogPhase.mintPrice = 0.0555 ether;
        ogPhase.limitPerAddress = 20;
        presaleParams[NautzSalePhase.OgSale] = ogPhase;

        PresaleParams memory earlyPhase;
        earlyPhase.name = "Early sale";
        earlyPhase.mintPrice = 0.0555 ether;
        earlyPhase.limitPerAddress = 20;
        presaleParams[NautzSalePhase.EarlySale] = earlyPhase;

        for (uint256 i = 1; i <= 120; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    modifier atPhase(NautzSalePhase _phase, string memory _phaseName) {
        require(
            currentPhase == _phase,
            string(abi.encodePacked(_phaseName, " is not active"))
        );
        _;
    }

    modifier validateNumberOfTokens(uint256 _numberOfTokens) {
        require(
            _numberOfTokens > 0 && _numberOfTokens <= maxPurchasePerMint,
            "Requested number of tokens is incorrect"
        );
        _;
    }

    modifier validatePresaleMintsAllowed(uint256 _numberOfTokens) {
        require(
            _numberOfTokens + addressToMints[msg.sender][currentPhase] <=
                presaleParams[currentPhase].limitPerAddress,
            "Exceeds number of allowed presale mints for current phase"
        );
        _;
    }

    modifier validateFreeMintsAllowed() {
        require(freeEnabled, "Free phase is not enabled");
        require(
            addressToMints[msg.sender][NautzSalePhase.Free] == 0,
            "Exceeds number of allowed free mints"
        );
        _;
    }

    modifier ensureAvailabilityFor(uint256 _numberOfTokens) {
        require(
            totalSupply() + _numberOfTokens <= MAX_NAUTZ,
            "Requested number of tokens not available"
        );
        _;
    }

    modifier validateEthPayment(uint256 _numberOfTokens, uint256 _mintPrice) {
        require(_mintPrice * _numberOfTokens == msg.value, "Inefficient ether");
        _;
    }

    function setProvenanceHash(string calldata _provenanceHash)
        external
        onlyOwner
    {
        PSYCHONAUTZ_PROVENANCE = _provenanceHash;
        emit ProvenanceHashSet(_provenanceHash);
    }

    function setTokenBaseUri(string calldata _tokenBaseUri) external onlyOwner {
        tokenBaseUri = _tokenBaseUri;
        emit TokenUriBaseSet(_tokenBaseUri);
    }

    function setMaxPurchasePerMint(uint256 _maxPurchasePerMint)
        external
        onlyOwner
    {
        maxPurchasePerMint = _maxPurchasePerMint;
        emit MaxPurchasePerMintSet(_maxPurchasePerMint);
    }

    function setPhaseParams(
        uint256 _phase,
        uint256 _mintPrice,
        uint256 _limitPerAddress
    ) external onlyOwner {
        NautzSalePhase phaseToUpdate = NautzSalePhase(_phase);
        presaleParams[phaseToUpdate].mintPrice = _mintPrice;
        presaleParams[phaseToUpdate].limitPerAddress = _limitPerAddress;
        emit PhaseParamsSet(_phase, _mintPrice, _limitPerAddress);
    }

    function setPhaseMerkleRoot(uint256 _phase, bytes32 _merkleRoot)
        external
        onlyOwner
    {
        NautzSalePhase phaseToUpdate = NautzSalePhase(_phase);
        presaleParams[phaseToUpdate].merkleRoot = _merkleRoot;
        emit PhaseMerkleRootSet(_phase, _merkleRoot);
    }

    function setCurrentPhase(uint256 _phase) external onlyOwner {
        currentPhase = NautzSalePhase(_phase);
        emit CurrentPhaseSet(_phase);
    }

    function setFreeEnabled(bool _freeEnabled) external onlyOwner {
        freeEnabled = _freeEnabled;
        emit FreeEnabledStatus(msg.sender, _freeEnabled);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function isAllowListEligible(
        uint256 _phase,
        address _addr,
        bytes32[] calldata _merkleProof
    ) external view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_addr));
        bytes32 merkleRoot = presaleParams[NautzSalePhase(_phase)].merkleRoot;
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    function mintFree(bytes32[] calldata _merkleProof)
        external
        payable
        whenNotPaused
        validateFreeMintsAllowed
        ensureAvailabilityFor(1)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        bytes32 merkleRoot = presaleParams[NautzSalePhase.Free].merkleRoot;
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid proof"
        );
        addressToMints[msg.sender][NautzSalePhase.Free] += 1;
        _safeMint(msg.sender, totalSupply() + 1);
    }

    function mintPresale(
        uint256 _phase,
        bytes32[] calldata _merkleProof,
        uint256 _numberOfTokens
    )
        external
        payable
        whenNotPaused
        atPhase(
            NautzSalePhase(_phase),
            presaleParams[NautzSalePhase(_phase)].name
        )
        validateNumberOfTokens(_numberOfTokens)
        validatePresaleMintsAllowed(_numberOfTokens)
        ensureAvailabilityFor(_numberOfTokens)
        validateEthPayment(
            _numberOfTokens,
            presaleParams[currentPhase].mintPrice
        )
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        bytes32 merkleRoot = presaleParams[currentPhase].merkleRoot;
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid proof"
        );
        addressToMints[msg.sender][currentPhase] += _numberOfTokens;
        for (uint256 i; i < _numberOfTokens; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function mint(uint256 _numberOfTokens)
        external
        payable
        whenNotPaused
        atPhase(NautzSalePhase.PublicSale, "Public phase ")
        validateNumberOfTokens(_numberOfTokens)
        ensureAvailabilityFor(_numberOfTokens)
        validateEthPayment(_numberOfTokens, mintPrice)
    {
        addressToMints[msg.sender][
            NautzSalePhase.PublicSale
        ] += _numberOfTokens;
        for (uint256 i; i < _numberOfTokens; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function ownerTokens(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Invalid Token ID");
        return
            bytes(tokenBaseUri).length > 0
                ? string(
                    abi.encodePacked(tokenBaseUri, tokenId.toString(), ".json")
                )
                : "";
    }
}