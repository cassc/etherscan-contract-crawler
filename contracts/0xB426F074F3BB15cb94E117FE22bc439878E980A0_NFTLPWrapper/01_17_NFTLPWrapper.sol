// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.12 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./NFTLP.sol";

contract NFTLPWrapper is Ownable, ReentrancyGuard {
    using Strings for uint256;

    bool _minting;
    NFTLP public targetContract;

    constructor(address targetContract_) {
        targetContract = NFTLP(targetContract_);
    }

    // Admin
    function setMinting(bool minting) external onlyOwner {
        _minting = minting;
    }

    function setTargetContract(address targetContract_) external onlyOwner {
        targetContract = NFTLP(targetContract_);
    }

    function withdrawWrapper(address to) external onlyOwner {
        (bool success, ) = to.call{value: address(this).balance}("");
        require(success, "NFTLPWrapper: Transfer failed");
    }

    // Proxy admin
    function setProvenance(uint256 aProvenance) external onlyOwner {
        targetContract.setProvenance(aProvenance);
    }

    function setMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        targetContract.setMerkleRoot(merkleRoot);
    }

    function setURI(string memory url) external onlyOwner {
        targetContract.setURI(url);
    }

    function setPricePublic(uint256 pricePublic) external onlyOwner {
        targetContract.setPricePublic(pricePublic);
    }

    function setPriceWaitlist(uint256 priceWaitlist) external onlyOwner {
        targetContract.setPriceWaitlist(priceWaitlist);
    }

    function setPublicMintingStart(
        uint256 publicMintinStart
    ) external onlyOwner {
        targetContract.setPublicMintingStart(publicMintinStart);
    }

    function setWaitlistMintingStart(
        uint256 waitlistMintingStart
    ) external onlyOwner {
        targetContract.setWaitlistMintingStart(waitlistMintingStart);
    }

    function transferNFTLPOwnership(address newOwner) external onlyOwner {
        targetContract.transferOwnership(newOwner);
    }

    function mintPrivate(address[] calldata recipients) external onlyOwner {
        targetContract.mintPrivate(recipients);
    }

    function withdraw(address to) external onlyOwner {
        targetContract.withdraw(to);
    }

    // Public write
    function mint(bytes32[] calldata) public payable nonReentrant {
        require(_minting, "NFTLPWrapper: minting inactive");
        require(
            msg.value >= targetContract._pricePublic(),
            "NFTLPWrapper: not enough ether"
        );
        require(tx.origin == msg.sender, "NFTLPWrapper: no bots please");

        address[] memory receivers = new address[](1);
        receivers[0] = msg.sender;
        targetContract.mintPrivate(receivers);
    }

    // Proxy read
    function leftToTake() public view returns (uint256) {
        return targetContract.leftToTake();
    }

    function uri(uint256 tokenId) public view virtual returns (string memory) {
        return targetContract.uri(tokenId);
    }

    function _totalSupply() public view returns (uint256) {
        return targetContract._totalSupply();
    }

    function balanceOf(
        address account,
        uint256 id
    ) public view returns (uint256) {
        return targetContract.balanceOf(account, id);
    }

    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) public view returns (uint256[] memory) {
        return targetContract.balanceOfBatch(accounts, ids);
    }
}