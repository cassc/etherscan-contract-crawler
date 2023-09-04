//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./core/NPassCore.sol";
import "./interfaces/IN.sol";

interface ITreasure {
    function depositsOf(address account) external view returns (uint256[] memory);
}

/**
 * @title Adorable Aliens
 * @author maximonee (twitter.com/maximonee_)
 * @notice This contract provides minting for Adorable Aliens NFT by twitter.com/adorablealiens_
 */
contract AdorableAliens is NPassCore {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor(
        string memory name,
        string memory symbol,
        address _nContractAddress,
        bool onlyNHolders,
        uint256 maxTotalSupply,
        uint16 reservedAllowance,
        uint256 priceForNHoldersInWei,
        uint256 priceForOpenMintInWei) NPassCore(
            name,
            symbol,
            IN(_nContractAddress),
            onlyNHolders,
            maxTotalSupply,
            reservedAllowance,
            priceForNHoldersInWei,
            priceForOpenMintInWei
        ) {
            // Start token IDs at 1
            _tokenIds.increment();
        }

    bool public isPublicSaleActive = false;

    uint16 public constant M_PERCENT_CUT = 15;
    uint16 public constant A_PERCENT_CUT = 35;
    uint16 public constant I_PERCENT_CUT = 35;
    uint16 public constant DF_PERCENT_CUT = 15;

    address public constant mAddress = 0x07AF777f46489dFd49336A17bA69583F89596D1c;
    address public constant aAddress = 0xc4aD094A9455D24b52f5b3ec37dA3c3982d3B3e1;
    address public constant iAddress = 0xf2e55Eeac7a3D49fC8E9899aFe01965df6366133;
    address public constant dfAddress = 0xc9b9553B32825fDb236a1cB318154343DEa531dA;

    address public constant treasureStakingAddress = 0x08543f4c79f7e5d585A2622cA485e8201eFd9aDA;
    ITreasure treasure = ITreasure(treasureStakingAddress);

    string public baseTokenURI = "https://arweave.net/7DXOpVQMLfcO1IXHsCs9EPuYk6DGCMoplrJt2NpvCCk/";

    function setPublicSaleState(bool _publicSaleActiveState) public onlyOwner {
        isPublicSaleActive = _publicSaleActiveState;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
    Update the base token URI
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    /**
    Allows minting for n holders if holding n in wallet or staking in Treasure farm
     */
    function _isNHolder() internal view returns (bool) {
        if (n.balanceOf(msg.sender) > 0) {
            return true;
        }

        if (treasure.depositsOf(msg.sender).length > 0) {
            return true;
        }

        return false;
    }

    /**
     * @notice Allow a n token holder to bulk mint tokens
     */
    function multiMintWithN(uint256 numberOfMints) public payable virtual nonReentrant {
        require(isPublicSaleActive, "SALE_NOT_ACTIVE");
        require(numberOfMints <= MAX_MULTI_MINT_AMOUNT, "NPass:TOO_LARGE");
        require(
            // If no reserved allowance we respect total supply contraint
            (reservedAllowance == 0 && totalSupply() + numberOfMints <= maxTotalSupply) ||
                reserveMinted + numberOfMints <= reservedAllowance,
            "NPass:MAX_ALLOCATION_REACHED"
        );
        require(msg.value >= priceForNHoldersInWei * numberOfMints, "NPass:INVALID_PRICE");

        require(_isNHolder(), "MUST_BE_AN_N_OWNER");

        // If reserved allowance is active we track mints count
        if (reservedAllowance > 0) {
            reserveMinted += uint16(numberOfMints);
        }

        for (uint256 i = 0; i < numberOfMints; i++) {
            uint256 tokenId = _tokenIds.current();
            _safeMint(msg.sender, tokenId);
            _tokenIds.increment();
        }

        _sendEthOut();
    }

    /**
     * @notice Allow public to bulk mint tokens
     */
    function multiMint(uint256 numberOfMints) public payable virtual nonReentrant {
        require(isPublicSaleActive, "SALE_NOT_ACTIVE");
        require(numberOfMints <= MAX_MULTI_MINT_AMOUNT, "NPass:TOO_LARGE");
        require(
            // If no reserved allowance we respect total supply contraint
            (reservedAllowance == 0 && totalSupply() + numberOfMints <= maxTotalSupply) ||
                reserveMinted + numberOfMints <= reservedAllowance,
            "NPass:MAX_ALLOCATION_REACHED"
        );
        require(msg.value >= priceForOpenMintInWei * numberOfMints, "NPass:INVALID_PRICE");

        // If reserved allowance is active we track mints count
        if (reservedAllowance > 0) {
            reserveMinted += uint16(numberOfMints);
        }
        
        for (uint256 i = 0; i < numberOfMints; i++) {
            uint256 tokenId = _tokenIds.current();
            _safeMint(msg.sender, tokenId);
            _tokenIds.increment();
        }

        _sendEthOut();
    }

    /**
     * @notice Allow a n token holder to mint a token with one of their n token's id
     */
    function mintWithN() public payable virtual nonReentrant {
        require(isPublicSaleActive, "SALE_NOT_ACTIVE");
        require(
            // If no reserved allowance we respect total supply contraint
            (reservedAllowance == 0 && totalSupply() < maxTotalSupply) || reserveMinted < reservedAllowance,
            "NPass:MAX_ALLOCATION_REACHED"
        );
        require(_isNHolder(), "MUST_BE_AN_N_OWNER");
        require(msg.value >= priceForNHoldersInWei, "NPass:INVALID_PRICE");

        // If reserved allowance is active we track mints count
        if (reservedAllowance > 0) {
            reserveMinted++;
        }

        uint256 tokenId = _tokenIds.current();
        _safeMint(msg.sender, tokenId);
        _tokenIds.increment();

        _sendEthOut();
    }

    /**
     * @notice Allow anyone to mint a token with the supply id if this pass is unrestricted.
     *         n token holders can use this function without using the n token holders allowance,
     *         this is useful when the allowance is fully utilized.
     */
    function mint() public payable virtual nonReentrant {
        require(isPublicSaleActive, "SALE_NOT_ACTIVE");
        require(!onlyNHolders, "NPass:OPEN_MINTING_DISABLED");
        require(openMintsAvailable() > 0, "NPass:MAX_ALLOCATION_REACHED");
        require(msg.value >= priceForOpenMintInWei, "NPass:INVALID_PRICE");

        uint256 tokenId = _tokenIds.current();
        _safeMint(msg.sender, tokenId);
        _tokenIds.increment();

        _sendEthOut();
    }

    function _sendEthOut() internal {
        uint256 value = msg.value;
        _sendTo(mAddress, (value * M_PERCENT_CUT) / 100);
        _sendTo(iAddress, (value * I_PERCENT_CUT) / 100);
        _sendTo(aAddress, (value * A_PERCENT_CUT) / 100);
        _sendTo(dfAddress, (value * DF_PERCENT_CUT) / 100);
    }

    function _sendTo(address to_, uint256 value) internal {
        address payable to = payable(to_);
        (bool success, ) = to.call{value: value}("");
        require(success, "ETH_TRANSFER_FAILED");
    }
}