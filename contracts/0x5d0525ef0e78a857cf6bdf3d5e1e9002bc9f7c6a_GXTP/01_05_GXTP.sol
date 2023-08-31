// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.20;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {ECDSA} from "solady/utils/ECDSA.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";

error AlreadyMinted();
error InvalidSignature();
error MintingClosed();
error Unauthorized();

contract GXTP is ERC721 {
    using ECDSA for bytes32;
    using Strings for uint256;

    bool public mintingOpen = true;
    uint256 public totalSupply = 0;
    address internal expectedSigner;
    address internal mintingToggler;
    address internal metadataOwner;
    string internal baseURI;
    mapping(address minter => bool used) public minted;
    mapping(uint256 tokenId => uint256 type_) public types;

    constructor(address _expectedSigner, address _mintingToggler, string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        expectedSigner = _expectedSigner;
        mintingToggler = _mintingToggler;
        metadataOwner = msg.sender;
    }

    function toggleMinting() external {
        if (msg.sender != mintingToggler) revert Unauthorized();
        mintingOpen = !mintingOpen;
    }

    function mint(bytes calldata signature, uint256 type_) external {
        if (!mintingOpen) revert MintingClosed();
        if (minted[msg.sender]) revert AlreadyMinted();
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                type_,
                DOMAIN_SEPARATOR(),
                keccak256(abi.encode(msg.sender))
            )
        );

        if (digest.recover(signature) != expectedSigner) revert InvalidSignature();

        types[totalSupply] = type_;
        minted[msg.sender] = true;
        _mint(msg.sender, totalSupply++);
    }

    function DOMAIN_SEPARATOR() public view returns (bytes32 separator) {
        separator = keccak256(
            abi.encode(keccak256("EIP712Domain(uint256 chainId, address collection)"), block.chainid, address(this))
        );
    }

    function setExpectedSigner(address _expectedSigner) external {
        if (msg.sender != expectedSigner) revert Unauthorized();
        expectedSigner = _expectedSigner;
    }

    function setMintingToggler(address _mintingToggler) external {
        if (msg.sender != _mintingToggler) revert Unauthorized();
        mintingToggler = _mintingToggler;
    }

    function setMetadataOwner(address _metadataOwner) external {
        if (msg.sender != metadataOwner) revert Unauthorized();
        metadataOwner = _metadataOwner;
    }

    function setBaseURI(string calldata _baseURI) external {
        if (msg.sender != metadataOwner) revert Unauthorized();
        baseURI = _baseURI;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return string.concat(baseURI, id.toString());
    }
}