// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ERC721A.sol";

contract KaijuFrenz is ERC721A, Ownable{
    uint256 public constant PRESALE_SUPPLY = 4535;
    uint256 public constant FREE_SUPPLY = 350;
    uint256 public constant MAX_SUPPLY = 6666;

    //Create Setters for price
    uint256 public WL_PRICE = 0.088 ether;
    uint256 public PUBLIC_PRICE = 0.12 ether;

    uint256 public constant PRESALE_LIMIT = 1;
    uint256 public constant MINT_LIMIT = 2;

    //Create Setters for status
    bool public isPublicSaleActive = false;
    bool public isPresaleActive = false;
    bool public isFreeActive = false;

    bool _revealed = false;

    string private baseURI = "";

    //Make setters for the 3
    bytes32 presaleRoot;
    bytes32 freemintRoot;

    mapping(address => bool) public freeMints;
    mapping(address => uint256) addressBlockBought;

        address public constant ADDRESS_1 =
        0xCb583ace502f4F8b9f72309c56B1195606e68ad9; //OWNER
        address public constant ADDRESS_2 =
        0xc9b5553910bA47719e0202fF9F617B8BE06b3A09; //ROYAL LABS

    uint256 public freeMintCount = 0;
    uint256 public presaleMintCount = 0;
    

    address signer;
    mapping(bytes32 => bool) public usedDigests;

    constructor() ERC721A("KaijuFrenz", "KAIJUFRENZ",25,6666) {}

    modifier isSecured(uint8 mintType) {
        require(addressBlockBought[msg.sender] < block.timestamp, "CANNOT_MINT_ON_THE_SAME_BLOCK");
        require(tx.origin == msg.sender,"CONTRACTS_NOT_ALLOWED_TO_MINT");

        if(mintType == 1) {
            require(isFreeActive, "FREE_MINT_IS_NOT_YET_ACTIVE");
        } 

        if(mintType == 2) {
            require(isPresaleActive, "PRESALE_MINT_IS_NOT_YET_ACTIVE");
        }

        if(mintType == 3) {
            require(isPublicSaleActive, "PUBLIC_MINT_IS_NOT_YET_ACTIVE");
        }
        _;
    }

    //Essential
    function mint(uint256 numberOfTokens, uint64 expireTime,
        bytes memory sig) external isSecured(3) payable {
        bytes32 digest = keccak256(abi.encodePacked(msg.sender,expireTime,numberOfTokens));
        require(
            isAuthorized(sig,digest),
            "CONTRACT_MINT_NOT_ALLOWED"
        );
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
        require(msg.value == PUBLIC_PRICE * numberOfTokens, "NOT_ENOUGH_ETH");
        addressBlockBought[msg.sender] = block.timestamp;
        usedDigests[digest] = true;
        _safeMint(msg.sender, numberOfTokens);
    }

    function presaleMint(bytes32[] memory proof)
        external
        isSecured(2)
        payable
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(proof, presaleRoot,leaf),
            "PROOF_INVALID"
        );
        require(
            1 + totalSupply() <= MAX_SUPPLY,
            "NOT_ENOUGH_SUPPLY"
        );
        require(
            1 + presaleMintCount <= PRESALE_SUPPLY,
            "NOT_ENOUGH_PRESALE_SUPPLY"
        );
        if (freeMints[msg.sender]) {
            require(
                numberMinted(msg.sender) + 1 <= PRESALE_LIMIT + 1,
                "EXCEED_PRESALE_MINT_LIMIT"
            );
        } else {
            require(
                numberMinted(msg.sender) + 1 <= PRESALE_LIMIT,
                "EXCEED_PRESALE_MINT_LIMIT"
            );
        }
        require(msg.value == WL_PRICE , "NOT_ENOUGH_ETH");
        addressBlockBought[msg.sender] = block.timestamp;
        presaleMintCount += 1;
        _safeMint(msg.sender, 1);
    }

    function freeMint(bytes32[] memory proof) external isSecured(1) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(proof, freemintRoot,leaf),
            "PROOF_INVALID"
        );
        require(
            1 + totalSupply() <= MAX_SUPPLY,
            "NOT_ENOUGH_SUPPLY"
        );
        require(1 + freeMintCount <= FREE_SUPPLY, "NOT_ENOUGH_FREE_SUPPLY");
        require(
            !freeMints[msg.sender],
            "ALREADY_FREE_MINTED"
        );
        addressBlockBought[msg.sender] = block.timestamp;
        freeMints[msg.sender] = true;
        freeMintCount += 1;
        _safeMint(msg.sender, 1);
    }

        function devMint(uint256 numberOfTokens) external onlyOwner {
        require(
            numberOfTokens + totalSupply() <= MAX_SUPPLY,
          "NOT_ENOUGH_SUPPLY"
        );
        require(
            numberOfTokens + numberMinted((msg.sender)) <= FREE_SUPPLY,
            "NOT_ENOUGH_FREE_SUPPLY"
        );
        require(
            numberOfTokens + numberMinted((msg.sender)) <= 100,
            "NOT_ENOUGH_TEAM_ALLOCATION"
        );
        freeMintCount += numberOfTokens;
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
    function setFreeStatus() external onlyOwner {
        isFreeActive = !isFreeActive;
    }

    //Essential

    function withdraw() external onlyOwner {
       uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        payable(ADDRESS_2).transfer((balance * 800) / 10000);
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

    function setPreSaleRoot(bytes32 _presaleRoot) external onlyOwner {
        presaleRoot = _presaleRoot;
    }

    function setFreeMintRoot(bytes32 _freemintRoot) external onlyOwner {
        freemintRoot = _freemintRoot;
    }


    //Passed as wei
    function setPublicPrice(uint256 _publicPrice) external onlyOwner {
        PUBLIC_PRICE = _publicPrice;
    }
    //Passed as wei
    function setPresalePrice(uint256 _wlPrice) external onlyOwner {
        WL_PRICE = _wlPrice;
    }

    function setSigner(address _signer) external onlyOwner{
        signer = _signer;
    }

        function isAuthorized(
        bytes memory sig,
        bytes32 digest
    ) private view returns (bool) {
        return ECDSA.recover(digest, sig) == signer;
    }

}