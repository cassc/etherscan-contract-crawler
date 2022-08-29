// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

abstract contract Genesis {
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        returns (address owner);
    function balanceOf(address owner)
        public
        view
        virtual
        returns (uint256 balance);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual;
}

abstract contract MintPass {
    function balanceOf(address owner, uint256 id)
        public
        view
        virtual
        returns (uint256 balance);
    function burnForAddress(
        uint256 _id, 
        uint256 _quantity,
        address _address
    ) public virtual;
}


contract ERC721AVault is Ownable, IERC721Receiver, PaymentSplitter, ReentrancyGuard {

    bool public saleIsActive;
    uint256 public price;
    uint256 public startTokenId;
    MintPass public mintpass;
    Genesis public genesis;

    constructor(
        address _mintpassAddress,
        address _genesisAddress,
        address[] memory _payees,
        uint256[] memory _shares,
        address _owner
    ) PaymentSplitter(_payees, _shares) {
        mintpass = MintPass(_mintpassAddress);
        genesis = Genesis(_genesisAddress);
        transferOwnership(_owner);
    }

    function setStartTokenId(uint256 _tokenId) public onlyOwner {
        startTokenId = _tokenId;
    }

    function canBuy(address _address) public view returns (uint256) {
        uint256 balance3 = mintpass.balanceOf(_address, 3);
        uint256 balance2 = mintpass.balanceOf(_address, 2);
        uint256 balance1 = mintpass.balanceOf(_address, 1);
        return balance3 * 5 + balance2 * 3 + balance1;
    }

    function availableSupply() public view returns (uint256) {
        return genesis.balanceOf(address(this));
    }

    function setContractAddresses(address _mintpassAddress, address _genesisAddress) public onlyOwner {
        mintpass = MintPass(_mintpassAddress);
        genesis = Genesis(_genesisAddress);
    }

    function setSaleState(bool _saleIsActive) public onlyOwner {
        saleIsActive = _saleIsActive;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function getVaultedTokens()
        public
        view
        returns (uint256[] memory) {
        uint256 vaultCount = genesis.balanceOf(address(this));
        uint256[] memory vaultedIds = new uint256[](vaultCount);
        uint256 currentId = startTokenId;
        uint256 vaultIndex = 0;
        while (vaultIndex < vaultCount) {
          address currentOwner = genesis.ownerOf(currentId);
          if (currentOwner == address(this)) {
            vaultedIds[vaultIndex] = currentId;
            vaultIndex++;
          }
          currentId++;
        }
        return vaultedIds;
    }

    function buyNFT(uint16 _quantity) public payable nonReentrant {
        require(saleIsActive, "Sale inactive");
        require(price * _quantity <= msg.value, "ETH incorrect");
        require(availableSupply() > 0, "Insufficient supply");
        uint256 balance3 = mintpass.balanceOf(msg.sender, 3);
        uint256 balance2 = mintpass.balanceOf(msg.sender, 2);
        uint256 balance1 = mintpass.balanceOf(msg.sender, 1);
        require(balance3 * 5 + balance2 * 3 + balance1 >= _quantity, "Invalid quantity");
        if (balance3 > 0) mintpass.burnForAddress(3, balance3, msg.sender);
        if (balance2 > 0) mintpass.burnForAddress(2, balance2, msg.sender);
        if (balance1 > 0) mintpass.burnForAddress(1, balance1, msg.sender);
        uint256[] memory tokenIds = getVaultedTokens();
        for (uint256 i = 0; i < _quantity; i++) {
            genesis.safeTransferFrom(
                address(this),
                msg.sender,
                tokenIds[i]
            );
        }
    }

    function withdrawAllNFTs() public onlyOwner {
        uint256[] memory tokenIds = getVaultedTokens();
        for (uint256 i = 0; i < tokenIds.length; i++) {
            genesis.safeTransferFrom(
                address(this),
                msg.sender,
                tokenIds[i]
            );
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}