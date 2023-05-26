//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract NarutoMuseumPass is ERC721("Naruto Museum Pass", "NMP"), Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _goldTokenIds;
    Counters.Counter private _silverTokenIds;
    mapping(address => bool) public minter;
    string private baseURL = "ipfs://bafybeidtuggvku6bqd6cu2dqt4tj6sfc6f4qwdcpli5otacyhyghq5xbrq";
    uint256 private _goldTotalSupply;

    constructor(uint256 goldTotalSupply) {
        _goldTotalSupply = goldTotalSupply;
    }

    modifier onlyMinter() {
        require(minter[_msgSender()], "Only minter.");
        _;
    }

    function setMinter(address _minter, bool _isMinter) external onlyOwner {
        minter[_minter] = _isMinter;
    }

    function setBaseURL(string calldata _baseURL) external onlyOwner {
        baseURL = _baseURL;
    }

    function mintGold(address _receiver) public onlyMinter {
        _goldTokenIds.increment();
        require(_goldTokenIds.current() <= _goldTotalSupply, "Total supply reached.");
        uint256 tokenId = _goldTokenIds.current();
        _safeMint(_receiver, tokenId);
    }

    function batchMintGold(address[] calldata _receivers) external onlyMinter {
        for (uint256 i = 0; i < _receivers.length; i++) {
            mintGold(_receivers[i]);
        }
    }

    function mintSilver(address _receiver) public onlyMinter {
        _silverTokenIds.increment();
        uint256 tokenId = _silverTokenIds.current();
        _safeMint(_receiver, _goldTotalSupply + tokenId);
    }

    function batchMintSilver(address[] calldata _receivers) external onlyMinter {
        for (uint256 i = 0; i < _receivers.length; i++) {
            mintSilver(_receivers[i]);
        }
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory trait;
        string memory image;
        string memory animationUrl;
        if (tokenId <= _goldTotalSupply) {
            trait = "Gold";
            image = string(abi.encodePacked(baseURL, "/gold.png"));
            animationUrl = string(abi.encodePacked(baseURL, "/gold.mp4"));
        } else {
            tokenId = tokenId - _goldTotalSupply;
            trait = "Silver";
            image = string(abi.encodePacked(baseURL, "/silver.png"));
            animationUrl = string(abi.encodePacked(baseURL, "/silver.mp4"));
        }

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"Naruto Museum Pass | ',
                                trait,
                                " #",
                                Strings.toString(tokenId),
                                '","description":"This is an official pass of NFT Naruto Museum. The pass provides the right to participate in future projects of the museum, such as Naruto Launchpad, Naruto Meta Museum, etc.","attributes":[{"trait_type":"Edition","value":"',
                                trait,
                                '"}],"image":"',
                                image,
                                '","external_url":"',
                                image,
                                '","animation_url":"',
                                animationUrl,
                                '"}'
                            )
                        )
                    )
                )
            );
    }
}