// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BOGADogs is ERC721, Ownable {
    uint8 public totalSupply;
    uint8 public maxSupply;
    uint256 public mintPrice;
    bool public isPublicMintEnabled;
    string internal baseTokenUri;
    address payable public withdrawWallet;
    mapping(address => uint8) public walletMints;

    constructor() ERC721("BOGA Dogs", "BOGADOGS") {
        totalSupply = 0;
        maxSupply = 200;
        mintPrice = 0.01 ether;
        isPublicMintEnabled = false;
        withdrawWallet = payable(msg.sender);
    }

    function setIsPublicMintEnabled(bool _isPublicMintEnabled)
        external
        onlyOwner
    {
        isPublicMintEnabled = _isPublicMintEnabled;
    }

    function setBaseTokenUri(string calldata _baseTokenUri) external onlyOwner {
        baseTokenUri = _baseTokenUri;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Token does not exist");
        return
            string(
                abi.encodePacked(
                    baseTokenUri,
                    Strings.toString(_tokenId),
                    ".json"
                )
            );
    }

    function withdraw() external onlyOwner {
        (bool success, ) = withdrawWallet.call{value: address(this).balance}(
            ""
        );
        require(success, "withdraw failed");
    }

    function mint(uint8 quantity) public payable {
        // requires
        require(isPublicMintEnabled, "minting not enabled");
        require(msg.value == quantity * mintPrice, "wrong mint value");
        require(quantity <= maxSupply - totalSupply, "can't mint that many");
        require(totalSupply < maxSupply, "sold out");

        // mint loop
        for (uint8 i; i < quantity; i++) {
            totalSupply++;
            walletMints[msg.sender]++;
            _safeMint(msg.sender, totalSupply);
        }
    }
}