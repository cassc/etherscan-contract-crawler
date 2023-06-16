// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ERC721A.sol";

contract Metakages is ERC721A, Ownable {
    uint256 public constant RESERVE_SUPPLY = 30;
    uint256 public constant MAX_SUPPLY = 3000;

    uint256 public WL_PRICE = 0.09 ether;
    uint256 public PUBLIC_PRICE = 0.1 ether;

    uint256 public constant MINT_LIMIT = 4;

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
        0x792c97d764148134AEA12B4f0Df362076F770C31; //Owner
    address public constant ADDRESS_2 =
        0x188A3c584F0dE9ee0eABe04316A94A41F0867C0C; //ZL

    address signer;
    mapping(bytes32 => bool) public usedDigests;

    constructor() ERC721A("Metakages", "METAKAGES", 30, 3000) {}

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
            numberOfTokens + totalSupply() <= MAX_SUPPLY,
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
        uint256 numberOfTokens,
        uint256 maxPresaleMint
    ) external payable isSecured(2) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        //Check KL type
        if (maxPresaleMint == 1) {
            require(
                MerkleProof.verify(proof, presaleRoot_1, leaf),
                "PROOF_INVALID"
            );
        } else if (maxPresaleMint == 2) {
            require(
                MerkleProof.verify(proof, presaleRoot_2, leaf),
                "PROOF_INVALID"
            );
        } else {
            revert("INVALID_MAX_PRESALE_MINT");
        }
        require(
            numberMinted(msg.sender) + numberOfTokens <= MINT_LIMIT,
            "EXCEED_MINT_LIMIT"
        );
        require(
            numberOfTokens + totalSupply() <= MAX_SUPPLY,
            "NOT_ENOUGH_SUPPLY"
        );
        if (freeMints[msg.sender]) {
            require(
                numberMinted(msg.sender) + numberOfTokens <= maxPresaleMint + 1,
                "EXCEED_PRESALE_MINT_LIMIT"
            );
        } else {
            require(
                numberMinted(msg.sender) + numberOfTokens <= maxPresaleMint,
                "EXCEED_PRESALE_MINT_LIMIT"
            );
        }
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

    function devMint(uint256 numberOfTokens) external onlyOwner {
        require(
            numberOfTokens + totalSupply() <= MAX_SUPPLY,
            "NOT_ENOUGH_SUPPLY"
        );
        require(
            numberOfTokens + numberMinted((msg.sender)) <= RESERVE_SUPPLY,
            "NOT_ENOUGH_RESERVE_SUPPLY"
        );
        _safeMint(msg.sender, numberOfTokens);
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
        payable(ADDRESS_2).transfer((balance * 1500) / 10000);
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

    function isAuthorized(bytes memory sig, bytes32 digest)
        private
        view
        returns (bool)
    {
        return ECDSA.recover(digest, sig) == signer;
    }
}