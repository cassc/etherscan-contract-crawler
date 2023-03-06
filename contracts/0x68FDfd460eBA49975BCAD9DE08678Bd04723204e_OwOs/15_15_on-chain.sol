// SPDX-License-Identifier: MIT

/*********************************
 *                                *
 *              OwO               *
 *                                *
 *********************************/

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./idescriptor.sol";

contract OwOs is ERC721Enumerable, Ownable {
    event SeedUpdated(uint256 indexed tokenId, uint256 seed);

    mapping(uint256 => uint256) internal seeds;
    IOwODescriptor public descriptor;
    uint256 public maxSupply = 10000;
    bool public minting = true;
    bool public canUpdateSeed = true;
    mapping(address => uint256) public referralRewards;
    uint256 totalRewards = 0;

    constructor(IOwODescriptor newDescriptor) ERC721("OwOs", "OWO") {
        descriptor = newDescriptor;
    }

    // function mint(uint32 count) external payable {
    //     require(minting, "Minting needs to be enabled to start minting");
    //     require(count < 101, "Exceeds max per transaction.");
    //     uint256 nextTokenId = totalSupply()+1;
    //     unchecked {
    //         require(nextTokenId + count <= maxSupply, "Exceeds max supply.");
    //     }

    //     for (uint32 i; i < count;) {
    //         seeds[nextTokenId] = generateSeed(nextTokenId);
    //         _mint(_msgSender(), nextTokenId);
    //         unchecked { ++nextTokenId; ++i; }
    //     }
    // }

    function mint(uint32 count, address referrer) external payable {
        require(minting, "Minting needs to be enabled to start minting");
        require(count < 101, "Exceeds max per transaction.");
        uint256 nextTokenId = totalSupply() + 1;
        unchecked {
            require(msg.value >= count * 0.005 ether, "Insufficient funds");
            require(nextTokenId + count <= maxSupply, "Exceeds max supply.");
        }

        for (uint32 i; i < count; ) {
            seeds[nextTokenId] = generateSeed(nextTokenId);
            _mint(_msgSender(), nextTokenId);
            unchecked {
                ++nextTokenId;
                ++i;
            }
        }

        if (referrer != address(0) && referrer != _msgSender()) {
            referralRewards[referrer] += msg.value / 10;
            totalRewards += msg.value / 10;
        }
    }
    
    function royaltyInfo(uint256 tokenId, uint256 value)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        return (owner(), (value * 5) / 100);
    }

    function withdrawReferralRewards() external {
        uint256 amount = referralRewards[msg.sender];
        require(amount > 0, "No referral rewards");
        totalRewards -= amount;
        referralRewards[msg.sender] = 0;
        (bool os, ) = payable(msg.sender).call{value: amount}("");
        require(os);
    }

    function setMinting(bool value) external onlyOwner {
        minting = value;
    }

    function setDescriptor(IOwODescriptor newDescriptor) external onlyOwner {
        descriptor = newDescriptor;
    }

    function withdraw() external payable onlyOwner {
        (bool os, ) = payable(owner()).call{
            value: address(this).balance - totalRewards
        }("");
        require(os);
    }

    function updateSeed(uint256 tokenId, uint256 seed) external onlyOwner {
        require(canUpdateSeed, "Cannot set the seed");
        seeds[tokenId] = seed;
        emit SeedUpdated(tokenId, seed);
    }

    function disableSeedUpdate() external onlyOwner {
        canUpdateSeed = false;
    }

    function burn(uint256 tokenId) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Not approved to burn."
        );
        delete seeds[tokenId];
        _burn(tokenId);
    }

    function getSeed(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "OwO does not exist.");
        return seeds[tokenId];
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "OwO does not exist.");
        uint256 seed = seeds[tokenId];
        return descriptor.tokenURI(tokenId, seed);
    }

    function generateSeed(uint256 tokenId) private view returns (uint256) {
        uint256 r = random(tokenId);
        uint256 headSeed = 100 * ((r % 7) + 10) + (((r >> 48) % 20) + 10);
        uint256 faceSeed = 100 *
            (((r >> 96) % 6) + 10) +
            (((r >> 96) % 20) + 10);
        uint256 bodySeed = 100 *
            (((r >> 144) % 7) + 10) +
            (((r >> 144) % 20) + 10);
        uint256 legsSeed = 100 *
            (((r >> 192) % 2) + 10) +
            (((r >> 192) % 20) + 10);
        return
            10000 *
            (10000 * (10000 * headSeed + faceSeed) + bodySeed) +
            legsSeed;
    }

    function random(uint256 tokenId)
        private
        view
        returns (uint256 pseudoRandomness)
    {
        pseudoRandomness = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), tokenId))
        );

        return pseudoRandomness;
    }
}