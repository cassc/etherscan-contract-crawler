// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

//import "hardhat/console.sol";

import "contracts/lib/Ownable.sol";
import "contracts/lib/HasFactories.sol";
import "contracts/nft/IMintableNft.sol";
import "contracts/INftController.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct ClaimData {
    address account; // account to claim
    uint256 time; // claim time
    address nftAddress;
    uint256 tokenId;
}

contract TheBattleByTheBayPool {
    using SafeERC20 for IERC20;

    uint256 immutable _claimTimerMinutes;
    INftController public immutable nftController;
    IMintableNft public immutable troll;
    IMintableNft public immutable mage;
    IMintableNft public immutable general;
    IERC20 public immutable erc20;
    bool _isGameOver;
    WinData _winData;
    ClaimData _claimData;

    event OnTakePool(
        address indexed account,
        address nftAddress,
        uint256 tokenId,
        uint256 poolEthCount
    );

    constructor(
        address erc20Address,
        uint256 claimTimer,
        address nftController_,
        address troll_,
        address mage_,
        address general_
    ) {
        erc20 = IERC20(erc20Address);
        _claimTimerMinutes = claimTimer;
        nftController = INftController(nftController_);
        troll = IMintableNft(troll_);
        mage = IMintableNft(mage_);
        general = IMintableNft(general_);
    }

    modifier gameNotOver() {
        require(!this.isGameOver(), "game is over");
        _;
    }

    receive() external payable {}

    function erc20RewardCount() external view returns (uint256) {
        return erc20.balanceOf(address(this));
    }

    function winData() external view returns (WinData memory) {
        return _winData;
    }

    function claimData() external view returns (ClaimData memory) {
        return _claimData;
    }

    function claimLapsedSeconds() external view returns (uint256) {
        require(_claimData.account != address(0), "has no claim data");
        if (block.timestamp > _claimData.time) return 0;
        return _claimData.time - block.timestamp;
    }

    function claim() external {
        require(_claimData.account != address(0), "has no claim data");
        _tryClaim();
    }

    function _tryClaim() internal returns (bool) {
        if (_claimData.account == address(0)) return false;
        if (block.timestamp < _claimData.time) return false;
        if (_isGameOver) return false;
        _isGameOver = true;
        sendEth(_claimData.account, address(this).balance);
        erc20.safeTransfer(_claimData.account, erc20.balanceOf(address(this)));
        nftController.setGameOver(
            WinData(
                _claimData.account,
                _claimData.nftAddress,
                _claimData.tokenId
            )
        );
        return true;
    }

    function sendEth(address addr, uint256 ethCount) internal {
        if (ethCount <= 0) return;
        (bool sent, ) = addr.call{value: ethCount}("");
        require(sent, "ethereum is not sent");
    }

    function takePool(
        address nftAddress,
        uint256 tokenId
    ) external gameNotOver {
        if (_tryClaim()) return;
        IMintableNft nft = IMintableNft(nftAddress);
        require(nft.ownerOf(tokenId) == msg.sender, "only for token owner");
        nft.burn(tokenId);

        if (_claimData.account != address(0)) {
            if (_claimData.nftAddress == address(troll))
                require(
                    nftAddress == address(mage),
                    "Troll can be beaten only by Mage"
                );
            else if (_claimData.nftAddress == address(mage))
                require(
                    nftAddress == address(general),
                    "Mage can be beaten only by General"
                );
            else if (_claimData.nftAddress == address(general))
                require(
                    nftAddress == address(troll),
                    "General can be beaten only by Troll"
                );
        }

        _claimData.account = msg.sender;
        _claimData.nftAddress = nftAddress;
        _claimData.tokenId = tokenId;
        _claimData.time = block.timestamp + this.claimTimerMinutes() * 1 minutes;

        emit OnTakePool(msg.sender, nftAddress, tokenId, address(this).balance);
    }

    function isGameOver() external view returns (bool) {
        return nftController.isGameOver();
    }

    function claimTimerMinutes() external view returns (uint256) {
        uint256 result = _claimTimerMinutes;
        if (nftController.mintedCount() >= nftController.maxMintCount() / 3)
            result = (_claimTimerMinutes * 2) / 3;
        if (
            nftController.mintedCount() >=
            (nftController.maxMintCount() * 2) / 3
        ) result = _claimTimerMinutes / 3;

        return result;
    }
}