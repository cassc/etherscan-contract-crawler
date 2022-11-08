// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "../libraries/SafeOwnable.sol";
import "../libraries/Verifier.sol";

contract Manifestation is SafeOwnable, ERC1155BurnableUpgradeable, Verifier {
    using StringsUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using ECDSAUpgradeable for bytes32;

    string private constant _HEX_SYMBOLS = "ETHEREUM_CUSTOM_EXTERNAL_SIGN_MSG_PREFIX";

    mapping(uint256 => uint256) public totalSupply;
    mapping(uint256 => uint256) public haveMinted;

    function initialize(uint256[] memory _equipments, uint256[] memory _mintTotalSupply, string memory url) public initializer {
        require(_equipments.length == _mintTotalSupply.length, "Deploy: param not enough");

        for (uint i = 0; i < _equipments.length; i++) {
            totalSupply[_equipments[i]] = _mintTotalSupply[i];
        }

        __ERC1155_init(url);
        _transferOwnership(msg.sender);
    }

    function setMintAmount(uint256 index, uint256 amount) external onlyOwner {
        totalSupply[index] = amount;
    }

    function setURI(string calldata newURI) external onlyOwner {
        _setURI(newURI);
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        string memory currentBaseURI = super.uri(tokenId);
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json")) : "";
    }

    function convertHash(bytes32 _hash) private pure returns (bytes32 hash) {
        uint256 value = uint256(_hash);
        string memory hexMsg = value.toHexString(32);
        hash = sha256(abi.encodePacked(_HEX_SYMBOLS, hexMsg));
    }

    function verifyMintParam(address account, uint256 tokenId, uint256 amount, uint8 v, bytes32 r, bytes32 s) private view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(account, "_", tokenId, "_", amount, "_", block.chainid, "_", address(this)));
        bytes32 cHash = convertHash(hash);
        return verifier == cHash.recover(v, r, s);
    }

    function mint(address to, uint256 id, uint256 amount, uint8 v, bytes32 r, bytes32 s) external {
        require(verifyMintParam(to, id, amount, v, r, s), "Mint: verify failed");

        haveMinted[id] += amount;
        require(haveMinted[id] <= totalSupply[id], "Mint: more than totalSupply");
        _mint(to, id, amount, "");
    }

    function recoverWrongToken(address token, address to) public onlyOwner {
        if (token == address(0)) {
            payable(to).transfer(address(this).balance);
        } else {
            uint256 balance = IERC20Upgradeable(token).balanceOf(address(this));
            IERC20Upgradeable(token).safeTransfer(to, balance);
        }
    }
}