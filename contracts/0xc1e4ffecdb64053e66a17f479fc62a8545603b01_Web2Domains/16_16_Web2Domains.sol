// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract Web2Domains is ERC721, Pausable, AccessControl, EIP712 {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    string private _baseURIextended;
    mapping(bytes32 => bool) signatureUsed;

    constructor(string memory _base)
        ERC721("Web2.Domains", "W2D")
        EIP712("Web2.Domains", "1.0.0")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        setBaseURI(_base);
    }

    function setBaseURI(string memory baseURI_) public onlyRole(MINTER_ROLE) {
        _baseURIextended = baseURI_;
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

    function _getMintHash(
        address to,
        string memory domain,
        uint256 maxBlock,
        uint256 minPrice
    ) internal view returns (bytes32) {
        return
            ECDSA.toEthSignedMessageHash(
                keccak256(
                    abi.encodePacked(
                        domainSeparatorV4(),
                        to,
                        domain,
                        maxBlock,
                        minPrice
                    )
                )
            );
    }

    function _validateMint(
        bytes memory signature,
        address to,
        string memory domain,
        uint256 maxBlock,
        uint256 minPrice,
        uint256 tokenId
    ) internal {
        require(to == msg.sender, "invalid sender");
        require(!signatureUsed[keccak256(signature)]);
        require(!_exists(tokenId), "token exists");
        require(block.number < maxBlock, "block too late");
        require(msg.value >= minPrice, "value too low");

        bytes32 digest = _getMintHash(to, domain, maxBlock, minPrice);
        address signer = ECDSA.recover(digest, signature);
        require(hasRole(MINTER_ROLE, signer), "invalid signer");

        signatureUsed[keccak256(signature)] = true;
    }

    event Mint(address to, string domain, uint256 tokenId);

    function mint(
        bytes calldata signature,
        address to,
        string calldata domain,
        uint256 maxBlock,
        uint256 minPrice
    ) public payable {
        uint256 tokenId = uint256(keccak256(abi.encodePacked(domain)));
        _validateMint(signature, to, domain, maxBlock, minPrice, tokenId);
        _safeMint(to, tokenId);
        emit Mint(to, domain, tokenId);
    }

    function burn(uint256 tokenId) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner or approved"
        );
        _burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}