// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract NuggiesLive is ERC1155, Ownable {
    using ECDSA for bytes32;
    using Strings for uint256;

    string public name = "For The Culture Game Tokens";

    address private systemAddress;
    address public burnContract;
    mapping(address => mapping(uint256 => bool)) public claimed;
    string private _baseURI;

    constructor(string memory baseUri, address _systemAddress) ERC1155("") {
        _baseURI = baseUri;
        systemAddress = _systemAddress;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function uri(uint256 id) public view virtual override returns (string memory) {
        string memory baseURI = _baseURI;
        return string.concat(baseURI, id.toString(), ".json");
    }

    function setSystemAddress(address _systemAddress) public onlyOwner {
        systemAddress = _systemAddress;
    }

    function setBurnContract(address _burnContract) public onlyOwner {
        burnContract = _burnContract;
    }

    function mint(uint256 id, uint256 amount, bytes memory signature) public {
        require(amount < 11, "Exceeds max mint");
        require(systemAddress != address(0), "System Addres not Set");
        require(!claimed[_msgSender()][id], "Already Claimed");
        bytes32 msgHash = keccak256(abi.encodePacked(msg.sender, id));
        require(isValidSignature(msgHash, signature), "Invalid signature");

        claimed[_msgSender()][id] = true;

        _mint(_msgSender(), id, amount, "0x0");
    }

    function isValidSignature(
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool isValid) {
        bytes32 signedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
        return signedHash.recover(signature) == systemAddress;
    }

    function burn(address account, uint256 id, uint256 value) public virtual {
        require(
            account == _msgSender() ||
                isApprovedForAll(account, _msgSender()) ||
                account == burnContract,
            "ERC1155: caller is not token owner or approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() ||
                isApprovedForAll(account, _msgSender()) ||
                account == burnContract,
            "ERC1155: caller is not token owner or approved"
        );

        _burnBatch(account, ids, values);
    }
}