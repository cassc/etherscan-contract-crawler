// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract FlamingoIncubator is Ownable, IERC721Receiver {
    using SafeMath for uint256;

    IERC721Enumerable internal PFSC_EGGS;
    uint256 public fee = 4000000000000000;

    error NotOwnerOfToken();
    error InvalidCaller();
    error InvalidFee();

    event Incubated(address indexed from, uint256 amount);

    mapping(address => uint256[]) public incubators;
    mapping(uint256 => address) public incubatedTokens;

    constructor(address token) {
        PFSC_EGGS = IERC721Enumerable(token);
    }

    modifier validCaller() {
        if (msg.sender == address(0)) revert InvalidCaller();
        _;
    }

    modifier validPayable(uint256 tokenCount) {
        uint256 totalFee = fee.mul(tokenCount);
        if (msg.value != totalFee) revert InvalidFee();
        _;
    }

    function changeFee(uint256 _fee) public onlyOwner {
        fee = _fee;
    }

    function incubate(
        uint256[] calldata tokenIds
    ) external payable validCaller validPayable(tokenIds.length) {
        uint256 length = tokenIds.length;

        if (incubators[msg.sender].length == 0) {
            incubators[msg.sender] = tokenIds;
        } else {
            for (uint256 j; j < length; ) {
                incubators[msg.sender].push(tokenIds[j]);
                unchecked {
                    j++;
                }
            }
        }

        for (uint256 i; i < length; ) {
            uint256 tokenId = tokenIds[i];
            address tokenOwner = PFSC_EGGS.ownerOf(tokenId);
            if (msg.sender != tokenOwner) {
                revert NotOwnerOfToken();
            }
            PFSC_EGGS.safeTransferFrom(tokenOwner, address(this), tokenId);
            incubatedTokens[tokenId] = msg.sender;
            unchecked {
                ++i;
            }
        }
        payable(owner()).transfer(msg.value);
        emit Incubated(msg.sender, length);
    }

    function emergencyWithdraw() external onlyOwner {
        uint256 tokenCount = PFSC_EGGS.balanceOf(address(this));
        for (uint256 i = tokenCount; i > 0; ) {
            uint256 tokenId = PFSC_EGGS.tokenOfOwnerByIndex(
                address(this),
                i.sub(1)
            );
            PFSC_EGGS.safeTransferFrom(address(this), owner(), tokenId);
            unchecked {
                i--;
            }
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}