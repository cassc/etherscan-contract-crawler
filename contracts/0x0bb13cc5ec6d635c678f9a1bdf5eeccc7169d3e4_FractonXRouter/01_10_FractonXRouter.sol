// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";

import "./interfaces/IFractonXRouter.sol";
import "./interfaces/IFractonXFactory.sol";
import "./interfaces/IFractonXERC20.sol";

contract FractonXRouter is IFractonXRouter, Initializable {

    uint256 constant TEN_THOUSAND = 10000;

    address public factory;

    function initialize(address factory_) public initializer {
        factory = factory_;
    }

    function swapERC20ToERC721(address erc20Addr, uint256 amountERC20) external {
        IERC20Upgradeable(erc20Addr).transferFrom(msg.sender, factory, amountERC20);
        IFractonXFactory(factory).swapERC20ToERC721(erc20Addr, msg.sender);
    }

    function swapERC721ToERC20(address erc721Addr, uint256 tokenId) external {
        require(isWhitelistUser(msg.sender, erc721Addr) ||
            IFractonXFactory(factory).closeSwap721To20() == 2, "INVALID CALLER");
        IERC721Upgradeable(erc721Addr).safeTransferFrom(msg.sender, factory, tokenId);
        IFractonXFactory(factory).swapERC721ToERC20(erc721Addr, tokenId, msg.sender);
    }

    function batchSwapERC20ToERC721(address erc20Addr, uint256 amountERC20, uint256 batchCount) external {
        require(IERC20Upgradeable(erc20Addr).balanceOf(msg.sender) >= amountERC20 * batchCount,
            "NOT ENOUNGH BALANCE");
        for (uint256 i = 0; i < batchCount; i++) {
            IERC20Upgradeable(erc20Addr).transferFrom(msg.sender, factory, amountERC20);
            IFractonXFactory(factory).swapERC20ToERC721(erc20Addr, msg.sender);
        }
    }

    function batchSwapERC721ToERC20(address erc721Addr, uint256[] calldata tokenIds) external {
        require(isWhitelistUser(msg.sender, erc721Addr) ||
            IFractonXFactory(factory).closeSwap721To20() == 2, "INVALID CALLER");
        uint256 length = tokenIds.length;
        for (uint256 i = 0; i < length; i++) {
            IERC721Upgradeable(erc721Addr).safeTransferFrom(msg.sender, factory, tokenIds[i]);
            IFractonXFactory(factory).swapERC721ToERC20(erc721Addr, tokenIds[i], msg.sender);
        }
    }



    function isWhitelistUser(address user, address erc721Addr) public view returns(bool) {
        bytes32 salt = keccak256(abi.encode(erc721Addr));
        return IAccessControlUpgradeable(factory).hasRole(salt, user);
    }

    function getAmountERC20(address erc20Addr) external view returns(uint256 amountERC20) {
        IFractonXFactory.ERC20Info memory erc20Info = IFractonXFactory(factory).getERC20Info(erc20Addr);
        uint256 swapFeeRate = IFractonXFactory(factory).swapFeeRate();
        uint256 fee = swapFeeRate * 1 * erc20Info.swapRatio / TEN_THOUSAND;
        return fee + erc20Info.swapRatio;
    }

    function erc20TransferFeeRate(address erc20Addr) external view returns(uint256) {
        return IFractonXERC20(erc20Addr).erc20TransferFeerate();
    }
}