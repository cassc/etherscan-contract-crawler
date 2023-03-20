// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./ShibariumNFT.sol";

contract ShibariumMigration is Ownable, Pausable {
    IERC20 public constant OLD_DAO =
        IERC20(0x15316d2438A8D7D534e4233B8E0edacD64c9FCde);
    IERC20 public constant OLD_GOV =
        IERC20(0x1088E575E70EfDe4a6be566e02976ED786C5f7F3);

    IERC20 public immutable NEW_DAO;
    ShibariumNFT public immutable NEW_NFT;

    mapping(address => bool) public gotNFT;

    event Migrated(address indexed user, uint256 amountDao, uint256 amountGov);

    constructor(address _newDao, address _newNft) Ownable() Pausable() {
        NEW_DAO = IERC20(_newDao);
        NEW_NFT = ShibariumNFT(_newNft);
    }

    function migrate() external {
        uint256 daoBalance = OLD_DAO.balanceOf(msg.sender);
        uint256 govBalance = OLD_GOV.balanceOf(msg.sender);

        require(daoBalance > 0 || govBalance > 0, "Nothing to migrate");

        if (daoBalance > 0) {
            require(
                OLD_DAO.transferFrom(msg.sender, address(this), daoBalance),
                "DAO Transfer failed"
            );
        }

        if (govBalance > 0) {
            require(
                OLD_GOV.transferFrom(msg.sender, address(this), govBalance),
                "GOV Transfer failed"
            );
        }

        if (NEW_NFT.totalSupply() < 1000 && !gotNFT[msg.sender]) {
            NEW_NFT.safeMint(msg.sender);
            gotNFT[msg.sender] = true;
        }

        uint256 balanceToGive = daoBalance + govBalance;

        require(
            NEW_DAO.transfer(msg.sender, balanceToGive),
            "Migration transfer failed"
        );

        emit Migrated(msg.sender, daoBalance, govBalance);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdraw() external onlyOwner {
        uint256 daoBalance = OLD_DAO.balanceOf(address(this));
        uint256 govBalance = OLD_GOV.balanceOf(address(this));

        if (daoBalance > 0) {
            require(
                OLD_DAO.transfer(msg.sender, daoBalance),
                "DAO Withdraw failed"
            );
        }

        if (govBalance > 0) {
            require(
                OLD_GOV.transfer(msg.sender, govBalance),
                "GOV Withdraw failed"
            );
        }
    }

    function withdrawBackNewTokens() external onlyOwner {
        uint256 newDaoBalance = NEW_DAO.balanceOf(address(this));
        NEW_DAO.transfer(msg.sender, newDaoBalance);
    }

    function clearBalance(address token, uint256 amount) external onlyOwner {
        bool ok = IERC20(token).transfer(msg.sender, amount);
        require(ok, "Clear balance failed");
    }
}