// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Fubao is ERC721A, Ownable, Pausable, ReentrancyGuard {
    // metadata
    string public baseURI;

    // collection info
    uint256 public constant collectionSize = 9960;
    uint256 public perAddressMaxMintAmount = 10;

    // for marketing etc.
    uint256 public reservedAmount;
    uint256 public reservedMintedAmount;
    mapping(uint256 => string) public mintChannelMap;

    // public mint config
    uint256 public publicAvailableAmount;
    uint256 public publicMintedAmount;
    uint256 public publicStartTime;
    uint256 public publicPrice;

    // white list mint config
    bytes32 public whiteListMerkleRoot;
    uint256 public whiteListMintedAmount;
    uint256 public whiteListStartTime;
    uint256 public whiteListEndTime;
    uint256 public whiteListPrice;

    // refund config
    mapping(uint256 => uint256) public refundPriceMap;
    mapping(uint256 => uint256) public refundEndTimeMap;
    uint256 public refundPeriod = 7 days;
    uint256 public refundLastEndTime;
    uint256 public refundedAmount;
    address public refundAddress;

    constructor(
        string memory baseURI_,
        uint256 reservedAmount_,
        uint256 publicAvailableAmount_,
        uint256 publicStartTime_,
        uint256 publicPrice_,
        bytes32 whiteListMerkleRoot_,
        uint256 whiteListStartTime_,
        uint256 whiteListEndTime_,
        uint256 whiteListPrice_
    ) ERC721A("996fubao", "FUBAO") {
        require(
            reservedAmount_ <= collectionSize &&
                publicAvailableAmount_ <= collectionSize - reservedAmount_ &&
                whiteListStartTime_ <= whiteListEndTime_,
            "invalid"
        );
        baseURI = baseURI_;
        reservedAmount = reservedAmount_;
        publicAvailableAmount = publicAvailableAmount_;
        publicStartTime = publicStartTime_;
        publicPrice = publicPrice_;
        whiteListMerkleRoot = whiteListMerkleRoot_;
        whiteListStartTime = whiteListStartTime_;
        whiteListEndTime = whiteListEndTime_;
        whiteListPrice = whiteListPrice_;
        refundAddress = msg.sender;
    }

    function setBaseURI(string calldata baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function setMintConfig(
        uint256 perAddressMaxMintAmount_,
        uint256 reservedAmount_,
        uint256 publicAvailableAmount_,
        uint256 publicStartTime_,
        uint256 publicPrice_,
        bytes32 whiteListMerkleRoot_,
        uint256 whiteListStartTime_,
        uint256 whiteListEndTime_,
        uint256 whiteListPrice_
    ) public onlyOwner {
        require(
            reservedAmount_ <= reservedAmount &&
                reservedAmount_ >= reservedMintedAmount &&
                publicAvailableAmount_ >= publicAvailableAmount &&
                publicAvailableAmount_ <= collectionSize - reservedAmount_ &&
                whiteListStartTime_ <= whiteListEndTime_,
            "invalid"
        );
        perAddressMaxMintAmount = perAddressMaxMintAmount_;
        reservedAmount = reservedAmount_;
        publicAvailableAmount = publicAvailableAmount_;
        publicStartTime = publicStartTime_;
        publicPrice = publicPrice_;
        whiteListMerkleRoot = whiteListMerkleRoot_;
        whiteListStartTime = whiteListStartTime_;
        whiteListEndTime = whiteListEndTime_;
        whiteListPrice = whiteListPrice_;
    }

    function setRefundConfig(uint256 refundPeriod_, address refundAddress_)
        public
        onlyOwner
    {
        refundPeriod = refundPeriod_;
        refundAddress = refundAddress_;
    }

    function mint(
        uint256 amount,
        uint256 whiteListTotalAmount,
        bytes32[] calldata whiteListMerkleProof,
        string calldata channel
    ) public payable callerIsUser nonReentrant {
        require(
            publicMintedAmount + amount <= publicAvailableAmount &&
                _numberMinted(msg.sender) + amount <= perAddressMaxMintAmount,
            "not enough amount"
        );
        require(bytes(channel).length <= 20, "channel too long");
        uint256 whiteListRemainAmount = 0;
        if (
            block.timestamp >= whiteListStartTime &&
            block.timestamp <= whiteListEndTime
        ) {
            whiteListRemainAmount = getWhiteListRemainAmount(
                msg.sender,
                whiteListTotalAmount,
                whiteListMerkleProof
            );
        }
        if (whiteListRemainAmount == 0) {
            require(
                block.timestamp >= publicStartTime,
                "public mint not started"
            );
            _publicMint(amount, channel);
            _refundIfOver(amount * publicPrice);
        } else {
            if (amount <= whiteListRemainAmount) {
                _whiteListMint(amount, channel);
                _refundIfOver(amount * whiteListPrice);
            } else {
                uint256 publicAmount = amount - whiteListRemainAmount;
                uint256 publicTotalPrice = publicAmount * publicPrice;
                uint256 whiteListTotalPrice = whiteListRemainAmount *
                    whiteListPrice;
                _publicMint(publicAmount, channel);
                _whiteListMint(whiteListRemainAmount, channel);
                _refundIfOver(publicTotalPrice + whiteListTotalPrice);
            }
        }
        emit Mint(msg.sender, amount, channel);
    }

    function getWhiteListRemainAmount(
        address user,
        uint256 totalAmount,
        bytes32[] calldata merkleProof
    ) public view returns (uint256) {
        if (totalAmount == 0) return 0;
        uint256 mintedAmount = _getAux(user);
        require(
            totalAmount >= mintedAmount &&
                MerkleProof.verify(
                    merkleProof,
                    whiteListMerkleRoot,
                    keccak256(abi.encodePacked(user, ":", totalAmount))
                ),
            "verify fail"
        );
        return totalAmount - mintedAmount;
    }

    function _publicMint(uint256 amount, string calldata channel) private {
        publicMintedAmount += amount;
        _setMintData(amount, publicPrice, channel);
        _safeMint(msg.sender, amount);
        emit PublicMint(msg.sender, amount, publicPrice, channel);
    }

    function _whiteListMint(uint256 amount, string calldata channel) private {
        publicMintedAmount += amount;
        whiteListMintedAmount += amount;
        _setAux(msg.sender, _getAux(msg.sender) + uint64(amount));
        _setMintData(amount, whiteListPrice, channel);
        _safeMint(msg.sender, amount);
        emit WhiteListMint(msg.sender, amount, whiteListPrice, channel);
    }

    function _setMintData(
        uint256 amount,
        uint256 price,
        string calldata channel
    ) private {
        uint256 index = _currentIndex;
        uint256 endIndex = index + amount;
        uint256 endTime = block.timestamp + refundPeriod;
        do {
            refundPriceMap[index] = price;
            refundEndTimeMap[index] = endTime;
            mintChannelMap[index] = channel;
            index++;
        } while (index != endIndex);
        if (endTime > refundLastEndTime) {
            refundLastEndTime = endTime;
        }
    }

    function refund(uint256[] calldata tokenIds)
        public
        callerIsUser
        nonReentrant
    {
        uint256 refundValue;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(msg.sender == ownerOf(tokenId), "not owner");
            require(
                block.timestamp <= refundEndTimeMap[tokenId],
                "refund expired"
            );
            transferFrom(msg.sender, refundAddress, tokenId);
            refundValue += refundPriceMap[tokenId];
        }
        refundedAmount += tokenIds.length;
        payable(msg.sender).transfer(refundValue);
        emit Refund(msg.sender, refundValue, tokenIds);
    }

    function airdrop(address user, uint256 amount) public onlyOwner {
        require(
            reservedMintedAmount + amount <= reservedAmount,
            "not enough amount"
        );
        reservedMintedAmount += amount;
        _safeMint(user, amount);
    }

    function airdropList(
        address[] calldata userList,
        uint256[] calldata amountList
    ) public onlyOwner {
        require(userList.length == amountList.length, "invalid");
        for (uint256 i = 0; i < userList.length; i++) {
            airdrop(userList[i], amountList[i]);
        }
    }

    // probably nothing

    bool public burnable = false;

    function setBurnable(bool burnable_) public onlyOwner {
        burnable = burnable_;
    }

    function burn(uint256[] calldata tokenIds) public callerIsUser {
        require(burnable, "not burnable");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(msg.sender == ownerOf(tokenId), "not owner");
            _burn(tokenId);
        }
        emit Burn(msg.sender, tokenIds);
    }

    // pausable

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfers(from, to, startTokenId, amount);
        require(!paused(), "paused");
    }

    // other

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "not user");
        _;
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function numberMinted(address user) public view returns (uint256) {
        return _numberMinted(user);
    }

    function numberBurned(address user) public view returns (uint256) {
        return _numberBurned(user);
    }

    function withdraw() public onlyOwner nonReentrant {
        require(block.timestamp >= refundLastEndTime, "refund not end");
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "fail");
    }

    function _refundIfOver(uint256 price) private {
        require(msg.value >= price, "not enough ETH");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    event PublicMint(
        address user,
        uint256 amount,
        uint256 price,
        string channel
    );
    event WhiteListMint(
        address user,
        uint256 amount,
        uint256 price,
        string channel
    );
    event Mint(address user, uint256 amount, string channel);
    event Refund(address user, uint256 value, uint256[] tokenIds);
    event Burn(address user, uint256[] tokenIds);
}