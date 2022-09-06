// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import '@openzeppelin/contracts/security/Pausable.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "../damoNft/IFactory.sol";

import "./interfaces/IAppConf.sol";

import "../libs/INft.sol";
import "../libs/IERC20Ex.sol";
import "../libs/Initializable.sol";

import "./Model.sol";

contract WishPool is Initializable, Pausable, Ownable {
    using SafeERC20 for IERC20Ex;

    struct WishData {
        uint256 wishId;
        address userAddr;
        string content;
        uint256 blockNumber;
        uint256 blockTime;
    }

    struct RedeemData {
        uint256 tokenId;
        string wishId;
        address grantAddr;
        string grantWishId;
        string grantColor;
        address redeemToken;
        uint256 donateAmount;
        uint256 incenseAmount;
    }

    // useraddr -> wishIndex -> wishcontent -> blocknumber -> blocktime
    event Wish(address indexed, uint256, string, uint256, uint256);

    // useraddr -> burnData -> grantData -> redeemToken -> donateAmount -> incenseAmount -> blocktime
    event Redeem(address indexed, string, string, address, uint256, uint256, uint256);

    event Initialized(address indexed);

    mapping(address => WishData[]) private wishMap;
    uint256 private wishCount;

    IAppConf private appConf;

    function initialize(IAppConf _appConf) external onlyOwner {
        appConf = _appConf;

        initialized = true;
        emit Initialized(address(appConf));
    }

    function wish(string memory content) external {
        wishCount++;
        wishMap[_msgSender()].push(WishData({
            wishId: wishCount,
            userAddr: _msgSender(),
            content: content,
            blockNumber: block.number,
            blockTime: block.timestamp
        }));

        emit Wish(_msgSender(), wishCount, content, block.number, block.timestamp);
    }

    function redeem(RedeemData memory redeemData) external needInit whenNotPaused payable {
        require(!appConf.validBlacklist(_msgSender()), "can not redeem");
        require(appConf.validRedeemToken(redeemData.redeemToken), "invalid redeem token");
        require(_msgSender() != redeemData.grantAddr, "can not grant to self");

        // nft info
        (, uint8 redeemNftGen,) = IFactory(appConf.getNftFactoryAddr()).tokenDetail(Model.NFT_TYPE_WISH, redeemData.tokenId);
        if (redeemNftGen == 2) { // pdg can not grant
            require(redeemData.grantAddr == address(0), "can not grant");
        }
        
        // incense amount check
        if (redeemData.incenseAmount > 0) {
            uint256 incenseMinAmount = appConf.getIncenseMinAmount();
            uint256 incenseMaxAmount = appConf.getIncenseMaxAmount();

            if (incenseMinAmount > 0) {
                require(redeemData.incenseAmount >= incenseMinAmount, "invalid incense amount1");
            }

            if (incenseMaxAmount > 0) {
                require(redeemData.incenseAmount <= incenseMaxAmount, "invalid incense amount2");
            }
        }
        
        if (redeemData.redeemToken == address(0)) {
            uint256 totalAmount = redeemData.donateAmount + redeemData.incenseAmount;
            require(msg.value >= totalAmount, "balance insufficient");
        }

        // burn redeem nft
        address burnToken = appConf.getRedeemNftToken();

        require(IERC721(burnToken).ownerOf(redeemData.tokenId) == _msgSender(), "invalid owner");
        INft(burnToken).burn(redeemData.tokenId);

        string memory burnData = string(bytes.concat(
            bytes(Strings.toHexString(burnToken)), "|", 
            bytes(Strings.toString(redeemData.tokenId)), "|", 
            bytes(Strings.toString(redeemNftGen)), "|", 
            bytes(redeemData.wishId)
        ));
        
        // handle grant
        (address grantToken, uint256 grantTokenId, uint8 grantNftGen) = _grant(redeemData.grantAddr);
        string memory grantData = string(bytes.concat(
            bytes(Strings.toHexString(grantToken)), "|", 
            bytes(Strings.toString(grantTokenId)), "|", 
            bytes(Strings.toString(grantNftGen)), "|", 
            bytes(redeemData.wishId), "|", 
            bytes(redeemData.grantColor), "|",
            bytes(Strings.toHexString(redeemData.grantAddr))
        ));

        // handle donate
        if (redeemData.donateAmount > 0) {
            _donate(_msgSender(), redeemData.redeemToken, redeemData.donateAmount);
        }

        // handle incense
        if (redeemData.incenseAmount > 0) {
            _incense(_msgSender(), redeemData.redeemToken, redeemData.incenseAmount);
        }

        emit Redeem(_msgSender(), burnData, grantData, redeemData.redeemToken, redeemData.donateAmount, redeemData.incenseAmount, block.timestamp);
    }

    function _grant(address grantAddr) private returns(address, uint256, uint8) {
        uint256 grantTokenId = 0;
        address grantNftToken = appConf.getGrantNftToken();
        uint8 grantNftGen = appConf.getGrantNftGen();

        if (grantAddr != address(0)) {
            uint8 nftType = appConf.getNftTokenType(grantNftToken);

            uint256[] memory grantTokenIds = IFactory(appConf.getNftFactoryAddr()).mintDamo(grantAddr, nftType, grantNftGen, 1, Model.SourceTypeGrant);
            grantTokenId = grantTokenIds[0];

            if (grantTokenId == 0) {
                revert("grant damo failure");
            }
        }
        
        return (grantNftToken, grantTokenId, grantNftGen);
    }

    function _donate(address userAddr, address redeemToken, uint256 donateAmount) private {
        if (redeemToken == address(0)) {
            Address.sendValue(payable(appConf.getDonateAddr()), donateAmount);
        } else {
            IERC20Ex(redeemToken).safeTransferFrom(userAddr, appConf.getDonateAddr(), donateAmount);
        }
    }

    function _incense(address userAddr, address redeemToken, uint256 incenseAmount) private {
        if (redeemToken == address(0)) {
            Address.sendValue(payable(appConf.getIncenseAddr()), incenseAmount);
        } else {
            IERC20Ex(redeemToken).safeTransferFrom(userAddr, appConf.getIncenseAddr(), incenseAmount);
        }
    }

    function getWishs(address userAddr) external view returns(WishData[] memory) {
        return wishMap[userAddr];
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}