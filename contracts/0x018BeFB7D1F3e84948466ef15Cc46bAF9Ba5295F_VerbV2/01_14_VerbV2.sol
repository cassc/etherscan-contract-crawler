// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ERC721A.sol";

contract VerbV2 is ERC721A, Ownable {
    uint256 public MAX_SUPPLY = 6500;
    uint256 public RESERVE_SUPPLY = 820; // TEAM + MIGRATION REFUND

    uint256 public WL_PRICE = 0.05 ether;
    uint256 public PUBLIC_PRICE = 0.05 ether;

    uint256 public  MINT_LIMIT = 10;

    bool public isPublicSaleActive = false;
    bool public isPresaleActive = false;

    bool _revealed = false;

    string private baseURI = "";

    bytes32 presaleRoot_1;
    bytes32 presaleRoot_2;
    bytes32 freemintRoot;

    mapping(address => bool) public freeMints;
    mapping(address => uint256) addressBlockBought;

    address public constant ADDRESS_1 =
        0x7bAdC616Fb80D3937677F9c2a4bf837Dea2aF8EC; //Owner
    address public constant ADDRESS_2 =
        0x188A3c584F0dE9ee0eABe04316A94A41F0867C0C; //ZL

    address signer;
    mapping(bytes32 => bool) public usedDigests;

    constructor() ERC721A("Verb", "VERB", RESERVE_SUPPLY, MAX_SUPPLY) {}

    modifier isSecured(uint8 mintType) {
        require(
            addressBlockBought[msg.sender] < block.timestamp,
            "CANNOT_MINT_ON_THE_SAME_BLOCK"
        );
        require(tx.origin == msg.sender, "CONTRACTS_NOT_ALLOWED_TO_MINT");

        if (mintType == 1) {
            require(isPublicSaleActive, "PUBLIC_MINT_IS_NOT_YET_ACTIVE");
        }

        if (mintType == 2) {
            require(isPresaleActive, "PRESALE_MINT_IS_NOT_YET_ACTIVE");
        }
        if (mintType == 3) {
            require(isPresaleActive, "FREE_MINT_IS_NOT_YET_ACTIVE");
        }

        _;
    }

    //Essential
    function mint(
        uint256 numberOfTokens,
        uint64 expireTime,
        bytes memory sig
    ) external payable isSecured(1) {
        bytes32 digest = keccak256(
            abi.encodePacked(msg.sender, expireTime, numberOfTokens)
        );
        require(isAuthorized(sig, digest), "CONTRACT_MINT_NOT_ALLOWED");
        require(block.timestamp <= expireTime, "EXPIRED_SIGNATURE");
        require(!usedDigests[digest], "SIGNATURE_LOOPING_NOT_ALLOWED");
        require(
            numberOfTokens + RESERVE_SUPPLY + totalSupply() <= MAX_SUPPLY,
            "NOT_ENOUGH_SUPPLY"
        );
        require(
            numberMinted(msg.sender) + numberOfTokens <= MINT_LIMIT,
            "EXCEED_MINT_LIMIT"
        );
        require(msg.value == PUBLIC_PRICE * numberOfTokens, "INVALID_AMOUNT");
        addressBlockBought[msg.sender] = block.timestamp;
        usedDigests[digest] = true;
        _safeMint(msg.sender, numberOfTokens);
    }

    function presaleMint(
        bytes32[] memory proof,
        uint256 numberOfTokens
    ) external payable isSecured(2) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
                MerkleProof.verify(proof, presaleRoot_1, leaf),
                "PROOF_INVALID"
            );
        require(
            numberMinted(msg.sender) + numberOfTokens <= MINT_LIMIT,
            "EXCEED_MINT_LIMIT"
        );
        require(
            numberOfTokens + totalSupply() <= MAX_SUPPLY,
            "NOT_ENOUGH_SUPPLY"
        );
        require(msg.value == WL_PRICE * numberOfTokens, "INVALID_AMOUNT");
        addressBlockBought[msg.sender] = block.timestamp;
        _safeMint(msg.sender, numberOfTokens);
    }

    function freeMint(bytes32[] memory proof) external isSecured(3) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, freemintRoot, leaf), "PROOF_INVALID");
        require(1 + totalSupply() <= MAX_SUPPLY, "NOT_ENOUGH_SUPPLY");
        require(!freeMints[msg.sender], "ALREADY_FREE_MINTED");
        addressBlockBought[msg.sender] = block.timestamp;
        freeMints[msg.sender] = true;
        _safeMint(msg.sender, 1);
    }

    function devMint(address[] memory _addresses, uint256[] memory quantities) external onlyOwner {
        require(_addresses.length == quantities.length,"WRONG_PARAMETERS");
        uint256 totalTokens = 0;
        for(uint256 i = 0 ; i < quantities.length; i++){
            totalTokens+= quantities[i];
        }
        require(totalTokens + totalSupply()  <= MAX_SUPPLY, "NOT_ENOUGH_SUPPLY");
        for(uint256 i = 0 ; i < _addresses.length; i++){
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
    function setPublicSaleStatus() external onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
    }

    function setPreSaleStatus() external onlyOwner {
        isPresaleActive = !isPresaleActive;
    }

    //Essential

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        payable(ADDRESS_2).transfer((balance * 1000) / 10000);
        payable(ADDRESS_1).transfer(address(this).balance);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (_revealed) {
            return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
        } else {
            return string(abi.encodePacked(baseURI));
        }
    }

    function tokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function setPreSaleRoot(bytes32 _presaleRoot_1, bytes32 _presaleRoot_2)
        external
        onlyOwner
    {
        presaleRoot_1 = _presaleRoot_1;
        presaleRoot_2 = _presaleRoot_2;
    }

    function setFreeMintRoot(bytes32 _freemintRoot) external onlyOwner {
        freemintRoot = _freemintRoot;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

        //Passed as wei
    function setPublicPrice(uint256 _publicPrice) external onlyOwner {
        PUBLIC_PRICE = _publicPrice;
    }

    //Passed as wei
    function setPresalePrice(uint256 _wlPrice) external onlyOwner {
        WL_PRICE = _wlPrice;
    }

    function decreaseSupply(uint256 _maxSupply) external onlyOwner {
        require(_maxSupply < MAX_SUPPLY, "CANT_INCREASE_SUPPLY");
        MAX_SUPPLY = _maxSupply;
    }

    function setMintLimit(uint256 _mintLimit) external onlyOwner{
        MINT_LIMIT = _mintLimit;
    }

    function reduceReserved(uint256 _reserveSupply) external onlyOwner{
        require(_reserveSupply < RESERVE_SUPPLY, "CANT_INCREASE_SUPPLY");
        RESERVE_SUPPLY = _reserveSupply;
    }
    function isAuthorized(bytes memory sig, bytes32 digest)
        private
        view
        returns (bool)
    {
        return ECDSA.recover(digest, sig) == signer;
    }
}