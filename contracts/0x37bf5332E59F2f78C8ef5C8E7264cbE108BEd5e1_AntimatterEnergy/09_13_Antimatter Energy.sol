// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";

import "./interfaces/IEnergy.sol";

import "hardhat/console.sol";

contract AntimatterEnergy is IEnergy, ERC721A, Ownable, ReentrancyGuard {
    string private metaURI;

    uint256 public constant MAX_SUPPLY = type(uint256).max;
    bool public collectStatus;
    address public override energyFactory;

    constructor(address energyFactory_) ERC721A("Antimatter Energy", "ATENG") {
        energyFactory = energyFactory_;
    }

    function collectEnergy(uint256 quantity, CollectProof calldata proof) external override nonReentrant {
        require(collectStatus, "Energy collection has not yet started");
        require(_totalMinted() + quantity <= MAX_SUPPLY, "Exceed the maximum amount of energy");
        _verifyProof(proof);
        require(proof.proofType == 0, "Invalid collect proof type");
        require(_msgSender() == proof.spaceman, "Do not steal others energy");
        require(_numberMinted(_msgSender()) + quantity <= proof.energyAmount, "You collect too much energy");

        // mint
        _safeMint(_msgSender(), quantity);
    }

    function burnEnergy(uint256[] calldata energy) external override {
        uint256 energyAmount = energy.length;
        for (uint256 i = 0; i < energyAmount; i++) {
            _burn(energy[i], true);
        }
    }

    function totalCollected() external view override returns (uint256) {
        return _totalMinted();
    }

    function energyCollected(address addr) external view override returns (uint256) {
        return _numberMinted(addr);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "The energy has not yet been collected");
        return metaURI;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function enableCollectStatus(bool collectStatus_) external override onlyOwner {
        collectStatus = collectStatus_;
    }

    function setTokenURI(string calldata tokenURI_) external onlyOwner {
        metaURI = tokenURI_;
    }

    function withdrawETH() external onlyOwner {
        (bool success, ) = _msgSender().call{ value: address(this).balance }("");
        require(success, "Withdraw failed");
    }

    function withdrawERC20(IERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(_msgSender(), balance);
    }

    function setEnergyFactory(address energyFactory_) external onlyOwner {
        energyFactory = energyFactory_;
    }

    receive() external payable {}

    function _verifyProof(CollectProof calldata proof) internal view {
        bytes32 _hash = keccak256(abi.encode(proof.proofType, proof.spaceman, proof.energyAmount));

        address energyFactory_ = ECDSA.recover(_hash, proof.v, proof.r, proof.s);
        require(energyFactory_ == energyFactory, "Verified collect proof error");
    }
}