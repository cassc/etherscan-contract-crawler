// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {
    MerkleProof
} from "lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";

import { Address } from "lib/openzeppelin-contracts/contracts/utils/Address.sol";
import { ERC721SeaDrop } from "./ERC721SeaDrop.sol";

contract KultDolceRoyals is ERC721SeaDrop {
    uint256 public whitelistMintFee;
    uint256 public publicMintFee;
    address public mintFeeReceiver;
    mapping(address => uint256) public whitelistMinted;
    mapping(address => uint256) public publicMinted;
    bytes32 public whitelistMerkleRoot;
    bool public whitelistMintActive;
    bool public publicMintActive;
    uint8 constant RESERVE_COUNT = 90;
    uint8 public whitelistMintLimitPerTx = 1;
    uint8 public whitelistMintMaxLimit = 1;
    uint8 public publicMintLimitPerTx = 1;
    uint8 public publicMintMaxLimit = 1;

    function _canMint(uint256 quantity) internal view {
        require(_totalMinted() <= maxSupply(), "REACHED_MAX_SUPPLY");
        require(quantity > 0, "QUANTITY_LESS_THAN_ONE");
        require(
            _totalMinted() + quantity <= maxSupply(),
            "QUANTITY_EXCEEDED_MAX_SUPPLY"
        );
    }

    constructor(
        string memory name,
        string memory symbol,
        address[] memory allowedSeaDrop,
        address mintFeeReceiver_,
        uint256 whitelistMintFee_,
        uint256 publicMintFee_
    ) ERC721SeaDrop(name, symbol, allowedSeaDrop) {
        mintFeeReceiver = mintFeeReceiver_;
        whitelistMintFee = whitelistMintFee_;
        publicMintFee = publicMintFee_;

        // Reserve tokens
        _safeMint(msg.sender, RESERVE_COUNT);
    }

    function setWhitelistMintFee(uint256 _whitelistMintFee) external onlyOwner {
        whitelistMintFee = _whitelistMintFee;
    }

    function setPublicMintFee(uint256 _publicMintFee) external onlyOwner {
        publicMintFee = _publicMintFee;
    }

    function setMintFeeReceiver(address mintFeeReceiver_) external onlyOwner {
        mintFeeReceiver = mintFeeReceiver_;
    }

    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistMerkleRoot = merkleRoot;
    }

    function setMintActive(bool _whitelistMintActive, bool _publicMintActive)
        external
        nonReentrant
        onlyOwner
    {
        whitelistMintActive = _whitelistMintActive;
        publicMintActive = _publicMintActive;
    }

    function setWhitelistMintLimitPerTx(uint8 _whitelistMintLimitPerTx)
        external
        onlyOwner
    {
        whitelistMintLimitPerTx = _whitelistMintLimitPerTx;
    }

    function setWhitelistMintMaxLimit(uint8 _whitelistMintMaxLimit)
        external
        onlyOwner
    {
        whitelistMintMaxLimit = _whitelistMintMaxLimit;
    }

    function setPublicMintLimitPerTx(uint8 _publicMintLimitPerTx)
        external
        onlyOwner
    {
        publicMintLimitPerTx = _publicMintLimitPerTx;
    }

    function setPublicMintMaxLimit(uint8 _publicMintMaxLimit)
        external
        onlyOwner
    {
        publicMintMaxLimit = _publicMintMaxLimit;
    }

    // Custom mints
    function mintWhitelist(
        bytes32[] calldata whitelistMerkleProof,
        uint8 quantity
    ) external payable nonReentrant {
        _canMint(quantity);
        require(whitelistMintActive, "WHITELIST_MINT_INACTIVE");
        require(
            MerkleProof.verify(
                whitelistMerkleProof,
                whitelistMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "INVALID_MERKLE_PROOF"
        );
        require(
            quantity <= whitelistMintLimitPerTx,
            "REACHED_WHITELIST_MINT_CAP_PER_TX"
        );
        require(
            whitelistMinted[msg.sender] + quantity <= whitelistMintMaxLimit,
            "REACHED_WHITELIST_MINT_CAP"
        );

        uint256 fee = whitelistMintFee * quantity;

        _transferInETH(fee);
        _transferOutETH(mintFeeReceiver, fee);

        _safeMint(msg.sender, quantity);

        whitelistMinted[msg.sender] += quantity;
    }

    function mintPublic(uint8 quantity) external payable nonReentrant {
        _canMint(quantity);
        require(publicMintActive, "PUBLIC_MINT_INACTIVE");
        require(
            quantity <= publicMintLimitPerTx,
            "REACHED_PUBLIC_MINT_CAP_PER_TX"
        );
        require(
            publicMinted[msg.sender] + quantity <= publicMintMaxLimit,
            "REACHED_PUBLIC_MINT_CAP"
        );

        uint256 fee = publicMintFee * quantity;

        _transferInETH(fee);
        _transferOutETH(mintFeeReceiver, fee);

        _safeMint(msg.sender, quantity);

        publicMinted[msg.sender] += quantity;
    }

    // Custom helpers
    function _transferInETH(uint256 amount) internal {
        require(msg.value >= amount, "INSUFFICIENT_ETH_RECEIVED");
    }

    function _transferOutETH(address receiver, uint256 amount) internal {
        require(amount > 0, "INVALID_AMOUNT");
        require(address(this).balance >= amount, "INSUFFICIENT_ETH_BALANCE");

        Address.sendValue(payable(receiver), amount);
    }
}