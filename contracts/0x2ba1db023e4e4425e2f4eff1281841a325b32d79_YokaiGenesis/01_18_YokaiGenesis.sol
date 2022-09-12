// SPDX-License-Identifier: MIT
// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./ERC721A.sol";

abstract contract YokaiBox {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual;

    function balanceOf(address owner) public virtual returns (uint256);
}

abstract contract XToken {
    function burn(uint256 tokenId) public virtual;
}

contract YokaiGenesis is ERC721A, Ownable, ReentrancyGuard {
    string private _baseURIextended = "https://yokailabs.net/genesis/metadata/";
    uint256 private MAX_SUPPLY = 4444;
    address public yokaiBoxContractAddress =
        address(0x264DCF6BABB849DDb9fe7380C698fEfFDA1811c4);
    address public RescueXToken;
    bool isHappyHour = true;
    bool isRescue = false;
    uint256[] public burnedYokai;
    bool isAdminMinted = false;
    uint256 public immutable revealStartTime = 1662904800;

    constructor() ERC721A("Yokai Genesis", "YOKAI") {}

    function adminMint(uint256 tokenId) public onlyOwner {
        YokaiBox yContract = YokaiBox(yokaiBoxContractAddress);
        require(!isAdminMinted, "admin already minted");
        _safeMint(msg.sender, 1, "");
        yContract.transferFrom(
            msg.sender,
            address(0x83FD84E8619D6d957FF2469256aDCfC6B5Df1B2B),
            tokenId
        );
        burnedYokai.push(tokenId);
    }

    function reveal(uint256[] memory tokenList) public {
        require(block.timestamp >= revealStartTime, "not start");
        YokaiBox yContract = YokaiBox(yokaiBoxContractAddress);
        uint256 ts = totalSupply();
        if (
            yContract.balanceOf(
                address(0x83FD84E8619D6d957FF2469256aDCfC6B5Df1B2B)
            ) +
                tokenList.length <=
            777 &&
            isHappyHour
        ) {
            require(
                ts + tokenList.length * 2 <= MAX_SUPPLY,
                "exceed max amount"
            );
            _safeMint(msg.sender, tokenList.length * 2, "");
        } else {
            require(ts + tokenList.length <= MAX_SUPPLY, "exceed max amount");
            _safeMint(msg.sender, tokenList.length, "");
        }
        for (uint256 i = 0; i < tokenList.length; i++) {
            yContract.transferFrom(
                msg.sender,
                address(0x83FD84E8619D6d957FF2469256aDCfC6B5Df1B2B),
                tokenList[i]
            );
            burnedYokai.push(tokenList[i]);
        }
    }

    function rescue(uint256 tokenId) public {
        XToken xToken = XToken(RescueXToken);
        require(totalSupply() + 1 <= MAX_SUPPLY, "exceed max amount");
        require(isRescue, "meow...");
        xToken.burn(tokenId);
        _safeMint(msg.sender, 1, "");
    }

    function toggleHappyHour() public onlyOwner {
        isHappyHour = !isHappyHour;
    }

    function toggleRescue() public onlyOwner {
        isRescue = !isRescue;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function setYokaiBoxContractAddress(address newAddress) public onlyOwner {
        yokaiBoxContractAddress = newAddress;
    }

    function setXtokenContractAddress(address newAddress) public onlyOwner {
        RescueXToken = newAddress;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawTokens(IERC20 token) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    function getBurnedList() public view returns (uint256[] memory) {
        return burnedYokai;
    }
}