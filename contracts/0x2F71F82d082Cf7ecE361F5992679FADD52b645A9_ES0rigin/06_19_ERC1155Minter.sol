// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import { ERC1155Pausable } from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import { ERC1155Supply } from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract ERC1155Minter is Ownable, ERC1155Pausable, ERC1155Supply, EIP712 {
    error CallerNotUser();
    error MintNotOpen();
    error TokenAlreadyMinted(uint256 id);
    error TokenSoldOut(uint256 id);
    error SignatureVerificationFailed();
    error NonexistentId(uint256 id);

    event MintStarted(uint256 maxSupplyPerToken, uint256 maxId);
    event MintStopped();

    struct MintConfig {
        address signer;
        uint256 maxSupplyPerToken;
        uint256 maxId;
    }

    string public name;
    string public symbol;
    bool public isMintOpen = false;
    MintConfig public mintConfig;
    bytes32 public constant MINT_TYPEHASH = keccak256("Mint(address wallet,uint256[] ids)");
    // Mapping from token type id to account current mint amount
    mapping(uint256 => mapping(address => uint8)) public currentMintedPerAddress;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory uri_
    ) ERC1155(uri_) EIP712(name_, "1") {
        name = name_;
        symbol = symbol_;
    }

    /**
     * @notice Caller is an externally owned account
     */
    modifier callerIsUser() {
        if (tx.origin != _msgSender()) {
            revert CallerNotUser();
        }
        _;
    }

    /**
     * @notice Execute function when mint is open
     */
    modifier whenMintOepn() {
        if (!isMintOpen) {
            revert MintNotOpen();
        }
        _;
    }

    /**
     * @notice Mint tokens
     * @param ids list of tokens to be minted
     * @param signature caller verification
     */
    function mint(uint256[] calldata ids, bytes calldata signature) external callerIsUser whenMintOepn {
        if (!verifySignature(ids, signature)) {
            revert SignatureVerificationFailed();
        }

        uint8 mintQuantity = 1;
        address to = _msgSender();

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            if (id > mintConfig.maxId) {
                revert NonexistentId(id);
            }
            if (totalSupply(id) + mintQuantity > mintConfig.maxSupplyPerToken) {
                revert TokenSoldOut(id);
            }
            if (currentMintedPerAddress[id][to] > 0) {
                revert TokenAlreadyMinted(id);
            }

            currentMintedPerAddress[id][to] = mintQuantity;
            _mint(to, id, mintQuantity, "");
        }
    }

    /**
     * @notice Start mint
     * @param signer signature signer
     * @param maxSupplyPerToken maximum amount for each token type
     * @param maxId maximum token type id
     */
    function startMint(address signer, uint256 maxSupplyPerToken, uint256 maxId) external onlyOwner {
        mintConfig.signer = signer;
        mintConfig.maxSupplyPerToken = maxSupplyPerToken;
        mintConfig.maxId = maxId;
        isMintOpen = true;
        emit MintStarted(maxSupplyPerToken, maxId);
    }

    /**
     * @notice Stop mint
     */
    function stopMint() external onlyOwner {
        isMintOpen = false;
        emit MintStopped();
    }

    /**
     * @notice Pause all token operations
     * Dealing with unforeseen circumstances, under community supervision
     */
    function emergencyPause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Batch query tokens' total supply
     * @param ids list of token type id
     */
    function batchQueryTotalSupply(uint256[] calldata ids) external view returns (uint256[] memory) {
        uint256[] memory list = new uint256[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            list[i] = totalSupply(ids[i]);
        }
        return list;
    }

    /**
     * @notice Batch query accounts' balances
     * @param account address to be queried
     * @param ids list of token type id 
     */
    function batchQueryBalance(address account, uint256[] calldata ids) external view returns (uint256[] memory) {
        uint256[] memory list = new uint256[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            list[i] = balanceOf(account, ids[i]);
        }
        return list;
    }

    /**
     * @notice Batch query current mint amount
     * @param account address to be queried
     * @param ids list of token type id 
     */
    function batchQueryCurrentMinted(address account, uint256[] calldata ids) external view returns (uint256[] memory) {
        uint256[] memory list = new uint256[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            list[i] = currentMintedPerAddress[ids[i]][account];
        }
        return list;
    }

    /**
     * @notice Used to verify mint signature
     * @param ids list of tokens
     * @param signature mint signature
     */
    function verifySignature(uint256[] memory ids, bytes memory signature) internal view returns (bool) {
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(MINT_TYPEHASH, _msgSender(), keccak256(abi.encodePacked(ids)))));
        return ECDSA.recover(digest, signature) == mintConfig.signer;
    }

    /**
     * @notice See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155Pausable, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}