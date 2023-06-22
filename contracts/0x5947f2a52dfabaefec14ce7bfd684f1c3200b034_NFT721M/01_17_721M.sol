// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import {DefaultOperatorFilterer} from "./OperatorFilterRegistry/DefaultOperatorFilterer.sol";
import {MembershipPoints} from "./Membership/MembershipPoints.sol";

contract NFT721M is ERC721A, DefaultOperatorFilterer, AccessControl, Pausable, MembershipPoints, Ownable {
    using SafeMath for uint256;
    bytes32 public constant MODIFY_ROLE = keccak256("MODIFY_ROLE");
    address public signer;
    string public baseUri;
    uint256 public maxCount;
    uint256 public individualWhiteListMintLimit;
    uint256 public individualPublicMintLimit;
    uint256 public whiteListMintPrice;
    uint256 public publicMintPrice;
    bool whiteListMintAvailable = false;
    bool publicMintAvailable = false;
    mapping(address => uint256) internal whiteListMintCountMap;
    mapping(address => uint256) internal publicMintCountMap;
    mapping(string => bool) internal nonceMap;
    mapping(uint256 => uint256) internal stakeMap;

    constructor() ERC721A("Foundo Pass", "FOUNDO PASS") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

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

    function setWhiteListMintAvailable(bool _whiteListMintAvailable) public onlyOwner {
        whiteListMintAvailable = _whiteListMintAvailable;
    }

    function setPublicMintAvailable(bool _publicMintAvailable) public onlyOwner {
        publicMintAvailable = _publicMintAvailable;
    }

    function setWhiteListMintPrice(uint256 _whiteListMintPrice) public onlyOwner {
        whiteListMintPrice = _whiteListMintPrice;
    }

    function setPublicMintPrice(uint256 _publicMintPrice) public onlyOwner {
        publicMintPrice = _publicMintPrice;
    }

    function setIndividualWhiteListMintLimit(uint256 _individualWhiteListMintLimit) public onlyOwner {
        individualWhiteListMintLimit = _individualWhiteListMintLimit;
    }

    function setIndividualPublicMintLimit(uint256 _individualPublicMintLimit) public onlyOwner {
        individualPublicMintLimit = _individualPublicMintLimit;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
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

    function modifyMembershipPoints(uint256 passId, int256 amount) public onlyRole(MODIFY_ROLE) whenNotPaused {
        _modifyMembershipPoints(passId, amount, ownerOf(passId));
    }

    function claimMembershipPoints(
        uint256 passId,
        int256 amount,
        bytes32 hash,
        bytes memory signature,
        uint256 blockHeight,
        string memory nonce
    ) public verifyBlock(blockHeight) verifyNonce(nonce) verifySigner(hash, signature) whenNotPaused {
        require(claimMembershipPointsHash(passId, amount, blockHeight, nonce, "claim_foundo_membership_points") == hash, "Invalid hash!");
        address ownerNow = ownerOf(passId);
        require(ownerNow == msg.sender, "Invalid pass owner!");
        _modifyMembershipPoints(passId, amount, ownerNow);
        nonceMap[nonce] = true;
    }

    function whiteListMint(
        uint256 quantity,
        bytes32 hash,
        bytes memory signature,
        uint256 blockHeight,
        string memory nonce
    ) external payable verifyNonce(nonce) verifySigner(hash, signature) {
        require(whiteListMintAvailable, "White list mint not available!");
        uint256 startId = _nextTokenId();
        require(
            startId + quantity <= maxCount,
            "Not enough stock!"
        );
        require(
            whiteListMintCountMap[msg.sender] + quantity <= individualWhiteListMintLimit,
            "You have reached individual white list mint limit!"
        );
        require(whiteListMintHash(quantity, blockHeight, nonce, "foundo_pass_white_list_mint") == hash, "Invalid hash!");
        uint256 totalPrice = quantity.mul(whiteListMintPrice);
        require(msg.value >= totalPrice, "Not enough money!");

        nonceMap[nonce] = true;
        whiteListMintCountMap[msg.sender] = whiteListMintCountMap[msg.sender] + quantity;
        _safeMint(msg.sender, quantity);

        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }

        emit MintSuccess(msg.sender, startId, quantity, totalPrice, nonce, blockHeight);
    }

    function mint(uint256 quantity) external payable {
        require(publicMintAvailable, "Mint not available!");
        uint256 startId = _nextTokenId();
        require(
            startId + quantity <= maxCount,
            "Not enough stock!"
        );
        require(
            publicMintCountMap[msg.sender] + quantity <= individualPublicMintLimit,
            "You have reached individual public mint limit!"
        );

        uint256 totalPrice = quantity.mul(publicMintPrice);
        require(msg.value >= totalPrice, "Not enough money!");

        publicMintCountMap[msg.sender] = publicMintCountMap[msg.sender] + quantity;
        _safeMint(msg.sender, quantity);

        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }

        emit MintSuccess(msg.sender, startId, quantity, totalPrice, "", 0);
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

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) whenNotPaused {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) whenNotPaused {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    payable
    override
    onlyAllowedOperator(from)
    whenNotPaused
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    //******Tool******
    modifier verifyBlock(uint256 blockHeight){
        require(blockHeight > block.number, "block expired!");
        _;
    }

    modifier verifyNonce(string memory nonce){
        require(!nonceMap[nonce], "Nonce already exist!");
        _;
    }

    modifier verifySigner(bytes32 hash, bytes memory signature){
        require(matchAddressSigner(hash, signature), "Invalid signature!");
        _;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual
    override(ERC721A, AccessControl)
    returns (bool) {
        return ERC721A.supportsInterface(interfaceId);
    }

    function claimMembershipPointsHash(uint256 passId, int256 amount, uint256 blockHeight, string memory nonce, string memory code)
    private
    view
    returns (bytes32)
    {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encodePacked(msg.sender, passId, amount, blockHeight, nonce, code)
                )
            )
        );
        return hash;
    }

    function whiteListMintHash(uint256 quantity, uint256 blockHeight, string memory nonce, string memory code)
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