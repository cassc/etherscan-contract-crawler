// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IRobo {
    function burn(uint256 tokenId) external;

    function ownerOf(uint256 tokenId) external view returns (address);
}

interface IRoboBurn {
    function burn(uint256[] memory tokenIds) external;
}

contract RoboBurn is IRoboBurn, Ownable, ReentrancyGuard {
    address public immutable robo;
    uint256 public immutable price;
    uint256 public immutable endTime;

    constructor(address robo_) {
        robo = robo_;
        price = 0.05 ether;
        endTime = block.timestamp + 15 days;
    }

    function burn(uint256[] memory tokenIds) external override nonReentrant {
        uint256 total = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            for (uint256 j = i + 1; j < tokenIds.length; j++) {
                require(tokenIds[i] != tokenIds[j], "Duplicate tokenId");
            }
            require(
                IRobo(robo).ownerOf(tokenIds[i]) == _msgSender(),
                "Caller is not owner"
            );
            IRobo(robo).burn(tokenIds[i]);
            total = total + price;
        }
        _widthdraw(_msgSender(), total);
    }

    function withdraw() external onlyOwner nonReentrant {
        require(block.timestamp >= endTime, "Too early");
        _widthdraw(_msgSender(), address(this).balance);
    }

    function _widthdraw(address recipient, uint256 amount) private {
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ETH_TRANSFER_FAILED");
    }

    receive() external payable {}
}