// SPDX-License-Identifier: MIT

// ░██╗░░░░░░░██╗███████╗██████╗░███╗░░██╗██████╗░██████╗░██████╗░███████╗
// ░██║░░██╗░░██║██╔════╝██╔══██╗████╗░██║╚════██╗██╔══██╗██╔══██╗╚════██║
// ░╚██╗████╗██╔╝█████╗░░██████╦╝██╔██╗██║░█████╔╝██████╔╝██║░░██║░░███╔═╝
// ░░████╔═████║░██╔══╝░░██╔══██╗██║╚████║░╚═══██╗██╔══██╗██║░░██║██╔══╝░░
// ░░╚██╔╝░╚██╔╝░███████╗██████╦╝██║░╚███║██████╔╝██║░░██║██████╔╝███████╗
// ░░░╚═╝░░░╚═╝░░╚══════╝╚═════╝░╚═╝░░╚══╝╚═════╝░╚═╝░░╚═╝╚═════╝░╚══════╝

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "erc721a/contracts/ERC721A.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

error ContractsCannotMint();
error IncorrectSig();
error MaxMintExceeded();
error NotEnoughEth();
error SaleNotActive();
error SignerCantBeBurner();
error SoldOut();
error WithdrawFailure();

// @author web_n3rdz (n3rdz.xyz)
contract MartianTown is ERC721A, Ownable, DefaultOperatorFilterer {
    using ECDSA for bytes32;

    address private _signerAddress;

    string public baseURI;
    uint256 public maxMintOG = 3;
    uint256 public maxMintPUB = 6;
    uint256 public maxMintWL = 2;
    uint256 public maxSupply;
    uint256 public price = 0.006 ether;
    bool public saleIsActive = false;
    bool public whitelistIsActive = false;

    enum Minter {
        OG,
        PUB,
        WL
    }

    constructor(
        uint256 maxSupply_,
        address signerAddress_,
        string memory baseURI_
    ) ERC721A("MartianTown", "MT") {
        maxSupply = maxSupply_;
        _signerAddress = signerAddress_;
        baseURI = baseURI_;
    }

    // =============================================================
    //                      PUBLIC FUNCTIONS
    // =============================================================

    /**
     * @dev Mint function.
     */
    function mint(
        bytes calldata signature,
        uint256 quantity,
        Minter minter
    ) external payable noContractMint requireActiveSale(minter) {
        if (!_verifySig(msg.sender, msg.value, quantity, minter, signature))
            revert IncorrectSig();
        if (totalSupply() + quantity > maxSupply) revert SoldOut();
        if (_numberMinted(msg.sender) + quantity > _minterMaxMint(minter))
            revert MaxMintExceeded();
        if (saleIsActive && msg.value < price * quantity) revert NotEnoughEth();

        _mint(msg.sender, quantity);
    }

    /**
     * @dev Check how many tokens the given address minted.
     */
    function minterMaxMint(Minter minter) external view returns (uint256) {
        return _minterMaxMint(minter);
    }

    /**
     * @dev Check how many tokens the given address minted.
     */
    function numberMinted(address minter) external view returns (uint256) {
        return _numberMinted(minter);
    }

    // =============================================================
    //                      INTERNAL FUNCTIONS
    // =============================================================

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _minterMaxMint(Minter minter) internal view returns (uint256) {
        if (minter == Minter.PUB) {
            return maxMintPUB;
        }

        if (minter == Minter.OG) {
            return maxMintOG;
        }

        return maxMintWL;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _verifySig(
        address sender,
        uint256 valueSent,
        uint256 quantity,
        Minter minter,
        bytes memory signature
    ) internal view returns (bool) {
        bytes32 messageHash = keccak256(
            abi.encodePacked(sender, valueSent, quantity, uint256(minter))
        );
        return
            _signerAddress ==
            messageHash.toEthSignedMessageHash().recover(signature);
    }

    // =============================================================
    //                      OWNER FUNCTIONS
    // =============================================================

    /**
     * @dev Aidrop tokens to given address (onlyOwner).
     */
    function airdop(address receiver, uint256 quantity) external onlyOwner {
        if (totalSupply() + quantity > maxSupply) revert SoldOut();
        _mint(receiver, quantity);
    }

    /**
     * @dev Flip public sale state (onlyOwner).
     */
    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /**
     * @dev Flip WL sale state (onlyOwner).
     */
    function flipWhitelistSaleState() external onlyOwner {
        whitelistIsActive = !whitelistIsActive;
    }

    /**
     * @dev Set base uri for token metadata (onlyOwner).
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    /**
     * @dev Set max mint per address for OG (onlyOwner).
     */
    function setMaxMintOG(uint256 maxMintOG_) external onlyOwner {
        maxMintOG = maxMintOG_;
    }

    /**
     * @dev Set max mint per address for PUB (onlyOwner).
     */
    function setMaxMintPUB(uint256 maxMintPUB_) external onlyOwner {
        maxMintPUB = maxMintPUB_;
    }

    /**
     * @dev Set max mint per address for WL (onlyOwner).
     */
    function setMaxMintWL(uint256 maxMintWL_) external onlyOwner {
        maxMintWL = maxMintWL_;
    }

    /**
     * @dev Set signer address (onlyOwner).
     */
    function setSignerAddress(address signerAddress_) external onlyOwner {
        if (signerAddress_ == address(0)) revert SignerCantBeBurner();
        _signerAddress = signerAddress_;
    }

    /**
     * @dev Set Price (onlyOwner).
     */
    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    /**
     * @dev Withdraw all funds (onlyOwner).
     */
    function withdrawAll() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) revert WithdrawFailure();
    }

    // =============================================================
    //                  OPERATOR FILTER REGISTRY
    // =============================================================

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

    // =============================================================
    //                        MODIFIERS
    // =============================================================

    /**
     * @dev Requires active sale.
     */
    modifier requireActiveSale(Minter minter) {
        if (!saleIsActive && !whitelistIsActive) revert SaleNotActive();
        if (minter == Minter.PUB && !saleIsActive) revert SaleNotActive();
        _;
    }

    /**
     * @dev Requires no contract minting.
     */
    modifier noContractMint() {
        if (msg.sender != tx.origin) revert ContractsCannotMint();
        _;
    }
}