// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IBAE.sol";

contract BaeBox is ERC1155, Ownable, ReentrancyGuard {
    uint[] public s1;
    uint[] public s2;
    uint[] public sPixel;
    uint[] public s3;

    IBAE public baeToken;
    IERC721 contractS1;
    IERC721 contractS2;
    IERC721 contractSPixel;
    IERC721 contractS3;

    uint[] public costs = [0.025 ether, 0.05 ether, 0.125 ether];

    struct Reward {
        uint s1;
        uint s2;
        uint s3;
        uint sPixel;
        uint maxBae;
        uint minBae;
    }

    Reward[] public rewards;

    uint[] tierMinted = [0, 0, 0];
    uint[] maxPerTier = [10, 10, 10];

    bool paused = true;

    uint freeTierLuck = 20;
    uint artistPassLuck = 40;

    constructor() ERC1155("ipfs://QmZNexPhocLhvVnWKkoxrdCkgSLEpBKXyvJonqGTqZrK7Y/{id}.json") {
        addReward(0, 0, 2, 2, 1000, 100);
        addReward(0, 2, 1, 3, 3000, 1000);
        addReward(2, 1, 1, 2, 5000, 3000);
    }

    /** Only Owner */

    /** Set ERC721 contracts and ERC20 contract */
    function setContracts(
        IERC721 _s1,
        IERC721 _s2,
        IERC721 _sPixel,
        IERC721 _s3,
        address _baeToken
    ) external onlyOwner {
        contractS1 = _s1;
        contractS2 = _s2;
        contractSPixel = _sPixel;
        contractS3 = _s3;
        baeToken = IBAE(_baeToken);
    }

    function setCosts(uint[] calldata _costs) public onlyOwner {
        costs = _costs;
    }

    function clearTierMinted() public onlyOwner {
        tierMinted = [0, 0, 0];
    }

    function setMaxPerTier(uint[] calldata _maxPerTier) public onlyOwner {
        maxPerTier = _maxPerTier;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setFreeTierLuck(uint _state) public onlyOwner {
        freeTierLuck = _state;
    }

    function setArtistPassLuck(uint _state) public onlyOwner {
        artistPassLuck = _state;
    }

    /** Replace existing array with new array of ids */
    function replaceContents(
        uint128[] calldata _s1,
        uint128[] calldata _s2,
        uint128[] calldata _sPixel,
        uint128[] calldata _s3
    ) public onlyOwner {
        s1 = _s1;
        s2 = _s2;
        sPixel = _sPixel;
        s3 = _s3;
    }

    /** Append data to existing data of season ids */
    function addBatchContents(uint128[] calldata _data, uint _season) public onlyOwner {
        if(_season == 1) {
            for(uint i = 0; i < _data.length; i++) {
                s1.push(_data[i]);
            }
        }
        else if(_season == 2) {
            for(uint i = 0; i < _data.length; i++) {
                s2.push(_data[i]);
            }
        }
        else if(_season == 3) {
            for(uint i = 0; i < _data.length; i++) {
                s3.push(_data[i]);
            }
        } else {
            for(uint i = 0; i < _data.length; i++) {
                sPixel.push(_data[i]);
            }
        }
    }

    /** For admin use, clear contents if added wrong ids */
    function clearContents(uint _season) public onlyOwner {
        if(_season == 1) {
            delete s1;
        }
        else if(_season == 2) {
            delete s2;
        }
        else if(_season == 3) {
            delete s3;
        } else {
            delete sPixel;
        }
    }

    /** Change reward values */
    function addReward(
        uint _s1,
        uint _s2,
        uint _s3,
        uint _sPixel,
        uint _maxBae,
        uint _minBae
    ) public onlyOwner {
        rewards.push(Reward(_s1, _s2, _s3, _sPixel, _maxBae, _minBae));
    }

    function clearRewards() public onlyOwner {
        delete rewards;
    }

    /** Minting Function */
    /** This will allow user to mint tier. */

    function mintBox(uint _tier) public payable nonReentrant {
        require(!paused, "Minting is paused");
        require(
            _tier == 0 || _tier == 1 || _tier == 2,
            "Invalid tier"
        );
        require(tierMinted[_tier] + 1 <= maxPerTier[_tier]);
        require(msg.value >= costs[_tier], "Not enough ether");

        // Send mint and increment minted tier of box
        _mint(msg.sender, _tier, 1, "");
        tierMinted[_tier] = tierMinted[_tier] + 1;
    }

    /** Opening Function */
    /** This will BURN your box after the contents are sent. */

    function openBox(uint _tier) public nonReentrant {
        require(!paused, "Opening is paused");
        require(
            _tier == 0 || _tier == 1 || _tier == 2,
            "Invalid tier"
        );
        require(balanceOf(msg.sender, _tier) > 0, "You do not own a box");

        // Function sends NFTs from box based on tier
        sendTierAmounts(_tier);

        // Burn the BaeBox token
        _burn(msg.sender, _tier, 1);
    }

    /** Helper functions */

    function sendTierAmounts(uint _tier) internal {
        Reward storage r = rewards[_tier];

        // Send s1 rewards
        if (r.s1 > 0) sendRandomS1(r.s1);

        // Send s2 rewards
        if (r.s2 > 0) sendRandomS2(r.s2);

        // Send s3 rewards
        if (r.s3 > 0) sendRandomS3(r.s3);

        sendPixel(r.sPixel);
        sendBae(r.maxBae, r.minBae);

        /** Random events for bonus passes */

        if(random(freeTierLuck) == 0) {
            _mint(msg.sender, 3, 1, "");
        }

        if(random(artistPassLuck) == 0) {
            _mint(msg.sender, 4, 1, "");
        }
    }

    function sendBae(uint max, uint min) internal {
        // Mint value between max and min
        uint n = random(max-min) + min;
        baeToken.mint(msg.sender, n * 10**18);
    }

    function sendRandomS1(uint amount) internal {
        require(s1.length >= amount, "Not enough s1!");

        for (uint i = 0; i < amount; i++) {
            contractS1.safeTransferFrom(
                owner(),
                msg.sender,
                s1[0]
            );
            removeByIndex(0, 1);
        }
    }

    function sendRandomS2(uint amount) internal {
        require(s2.length >= amount, "Not enough s2!");

        for (uint i = 0; i < amount; i++) {
            contractS2.safeTransferFrom(
                owner(),
                msg.sender,
                s2[0]
            );
            removeByIndex(0, 2);
        }
    }

    function sendRandomS3(uint amount) internal {
        require(s3.length >= amount, "Not enough s3!");

        for (uint i = 0; i < amount; i++) {
            contractS3.safeTransferFrom(
                owner(),
                msg.sender,
                s3[0]
            );
            removeByIndex(0, 3);
        }
    }

    function sendPixel(uint amount) internal {
        require(sPixel.length >= amount, "Not enough pixelbaes!");
        // Send pixel, then remove pixel from storage
        for (uint i = 0; i < amount; i++) {
            contractSPixel.safeTransferFrom(
                owner(),
                msg.sender,
                sPixel[0]
            );
            removeByIndex(0, 4);
        }
    }

    function removeByIndex(uint index, uint season) internal {
        if (season == 1) {
            for (uint i = index; i < s1.length - 1; i++) {
                s1[i] = s1[i + 1];
            }
            s1.pop();
        } else if (season == 2) {
            for (uint i = index; i < s2.length - 1; i++) {
                s2[i] = s2[i + 1];
            }
            s2.pop();
        } else if (season == 3) {
            for (uint i = index; i < s3.length - 1; i++) {
                s3[i] = s3[i + 1];
            }
            s3.pop();
        } else {
            for (uint i = index; i < sPixel.length - 1; i++) {
                sPixel[i] = sPixel[i + 1];
            }
            sPixel.pop();
        }
    }

    function random(uint length) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.timestamp, block.difficulty, length)
                )
            ) % length;
    }

    /** Public views */
    function showCostsPerTier() public view returns (uint[] memory) {
        return costs;
    }

    function showTiersMinted() public view returns(uint[] memory) {
        return tierMinted;
    }

    function showMaxPerTier() public view returns(uint[] memory) {
        return maxPerTier;
    }

    /** Owner Views */

    function showS1Ids() public view onlyOwner returns (uint[] memory) {
        return s1;
    }

    function showS2Ids() public view onlyOwner returns (uint[] memory) {
        return s2;
    }

    function showSPixelIds() public view onlyOwner returns (uint[] memory) {
        return sPixel;
    }

    function showS3Ids() public view onlyOwner returns (uint[] memory) {
        return s3;
    }

    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}