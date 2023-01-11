// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract Web2Domains is
    ERC721,
    ERC721Enumerable,
    Pausable,
    AccessControlEnumerable,
    EIP712
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");
    string private _baseURIextended;
    address payable private _feeRecipient;
    mapping(bytes32 => bool) private signatureUsed;
    mapping(uint256 => uint256) public expirations;

    constructor(
        string memory _base
    ) ERC721("Web2.Domains", "W2D") EIP712("Web2.Domains", "1.0.0") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(BURNER_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, msg.sender);
        _grantRole(BRIDGE_ROLE, msg.sender);
        setBaseURI(_base);
        setFeeRecipient(payable(msg.sender));
    }

    function setBaseURI(string memory baseURI_) public onlyRole(MANAGER_ROLE) {
        _baseURIextended = baseURI_;
    }

    function setFeeRecipient(
        address payable feeRecipient_
    ) public onlyRole(MANAGER_ROLE) {
        _feeRecipient = feeRecipient_;
    }

    function domainSeparatorV4() public view returns (bytes32) {
        return _domainSeparatorV4();
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    bytes32 constant MINT_TYPEHASH =
        keccak256(
            "Mint(string domain,uint256 maxBlock,uint256 minPrice,uint256 expireAt)"
        );

    function _getMintHash(
        string memory domain,
        uint256 maxBlock,
        uint256 minPrice,
        uint256 expireAt
    ) internal view returns (bytes32) {
        return
            ECDSA.toEthSignedMessageHash(
                keccak256(
                    abi.encodePacked(
                        domainSeparatorV4(),
                        MINT_TYPEHASH,
                        domain,
                        maxBlock,
                        minPrice,
                        expireAt
                    )
                )
            );
    }

    function _validateMint(
        bytes memory signature,
        string memory domain,
        uint256 maxBlock,
        uint256 minPrice,
        uint256 expireAt
    ) internal view {
        require(!signatureUsed[keccak256(signature)], "signature used");
        require(block.number < maxBlock, "block too late");
        require(msg.value >= minPrice, "value too low");

        bytes32 digest = _getMintHash(domain, maxBlock, minPrice, expireAt);
        address signer = ECDSA.recover(digest, signature);
        require(hasRole(MINTER_ROLE, signer), "Invalid signer");
    }

    event Mint(address to, string indexed domain, uint256 indexed tokenId);

    function mint(
        bytes calldata signature,
        string calldata domain,
        uint256 maxBlock,
        uint256 minPrice,
        uint256 expireAt
    ) public payable whenNotPaused {
        uint256 tokenId = uint256(keccak256(abi.encodePacked(domain)));
        _validateMint(signature, domain, maxBlock, minPrice, expireAt);

        signatureUsed[keccak256(signature)] = true;
        expirations[tokenId] = expireAt;
        _safeMint(msg.sender, tokenId);
        emit Mint(msg.sender, domain, tokenId);
    }

    function mintBridge(
        address to,
        string calldata domain,
        uint256 expireAt
    ) public whenNotPaused onlyRole(BRIDGE_ROLE) {
        uint256 tokenId = uint256(keccak256(abi.encodePacked(domain)));

        expirations[tokenId] = expireAt;
        _safeMint(to, tokenId);
    }

    bytes32 constant RENEW_TYPEHASH =
        keccak256(
            "Renew(string domain,uint256 maxBlock,uint256 minPrice,uint256 expireAt)"
        );

    function _getRenewHash(
        string memory domain,
        uint256 maxBlock,
        uint256 minPrice,
        uint256 expireAt
    ) internal view returns (bytes32) {
        return
            ECDSA.toEthSignedMessageHash(
                keccak256(
                    abi.encodePacked(
                        domainSeparatorV4(),
                        RENEW_TYPEHASH,
                        domain,
                        maxBlock,
                        minPrice,
                        expireAt
                    )
                )
            );
    }

    function _validateRenew(
        bytes memory signature,
        string memory domain,
        uint256 maxBlock,
        uint256 minPrice,
        uint256 tokenId,
        uint256 expireAt
    ) internal view {
        require(!signatureUsed[keccak256(signature)], "Used Signature");
        require(_exists(tokenId), "token does not exists");
        require(block.number < maxBlock, "block too late");
        require(msg.value >= minPrice, "value too low");

        bytes32 digest = _getRenewHash(domain, maxBlock, minPrice, expireAt);
        address signer = ECDSA.recover(digest, signature);
        require(hasRole(MINTER_ROLE, signer), "Invalid signer");
    }

    event Renew(string indexed domain, uint256 indexed tokenId);

    function renew(
        bytes calldata signature,
        string calldata domain,
        uint256 maxBlock,
        uint256 minPrice,
        uint256 expireAt
    ) public payable whenNotPaused {
        uint256 tokenId = uint256(keccak256(abi.encodePacked(domain)));
        _validateRenew(
            signature,
            domain,
            maxBlock,
            minPrice,
            tokenId,
            expireAt
        );

        signatureUsed[keccak256(signature)] = true;
        expirations[tokenId] = expireAt;
        emit Renew(domain, tokenId);
    }

    function withdraw() public {
        require(_feeRecipient != address(0), 'Fee recipient not set');
        _feeRecipient.transfer(address(this).balance);
    }

    function burn(uint256 tokenId) public whenNotPaused {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner or approved"
        );
        _burn(tokenId);
    }

    function burnExpired(uint256 tokenId) public whenNotPaused {
        require(expirations[tokenId] < block.timestamp, "Not expired");
        _burn(tokenId);
    }

    function burnAdmin(uint256 tokenId) public onlyRole(BURNER_ROLE) {
        _burn(tokenId);
    }

    event RequestImport(address indexed user, string indexed domain, uint deposit);
    function requestImport(string calldata domain) payable public {
        emit RequestImport(msg.sender, domain, msg.value);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        if (to != address(0)) {
            require(expirations[tokenId] > block.timestamp, "Domain expired");
        }
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721, AccessControlEnumerable, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}