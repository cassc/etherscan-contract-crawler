// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "./interfaces/ILandMetaDataRender.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MOPNLand is ERC721A, Ownable, ReentrancyGuard {
    uint256 public constant MAX_SUPPLY = 10981;

    uint256 public constant ADDRESS_MINT_LIMIT = 5;

    uint256 public immutable R; // Common ratio, 1001 means 1.001

    address public immutable ADDR_TREASURY;

    address public metadataRenderAddress;

    address public auctionAddress;

    uint256 public startPrice;

    uint256 public startTime;

    event EthMinted(address indexed to, uint256 amount, uint256 quantity);
    event AuctionMinted(address indexed to, uint256 amount);

    error withdrawFailed();

    constructor(
        uint256 startTime_,
        uint256 startPrice_,
        uint256 r_,
        address treasuryAddress,
        address metadataRenderAddress_,
        address auctionAddress_
    ) ERC721A("MOPNLAND", "LAND") {
        startTime = startTime_;
        startPrice = startPrice_;
        R = r_;
        ADDR_TREASURY = treasuryAddress;
        metadataRenderAddress = metadataRenderAddress_;
        auctionAddress = auctionAddress_;
    }

    function setStartTime(uint256 startTime_) external onlyOwner {
        startTime = startTime_;
    }

    function setRender(address metadataRenderAddress_) external onlyOwner {
        require(_isContract(metadataRenderAddress_), "Invalid address");
        metadataRenderAddress = metadataRenderAddress_;
    }

    function setAuction(address auctionAddress_) external onlyOwner {
        require(_isContract(auctionAddress_), "Invalid address");
        auctionAddress = auctionAddress_;
    }

    function _isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function ethMint(uint256 quantity) external payable nonReentrant {
        require(
            startTime > 0 && block.timestamp >= startTime,
            "Mint has not started yet"
        );

        uint256 requiredPrice = ethMintTotalPrice(quantity);
        require(msg.value >= requiredPrice, "Insufficient payment");

        require(
            _numberMinted(msg.sender) + quantity <= ADDRESS_MINT_LIMIT,
            "Exceeds address mint limit"
        );

        _mintLand(msg.sender, quantity);

        // reset new startPrice
        if (totalSupply() < MAX_SUPPLY) {
            _resetStartPrice(quantity + 1);
        }

        // Refund excess payment
        if (msg.value > requiredPrice) {
            uint256 excessPayment = msg.value - requiredPrice;
            (bool success, ) = msg.sender.call{value: excessPayment}("");
            require(success, "Failed to refund excess payment");
        }

        emit EthMinted(msg.sender, requiredPrice, quantity);
    }

    function auctionMint(address to, uint256 amount) external {
        require(msg.sender == auctionAddress, "Invalid auctionAddress");
        _mintLand(to, 1);

        emit AuctionMinted(to, amount);
    }

    function _mintLand(address to, uint256 quantity) internal {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Reached max supply");
        _safeMint(to, quantity);
    }

    function ethMintTotalPrice(uint256 quantity) public view returns (uint256) {
        int128 commonRatio = ABDKMath64x64.divu(R, 1000);

        uint256 sum = ABDKMath64x64.mulu(
            ABDKMath64x64.div(
                ABDKMath64x64.sub(
                    ABDKMath64x64.fromUInt(1),
                    ABDKMath64x64.pow(commonRatio, quantity)
                ),
                ABDKMath64x64.sub(ABDKMath64x64.fromUInt(1), commonRatio)
            ),
            startPrice
        );

        // round to four decimal places
        return ((sum + 10 ** 14 / 2) / 10 ** 14) * 10 ** 14;
    }

    function _resetStartPrice(uint256 n) internal {
        int128 commonRatio = ABDKMath64x64.divu(R, 1000);
        uint256 nthTerm = ABDKMath64x64.mulu(
            ABDKMath64x64.pow(commonRatio, n - 1),
            startPrice
        );

        startPrice = nthTerm;
    }

    function nextTokenId() external view returns (uint256) {
        return _nextTokenId();
    }

    function tokenURI(
        uint256 id
    ) public view override returns (string memory tokenuri) {
        require(_exists(id), "not exist");
        require(
            metadataRenderAddress != address(0),
            "Invalid metadataRenderAddress"
        );

        ILandMetaDataRender metadataRender = ILandMetaDataRender(
            metadataRenderAddress
        );
        tokenuri = metadataRender.constructTokenURI(id);
    }

    function withdraw(uint256 amount) external onlyOwner {
        (bool success, ) = payable(ADDR_TREASURY).call{value: amount}("");
        if (!success) {
            revert withdrawFailed();
        }
    }
}