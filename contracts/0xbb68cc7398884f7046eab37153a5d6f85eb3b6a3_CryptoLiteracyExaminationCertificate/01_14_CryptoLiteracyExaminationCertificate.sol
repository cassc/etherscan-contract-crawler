// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract CryptoLiteracyExaminationCertificate is ERC1155, AccessControl, Ownable {
    using ECDSA for bytes32;
    using Strings for uint256;

    // Role
    bytes32 public constant ADMIN = "ADMIN";

    // Signature
    mapping(uint256 => uint256) public nonces;
    address private signer;

    // Metadata
    string public name = "Crypto Literacy Examination Certificate";
    string public symbol = "CLEC";
    string public baseURI;
    string public baseExtension = ".json";

    // Modifier
    modifier doNotHave(uint256 _tokenId, address _address) {
        require(balanceOf(_address, _tokenId) == 0, 'Already have');
        _;
    }
    modifier isValidSignature (uint256 _tokenId, address _address, bytes calldata _signature) {
        address recoveredAddress = keccak256(
            abi.encodePacked(
                _address,
                _tokenId,
                nonces[_tokenId]
            )
        ).toEthSignedMessageHash().recover(_signature);
        require(recoveredAddress == signer, "Invalid Signature");
        _;
    }

    // Constructor
    constructor() ERC1155("") {
        _grantRole(ADMIN, msg.sender);
    }

    // Mint
    function mint(uint256 _tokenId, bytes calldata _signature) external
        doNotHave(_tokenId, msg.sender)
        isValidSignature(_tokenId, msg.sender, _signature)
    {
        _mint(msg.sender, _tokenId, 1, "");
        nonces[_tokenId]++;
    }
    function airdrop(uint256 _tokenId, address[] calldata _addresses) external onlyRole(ADMIN) {
        for (uint256 i = 0; i < _addresses.length; i++) {
            if (balanceOf(_addresses[i], _tokenId) > 0) continue;
            _mint(_addresses[i], _tokenId, 1, "");
        }
    }

    // Getter
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseURI, tokenId.toString(), baseExtension));
    }

    // Setter
    function setSigner(address _value) external onlyRole(ADMIN) {
        signer = _value;
    }
    function setBaseURI(string memory _value) external onlyRole(ADMIN) {
        baseURI = _value;
    }
    function setBaseExtension(string memory _value) external onlyRole(ADMIN) {
        baseExtension = _value;
    }
    function resetBaseExtension() external onlyRole(ADMIN) {
        baseExtension = "";
    }

    // AccessControl
    function grantRole(bytes32 role, address account) public override onlyOwner {
        _grantRole(role, account);
    }
    function revokeRole(bytes32 role, address account) public override onlyOwner {
        _revokeRole(role, account);
    }

    // SBT
    function setApprovalForAll(address, bool) public virtual override {
        revert("This token is SBT");
    }
    function _beforeTokenTransfer(address, address from, address to, uint256[] memory ids, uint256[] memory, bytes memory) internal virtual override {
        for (uint256 i = 0; i < ids.length; i++) {
            require(from == address(0) || to == address(0), "This token is SBT");
        }
    }

    // interface
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool) {
        return
            ERC1155.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }
}