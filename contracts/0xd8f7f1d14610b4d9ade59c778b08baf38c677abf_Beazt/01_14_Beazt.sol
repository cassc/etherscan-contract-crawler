// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Beazt is Ownable, EIP712, ERC721A {
    uint256 public TOTAL_SUPPLY = 4500;
    uint256 public MAX_QTY_PER_MINTER = 1;
    string private _tokenBaseURI;
    uint256 public privateSalesStartTime;
    uint256 public privateSalesEndTime;
    uint256 public publicSalesStartTime;
    bool public canTrain = false;
    uint256 public trainDurations = 432000; // 5 days * 24 hours * 60 mins * 60 sec
    mapping(address => uint256) public privateSalesMinterToTokenQty;
    mapping(address => uint256) public publicSalesMinterToTokenQty;
    mapping(uint256 => bool) public isTraining;
    mapping(uint256 => uint256) public startTrainTime;
    mapping(uint256 => bool) public isBeazt;

    bytes32 public constant WHITELIST_TYPEHASH =
        keccak256("Whitelist(address buyer,uint256 signedQty,uint256 nonce)");
    bytes32 public constant HUMAN_TYPEHASH =
        keccak256("Human(uint256 tokenId,bool isHuman)");
    address public whitelistSigner;

    modifier isPrivateSalesActive() {
        require(isPrivateSalesActivated(), "XPRIVATE");
        _;
    }

    modifier isPublicSalesActive() {
        require(isPublicSalesActivated(), "XPUBLIC");
        _;
    }

    modifier isSenderWhitelisted(
        uint256 _signedQty,
        uint256 _nonce,
        bytes memory _signature
    ) {
        require(
            getSigner(msg.sender, _signedQty, _nonce, _signature) ==
                whitelistSigner,
            "XWLIST"
        );
        _;
    }

    modifier onlyHuman(uint256 _tokenId, bytes memory _signature) {
        require(
            getSigner2(_tokenId, true, _signature) == whitelistSigner,
            "XHUMAN"
        );
        _;
    }

    constructor() ERC721A("Beazt", "BEAZT") EIP712("BEAZT", "1") {}

    function isPrivateSalesActivated() public view returns (bool) {
        return
            privateSalesStartTime > 0 &&
            privateSalesEndTime > 0 &&
            block.timestamp >= privateSalesStartTime &&
            block.timestamp <= privateSalesEndTime;
    }

    function isPublicSalesActivated() public view returns (bool) {
        return
            publicSalesStartTime > 0 && block.timestamp >= publicSalesStartTime;
    }

    function PRICE() public view returns (uint256) {
        if (isPublicSalesActivated()) return 0.0097 ether;
        return 0.0079 ether;
    }

    function privateSalesMint(
        uint256 _signedQty,
        uint256 _nonce,
        bytes memory _signature
    )
        external
        payable
        isPrivateSalesActive
        isSenderWhitelisted(_signedQty, _nonce, _signature)
    {
        require(totalSupply() < TOTAL_SUPPLY, ">LMT");
        require(privateSalesMinterToTokenQty[msg.sender] == 0, ">QTY");
        require(msg.value == PRICE(), "<$");
        privateSalesMinterToTokenQty[msg.sender] += 1;
        _safeMint(msg.sender, 1);
    }

    function publicSalesMint() external payable isPublicSalesActive {
        require(totalSupply() < TOTAL_SUPPLY, ">LMT");
        require(
            publicSalesMinterToTokenQty[msg.sender] + 1 <= MAX_QTY_PER_MINTER,
            ">QTY"
        );
        require(msg.value == PRICE(), "<$");
        publicSalesMinterToTokenQty[msg.sender] += 1;
        _safeMint(msg.sender, 1);
    }

    function gift(address[] calldata receivers) external onlyOwner {
        require(totalSupply() + receivers.length <= TOTAL_SUPPLY, ">LMT");

        for (uint256 i = 0; i < receivers.length; i++) {
            _safeMint(receivers[i], 1);
        }
    }

    function train(uint256 _tokenId, bytes memory _signature)
        external
        onlyHuman(_tokenId, _signature)
    {
        require(canTrain, "XSTART");
        require(ownerOf(_tokenId) == msg.sender, "XOWN");
        require(!isTraining[_tokenId], "ISTRAIN");
        require(!isBeazt[_tokenId], "ISBEAZT");
        isTraining[_tokenId] = true;
        startTrainTime[_tokenId] = block.timestamp;
    }

    function makeMeBeazt(uint256 _tokenId) external {
        require(ownerOf(_tokenId) == msg.sender, "XOWN");
        require(isTraining[_tokenId], "XTRAIN");
        require(
            startTrainTime[_tokenId] + trainDurations < block.timestamp,
            "XSTRONG"
        );
        isTraining[_tokenId] = false;
        isBeazt[_tokenId] = true;
    }

    function setPrivateSalesTime(uint256 _startTime, uint256 _endTime)
        external
        onlyOwner
    {
        require(_endTime >= _startTime, "TORDER");
        privateSalesStartTime = _startTime;
        privateSalesEndTime = _endTime;
    }

    function setPublicSalesTime(uint256 _startTime) external onlyOwner {
        publicSalesStartTime = _startTime;
    }

    function setTrainDurations(uint256 timeInSec) external onlyOwner {
        trainDurations = timeInSec;
    }

    function setCanTrain(bool _canTrain) external onlyOwner {
        canTrain = _canTrain;
    }

    function setWhitelistSigner(address _address) external onlyOwner {
        whitelistSigner = _address;
    }

    function getSigner(
        address _buyer,
        uint256 _signedQty,
        uint256 _nonce,
        bytes memory _signature
    ) public view returns (address) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(WHITELIST_TYPEHASH, _buyer, _signedQty, _nonce)
            )
        );
        return ECDSA.recover(digest, _signature);
    }

    function getSigner2(
        uint256 _tokenId,
        bool _isHuman,
        bytes memory _signature
    ) public view returns (address) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(HUMAN_TYPEHASH, _tokenId, _isHuman))
        );
        return ECDSA.recover(digest, _signature);
    }

    function withdrawAll() external onlyOwner {
        require(address(this).balance > 0, "ZERO");
        payable(msg.sender).transfer(address(this).balance);
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    function _startTokenId() internal pure override(ERC721A) returns (uint256) {
        return 1;
    }

    function _baseURI()
        internal
        view
        override(ERC721A)
        returns (string memory)
    {
        return _tokenBaseURI;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override(ERC721A) {
        require(!isTraining[startTokenId], "ISTRAIN");
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }
}