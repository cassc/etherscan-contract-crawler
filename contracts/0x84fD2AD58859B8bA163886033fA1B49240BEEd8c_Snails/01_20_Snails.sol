//SPDX-License-Identifier: Unlicense
/**

 */
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./BaseERC721.sol";

contract Snails is Ownable, ReentrancyGuard, BaseERC721 {
    uint256 public currentMintLimit = 1000;

    event Claimed(uint256 id, address sender);
    event ToggleWhitelist(bool live);
    event UpdateCurrentMintLimit(uint256 limit);

    constructor()
        BaseERC721(
            1000,
            1,
            "https://ipfs.io/ipfs/QmVVbjePSTmkGFXTD6qpT4Y65mCdXMrtGpvV9yi5VDEQdN/",
            "Snails Free Mint",
            "SFM"
        )
    {}

    /**
        @dev claim free NFT
     */
    function claim() external nonReentrant {
        uint256 current = totalSupply();
        require(current + 1 <= currentMintLimit, "Current Mint Limit Reached");
        mint(1);
        emit Claimed(current, msg.sender);
    }

    function claimByWallet(address account) external view returns (uint256) {
        return mintCount[account];
    }

    function setCurrentMintLimit(uint256 _newLimit) external onlyOwner {
        currentMintLimit = _newLimit;
        emit UpdateCurrentMintLimit(currentMintLimit);
    }
}