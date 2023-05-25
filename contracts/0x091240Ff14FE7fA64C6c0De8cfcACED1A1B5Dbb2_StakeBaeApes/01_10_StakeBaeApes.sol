// SPDX-License-Identifier: GPL-3.0

/*
██████╗  █████╗ ███████╗     █████╗ ██████╗ ███████╗███████╗
██╔══██╗██╔══██╗██╔════╝    ██╔══██╗██╔══██╗██╔════╝██╔════╝
██████╔╝███████║█████╗      ███████║██████╔╝█████╗  ███████╗
██╔══██╗██╔══██║██╔══╝      ██╔══██║██╔═══╝ ██╔══╝  ╚════██║
██████╔╝██║  ██║███████╗    ██║  ██║██║     ███████╗███████║
╚═════╝ ╚═╝  ╚═╝╚══════╝    ╚═╝  ╚═╝╚═╝     ╚══════╝╚══════╝

~ See you in Banana Coast!

Founders: @richThecreator, @GreatRedApe @Ape-Eeeee
Developed By: @richTheCreator
*/

pragma solidity ^0.8.0;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC721, IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

contract StakeBaeApes is Ownable, IERC721Receiver {
    using EnumerableSet for EnumerableSet.UintSet;

    // Contract Addresses
    address public immutable erc721Address;

    // Deposit Tracking
    mapping(address => EnumerableSet.UintSet) private _deposits;
    mapping(address => mapping(uint256 => uint256)) public _depositTimes;

    // Events
    event Deposit(address addr, uint256[] tokenIds);
    event Withdraw(address addr, uint256[] tokenIds);

    constructor(address _erc721Address) {
        erc721Address = _erc721Address;
    }

    /**
     * Track deposits of an account
     */
    function depositsOf(address account)
        external
        view
        returns (uint256[] memory)
    {
        EnumerableSet.UintSet storage depositSet = _deposits[account];
        uint256[] memory tokenIds = new uint256[](depositSet.length());
        for (uint256 i; i < depositSet.length(); i++) {
            tokenIds[i] = depositSet.at(i);
        }
        return tokenIds;
    }

    /**
     * Get the deposits information as an array of packed byte strings
     */
    function depositsOfAdvanced(address account)
        external
        view
        returns (bytes[] memory)
    {
        EnumerableSet.UintSet storage depositSet = _deposits[account];
        bytes[] memory depositTimes = new bytes[](depositSet.length());
        for (uint256 i; i < depositSet.length(); i++) {
            uint256 tokenId = depositSet.at(i);
            depositTimes[i] = abi.encodePacked(
                tokenId,
                _depositTimes[account][tokenId]
            );
        }
        return depositTimes;
    }

    /**
     * Deposit Bae Apes into the contract
     */
    function deposit(uint256[] calldata tokenIds) external {
        for (uint256 i; i < tokenIds.length; i++) {
            IERC721(erc721Address).safeTransferFrom(
                msg.sender,
                address(this),
                tokenIds[i],
                ""
            );
            _depositTimes[msg.sender][tokenIds[i]] = block.timestamp;
            _deposits[msg.sender].add(tokenIds[i]);
        }
        emit Deposit(msg.sender, tokenIds);
    }

    /**
     * Withdraw Bae Apes from the contract
     */
    function withdraw(uint256[] calldata tokenIds) external {
        for (uint256 i; i < tokenIds.length; i++) {
            require(
                _deposits[msg.sender].contains(tokenIds[i]),
                "Token not deposited"
            );
            _deposits[msg.sender].remove(tokenIds[i]);
            IERC721(erc721Address).safeTransferFrom(
                address(this),
                msg.sender,
                tokenIds[i],
                ""
            );
        }
        emit Withdraw(msg.sender, tokenIds);
    }

    /**
     * Allows contract owner to withdraw some token from the contract
     */
    function withdrawTokens(IERC20 erc20Address) external onlyOwner {
        uint256 tokenSupply = erc20Address.balanceOf(address(this));
        erc20Address.transfer(msg.sender, tokenSupply);
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