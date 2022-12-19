///SPDX-License-Identifier:MIT
pragma solidity 0.8.13;

import "@rari-capital/solmate/src/tokens/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./BoolMapWhitelist.sol";

contract Inception is ERC721, ERC2981, BoolMap {
    address public owner;
    address public signerAddress;
    uint256 public saleState;
    uint256 private tokenId;
    uint256 public saleStart;
    uint256 public insiderPrice;
    uint256 public fellowPrice;
    uint256 public publicPrice;
    uint256 public reservedPrivateNfts;
    uint256 public reservedNfts;

    struct DutchAuction {
        uint80 startPrice;
        uint80 endPrice;
        uint32 auctionDuration;
        uint32 dropDuration;
        uint80 dropAmount;
    }

    DutchAuction public dutchAuction;

    uint256 public constant MAXIMUM_NFT = 8888;

    uint256 public maximumTransactionPerMint;

    bytes32 public constant PROVENANCE_HASH = 0xc2908578a697fff44c97633f2d502ac7774cccf6224499c8b09d196cf0651781;

    string private _tokenURI;

    // from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/3d7a93876a2e5e1d7fe29b5a0e96e222afdc4cfa/contracts/access/Ownable.sol#L23
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /////////////////////////////// CONSTRUCTOR ///////////////////////////////

    constructor(address _signer, address ownerAddress) ERC721("RCM INCEPTION", "icNFT") {
        signerAddress = _signer;
        owner = ownerAddress;
    }

    /////////////////////////////// MINT FUNCTIONS ///////////////////////////////

    function insiderMint(uint16 index, bytes calldata signature) external payable notBot {
        require(saleState == 1, "insider mint is not active");
        require(msg.value == insiderPrice, "not enough ether");
        require(tokenId < MAXIMUM_NFT - reservedNfts, "maximum NFT exceeds");

        isSignatureValid(index, signature);

        unchecked {
            ++tokenId;
        }

        _mint(msg.sender, tokenId);

        --reservedPrivateNfts;
    }

    function fellowMint(uint16 index, bytes calldata signature) external payable notBot {
        require(saleState == 2, "fellow mint is not active");
        require(msg.value == fellowPrice, "not enough ether");
        require(tokenId < MAXIMUM_NFT - reservedNfts, "maximum NFT exceeds");

        isSignatureValid(index, signature);

        unchecked {
            ++tokenId;
        }

        _mint(msg.sender, tokenId);

        --reservedPrivateNfts;
    }

    function auctionMint(uint256 amount) external payable notBot {
        uint256 _tokenId = tokenId;

        uint256 price = amount * auctionPrice();

        require(saleState == 3 && block.timestamp >= saleStart, "auction sale is not active");
        require(amount + _tokenId <= MAXIMUM_NFT - reservedPrivateNfts - reservedNfts, "maximum NFT exceeds");
        require(amount <= maximumTransactionPerMint, "maximum nft per transaction exceeds");
        require(msg.value >= price, "not enough ether");

        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }

        for (uint256 i = 0; i < amount; ) {
            unchecked {
                ++i;
                ++_tokenId;
            }

            _mint(msg.sender, _tokenId);
        }

        tokenId = _tokenId;
    }

    function publicMint(uint256 amount) external payable notBot {
        uint256 _tokenId = tokenId;

        require(saleState == 4 && block.timestamp >= saleStart, "public sale is not active");
        require(tokenId + amount <= MAXIMUM_NFT - reservedPrivateNfts - reservedNfts, "maximum NFT exceeds");
        require(amount <= maximumTransactionPerMint, "maximum nft per transaction exceeds");
        require(msg.value == publicPrice * amount, "not enough ether");

        for (uint256 i = 0; i < amount; ) {
            unchecked {
                ++i;
                ++_tokenId;
            }

            _mint(msg.sender, _tokenId);
        }

        tokenId = _tokenId;
    }

    function teamMint(
        address[] calldata to,
        uint256[] calldata amount,
        bool reserved
    ) external onlyOwner {
        uint256 _tokenId = tokenId;
        uint256 totalToken = 0;

        for (uint256 i = 0; i < amount.length; ) {
            for (uint256 k = 0; k < amount[i]; ) {
                unchecked {
                    ++k;
                    ++_tokenId;
                    ++totalToken;
                }

                _mint(to[i], _tokenId);
            }

            unchecked {
                ++i;
            }
        }

        if (reserved) {
            reservedNfts -= totalToken;
        }

        require(_tokenId <= MAXIMUM_NFT, "maximum NFT exceeds");

        tokenId = _tokenId;
    }

    /////////////////////////////// GOVERNANCE FUNCTIONS ///////////////////////////////

    function setFellowPrice(uint256 _fellowPrice) external onlyOwner {
        fellowPrice = _fellowPrice;
    }

    function setInsiderPrice(uint256 _insiderPrice) external onlyOwner {
        insiderPrice = _insiderPrice;
    }

    function setReserved(uint16 _reservedPrivateNfts, uint256 _reservedNfts) external onlyOwner {
        require(tokenId + _reservedPrivateNfts + _reservedNfts <= MAXIMUM_NFT, "invalid reserved nft amount");

        reservedNfts = _reservedNfts;
        reservedPrivateNfts = _reservedPrivateNfts;
    }

    function setMaximumNftLimitPerTransaction(uint256 limit) external onlyOwner {
        maximumTransactionPerMint = limit;
    }

    function setPublicPrice(uint256 _publicPrice) external onlyOwner {
        publicPrice = _publicPrice;
    }

    function setAuctionDetails(DutchAuction calldata _dutchAuction) external onlyOwner {
        dutchAuction = _dutchAuction;
    }

    function changeState(uint256 _saleState) external onlyOwner {
        saleState = _saleState;
    }

    function setSaleStart(uint256 startTime) external onlyOwner {
        saleStart = startTime;
    }

    function changeSigner(address _signer) external onlyOwner {
        signerAddress = _signer;
    }

    function changeOwner(address newOwner) external onlyOwner {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function changeURI(string calldata newURI) external onlyOwner {
        _tokenURI = newURI;
    }

    function setRoyalty(address royaltyAddress, uint96 royaltyRate) external onlyOwner {
        require(royaltyRate <= 1000, "royalty can not be greater than 1000");
        _setDefaultRoyalty(royaltyAddress, royaltyRate);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "transfer failed");
    }

    function setWhitelistSlots(uint256 whitelistedAddressAmount) external onlyOwner {
        optimizeSlots(whitelistedAddressAmount);
    }

    /////////////////////////////// VIEW FUNCTIONS ///////////////////////////////

    function auctionPrice() public view returns (uint256) {
        DutchAuction memory _dutchAuction = dutchAuction;

        uint256 _saleStart = saleStart;
        uint256 currentTime = block.timestamp;

        if (currentTime <= _saleStart) {
            return uint256(_dutchAuction.startPrice);
        }

        if (currentTime - _saleStart < uint256(_dutchAuction.auctionDuration)) {
            uint256 dropStep = (currentTime - _saleStart) / uint256(_dutchAuction.dropDuration);
            return uint256(_dutchAuction.startPrice) - (dropStep * uint256(_dutchAuction.dropAmount));
        } else {
            return uint256(_dutchAuction.endPrice);
        }
    }

    function totalSupply() external view returns (uint256) {
        return tokenId;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        ownerOf(_tokenId);

        return string(abi.encodePacked(_tokenURI, Strings.toString(_tokenId)));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return ERC721.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    ///////////////////////////////////////////////////////////////////////////

    function isSignatureValid(uint16 index, bytes memory signature) private {
        require(signature.length == 65, "invalid signature");
        require(canMint(index), "already minted");
        setMinted(index);

        bytes32 signatureHash = ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(msg.sender, address(this), index, saleState)));

        address _signerAddress = ECDSA.recover(signatureHash, signature);
        require(signerAddress == _signerAddress, "invalid signature");
    }

    /////////////////////////////// MODIFIERS ///////////////////////////////

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    modifier notBot() {
        require(msg.sender == tx.origin, "only human");
        _;
    }
}