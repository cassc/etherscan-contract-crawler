// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract WAGME is ERC721AQueryable, ERC721ABurnable, Ownable {
    uint public maxSupply = 420;
    bool public isMintActive = true;
    uint public estimatedMergeBlock = 15537205;
    uint public contractCreationBlock;

    constructor() ERC721A("We Are All Going To Merge", "WAGME") {
        contractCreationBlock = block.number;
    }

    function toggleMintState() external onlyOwner {
        isMintActive = !isMintActive;
    }

    function setEstimatedMergeBlock(uint _estimatedMergeBlock) external onlyOwner {
        require(contractCreationBlock < _estimatedMergeBlock, "False block");
        estimatedMergeBlock = _estimatedMergeBlock;
    }

    function mint() public {
        require(isMintActive, "Minting is not active");
        require(_nextTokenId() < maxSupply, "Mint out!");

        uint64 usedMints = _getAux(msg.sender);
        require(usedMints == 0, "One mint per wallet");

        _setAux(msg.sender, 1);
        _safeMint(msg.sender, 1);
    }

    function airdrop(address _to, uint _mintAmount) public onlyOwner {
        require(_nextTokenId() < maxSupply, "Mint out!");
        _safeMint(_to, _mintAmount);
    }

    function inverseLerp100x(uint a, uint b, uint value) public pure returns (uint)
    {
        if (a != b)
            return ((value - a) * 100) / ((b - a));
        else
            return 0;
    }

    function getMergeProgress() public view returns (uint){
        return inverseLerp100x(contractCreationBlock, estimatedMergeBlock, block.number);
    }

    function getCircle1Pos() public view returns (uint) {
        return 200 + getMergeProgress();
    }

    function getCircle2Pos() public view returns (uint) {
        return 400 - getMergeProgress();
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string[5] memory parts;

        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 600 600" fill="none" preserveAspectRatio="xMinYMin meet"><rect height="100%" fill="black" width="100%"/><circle cx="';

        parts[1] = _toString(getCircle1Pos());

        parts[2] = '" cy="300" r="25" fill="white"/><circle cx="';

        parts[3] = _toString(getCircle2Pos());

        parts[4] = '" cy="300" r="25" fill="white"/></svg>';

        string memory output = string(
            abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4])
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "WAGME #',
                        _toString(tokenId),
                        '", "description": "WE ARE ALL GOING TO MERGE is a fun little project to visualize merge on-chain!", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(abi.encodePacked("data:application/json;base64,", json));

        return output;
    }
}