// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract YantraNFTs is ERC721, Ownable {
    uint256 public mintPrice;
    uint256 public totalSupply;
    uint256 public maxSupply;
    uint256 public maxPerTx;
    uint256 public roundLimit;
    uint256 public roundSupply;
    bool public isMintEnabled;
    string internal baseTokenUri;
    address payable public withdrawWallet;
    mapping(address => uint256) public walletMints;

    constructor() payable ERC721("Yantra NFTs", "$YAN") {
        mintPrice = 0.089 ether;
        roundSupply = 0;
        roundLimit = 500;
        totalSupply = 0;
        maxSupply = 5000;
        maxPerTx = 10;
        withdrawWallet = payable(0x43C2B1aDdE05Ec23b9BCBD4F10A7d5d9C111e6A1);
    }

    function saleStatus()
        public
        view
        returns (
            bool _mintEnabled,
            uint256 _mintPrice,
            uint256 _roundSupply,
            uint256 _roundLimit,
            uint256 _totalSupply,
            uint256 _maxPerTx
        )
    {
        _mintEnabled = isMintEnabled;
        _mintPrice = mintPrice;
        _roundSupply = roundSupply;
        _roundLimit = roundLimit;
        _totalSupply = totalSupply;
        _maxPerTx = maxPerTx;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMaxPerTransaction(uint256 _maxPerTx) external onlyOwner {
        maxPerTx = _maxPerTx;
    }

    function setWithdrawWallet(address _walletAddress) external onlyOwner {
        withdrawWallet = payable(_walletAddress);
    }

    function setCurrentRoundLimit(uint256 _roundLimit) external onlyOwner {
        require(
            _roundLimit > roundSupply,
            "Current supply cannot be greater than limit"
        );
        require(
            _roundLimit + totalSupply <= maxSupply,
            "Round will exceed max supply"
        );
        roundLimit = _roundLimit;
    }

    function startNewRound(uint256 _roundLimit) external onlyOwner {
        require(
            _roundLimit + totalSupply <= maxSupply,
            "Round will exceed max supply"
        );
        require(roundLimit == roundSupply, "Previous round is not over");
        roundLimit = _roundLimit;
        roundSupply = 0;
    }

    function setIsMintEnabled(bool _isMintEnabled) external onlyOwner {
        isMintEnabled = _isMintEnabled;
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
        require(success, "Failed to withdraw!");
    }

    function mint(uint256 _quantity) public payable {
        require(isMintEnabled, "Mint is not enabled");
        require(msg.value == _quantity * mintPrice, "Value is wrong");
        require(totalSupply + _quantity <= maxSupply, "NFTs sold out");
        require(roundSupply + _quantity <= roundLimit, "Round limit exceeded");
        require(_quantity <= maxPerTx, "Maximum per transaction exceeded");

        for (uint256 i = 0; i < _quantity; i++) {
            uint256 latestTokenId = totalSupply + 1;
            totalSupply++;
            roundSupply++;
            _safeMint(msg.sender, latestTokenId);
        }
        walletMints[msg.sender] += _quantity;
    }
}