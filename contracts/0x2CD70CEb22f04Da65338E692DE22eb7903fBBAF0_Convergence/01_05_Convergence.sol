//
//                     ,▄██▄ ,▄▄█▀
//                  ▄█████▌¬'███▀▀██▄
//               ,║█▌  ║█▌ ,██⌐  ▄█████▄ 
//              ██▀▀██▄ ║█▌▄██▌▄███▀   ██
//            ▐█▌  '██▌███████████████████µ
//           ╓█████▄╙███████████████└    ██
//            ██  └▀█████████████▓█████████▌
//           ╙███▄▄▄█████████████████, ─└██µ
//           ▐██╙╙▀▀███████████▀███████▄▄██⌐
//            ╙██▄▄▄█████████████████  ╙██▌
//             '╙██▀╙└└┌██████████ ╙██, ▄█▌
//              ║█▄,▄███▀'║██¬`██  ╙███▀▀
//               ╙▀▀▀█▌  ╓██▌  ██▄▄██▀
//                  ╙████▀█████▀╙▀▀─
//   𝙛𝙤𝙧 𝙖𝙣 𝙚𝙭𝙥𝙚𝙧𝙞𝙢𝙚𝙣𝙩 𝙩𝙤 𝙙𝙧𝙖𝙬 ║█▌─
//   𝙖 𝙘𝙤𝙣𝙘𝙡𝙪𝙨𝙞𝙤𝙣 𝙞𝙩 𝙢𝙪𝙨𝙩 𝙛𝙞𝙧𝙨𝙩  j█▌
//   𝙘𝙤𝙢𝙚 𝙩𝙤 𝙖𝙣 𝙚𝙣𝙙.        j█▌
//     ___ ___ ___ _ _ ___▐█▌_ ___ ___ ___ ___ ___ 
//    |  _| . |   | | | -_|  _| . | -_|   |  _| -_|
//    |___|___|_|_|\_/|___|_| |_  |___|_|_|___|___|
//                            |___| 𝘵𝘰 𝘣𝘦 𝘤𝘰𝘯𝘵𝘪𝘯𝘶𝘦𝘥...    
//
//           𝘢 𝘨𝘦𝘯𝘦𝘳𝘢𝘵𝘪𝘷𝘦 𝘢𝘳𝘵 𝘦𝘹𝘱𝘦𝘳𝘪𝘮𝘦𝘯𝘵 𝘧𝘳𝘰𝘮 𝘣𝘶𝘻𝘻𝘺
//           SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Convergence is ERC721A, Ownable {
    string public _baseTokenURI;
    uint public price = 0.01 ether;
    address private buzz = 0xFa24220e5Fc440DC548b1dD08d079063Adf93f28;
    address public lastMinted;
    uint public startTime = 1670954400;
    uint public lastMintTime = startTime;

    constructor(string memory baseURI) ERC721A("convergence", "CNVG") {
        _baseTokenURI = baseURI;
    }

    function mint() external payable {
        require(lastMinted != msg.sender, "Address already minted");
        require(msg.value == price, "Invalid price");
        require(lastMintTime + 1 days > block.timestamp, "Minting has closed");
        require(startTime < block.timestamp, "Minting hasn't begun.");

        _mint(msg.sender, 1);

        lastMinted = msg.sender;
        lastMintTime = block.timestamp;
    }

    function endTime() external view returns (uint) {
        return lastMintTime + 1 days;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setStartTime(uint newStartTime) external onlyOwner {
        if (lastMintTime == startTime) {
            lastMintTime = newStartTime;
        }

        startTime = newStartTime;
    }

    function withdraw() external onlyOwner {
        (bool s, ) = buzz.call{value: (address(this).balance)}("");
        require(s, "withdraw failed");
    }
}