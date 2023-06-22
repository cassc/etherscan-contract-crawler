//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract UMA is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply {
    string public constant name = "UASIS METASPACE APPAREL";
    string public constant symbol = "UMA";

    uint256 public mintIndex;
    uint256 public tokensSupply;

    address private _signer;
    mapping(uint256 => uint256) private _signatureIds;

    constructor(
        string memory _uri,
        address signer
    ) ERC1155(_uri) {
        _signer = signer;
    }

    function mint(
        uint256 price,
        uint256 tokenId,
        uint256 amount,
        uint256 signatureId,
        bytes memory signature
    ) public payable {
        require(
            _signatureIds[signatureId] == 0,
            "signatureId already used"
        );

        require(
            checkMintSignature(msg.sender, price, tokenId, amount, signatureId, signature) == _signer,
            "Not authorized to mint"
        );

        require(
            msg.value == price * amount,
            "Ether value sent is not correct"
        );

        _signatureIds[signatureId] = 1;
        mintIndex++;

        if (!exists(tokenId)) {
            tokensSupply++;
        }

        _mint(msg.sender, tokenId, amount, "");
    }

    function mintBatch(
        uint256 tokenId,
        address[] memory to,
        uint256[] memory amounts
    ) public onlyOwner {
        if (!exists(tokenId)) {
            tokensSupply++;
        }

        for (uint256 i = 0; i < to.length; i++) {
            _mint(to[i], tokenId, amounts[i], "");
        }
    }

    function setURI(string memory newURI) public onlyOwner {
        _setURI(newURI);
    }

    function setSigner(address signer) external onlyOwner {
        _signer = signer;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function checkMintSignature(
        address wallet,
        uint256 price,
        uint256 tokenId,
        uint256 amount,
        uint256 signatureId,
        bytes memory signature
    ) public pure returns (address) {
        return ECDSA.recover(
            ECDSA.toEthSignedMessageHash(
                keccak256(abi.encode(wallet, price, tokenId, amount, signatureId))
            ), signature
        );
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    internal
    override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}