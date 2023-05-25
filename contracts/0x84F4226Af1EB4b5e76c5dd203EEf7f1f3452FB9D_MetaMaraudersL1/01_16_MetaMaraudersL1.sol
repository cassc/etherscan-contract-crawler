// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

//  __       __              __
// /  \     /  |            /  |
// $$  \   /$$ |  ______   _$$ |_     ______
// $$$  \ /$$$ | /      \ / $$   |   /      \
// $$$$  /$$$$ |/$$$$$$  |$$$$$$/    $$$$$$  |
// $$ $$ $$/$$ |$$    $$ |  $$ | __  /    $$ |
// $$ |$$$/ $$ |$$$$$$$$/   $$ |/  |/$$$$$$$ |
// $$ | $/  $$ |$$       |  $$  $$/ $$    $$ |
// $$/      $$/  $$$$$$$/    $$$$/   $$$$$$$/
//
//  __       __                                               __
// /  \     /  |                                             /  |
// $$  \   /$$ |  ______    ______   ______   __    __   ____$$ |  ______    ______    _______
// $$$  \ /$$$ | /      \  /      \ /      \ /  |  /  | /    $$ | /      \  /      \  /       |
// $$$$  /$$$$ | $$$$$$  |/$$$$$$  |$$$$$$  |$$ |  $$ |/$$$$$$$ |/$$$$$$  |/$$$$$$  |/$$$$$$$/
// $$ $$ $$/$$ | /    $$ |$$ |  $$/ /    $$ |$$ |  $$ |$$ |  $$ |$$    $$ |$$ |  $$/ $$      \
// $$ |$$$/ $$ |/$$$$$$$ |$$ |     /$$$$$$$ |$$ \__$$ |$$ \__$$ |$$$$$$$$/ $$ |       $$$$$$  |
// $$ | $/  $$ |$$    $$ |$$ |     $$    $$ |$$    $$/ $$    $$ |$$       |$$ |      /     $$/
// $$/      $$/  $$$$$$$/ $$/       $$$$$$$/  $$$$$$/   $$$$$$$/  $$$$$$$/ $$/       $$$$$$$/

/// @title MetaMarauders
/// @author Smart-Chain Team

contract MetaMaraudersL1 is ERC721, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Strings for uint256;

    string public constant VERSION = "1";

    uint256 public mintableSupply;
    uint256 public priceSale = 0.1 ether;
    uint256 public constant maxMint = 25;
    uint256 public reservedSupplyAllocation;
    bool public saleIsActive;
    bool public saleHasEnded;
    address public reserveAddress;
    string public preRevealURI;
    string public proofSig;

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        string memory tokenBaseURI,
        uint256 mintableSupply_,
        uint256 reservedSupplyAllocation_,
        address reserveAddress_
    ) ERC721(tokenName, tokenSymbol) {
        require(
            mintableSupply_ > reservedSupplyAllocation_,
            "Cannot set reserve greater than supply"
        );
        mintableSupply = mintableSupply_;
        _setBaseURI(tokenBaseURI);
        saleIsActive = false;
        saleHasEnded = false;
        reservedSupplyAllocation = reservedSupplyAllocation_;
        reserveAddress = reserveAddress_;
    }

    function mint(uint256 amountToMint)
        external
        payable
        nonReentrant
        returns (bool)
    {
        require(saleIsActive, "NFT sale is no longer available");
        require(amountToMint <= maxMint, "Amount for minting is too high");
        uint256 supply = totalSupply();
        require(
            mintableSupply.sub(reservedSupplyAllocation) >=
                supply.add(amountToMint),
            "Mintable hardcap reached"
        );
        require(
            msg.value >= priceSale.mul(amountToMint),
            "Incorrect ETH amount sent"
        );
        for (uint256 i = 0; i < amountToMint; i++) {
            _safeMint(msg.sender, supply.add(i));
        }
        return true;
    }

    function airdrop(address[] memory recipient)
        external
        onlyOwner
        returns (bool)
    {
        uint256 supply = totalSupply();
        require(
            recipient.length <= reservedSupplyAllocation,
            "Amount exceeds reserved allocation"
        );
        require(
            supply.add(recipient.length) <= mintableSupply,
            "Mintable hardcap reached"
        );
        for (uint256 i = 0; i < recipient.length; i++) {
            _safeMint(recipient[i], supply.add(i));
        }
        reservedSupplyAllocation = reservedSupplyAllocation.sub(
            recipient.length
        );
        return true;
    }

    function migrate(address[] memory recipient, uint256[] memory tokenIds)
        external
        onlyOwner
        returns (bool)
    {
        require(
            recipient.length == tokenIds.length,
            "Incorrect migration parameters"
        );
        require(
            recipient.length <= reservedSupplyAllocation,
            "Amount exceeds reserved allocation"
        );
        require(
            totalSupply().add(recipient.length) <= mintableSupply,
            "Mintable hardcap reached"
        );
        for (uint256 i = 0; i < recipient.length; i++) {
            _safeMint(recipient[i], tokenIds[i]);
        }
        reservedSupplyAllocation = reservedSupplyAllocation.sub(
            recipient.length
        );
        return true;
    }

    function withdrawSale() external payable onlyOwner returns (bool) {
        require(
            payable(address(reserveAddress)).send(address(this).balance),
            "Error while withdrawing reserve"
        );
        return true;
    }

    function balanceOfUser(address userBalance)
        external
        view
        returns (uint256[] memory)
    {
        uint256 amountOfTokens = balanceOf(userBalance);
        uint256[] memory tokenIds = new uint256[](amountOfTokens);
        for (uint256 i = 0; i < amountOfTokens; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(userBalance, i);
        }
        return tokenIds;
    }

    function setSaleActiveStatus(bool saleActiveStatus_) external onlyOwner {
        saleIsActive = saleActiveStatus_;
    }

    function setSaleEndingStatus(bool saleEndingStatus_) external onlyOwner {
        saleHasEnded = saleEndingStatus_;
    }

    function setReservedSupplyAllocation(uint256 reservedSupplyAllocation_)
        external
        onlyOwner
    {
        reservedSupplyAllocation = reservedSupplyAllocation_;
    }

    function getPrice() external view returns (uint256) {
        return priceSale;
    }

    function setPrice(uint256 newPriceSale) external onlyOwner {
        priceSale = newPriceSale;
    }

    function setPreRevealURI(string memory preRevealURI_) external onlyOwner {
        preRevealURI = preRevealURI_;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _setBaseURI(baseURI);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory base = baseURI();
        return
            saleHasEnded
                ? string(abi.encodePacked(base, tokenId.toString()))
                : preRevealURI;
    }

    function setProofSig(string calldata proofSig_) external onlyOwner {
        proofSig = proofSig_;
    }
}