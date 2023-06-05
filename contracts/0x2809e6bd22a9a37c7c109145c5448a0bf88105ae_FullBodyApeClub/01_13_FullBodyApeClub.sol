// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BoredApeYachtClub {
    function ownerOf(uint256) public returns (address) {}
}

contract FullBodyApeClub is ERC721Enumerable, Ownable {
    uint256 public maxTokens = 1111;
    uint256 public tokenPrice = 60000000000000000;
	uint256 public discountPer3 = 30000000000000000;

    bool public started = false;
    bool public paused = false;

    string _baseTokenURI;

    BoredApeYachtClub baycContract;

    mapping(uint256 => uint256) public versionsMinted;
    mapping(uint256 => uint256) public apeNumber;

    constructor(string memory baseURI, address baycAddress)
        ERC721("FullBodyApeClub", "FBAC")
    {
        _baseTokenURI = baseURI;
        baycContract = BoredApeYachtClub(baycAddress);
    }

    function mint(uint256[] memory apes) public payable {
        require(started, "We haven't started yet");
        require(!paused, "We're paused");
        require(apes.length <= 25, "Can't mint more than 25 at once");
        require(
            totalSupply() + apes.length <= maxTokens,
            "Can't fulfil requested tokens"
        );
		uint256 discount = (apes.length / 3) * discountPer3;
        require(
            msg.value >= tokenPrice * apes.length - discount,
            "Didn't send enough ETH"
        );

		uint256 token = 0;
        for (uint256 i = 0; i < apes.length; i++) {
            uint256 ape = apes[i];
            require(
                baycContract.ownerOf(ape) == msg.sender,
                "Not the owner of this ape"
            );
            require(
                versionsMinted[ape] < 3,
                "All versions of this ape have been minted"
            );
			token = totalSupply() + 1;
            versionsMinted[ape]++;
            apeNumber[token] = ape;
            _safeMint(msg.sender, token);
        }
    }

    function send(uint256[] memory apes) public onlyOwner {
        require(apes.length <= 25, "Can't mint more than 25 at once");
        require(
            totalSupply() + apes.length <= maxTokens,
            "Can't fulfil requested tokens"
        );

		uint256 token = 0;
        for (uint256 i = 0; i < apes.length; i++) {
            uint256 ape = apes[i];
            require(
                versionsMinted[ape] < 3,
                "All versions of this ape have been minted"
            );
			token = totalSupply() + 1;
            versionsMinted[ape]++;
            apeNumber[token] = ape;
            _safeMint(baycContract.ownerOf(ape), token);
        }
    }

    function start() external onlyOwner {
        started = true;
    }

    function pause(bool val) external onlyOwner {
        paused = val;
    }

    function setTokenPrice(uint256 _price) external onlyOwner {
        tokenPrice = _price;
    }

    function setBAYCContract(address bayc) external onlyOwner {
        baycContract = BoredApeYachtClub(bayc);
    }

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function getBaseURI() external view onlyOwner returns (string memory) {
        return _baseTokenURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}