// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ERC721AQueryable.sol";
import "./operator-filter-registry/OperatorFilterer.sol";


contract RacePermit is ERC721AQueryable, Ownable, OperatorFilterer{
    uint16 public MAX_SUPPLY = 2888;

    bool public isFreeMintActive = false;

    bool _revealed = false;

    string private baseURI = "";

    bytes32 freemintRoot;

    struct UserPurchaseInfo {
        uint16 freeMinted;
    }

    mapping(address => UserPurchaseInfo) public userPurchase; 

    address signer;
    mapping(bytes32 => bool) public usedDigests;

    constructor() ERC721A("RacePermit", "RACEPERMIT") OperatorFilterer(address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6), false) {}
    modifier isSecured(uint16 mintType) {
        require(tx.origin == msg.sender, "CONTRACTS_NOT_ALLOWED_TO_MINT");
        if (mintType == 3) {
            require(isFreeMintActive, "FREE_MINT_IS_NOT_YET_ACTIVE");
        }
        _;
    }

    modifier supplyMintLimit(uint16 numberOfTokens) {
        require(
            numberOfTokens + totalSupply() <= MAX_SUPPLY,
            "NOT_ENOUGH_SUPPLY"
        );
        _;
    }

    function freeMint(
        bytes32[] memory proof,
        uint16 numberOfTokens,
        uint16 maxMint
    ) external isSecured(3) supplyMintLimit(numberOfTokens) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, maxMint));
        require(MerkleProof.verify(proof, freemintRoot, leaf), "PROOF_INVALID");
        require(
            userPurchase[msg.sender].freeMinted + numberOfTokens <= maxMint,
            "EXCEED_ALLOCATED_MINT_LIMIT"
        );
        userPurchase[msg.sender].freeMinted += numberOfTokens;
            _mint(msg.sender, numberOfTokens);
    }

    function devMint(address[] memory _addresses, uint16[] memory quantities)
        external
        onlyOwner
    {
        require(_addresses.length == quantities.length, "WRONG_PARAMETERS");
        uint16 totalTokens = 0;
        for (uint16 i = 0; i < quantities.length; i++) {
            totalTokens += quantities[i];
        }
        require(totalTokens + totalSupply() <= MAX_SUPPLY, "NOT_ENOUGH_SUPPLY");
        for (uint16 i = 0; i < _addresses.length; i++) {
            _safeMint(_addresses[i], quantities[i]);
        }
    }

    //Essential
    function setBaseURI(string calldata URI) external onlyOwner {
        baseURI = URI;
    }

    function reveal(bool revealed, string calldata _baseURI) public onlyOwner {
        _revealed = revealed;
        baseURI = _baseURI;
    }

    //Essential

    function setFreeMintStatus() external onlyOwner {
        isFreeMintActive = !isFreeMintActive;
    }

    //Essential

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A, IERC721A)
        returns (string memory)
    {
        if (_revealed) {
            return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
        } else {
            return string(abi.encodePacked(baseURI));
        }
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function setFreeMintRoot(bytes32 _freemintRoot) external onlyOwner {
        freemintRoot = _freemintRoot;
    }



    function decreaseSupply(uint16 _maxSupply) external onlyOwner {
        require(_maxSupply < MAX_SUPPLY, "CANT_INCREASE_SUPPLY");
        MAX_SUPPLY = _maxSupply;
    }

    //OS FILTERER
    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
             override(ERC721A, IERC721A)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
           override(ERC721A, IERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
          override(ERC721A, IERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

}