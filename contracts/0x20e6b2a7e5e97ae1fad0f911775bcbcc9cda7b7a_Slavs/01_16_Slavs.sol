// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Slavs is ERC721Enumerable, Ownable {
    using ECDSA for bytes32;
    using SafeCast for uint256;
    using SafeMath for uint256;
    using Strings for uint256;

    bytes32 public DOMAIN_SEPARATOR;

    uint8 public currentPresaleId;
    uint8 public tokensReserved;
    uint16 public immutable reserveCount;
    uint16 public nextTokenId;
    uint16 public maxMintsPerTransaction = 10;
    uint256 public startingIndex;
    uint256 public startingIndexBlock;
    uint256 public presaleTokenPrice = 0.02 ether;
    uint256 public tokenPrice = 0.04 ether;
    uint256 public immutable maxSupply;

    bool isPresaleActive = false;
    bool isSaleOpen = false;

    address whitelister;
    address payable public treasury;

    mapping(uint8 => mapping(address => uint16)) public presaleBoughtCounts;

    bytes32 public constant PRESALE_TYPEHASH =
        keccak256("Presale(address buyer,uint16 maxCount, uint8 presaleId )");

    string public baseURI;
    string public SLAVS_PROVENANCE = "";

    constructor(uint256 _maxSupply, uint16 _reserveCount)
        ERC721("Slavs token", "SLAV")
    {
        require(
            _reserveCount <= _maxSupply,
            "Slavs: reserve count out of range"
        );

        isPresaleActive = false;
        maxSupply = _maxSupply;
        reserveCount = _reserveCount;
        currentPresaleId = 1;

        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("Slavs")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    modifier saleIsOpen() {
        require(isSaleOpen, "Slavs: sale is closed");
        require(nextTokenId < maxSupply, "Slavs: sale is closed");
        _;
    }

    modifier presaleIsOpen() {
        require(isPresaleActive, "Slavs: presale is closed");
        _;
    }

    function mintPresaleTokens(
        uint16 maxCount,
        uint8 presaleId,
        uint8 count,
        bytes memory signature
    ) external payable presaleIsOpen {
        bytes32 message = formMessage(maxCount, presaleId, msg.sender);

        address signer = recoverAddress(message, signature);
        require(whitelister == signer, "Invalid signature provided");

        uint16 _nextTokenId = nextTokenId;

        require(treasury != address(0), "Slavs: treasury not set");
        require(presaleTokenPrice > 0, "Slavs: token price not set");
        require(count > 0, "Slavs: invalid count");

        require(
            _nextTokenId + count <= maxSupply,
            "Slavs: max supply exceeded"
        );
        require(
            presaleTokenPrice * count == msg.value,
            "Slavs: incorrect Ether value"
        );

        require(
            signer != address(0) && signer == whitelister,
            "Slavs: invalid signature"
        );

        require(
            presaleBoughtCounts[currentPresaleId][msg.sender] + count <=
                maxCount,
            "Slavs: presale max count exceeded"
        );
        presaleBoughtCounts[currentPresaleId][msg.sender] += count;

        treasury.transfer(msg.value);

        for (uint256 ind = 0; ind < count; ind++) {
            _safeMint(msg.sender, _nextTokenId + ind);
        }
        nextTokenId += count;
    }

    function publicMint(uint8 quantity) external payable saleIsOpen {
        uint256 _nextTokenId = nextTokenId;
        require(
            quantity <= maxMintsPerTransaction,
            "Slavs: too many tokens requested in one transaction"
        );
        require(treasury != address(0), "Slavs: no treasury yet");
        require(quantity > 0, "Slavs: invalid count");
        require(
            _nextTokenId + quantity <= maxSupply,
            "Slavs: max supply exceeded"
        );
        require(tokenPrice * quantity == msg.value, "Slavs: no free stuff");
        treasury.transfer(msg.value);

        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(msg.sender, _nextTokenId + i);
        }

        nextTokenId += quantity;
    }

    function reserveTokens(address recipient, uint8 count) external onlyOwner {
        require(recipient != address(0), "Slavs: zero address");

        uint256 _nextTokenId = nextTokenId;

        require(count > 0, "Slavs: invalid count");
        require(
            _nextTokenId + count <= maxSupply,
            "Slavs: max supply exceeded"
        );

        require(
            tokensReserved + count <= reserveCount,
            "Slavs: max reserve count exceeded"
        );
        tokensReserved += count;

        for (uint16 ind = 0; ind < count; ind++) {
            _safeMint(recipient, _nextTokenId + ind);
        }
        nextTokenId += count;
    }

    function hashMessage(bytes32 message) internal pure returns (bytes32) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        return keccak256(abi.encodePacked(prefix, message));
    }

    function getSigner(
        bytes32 message,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        require(
            uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "invalid signature 's' value"
        );
        require(v == 27 || v == 28, "invalid signature 'v' value");
        address signer = ecrecover(hashMessage(message), v, r, s);
        require(signer != address(0), "invalid signature");

        return signer;
    }

    function recoverAddress(bytes32 message, bytes memory signature)
        internal
        pure
        returns (address)
    {
        if (signature.length != 65) {
            revert("invalid signature length");
        }
        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return getSigner(message, v, r, s);
    }

    function processSignature(
        uint16 maxCount,
        uint8 presaleId,
        bytes memory signature
    ) external view returns (address) {
        bytes32 message = formMessage(maxCount, presaleId, msg.sender);
        address signer = recoverAddress(message, signature);
        return signer;
    }

    function formMessage(
        uint16 maxCount,
        uint8 presaleId,
        address buyer
    ) public pure returns (bytes32) {
        bytes32 message = keccak256(
            abi.encodePacked(maxCount, presaleId, buyer)
        );
        return message;
    }

    function setStartingIndex() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");

        startingIndex = uint256(blockhash(startingIndexBlock)) % maxSupply;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number.sub(startingIndexBlock) > 255) {
            startingIndex = uint256(blockhash(block.number - 1)) % maxSupply;
        }
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }
    }

    function setStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");

        startingIndexBlock = block.number;
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        SLAVS_PROVENANCE = provenanceHash;
    }

    function setWhitelister(address whitelistSigner) external onlyOwner {
        require(whitelistSigner != address(0), "Slavs: zero address");

        whitelister = whitelistSigner;
    }

    function openPresale(bool changeId) external onlyOwner {
        require(
            isPresaleActive == false,
            "Slavs: to open presale, others need to be closed"
        );

        isPresaleActive = true;
        if (changeId) {
            currentPresaleId++;
        }
    }

    function closePresale() external onlyOwner {
        require(
            isPresaleActive == true,
            "Slavs: to close presale, one need to be open"
        );

        isPresaleActive = false;
    }

    function openSale() external onlyOwner {
        require(
            isSaleOpen == false,
            "Slavs: to open sale, others need to be closed"
        );

        isSaleOpen = true;
    }

    function closeSale() external onlyOwner {
        require(
            isSaleOpen == true,
            "Slavs: to close sale, one needs to be open"
        );

        isSaleOpen = false;
    }

    function setTreasury(address payable _treasury) external onlyOwner {
        treasury = _treasury;
    }

    function setBaserURI(string calldata _newBaseUri) external onlyOwner {
        baseURI = _newBaseUri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function burn(uint16 tokenId) external onlyOwner {
        _burn(tokenId);
    }

    function setTokenPrice(uint256 _tokenPrice) external onlyOwner {
        tokenPrice = _tokenPrice;
    }

    function setMaxMintPerTransaction(uint16 _maxMint) external onlyOwner {
        maxMintsPerTransaction = _maxMint;
    }

    function setPresaleTokenPrice(uint256 _tokenPrice) external onlyOwner {
        presaleTokenPrice = _tokenPrice;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseUri = _baseURI();
        string memory sequenceId;

        if (startingIndex > 0) {
            sequenceId = ((tokenId + startingIndex) % maxSupply).toString();
        } else {
            sequenceId = tokenId.toString();
        }
        return string(abi.encodePacked(baseUri, sequenceId));
    }

    function getIsPresaleActive() public view returns (bool) {
        return isPresaleActive;
    }

    function getIsSaleOpen() public view returns (bool) {
        return isSaleOpen;
    }

    function getCurrentPresaleTokensBought() public view returns (uint256) {
        return presaleBoughtCounts[currentPresaleId][msg.sender];
    }
}