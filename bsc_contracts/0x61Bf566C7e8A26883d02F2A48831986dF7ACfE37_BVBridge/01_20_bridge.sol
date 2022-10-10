// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
// import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
// import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
// import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interface/I721.sol";
import "../other/divestor_upgradeable.sol";

contract BVBridge is ERC721HolderUpgradeable, ERC1155HolderUpgradeable, OwnableUpgradeable, DivestorUpgradeable {
    struct Meta {
        bool isOpen;
        address banker;
    }

    struct Token {
        bool isOpen;
        uint8 tax;
        uint256 mode;
        uint256 minAmount;
        address token;
    }

    Meta public meta;
    mapping(address => Token) public tokenInfo;

    mapping(uint256 => bool) public isSend;

    modifier isOpen() {
        require(meta.isOpen, "not open yet");
        _;
    }

    modifier onlyBanker() {
        require(_msgSender() == meta.banker, "not banker's calling");
        _;
    }

    modifier checkProtoc(uint256 protocol_) {
        require(protocol_ == 721 || protocol_ == 1155, "wrong protocol");
        _;
    }

    event AcrossERC20(address indexed account, address indexed token, uint256 amount);
    event AcrossERC721(address indexed account, address indexed token, uint256[] cardIds, uint256[] tokenIds);

    event SendERC20(uint256 indexed id, address indexed account, address indexed token, uint256 amount);
    event SendERC721(uint256 indexed id, address indexed account, address indexed token, uint256[] cardIds);

    function initialize(
        address bvg_,
        address bvt_,
        address igo_
    ) public initializer {
        __Ownable_init_unchained();
        address banker_ = msg.sender;

        meta.banker = banker_;
        meta.isOpen = true;

        tokenInfo[bvt_] = Token({ isOpen: true, tax: 1, mode: 20, minAmount: 40 ether, token: bvt_ });
        tokenInfo[bvg_] = Token({ isOpen: true, tax: 1, mode: 20, minAmount: 50000 ether, token: bvg_ });
        tokenInfo[igo_] = Token({ isOpen: true, tax: 0, mode: 721, minAmount: 0, token: igo_ });
    }

    function updateInfo(address bvg_, address bvt_) public onlyOwner {
        tokenInfo[bvt_] = Token({ isOpen: true, tax: 1, mode: 20, minAmount: 40 ether, token: bvt_ });
        tokenInfo[bvg_] = Token({ isOpen: true, tax: 1, mode: 20, minAmount: 50000 ether, token: bvg_ });
    }

    function acrossERC20(address token_, uint256 amount_) public isOpen {
        Token memory tInfo = tokenInfo[token_];
        require(tInfo.isOpen, "not open");
        require(amount_ >= tInfo.minAmount, "amount too small");

        IERC20(tInfo.token).transferFrom(msg.sender, address(this), amount_);

        emit AcrossERC20(msg.sender, token_, amount_);
    }

    function acrossERC721(address token_, uint256[] calldata tids_) public isOpen {
        Token memory tInfo = tokenInfo[token_];
        require(tInfo.isOpen, "not open");

        uint256[] memory cids_ = new uint256[](tids_.length);

        I721 token = I721(tInfo.token);

        for (uint256 i; i < tids_.length; i++) {
            uint256 tokenId = tids_[i];
            cids_[i] = token.tokenToCard(tokenId);
            token.transferFrom(msg.sender, address(this), tokenId);
        }

        emit AcrossERC721(msg.sender, token_, cids_, tids_);
    }

    function sendERC20(
        address account_,
        address token_,
        uint256 amount_,
        uint256 id_
    ) public onlyBanker {
        require(isSend[id_] == false, "already send");
        Token memory tInfo = tokenInfo[token_];
        require(tInfo.isOpen, "not open");

        isSend[id_] = true;

        uint256 sendAmount = (amount_ * (100 - tInfo.tax)) / 100;
        IERC20(token_).transfer(account_, sendAmount);

        emit SendERC20(id_, account_, token_, sendAmount);
    }

    function sedERC721(
        address account_,
        address token_,
        uint256[] calldata cardIds_,
        uint256 id_
    ) public onlyBanker {
        require(isSend[id_] == false, "already send");
        Token memory tInfo = tokenInfo[token_];
        require(tInfo.isOpen, "not open");

        isSend[id_] = true;

        uint256[] memory amounts = new uint256[](cardIds_.length);
        for (uint256 i; i < cardIds_.length; i++) {
            amounts[i] = 1;
        }
        I721(token_).mintBatch(account_, cardIds_, amounts);

        emit SendERC721(id_, account_, token_, cardIds_);
    }


    /************************************************************ onlyOwner  ************************************************************/
    function setTokenInfo(
        bool isOpen_,
        uint8 mode_,
        uint8 tax_,
        uint256 minAmount_,
        address token_
    ) public onlyOwner {
        tokenInfo[token_] = Token({ isOpen: isOpen_, tax: tax_, mode: mode_, minAmount: minAmount_, token: token_ });
    }

    function setBanker(address newBanker_) external onlyOwner {
        meta.banker = newBanker_;
    }

    function setOpen(bool isOpen_) external onlyOwner {
        meta.isOpen = isOpen_;
    }

    receive() external payable {}

    /************************************************************ onlyOwner end ************************************************************/
}