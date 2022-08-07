// SPDX-License-Identifier: MIT
// Creator: twitter.com/runo_dev
// ERC-1155 Based NFT Contract

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Chromaspective is ERC1155, Ownable, ERC2981 {
    address private validator;
    address public _dev = 0x4E309329764DFb001d52c08FAe14e46a745Df506;

    mapping(uint256 => mapping(address => uint256)) public purchases;
    mapping(uint256 => mapping(address => uint256)) public claims;
    mapping(uint256 => uint256) public claimCounts;
    mapping(uint256 => uint256) public currentSupply;
    mapping(uint256 => uint256) public supplyLimit;
    mapping(uint256 => uint256) public claimLimit;
    mapping(uint256 => uint256) public purchaseLimitPerAcc;
    mapping(uint256 => uint256) public claimLimitPerAcc;
    mapping(uint256 => uint256) public purchasePrices;
    mapping(uint256 => uint256) public claimPrices;
    mapping(uint256 => string) public tokenURIs;
    uint256 public currentMintingId;
    bool public saleIsActive;
    bool public claimIsActive;

    constructor(address _validator) ERC1155("") {
        currentMintingId = 1;
        validator = _validator;
        tokenURIs[
            1
        ] = "https://ipfs.io/ipfs/QmdbSY7BvPbLxGELAKUG79Dq1q22yxuzzHqQMd7xj4v5zi";
        supplyLimit[1] = 31;
        claimLimit[1] = 1;
        claimLimitPerAcc[1] = 1;
        purchasePrices[1] = 31 * 10**16; // 0.31 ether
        _setDefaultRoyalty(msg.sender, 1000);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier onlyAdmins() {
        require(
            tx.origin == _dev || tx.origin == owner(),
            "The caller is not owner or admin"
        );
        _;
    }

    modifier verify(address _buyer, bytes memory _sign) {
        require(_sign.length == 65, "Invalid signature length");

        bytes memory addressBytes = toBytes(_buyer);

        bytes32 _hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked("selaykarasu", addressBytes))
            )
        );

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(_sign, 32))
            s := mload(add(_sign, 64))
            v := byte(0, mload(add(_sign, 96)))
        }

        require(ecrecover(_hash, v, r, s) == validator, "Invalid sign");
        _;
    }

    function claim(bytes memory sign)
        external
        payable
        callerIsUser
        verify(msg.sender, sign)
    {
        uint256 amount = 1;
        require(claimIsActive, "Claim is not active.");
        require(
            msg.value >= claimPrices[currentMintingId] * amount,
            "Insufficient payment."
        );
        require(
            supplyLimit[currentMintingId] == 0 ||
                currentSupply[currentMintingId] + amount <=
                supplyLimit[currentMintingId],
            "Limit reached."
        );
        require(
            claimLimit[currentMintingId] == 0 ||
                claimCounts[currentMintingId] + amount <=
                claimLimit[currentMintingId],
            "Claim limit reached."
        );
        require(
            claimLimitPerAcc[currentMintingId] == 0 ||
                claims[currentMintingId][msg.sender] + amount <=
                claimLimitPerAcc[currentMintingId],
            "Limit per account reached."
        );
        currentSupply[currentMintingId] =
            currentSupply[currentMintingId] +
            amount;
        claims[currentMintingId][msg.sender] =
            claims[currentMintingId][msg.sender] +
            amount;
        claimCounts[currentMintingId] += amount;

        _mint(msg.sender, currentMintingId, amount, "");
    }

    function purchase(uint256 amount) external payable callerIsUser {
        require(saleIsActive, "Sale is not active.");
        require(
            msg.value >= purchasePrices[currentMintingId] * amount,
            "Insufficient payment."
        );
        require(
            supplyLimit[currentMintingId] == 0 ||
                currentSupply[currentMintingId] + amount <=
                supplyLimit[currentMintingId] - claimCounts[currentMintingId],
            "Limit reached."
        );
        require(
            purchaseLimitPerAcc[currentMintingId] == 0 ||
                purchases[currentMintingId][msg.sender] + amount <=
                purchaseLimitPerAcc[currentMintingId],
            "Limit per account reached."
        );
        currentSupply[currentMintingId] =
            currentSupply[currentMintingId] +
            amount;
        purchases[currentMintingId][msg.sender] =
            purchases[currentMintingId][msg.sender] +
            amount;

        _mint(msg.sender, currentMintingId, amount, "");
    }

    function mintToAddress(
        address to,
        uint256 amount,
        uint256 tokenId
    ) public onlyAdmins {
        require(
            supplyLimit[tokenId] == 0 ||
                currentSupply[tokenId] + amount <= supplyLimit[tokenId],
            "Limit reached."
        );
        currentSupply[tokenId] = currentSupply[tokenId] + amount;
        _mint(to, tokenId, amount, "");
    }

    // getters
    function isAccClaimedAll(uint256 tokenId, address account)
        external
        view
        returns (bool)
    {
        return claims[tokenId][account] >= claimLimitPerAcc[tokenId];
    }

    // setters
    function toggleSaleStatus() external onlyAdmins {
        saleIsActive = !saleIsActive;
    }

    function toggleClaimStatus() external onlyAdmins {
        claimIsActive = !claimIsActive;
    }

    function setCurrentMintingId(uint256 id) external onlyAdmins {
        currentMintingId = id;
    }

    function setValidator(address _validator) external onlyAdmins {
        validator = _validator;
    }

    function setTokenURI(uint256 tokenId, string calldata newUri)
        external
        onlyAdmins
    {
        tokenURIs[tokenId] = newUri;
    }

    /**
     * setting limits 0 means unlimited.
     * setting prices 0 means free.
     */
    function setSupply(uint256 tokenId, uint256 newSupply) external onlyAdmins {
        require(
            newSupply == 0 || currentSupply[tokenId] <= newSupply,
            "Supply should exceed current supply"
        );
        supplyLimit[tokenId] = newSupply;
    }

    function setClaimLimit(uint256 tokenId, uint256 newLimit)
        external
        onlyAdmins
    {
        require(
            claimCounts[tokenId] <= newLimit,
            "Limit should exceed current claim counts"
        );
        claimLimit[tokenId] = newLimit;
    }

    function setLimitsPerAcc(
        uint256 tokenId,
        uint256 _purchase,
        uint256 _claim
    ) external onlyAdmins {
        purchaseLimitPerAcc[tokenId] = _purchase;
        claimLimitPerAcc[tokenId] = _claim;
    }

    function setPrices(
        uint256 tokenId,
        uint256 _claimPrice,
        uint256 _purchasePrice
    ) external onlyAdmins {
        purchasePrices[tokenId] = _purchasePrice;
        claimPrices[tokenId] = _claimPrice;
    }

    function withdrawFunds() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setDev(address account) external onlyOwner {
        _dev = account;
    }

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBps)
        external
        onlyOwner
    {
        _setDefaultRoyalty(_receiver, _royaltyFeesInBps);
    }

    // overrides
    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return tokenURIs[tokenId];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    //utils
    function toBytes(address a) internal pure returns (bytes memory b) {
        assembly {
            let m := mload(0x40)
            a := and(a, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            mstore(
                add(m, 20),
                xor(0x140000000000000000000000000000000000000000, a)
            )
            mstore(0x40, add(m, 52))
            b := m
        }
    }
}