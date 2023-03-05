// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Tsuna Mint
/// @author @whiteoakkong

//phase 0 - Vault Mint
//phase 1 - V2 + Public Mint
//phase 2 - V1 Mint

import "open-zeppelin/contracts/access/Ownable.sol";
import "ERC721A/contracts/ERC721A.sol";
import "open-zeppelin/contracts/utils/cryptography/ECDSA.sol";
import "open-zeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Tsuna is ERC721A("Tsuna", "TSUNA"), Ownable, DefaultOperatorFilterer {
    using ECDSA for bytes32;
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 6777;
    uint256 public constant V2_CAP = 5666;
    uint256 public constant VAULT_SUPPLY = 111;
    uint256 public constant WALLET_MAX = 2;

    uint256 public priceV2 = 0.019 ether;
    uint256 public pricePublic = 0.029 ether;

    uint256 public phase;

    address public tsunaVault;
    address public signer = 0xf8e8Cf9116f91d3ec574a3aF417462F9E16fb585;

    string public baseURI = "metadata.tsunaworld.com/";
    string private uriExtension = "";

    //=========================================================================

    receive() external payable {}

    function mintV2(uint64 quantity, bytes memory signature) external payable {
        require(phase == 1, "Invalid phase");
        require(_totalMinted() + quantity <= V2_CAP, "Invalid quantity");
        require(msg.value >= priceV2 * quantity, "Invalid value");
        require(
            _isValidSignature(signature, msg.sender, 1),
            "Invalid signature"
        );
        uint64 aux = _getAux(msg.sender);
        require(aux + quantity <= 2, "Already minted");
        _setAux(msg.sender, aux + quantity);
        _mint(msg.sender, quantity);
    }

    function mintPublic(uint64 quantity) external payable {
        require(tx.origin == msg.sender, "Invalid sender");
        require(phase == 1, "Invalid phase");
        require(_totalMinted() + quantity <= V2_CAP, "Invalid quantity");
        require(msg.value >= pricePublic * quantity, "Invalid value");
        uint64 aux = _getAux(msg.sender);
        require(aux + quantity <= 2, "Already minted");
        _setAux(msg.sender, aux + quantity);
        _mint(msg.sender, quantity);
    }

    function mintV1(bytes memory signature) external payable {
        require(phase == 2, "Invalid phase");
        require(_totalMinted() < MAX_SUPPLY, "Invalid quantity");
        require(
            _isValidSignature(signature, msg.sender, 2),
            "Invalid signature"
        );
        uint64 aux = _getAux(msg.sender);
        require(aux < 3, "Already minted");
        _setAux(msg.sender, 3);
        _mint(msg.sender, 1);
    }

    // ========== ACCESS CONTROLLED ==========

    ///@notice Function to mint tokens to the vault address.
    function mintVault(uint64 quantity) external onlyOwner {
        require(_totalMinted() + quantity <= MAX_SUPPLY, "Invalid quantity");
        _mint(tsunaVault, quantity);
    }

    ///@notice Function to set the price for V2 and Public mint.
    function setPrice(uint256 _type, uint256 _price) external onlyOwner {
        if (_type == 1) priceV2 = _price;
        if (_type == 2) pricePublic = _price;
    }

    ///@notice Function to set the vault address.
    function setVault(address _vault) external onlyOwner {
        tsunaVault = _vault;
    }

    ///@notice Function to set the phase.
    function setPhase(uint256 _phase) external onlyOwner {
        phase = _phase;
    }

    ///@notice Function to withdraw funds from the contract to vault address.
    ///@dev Cannot withdraw to 0 address.
    function withdraw(uint256 amount) external onlyOwner {
        require(tsunaVault != address(0), "Invalid address");
        (bool success, ) = payable(tsunaVault).call{value: amount}("");
        require(success, "Transfer failed.");
    }

    ///@notice Function to set the signer address.
    function updateSigner(address _signer) external onlyOwner {
        require(_signer != address(0), "Invalid address");
        signer = _signer;
    }

    ///@notice Function to set the uri extension.
    function updateExtension(string memory _ext) external onlyOwner {
        uriExtension = _ext;
    }

    ///@notice Function to set the baseURI for the contract.
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    // ========== UTILITY ==========

    ///@notice internal signature validation function.
    function _isValidSignature(
        bytes memory signature,
        address _address,
        uint256 _phase
    ) internal view returns (bool) {
        bytes32 data = keccak256(abi.encodePacked(_address, _phase));
        return signer == data.toEthSignedMessageHash().recover(signature);
    }

    ///@notice Function to return tokenURI.
    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return
            string(
                abi.encodePacked(
                    baseURI,
                    Strings.toString(_tokenId),
                    uriExtension
                )
            );
    }

    ///@notice Overriding the default tokenID start to 1.
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    // ============ OPERATOR-FILTER-OVERRIDES ============

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}