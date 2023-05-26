// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {DefaultOperatorFilterer} from "./OperatorFilterRegistry/DefaultOperatorFilterer.sol";

contract NFT721A is ERC721A, DefaultOperatorFilterer, Ownable {
    using SafeMath for uint256;
    address public signer;
    string public baseUri;
    uint256 public reserveCount = 0;
    uint256 public maxCount = 5000;
    bool whiteListReserveAvailable = false;
    bool waitListReserveAvailable = false;
    bool publicReserveAvailable = false;
    bool claimAvailable = false;
    uint256 public whiteListReservePrice = 20000000000000000;
    uint256 public normalReservePrice = 30000000000000000;
    uint256 public individualReserveLimit = 2;
    mapping(address => uint256) internal reserveCountMap;
    mapping(address => uint256) internal claimCountMap;
    mapping(string => bool) internal nonceMap;
    mapping(uint256 => uint256) internal stakeMap;

    constructor() ERC721A("Producer C", "PRODUCER C") {}

    event ReserveSuccess(address indexed operatorAddress, uint256 quantity, uint256 price, string nonce, uint256 blockHeight);

    event MintSuccess(address indexed operatorAddress, uint256 startId, uint256 quantity, uint256 price, string nonce, uint256 blockHeight);

    event LocalStakeSuccess(address indexed operatorAddress, uint256 tokenId, uint256 blockTimestamp);

    event LocalRedeemSuccess(address indexed operatorAddress, uint256 tokenId, uint256 blockTimestamp);

    //******SET UP******
    function setBaseURI(string memory _newURI) public onlyOwner {
        baseUri = _newURI;
    }

    function setMaxCount(uint256 _maxCount) public onlyOwner {
        maxCount = _maxCount;
    }

    function setSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    function setWhiteListReserveAvailable(bool _whiteListReserveAvailable) public onlyOwner {
        whiteListReserveAvailable = _whiteListReserveAvailable;
    }

    function setWaitListReserveAvailable(bool _waitListReserveAvailable) public onlyOwner {
        waitListReserveAvailable = _waitListReserveAvailable;
    }

    function setPublicReserveAvailable(bool _publicReserveAvailable) public onlyOwner {
        publicReserveAvailable = _publicReserveAvailable;
    }

    function setClaimAvailable(bool _claimAvailable) public onlyOwner {
        claimAvailable = _claimAvailable;
    }

    function setWhiteListReservePrice(uint256 _whiteListReservePrice) public onlyOwner {
        whiteListReservePrice = _whiteListReservePrice;
    }

    function setNormalReservePrice(uint256 _normalReservePrice) public onlyOwner {
        normalReservePrice = _normalReservePrice;
    }

    function setIndividualReserveLimit(uint256 _individualReserveLimit) public onlyOwner {
        individualReserveLimit = _individualReserveLimit;
    }

    //******Functions******
    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    function withdrawAll() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdraw(uint256 amount) public payable onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    function whiteListReserve(
        uint256 quantity,
        bytes32 hash,
        bytes memory signature,
        uint256 blockHeight,
        string memory nonce
    ) external payable {
        require(whiteListReserveAvailable, "White list reserve not available!");
        require(
            reserveCountMap[msg.sender] + quantity <= individualReserveLimit,
            "You have reached individual reserve limit!"
        );
        //require(blockHeight >= block.number, "The block has expired!");
        require(!nonceMap[nonce], "Nonce already exist!");
        require(hashReserve(quantity, blockHeight, nonce, "producer_c_white_list_reserve") == hash, "Invalid hash!");
        require(matchAddressSigner(hash, signature), "Invalid signature!");
        uint256 totalPrice = quantity.mul(whiteListReservePrice);
        require(msg.value >= totalPrice, "Not enough money!");
        require(
            reserveCount + quantity <= maxCount,
            "Not enough stock!"
        );

        nonceMap[nonce] = true;
        reserveCount = reserveCount + quantity;
        reserveCountMap[msg.sender] = reserveCountMap[msg.sender] + quantity;

        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }

        emit ReserveSuccess(msg.sender, quantity, totalPrice, nonce, blockHeight);
    }

    function waitListReserve(
        uint256 quantity,
        bytes32 hash,
        bytes memory signature,
        uint256 blockHeight,
        string memory nonce
    ) external payable {
        require(waitListReserveAvailable, "Wait list reserve not available!");
        require(
            reserveCountMap[msg.sender] + quantity <= individualReserveLimit,
            "You have reached individual reserve limit!"
        );
        //require(blockHeight >= block.number, "The block has expired!");
        require(!nonceMap[nonce], "Nonce already exist!");
        require(hashReserve(quantity, blockHeight, nonce, "producer_c_wait_list_reserve") == hash, "Invalid hash!");
        require(matchAddressSigner(hash, signature), "Invalid signature!");
        uint256 totalPrice = quantity.mul(normalReservePrice);
        require(msg.value >= totalPrice, "Not enough money!");
        require(
            reserveCount + quantity <= maxCount,
            "Not enough stock!"
        );

        nonceMap[nonce] = true;
        reserveCount = reserveCount + quantity;
        reserveCountMap[msg.sender] = reserveCountMap[msg.sender] + quantity;

        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }

        emit ReserveSuccess(msg.sender, quantity, totalPrice, nonce, blockHeight);
    }

    function reserve(uint256 quantity) external payable {
        require(publicReserveAvailable, "Reserve not available!");
        require(
            reserveCountMap[msg.sender] + quantity <= individualReserveLimit,
            "You have reached individual reserve limit!"
        );
        uint256 totalPrice = quantity.mul(normalReservePrice);
        require(msg.value >= totalPrice, "Not enough money!");
        require(
            reserveCount + quantity <= maxCount,
            "Not enough stock!"
        );

        reserveCount = reserveCount + quantity;
        reserveCountMap[msg.sender] = reserveCountMap[msg.sender] + quantity;

        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }

        emit ReserveSuccess(msg.sender, quantity, totalPrice, "", 0);
    }

    function checkReservedQuantity(address walletAddress) public view returns (uint256)  {
        return reserveCountMap[walletAddress];
    }

    function checkClaimedQuantity(address walletAddress) public view returns (uint256)  {
        return claimCountMap[walletAddress];
    }

    function claim(uint256 quantity) external {
        require(claimAvailable, "Claim not available!");
        uint256 startId = _nextTokenId();
        require(
            startId + quantity <= maxCount,
            "Not enough stock!"
        );
        require(
            claimCountMap[msg.sender] + quantity <= reserveCountMap[msg.sender] && claimCountMap[msg.sender] + quantity <= individualReserveLimit,
            "You had not reserved enough producer c!"
        );

        claimCountMap[msg.sender] = claimCountMap[msg.sender] + quantity;
        _safeMint(msg.sender, quantity);

        emit MintSuccess(msg.sender, startId, quantity, 0, "", 0);
    }

    function airdrop(address to, uint256 quantity) public onlyOwner {
        require(
            _nextTokenId() + quantity <= maxCount,
            "The quantity exceeds the stock!"
        );
        _safeMint(to, quantity);
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId, true);
    }

    function checkLocalStakeStatus(uint256 tokenId) public view returns (uint256)  {
        return stakeMap[tokenId];
    }

    function localStake(uint256[] memory tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(ownerOf(tokenId) == msg.sender, "Caller is not owner!");

            if (stakeMap[tokenId] == 0) {
                stakeMap[tokenId] = block.timestamp;
                emit LocalStakeSuccess(msg.sender, tokenId, block.timestamp);
            }
        }
    }

    function localRedeem(uint256[] memory tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(ownerOf(tokenId) == msg.sender, "Caller is not owner!");

            if (stakeMap[tokenId] > 0) {
                stakeMap[tokenId] = 0;
                emit LocalRedeemSuccess(msg.sender, tokenId, block.timestamp);
            }
        }
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override
    {
        require(stakeMap[startTokenId] == 0, "This token is staking!");
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    //******OperatorFilterer******
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    payable
    override
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    //******Tool******
    function hashReserve(uint256 quantity, uint256 blockHeight, string memory nonce, string memory code)
    private
    view
    returns (bytes32)
    {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encodePacked(msg.sender, quantity, blockHeight, nonce, code)
                )
            )
        );
        return hash;
    }

    function matchAddressSigner(bytes32 hash, bytes memory signature)
    internal
    view
    returns (bool)
    {
        return signer == recoverSigner(hash, signature);
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) internal pure returns (address){
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
    internal
    pure
    returns (
        bytes32 r,
        bytes32 s,
        uint8 v
    )
    {
        require(sig.length == 65, "Invalid signature length!");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}