// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { MerkleProofAllowlist } from "@metacrypt/contracts/allowlist/MerkleProofAllowlist.sol";
import { MetacryptERC721 } from "@metacrypt/contracts/erc721/MetacryptERC721.sol";

import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title ERC721 Contract for Afropolitan Founding Citizens
/// @author [email protected]
contract AfropolitanFC is MetacryptERC721, MerkleProofAllowlist, Ownable, Pausable {
    address private withdrawTarget;

    constructor(
        address _withdrawTarget,
        address _royaltyReceiver,
        uint96 _royaltyNumerator
    )
        MetacryptERC721(
            "Afropolitan Founding Citizen",
            "AFRO-FC",
            "https://afropolitan-drops.metacrypt.org/api/metadata/founding-citizen/",
            _royaltyReceiver,
            _royaltyNumerator
        )
    {
        withdrawTarget = _withdrawTarget;
    }

    function setMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
        _setMerkleRoot(_newMerkleRoot);
    }

    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        _setBaseURI(_newBaseURI);
    }

    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) external onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function setPaused(bool pause) external onlyOwner {
        require(paused() != pause, "Already set");
        if (pause) {
            _pause();
        } else {
            _unpause();
        }
    }

    function setWithdrawTarget(address _newWithdrawTarget) external onlyOwner {
        require(withdrawTarget != _newWithdrawTarget, "Already set");

        withdrawTarget = _newWithdrawTarget;
    }

    function claimNative() external onlyOwner {
        payable(withdrawTarget).transfer(address(this).balance);
    }

    function claimToken(address _token) external onlyOwner {
        IERC20(_token).transfer(withdrawTarget, IERC20(_token).balanceOf(address(this)));
    }

    /**
     ** Sale Parameters
     */
    uint256 public constant MAX_NFTS = 525;

    uint256 public mintTimestampPublic = 0;
    uint256 public mintTimestampAllowlist = 0;

    uint256 public mintPricePublic = 0.5 ether;
    uint256 public mintPriceAllowlist = 0.2 ether;

    uint256 public mintLimitPublic = type(uint256).max;
    uint256 public mintLimitAllowlist = 1;

    mapping(address => uint256) public mintedDuringPublicSale;
    mapping(address => uint256) public mintedDuringAllowlistSale;

    function isPublicSaleOpen() public view returns (bool) {
        return mintTimestampPublic == 0 ? false : (block.timestamp >= mintTimestampPublic);
    }

    function isAllowlistSaleOpen() public view returns (bool) {
        return mintTimestampAllowlist == 0 ? false : (block.timestamp >= mintTimestampAllowlist);
    }

    function setMintingTime(uint256 _public, uint256 _allowlist) external onlyOwner {
        mintTimestampPublic = _public;
        mintTimestampAllowlist = _allowlist;
    }

    function setMintingPrice(uint256 _public, uint256 _allowlist) external onlyOwner {
        mintPricePublic = _public;
        mintPriceAllowlist = _allowlist;
    }

    function setMintingLimits(uint256 _public, uint256 _allowlist) external onlyOwner {
        mintLimitPublic = _public;
        mintLimitAllowlist = _allowlist;
    }

    enum SaleMode {
        PUBLIC_SALE,
        ALLOWLIST_SALE
    }

    modifier passesRequirements(
        address account,
        uint256 quantity,
        SaleMode mode
    ) {
        require(totalSupply() + quantity <= MAX_NFTS, "Invalid quantity");

        if (mode == SaleMode.PUBLIC_SALE) {
            // Public Sale
            require(isPublicSaleOpen(), "Public sale not open yet");
            require(mintedDuringPublicSale[account] + quantity <= mintLimitPublic, "Minting Limit Exceeded");
            require(msg.value >= (mintPricePublic * quantity), "Invalid amount");
        } else if (mode == SaleMode.ALLOWLIST_SALE) {
            // Allowlist Sale
            require(isAllowlistSaleOpen(), "Allowlist sale not open yet");
            require(mintedDuringAllowlistSale[account] + quantity <= mintLimitAllowlist, "Minting Limit Exceeded");
            require(msg.value >= (mintPriceAllowlist * quantity), "Invalid amount");
        }
        _;
    }

    function mintPublic(address target, uint256 quantity)
        external
        payable
        passesRequirements(target, quantity, SaleMode.PUBLIC_SALE)
    {
        mintedDuringPublicSale[target] += quantity;

        _mint(target, quantity);
    }

    function mintAllowlist(
        address target,
        uint256 quantity,
        bytes32[] memory proof
    ) external payable passesRequirements(target, quantity, SaleMode.ALLOWLIST_SALE) {
        require(_isProofValid(target, proof), "Invalid proof");

        mintedDuringAllowlistSale[target] += quantity;

        _mint(target, quantity);
    }

    function mintOwner(address target, uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= MAX_NFTS, "Invalid quantity");

        _mint(target, quantity);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override whenNotPaused {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }
}