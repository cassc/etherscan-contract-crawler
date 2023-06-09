// contracts/Ethersparks.sol
//SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Inspired from BGANPUNKS V2 (bastardganpunks.club) & Chubbies
contract Ethersparks is ERC721, Ownable {
    using SafeMath for uint256;
    uint public constant MAX_ETHERSPARKS = 10200;
    bool public hasSaleStarted = false;

    // The IPFS hash for all Ethersparks concatenated *might* stored here once all Ethersparks are issued and if I figure it out
    string public METADATA_PROVENANCE_HASH = "";

    // Truth.
    string public constant R =
        "Those cute little Ethersparks are on a mission to the moon.";

    constructor() ERC721("Ethersparks", "ETHERSPARKS") {
        setBaseURI("https://ethersparks.mypinata.cloud/ipfs/QmRcZ8tZ5PLMvmqkJvoWswvNenSX9XeP7qiNtZ2AkbAf67/");
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function calculatePrice() public view returns (uint256) {
        require(hasSaleStarted == true, "Sale hasn't started");
        require(totalSupply() < MAX_ETHERSPARKS, "Sale has already ended");

        uint currentSupply = totalSupply();
        if (currentSupply >= 10000) {
            return 130000000000000000;         // 10000-10199: 0.13 ETH
        } else if (currentSupply >= 9500) {
            return 110000000000000000;           // 9500-9999:  0.11 ETH
         } else if (currentSupply >= 7500) {
            return 90000000000000000;           // 7500-9499:  0.09 ETH
        } else if (currentSupply >= 3500) {
            return 70000000000000000;           // 3500-7499:  0.07 ETH
        } else if (currentSupply >= 1500) {
            return 50000000000000000;           // 1500-3499:  0.05 ETH
        } else if (currentSupply >= 500) {
            return 30000000000000000;           // 500-1499:  0.03 ETH
        } else {
            return 10000000000000000;           // 0-499:   0.01 ETH
        }
    }

    function calculatePriceForToken(uint _id) public view returns (uint256) {
        require(_id < MAX_ETHERSPARKS, "Sale has already ended");

        if (_id >= 10000) {
            return 130000000000000000;     // 10000-10199: 0.13 ETH
        } else if (_id >= 9500) {
            return 110000000000000000;       // 9500-9999:  0.11 ETH
        } else if (_id >= 7500) {
            return 90000000000000000;       // 7500-9499:  0.09 ETH
        } else if (_id >= 3500) {
            return 70000000000000000;       // 3500-7499:  0.07 ETH
        } else if (_id >= 1500) {
            return 50000000000000000;       // 1500-3499:  0.05 ETH
        } else if (_id >= 500) {
            return 30000000000000000;       // 500-1499:  0.03 ETH
        } else {
            return 10000000000000000;       // 0-499:   0.01 ETH
        }
    }

    function adoptEthersparks(uint256 numEthersparks) public payable {
        require(totalSupply() < MAX_ETHERSPARKS, "Sale has already ended");
        require(
            numEthersparks > 0 && numEthersparks <= 20,
            "You can adopt minimum 1, maximum 20 Ethersparks"
        );
        require(
            totalSupply().add(numEthersparks) <= MAX_ETHERSPARKS,
            "Exceeds MAX_ETHERSPARKS"
        );
        require(
            msg.value >= calculatePrice().mul(numEthersparks),
            "Ether value sent is below the price"
        );

        for (uint i = 0; i < numEthersparks; i++) {
            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
    }

    // God Mode
    function setProvenanceHash(string memory _hash) public onlyOwner {
        METADATA_PROVENANCE_HASH = _hash;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    function startSale() public onlyOwner {
        hasSaleStarted = true;
    }

    function pauseSale() public onlyOwner {
        hasSaleStarted = false;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function reserveGiveaway(uint256 numEthersparks) public onlyOwner {
        uint currentSupply = totalSupply();
        require(
            totalSupply().add(numEthersparks) <= 60,
            "Exceeded giveaway supply"
        );
        require(hasSaleStarted == false, "Sale has already started");
        uint256 index;
        // Reserved for people who helped this project and giveaways
        for (index = 0; index < numEthersparks; index++) {
            _safeMint(owner(), currentSupply + index);
        }
    }
}