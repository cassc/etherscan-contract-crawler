// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./InterfaceBabyTigers.sol";



contract BabyTigersManager is ReentrancyGuard, Ownable {

    // Contracts
    address public babyTigersAddress;
    InterfaceBabyTigers babyTigersContract;
    address public typicalTigersAddress;
    IERC721Enumerable typicalTigersContract;

    // Sale Status
    bool public holderSaleIsActive = false;
    mapping(uint256 => bool) public claimedTypicalTigers;

    // Events
    event HolderSaleActivation(bool isActive);
    event BabyTigersManagerChanged(address newManager);

    constructor(address _typicalTigersAddress, address _babyTigersAddress) {
        babyTigersAddress = _babyTigersAddress;
        babyTigersContract = InterfaceBabyTigers(_babyTigersAddress);
        typicalTigersAddress = _typicalTigersAddress;
        typicalTigersContract = IERC721Enumerable(_typicalTigersAddress);
    }

    //Holder status validation
    function isTypicalTigerAvailable(uint256 _tokenId) public view returns(bool) {
        bool isAvailableOnBabyTigersContract = babyTigersContract.isTypicalTigerAvailable(_tokenId);
        return claimedTypicalTigers[_tokenId] != true && isAvailableOnBabyTigersContract;
    }


    // Minting
    function ownerMint(address _to, uint256 _count) external onlyOwner {
        babyTigersContract.ownerMint(_to, _count);
    }

    function holderMint(uint256[] calldata _typicalTigerIds, uint256 _count) external nonReentrant {
        require(holderSaleIsActive, "HOLDER_SALE_INACTIVE");
        require(
            _count == _typicalTigerIds.length,
            "INSUFFICIENT_TT_TOKENS"
        );
        require(typicalTigersContract.balanceOf(msg.sender) > 0, "NO_TT_TOKENS");
        for (uint256 i = 0; i < _typicalTigerIds.length; i++) {
            require(isTypicalTigerAvailable(_typicalTigerIds[i]), "TT_ALREADY_CLAIMED");
            require(typicalTigersContract.ownerOf(_typicalTigerIds[i]) == msg.sender, "NOT_TT_OWNER");
            claimedTypicalTigers[_typicalTigerIds[i]] = true;
        }
        babyTigersContract.ownerMint(msg.sender, _count);
    }

    // This should toggle holderSaleIsActive in the manager contract's storage
    function toggleHolderSaleStatus() external onlyOwner {
        holderSaleIsActive = !holderSaleIsActive;
        emit HolderSaleActivation(holderSaleIsActive);
    }

    function toggleWhitelistSaleStatus() external onlyOwner {
        babyTigersContract.toggleWhitelistSaleStatus();
    }

    function toggleSaleStatus() external onlyOwner {
        babyTigersContract.toggleSaleStatus();
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        babyTigersContract.setMintPrice(_mintPrice);
    }

    function setWhitelistMintPrice(uint256 _mintPrice) external onlyOwner {
        babyTigersContract.setWhitelistMintPrice(_mintPrice);
    }

    function setMaxPurchase(uint256 _maxPurchase) external onlyOwner {
        babyTigersContract.setMaxPurchase(_maxPurchase);
    }

    function lockMetadata() external onlyOwner {
        babyTigersContract.lockMetadata();
    }

    function withdraw() external onlyOwner {
        babyTigersContract.withdraw();
        payable(owner()).transfer(address(this).balance);
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        babyTigersContract.setBaseURI(baseURI);
    }

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        babyTigersContract.setMerkleRoot(_root);
    }

    function transferBabyTigersOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "NO_ADDRESS_PROVIDED");
        babyTigersContract.transferOwnership(_newOwner);
        emit BabyTigersManagerChanged(_newOwner);
    }

    receive() external payable virtual {}
}