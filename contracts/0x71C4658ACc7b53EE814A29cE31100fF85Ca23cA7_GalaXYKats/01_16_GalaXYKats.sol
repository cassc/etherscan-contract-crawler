// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// @title  Main NFT Contract
// @notice In addition to the standard ERC721 interface, this contract implements
//         a merkle tree based pre-sale function that allows white listed users to
//         purchase the NFT at a discount.
contract GalaXYKats is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using MerkleProof for bytes32[];
    using ECDSA for bytes32;

    // constants
    uint256 public constant PRE_SALE_NFT_PRICE = 0.076 ether;
    uint256 public constant PUBLIC_SALE_NFT_PRICE = 0.08 ether;
    uint256 public constant MAX_NFT_PURCHASE = 5;
    uint256 public constant MAX_SUPPLY = 10000;    

    // free claim related
    uint256 public freeClaimStartTime;
    uint256 public freeClaimEndTime;
    bytes32 private _freeClaimMerkleRoot;
    mapping(address => bool) public claimed;

    // pre-sale related
    uint256 public preSaleStartTime;
    uint256 public publicSaleStartTime;
    bytes32 private _merkleRoot;
    mapping(address => bool) public presaleMinted;

    // public sale related
    mapping(string => bool) public _usedNonces;
    
    // whole contract related
    bool public disabled;
    string private _baseURIExtended;
    address private _signerAddress;
    
    constructor() ERC721("GalaXY Kats", "GXYK") {}

    /* ************** */
    /* USER FUNCTIONS */
    /* ************** */

    // @notice This function can be called by whitelisted users to claim a specified number
    //         of NFTs for free
    // @notice The whitelist mechanism is based on merkle proof; see details in the link below
    //         https://docs.openzeppelin.com/contracts/3.x/api/cryptography#MerkleProof
    // @param  proof - merkle proof to verify that msg.sender is indeed in the whitelist
    // @param  amount - number of NFTs to be claimed
    function claim(bytes32[] memory proof, uint256 amount)
        external
        nonReentrant
    {
        // checks
        require(freeClaimStartTime != 0, "start time not set");
        require(block.timestamp > freeClaimStartTime, "free claim hasn't started");
        require(block.timestamp < freeClaimEndTime, "free claim has finished");
        
        require(_freeClaimMerkleRoot != "", "merkleRoot not set");
        require(!claimed[msg.sender], "this address has already claimed");
        require(!disabled, "the contract is disabled");
        require(
            proof.verify(
                _freeClaimMerkleRoot,
                keccak256(abi.encodePacked(msg.sender, amount))
            ),
            "failed to verify merkle root"
        );
        // effects
        claimed[msg.sender] = true;
        // interaction
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, totalSupply());
        }
    }

    // @notice This function can be called by whitelisted users to purchase ONE NFT
    //         at a discounted price.
    // @notice The whitelist mechanism is based on merkle proof; see details in the link below
    //         https://docs.openzeppelin.com/contracts/3.x/api/cryptography#MerkleProof
    // @param  proof - merkle proof to verify that msg.sender is indeed in the whitelist
    // @param  merkleProofQuantity - the quantiy as written in the merkle tree
    // @param  actualPurchaseQuantity - the actual quantiy the user wants to buy
    function mintPreSale(
        bytes32[] memory proof,
        uint256 merkleProofQuantity,
        uint256 actualPurchaseQuantity
    ) external payable nonReentrant {
        require(preSaleStartTime != 0, "presaleStartTime not set");
        require(block.timestamp > preSaleStartTime, "presale hasn't started");
        require(block.timestamp < publicSaleStartTime, "presale has finished");
        require(_merkleRoot != "", "merkleRoot not set");
        require(!disabled, "the contract is disabled");
        require(
            proof.verify(
                _merkleRoot,
                keccak256(abi.encodePacked(msg.sender, merkleProofQuantity))
            ),
            "failed to verify merkle root"
        );
        require(
            merkleProofQuantity >= actualPurchaseQuantity,
            "intended purchase quantity has to be less than or equal to merkle proof token quantity"
        );
        require(
            !presaleMinted[msg.sender],
            "this EOA has minted its presale already"
        );
        require(
            PRE_SALE_NFT_PRICE * actualPurchaseQuantity == msg.value,
            "Sent ether value is incorrect"
        );
        presaleMinted[msg.sender] = true;
        for (uint256 i = 0; i < actualPurchaseQuantity; i++) {
            _safeMint(msg.sender, totalSupply());
        }
    }

    // @notice This function can be called by anyone after presale has finished.
    // @param  hash - has of signature
    // @param  signature - signature signed by server
    // @param  nonce - unique identifier
    // @param  tokenQuantity - the number of NFT to be purchased.
    function buy(
        bytes32 hash,
        bytes memory signature,
        string memory nonce,
        uint256 tokenQuantity
    ) external payable nonReentrant {
        require(matchAddresSigner(hash, signature), "DIRECT_MINT_DISALLOWED");
        require(!_usedNonces[nonce], "HASH_USED");
        require(
            hashTransaction(msg.sender, tokenQuantity, nonce) == hash,
            "HASH_FAIL"
        );

        require(publicSaleStartTime != 0, "publicsaleStartTime not set");
        require(
            block.timestamp > publicSaleStartTime,
            "publicSale hasn't started"
        );
        require(
            tokenQuantity > 0,
            "Number of tokens can not be less than or equal to 0"
        );
        require(
            tokenQuantity <= MAX_NFT_PURCHASE,
            "Can only mint up to 5 per purchase"
        );
        require(
            totalSupply() + tokenQuantity <= MAX_SUPPLY,
            "Purchase would exceed max supply of tokens"
        );
        require(
            PUBLIC_SALE_NFT_PRICE * tokenQuantity == msg.value,
            "Sent ether value is incorrect"
        );
        require(!disabled, "the contract is disabled");
        _usedNonces[nonce] = true;
        for (uint256 i = 0; i < tokenQuantity; i++) {
            _safeMint(msg.sender, totalSupply());
        }
    }

    // @notice This function can be called to retrieve the tokenURI
    // @param  tokenId - the unique identifier for one NFT
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory base = _baseURI();
        require(bytes(base).length != 0, "baseURI not set");
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    /* *************** */
    /* ADMIN FUNCTIONS */
    /* *************** */

    // @notice This function sets the merkle root to verify whether the msg.sender
    //         is in the predetermined whitelist
    // @notice The merkle root can be generated by ./merkle/merkle.js. Please refer
    //         to that source code for merkle tree calculation
    // @param  root - the merkle root
    function setFreeClaimMerkleRoot(bytes32 root) external onlyOwner {
        _freeClaimMerkleRoot = root;
    }

    // @notice This function sets the startTime
    //         https://www.epochconverter.com/ for time conversion between unix epoch time to human readable time
    // @param  _startTime - the startTime, in unix epoch time
    function setFreeClaimStartTime(uint256 _freeClaimStartTime) external onlyOwner {
        freeClaimStartTime = _freeClaimStartTime;
    }

    // @notice This function sets the endTime
    //         https://www.epochconverter.com/ for time conversion between unix epoch time to human readable time
    // @param  _endTime - the endTime, in unix epoch time
    function setFreeClaimEndTime(uint256 _freeClaimEndTime) external onlyOwner {
        freeClaimEndTime = _freeClaimEndTime;
    }

    // @notice This function sets the merkle root to verify whether the msg.sender
    //         is in the predetermined whitelist
    // @notice The merkle root can be generated by ./merkle/merkle.js. Please refer
    //         to that source code for merkle tree calculation
    // @param  root - the merkle root
    function setMerkleRoot(bytes32 root) external onlyOwner {
        _merkleRoot = root;
    }

    // @notice This function sets the disabled state, in order to disable/enable minting
    // @param  isDisabled - the disabled state
    function setDisabled(bool _disabled) external onlyOwner {
        disabled = _disabled;
    }

    // @notice This function sets the preSaleStartTime
    //         https://www.epochconverter.com/ for time conversion between unix epoch time to human readable time
    // @param  _preSaleStartTime - the preSaleStartTime, in unix epoch time
    function setPreSaleStartTime(uint256 _preSaleStartTime) external onlyOwner {
        preSaleStartTime = _preSaleStartTime;
    }

    // @notice This function sets the publicSaleStartTime
    //         https://www.epochconverter.com/ for time conversion between unix epoch time to human readable time
    // @param  _publicSaleStartTime - the publicSaleStartTime, in unix epoch time
    function setPublicSaleStartTime(uint256 _publicSaleStartTime) external onlyOwner {
        publicSaleStartTime = _publicSaleStartTime;
    }

    // @notice This function allows the team to reserve <num> NFTs for
    //         promotional purposes or airdrops
    // @dev    Note that 17 million gas units to reserve 150 NFTS.
    //         The caller need to watch out for reaching the block gas limit.
    // @param  num - the number of NFTs to reserve
    function reserveTokens(uint256 num) external onlyOwner {
        uint256 supply = totalSupply();
        uint256 i;
        for (i = 0; i < num; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    // @notice This function sets the BaseURI for this NFT collection
    //         All the URIs will be in the format of <BASE_URI>/<TOKEN_ID>
    //         See function tokenURI for implementation
    // @param  baseURI_ - the base URI of a NFT's token URI
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIExtended = baseURI_;
    }

    // @notice This function allows the contract owner to withdraw the eth in this contract
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setSignerAddress(address addr) external onlyOwner {
        _signerAddress = addr;
    }

    /* ****************** */
    /* INTERNAL FUNCTIONS */
    /* ****************** */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }

    function matchAddresSigner(bytes32 hash, bytes memory signature)
        private
        view
        returns (bool)
    {
        return _signerAddress == hash.recover(signature);
    }

    function hashTransaction(
        address sender,
        uint256 qty,
        string memory nonce
    ) private pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(sender, qty, nonce))
            )
        );

        return hash;
    }
}