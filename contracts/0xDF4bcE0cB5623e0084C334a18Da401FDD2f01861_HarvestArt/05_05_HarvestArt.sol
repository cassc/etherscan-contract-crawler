pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

// ⠀⡠⡤⢤⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⢿⡢⣁⢄⢫⡲⢤⡀⠀⠀⠀⠀⢀⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠘⣧⡁⢔⢑⢄⠙⣬⠳⢄⠀⠀⣾⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠘⢎⣤⠑⣤⠛⢄⠝⠃⡙⢦⣸⣧⡀⠀⢠⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠈⢧⡿⣀⠷⣁⠱⢎⠉⣦⡛⢿⣷⣤⣯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠈⠉⠛⠻⢶⣵⣎⣢⡜⠣⣠⠛⢄⣜⣳⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠈⠻⢿⣿⣾⣿⣾⣿⣿⣿⣿⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⣿⠟⠛⠛⠛⢿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠋⠀⠀⠀⠀⠀⠙⠿⣿⣿⣿⣿⣿⣿⣿⠂⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⠿⠋⠁

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface ERCBase {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function isApprovedForAll(address account, address operator) external view returns (bool);
}

interface ERC721Partial is ERCBase {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface ERC1155Partial is ERCBase {
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata) external;
}

contract HarvestArt is ReentrancyGuard, Pausable, Ownable {

    bytes4 _ERC721 = 0x80ac58cd;
    bytes4 _ERC1155 = 0xd9b67a26;

    address public barn = address(0);
    uint256 public defaultPrice = 1 gwei;
    uint256 public maxTokensPerTx = 100;

    mapping (address => uint256) private _contractPrices;

    function setBarn(address _barn) onlyOwner public {
        barn = _barn;
    }

    function setDefaultPrice(uint256 _defaultPrice) onlyOwner public {
        defaultPrice = _defaultPrice;
    }

    function setMaxTokensPerTx(uint256 _maxTokensPerTx) onlyOwner public {
        maxTokensPerTx = _maxTokensPerTx;
    }

    function setPriceByContract(address contractAddress, uint256 price) onlyOwner public {
        _contractPrices[contractAddress] = price;
    }

    function pause() onlyOwner public {
        _pause();
    }

    function unpause() onlyOwner public {
        _unpause();
    }

    function _getPrice(address contractAddress) internal view returns (uint256) {
        if (_contractPrices[contractAddress] > 0)
            return _contractPrices[contractAddress];
        else
            return defaultPrice;
    }

    function batchTransfer(address[] calldata tokenContracts, uint256[] calldata tokenIds, uint256[] calldata counts) external whenNotPaused {
        require(barn != address(0), "Barn cannot be the 0x0 address");
        require(tokenContracts.length > 0, "Must have 1 or more token contracts");
        require(tokenContracts.length == tokenIds.length && tokenIds.length == counts.length, "All params must have equal length");

        ERCBase tokenContract;
        uint256 totalTokens = 0;
        uint256 totalPrice = 0;

        for (uint256 i = 0; i < tokenContracts.length; i++) {
            require(counts[i] > 0, "Token count must be greater than zero.");

            tokenContract = ERCBase(tokenContracts[i]);

            if (tokenContract.supportsInterface(_ERC721)) {
                totalTokens += 1;
                totalPrice += _getPrice(tokenContracts[i]);
            }
            else if (tokenContract.supportsInterface(_ERC1155)) {
                totalTokens += counts[i];
                totalPrice += _getPrice(tokenContracts[i]) * counts[i];
            }
            else {
                continue;
            }

            require(totalTokens < maxTokensPerTx, "Maximum token count reached.");
            require(address(this).balance > totalPrice, "Not enough ether in contract.");
            require(tokenContract.isApprovedForAll(msg.sender, address(this)), "Token not yet approved for all transfers");

            if (tokenContract.supportsInterface(_ERC721)) {
                ERC721Partial(tokenContracts[i]).transferFrom(msg.sender, barn, tokenIds[i]);
            }
            else {
                ERC1155Partial(tokenContracts[i]).safeTransferFrom(msg.sender, barn, tokenIds[i], counts[i], "");
            }
        }

        (bool sent, ) = payable(msg.sender).call{ value: totalPrice }("");
        require(sent, "Failed to send ether.");
    }

    receive () external payable { }

    function withdrawBalance() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}