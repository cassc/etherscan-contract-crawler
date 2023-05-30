// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import '@openzeppelin/contracts/utils/Strings.sol';
import "./HMN5.sol";
import "./ResidentCapsule.sol";

contract HMN5Minter is Ownable, ReentrancyGuard {

    function mintHmn5(uint256[] memory tokenIds) external payable nonReentrant {
        uint256 quantity = tokenIds.length;
        uint256 totalPaid = 0;
        require(mintEnabled, "Mint is not enabled yet");
        require(quantity <= transactionLimit, "Over transaction limit");
        require(msg.sender == tx.origin, "No contracts");

        for(uint256 x = 0; x < quantity; x++) {
            if(tokenIds[x] > freeBurnMaxTokenId) {
                totalPaid++;
            }
        }

        require(msg.value == price * totalPaid, "Invalid ETH amount");

        for(uint256 x = 0; x < quantity; x++) {
            residentToken.burn(tokenIds[x]);
        }

        _mintHmn5(msg.sender, quantity);
    }

    function _mintHmn5(address account, uint256 quantity) internal {
        hmn5.giftMint(account, quantity);
    }

    function giftHmn5Mint(address account, uint256 total) external onlyOwner {
        hmn5.giftMint(account, total);
    }

    HMN5 public hmn5;
    function setHmn5(address addr_) public onlyOwner {
        hmn5 = HMN5(addr_);
    }

    HMN5ResidentCapsule public residentToken;
    function setResidentToken(address addr_) public onlyOwner {
        residentToken = HMN5ResidentCapsule(addr_);
    }
    
    function returnHmn5Ownership() external onlyOwner {
        hmn5.transferOwnership(0xFCb55C98c6D6D30B805CC388dc18468e01F5773B);
    }

    uint256 public freeBurnMaxTokenId = 1654;
    function setFreeBurnMaxTokenId(uint256 tokenId) external onlyOwner {
        freeBurnMaxTokenId = tokenId;
    }

    uint256 public price = 0.069 ether;
    function setPrice(uint256 price_) public onlyOwner {
        price = price_;
    }

    bool public mintEnabled;
    function setMintEnabled(bool mintEnabled_) public onlyOwner {
        mintEnabled = mintEnabled_;
    }

    uint256 public transactionLimit = 21;
    function setTransactionLimit(uint256 transactionLimit_) public onlyOwner {
        transactionLimit = transactionLimit_;
    }

    function releaseFunds() external onlyOwner {
        Address.sendValue(payable(0x6569E6B8B90A2d9290Ea07Fe98E24aE393C71783), address(this).balance);
    }
}