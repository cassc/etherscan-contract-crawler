// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./ERC1155MaxSupply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract CryptoonGoonzLive is ERC1155MaxSupply, ERC1155Burnable, IERC2981, Ownable {
    using ECDSA for bytes32;
    using Strings for uint256;

    address public royaltyAddress;
    uint256 public royaltyBasisPoints;
    // set to 10000 so fees are expressed in basis points
    uint256 private constant ROYALTY_DENOMINATOR = 10000;

    // IYK-controlled address to sign mint messages for txn relayers
    address public signVerifier;
    mapping(address => uint256) public mintNonces;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        address _royaltyAddress,
        uint256 _royaltyBasisPoints
    ) ERC1155MaxSupply(_name, _symbol) ERC1155(_uri) {
        royaltyAddress = _royaltyAddress;
        royaltyBasisPoints = _royaltyBasisPoints;
    }

    // Minting function with signature for txn relayers
    function mintWithSig(
        address account,
        uint256 id,
        bytes memory data,
        bytes memory sig,
        uint256 blockExpiry
    ) external virtual {
        bytes32 message = getMintSigningHash(blockExpiry, account, id).toEthSignedMessageHash();
        require(ECDSA.recover(message, sig) == signVerifier, "Permission to call this function failed");
        require(block.number < blockExpiry, "Sig expired");

        mintNonces[account]++;

        _mint(account, id, 1, data);
    }

    function getMintSigningHash(
        uint256 blockExpiry,
        address account,
        uint256 id
    ) public view virtual returns (bytes32) {
        return keccak256(abi.encodePacked(blockExpiry, account, id, address(this), mintNonces[account]));
    }

    function getMintNonce(address account) external view virtual returns (uint256) {
        return mintNonces[account];
    }

    function getSignVerifier() external view returns (address) {
        return signVerifier;
    }

    function setSignVerifier(address verifier) external onlyOwner {
        signVerifier = verifier;
    }

    function mintAndSetMaxSupply(
        address[] memory _recipients,
        uint256 _id,
        uint256 maxSupply,
        bool retired
    ) external onlyOwner {
        setMaxSupply(_id, maxSupply, retired);
        for (uint256 i = 0; i < _recipients.length; i++) {
            _mint(_recipients[i], _id, 1, "");
        }
    }

    function mint(address[] memory _recipients, uint256 _id) external onlyOwner {
        for (uint256 i = 0; i < _recipients.length; i++) {
            _mint(_recipients[i], _id, 1, "");
        }
    }

    function mintMany(
        address _recipient,
        uint256 _id,
        uint256 quantity
    ) external onlyOwner {
        _mint(_recipient, _id, quantity, "");
    }

    function setMaxSupply(
        uint256 id,
        uint256 supply,
        bool retired
    ) public onlyOwner {
        super._setMaxSupply(id, supply, retired);
    }

    function retire(uint256 id) public onlyOwner {
        super._retire(id);
    }

    function setURI(string memory newuri) external onlyOwner {
        super._setURI(newuri);
    }

    function uri(uint256 id) public view virtual override returns (string memory) {
        require(exists(id), "URI query for nonexistent token");

        return string(abi.encodePacked(super.uri(id), id.toString()));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal override(ERC1155MaxSupply, ERC1155) {
        super._mint(to, id, amount, data);
    }

    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155MaxSupply, ERC1155) {
        super._mintBatch(to, ids, amounts, data);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155MaxSupply, ERC1155) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function setRoyaltyAddress(address _royaltyAddress) external onlyOwner {
        royaltyAddress = _royaltyAddress;
    }

    function setRoyaltyBasisPoints(uint256 _royaltyBasisPoints) external onlyOwner {
        require(_royaltyBasisPoints < royaltyBasisPoints, "New royalty amount must be lower");
        royaltyBasisPoints = _royaltyBasisPoints;
    }

    /**
     * @dev See {IERC2981-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(exists(tokenId), "Non-existent token");
        return (royaltyAddress, (salePrice * royaltyBasisPoints) / ROYALTY_DENOMINATOR);
    }
}