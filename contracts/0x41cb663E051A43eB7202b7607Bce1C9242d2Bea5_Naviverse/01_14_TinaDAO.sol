//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma abicoder v2; // required to accept structs as function parameters

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "erc721a/contracts/ERC721A.sol";

/**
 @title Naviverse 
 @author Lee Ting Ting
 */
contract Naviverse is Ownable, ERC721A, EIP712 {
    using Address for address;

    // Stage info (packed)
    struct StageInfo {
        uint8 stageId;
        uint16 maxSupply;
        uint32 startTime;
        uint32 withdrawTime;
        uint32 endTime;
        uint160 mintPrice;
    }
    StageInfo public stageInfo;

    // Maximum limit of tokens that can ever exist
    uint16 private constant MAX_SUPPLY = 8160;

    // Stage ID at public stage
    uint8 private constant PUBLIC_STAGE_ID = 2;

    // The base link that leads to the image / video of the token
    string private baseTokenURI;

    address private devAddr = 0xBefBbc6433aaE7e10DCeDb1656C06a7cDd605FEE;
    address private teamAddr = 0x56C3F826e3A23b6f25976af4f3b96cE2F8265FCf;

    string private _contractURI = "https://gateway.pinata.cloud/ipfs/Qmbfe943wdeD3x4zVxQgiCWmvevtKfEK9FLutc5QMjk3cc";

    struct MinterInfo {
        uint8 stageId;
        uint256 maxMintCount;
    }

    // Stage ID check
    mapping(address => MinterInfo) private _whitelistInfo;

    mapping(address => uint256) public _mintedCounts;

    // voucher for user to redeem
    struct NFTVoucher {
        address redeemer; // specify user to redeem this voucher
        uint8 stageId; // ID to check if voucher has been redeemed
        uint256 amount; // max amount to mint in stage
        uint8 priceIndex; // index of price in stage, 0, 0.19, 0.25, 0.07, 0.125
    }

    // price list
    uint[] prices = [0, 0.19 ether, 0.25 ether, 0.07 ether, 0.125 ether];

    constructor(
        string memory _name,
        string memory _symbol,
        StageInfo memory _initStageInfo,
        string memory _baseTokenURI
    ) ERC721A(_name, _symbol) EIP712(_name, "1") { // version 1
        stageInfo = _initStageInfo;
        baseTokenURI = _baseTokenURI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setNewContractURI(string memory _newURI) external onlyOwner {
        _contractURI = _newURI;
    }

    /// @notice Whitelist mint using the voucher
    function whitelistMint(
        NFTVoucher calldata voucher,
        bytes calldata signature,
        uint256 amount
    ) external payable {
        MinterInfo storage minterInfo = _whitelistInfo[_msgSender()];
        // if haven't redeemed then redeem first
        if (minterInfo.stageId <= stageInfo.stageId) {
            // make sure that the signer is authorized to mint NFTs
            _verify(voucher, signature);
            // check current stage
            require(voucher.stageId == stageInfo.stageId, "Wrong stage");
            // update minter info
            minterInfo.stageId = voucher.stageId;
            minterInfo.maxMintCount = voucher.amount;
        }

        // check time
        require(block.timestamp >= stageInfo.startTime, "Sale not started");
        require(block.timestamp <= stageInfo.endTime || stageInfo.endTime == 0, "Sale already ended");
        // check if enough maxMintCount
        require(amount <= minterInfo.maxMintCount - _mintedCounts[_msgSender()], "Not enough maxMintCount");
        // check if exceed
        require(totalSupply() + amount <= stageInfo.maxSupply, "Exceed stage max supply");
        // check fund
        require(msg.value >= prices[voucher.priceIndex] * amount, "Not enough fund");
        super._safeMint(_msgSender(), amount);
        _mintedCounts[_msgSender()] += amount;
    }

    /// @notice Public mint
    function publicMint(uint256 amount) external payable {
        
        // check time
        require(block.timestamp >= stageInfo.endTime + 24 hours, "Sale not started");
        // check if exceed total supply
        require(totalSupply() + amount <= MAX_SUPPLY, "Exceed total supply");
        // check fund
        require(msg.value >= stageInfo.mintPrice * amount, "Not enough fund to mint NFT");
        // batch mint
        super._safeMint(_msgSender(), amount);
    }

    /// @dev Verify voucher
    function _verify(NFTVoucher calldata voucher, bytes calldata signature) public view {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256("NFTVoucher(address redeemer,uint8 stageId,uint256 amount,uint8 priceIndex)"),
                    _msgSender(),
                    voucher.stageId,
                    voucher.amount,
                    voucher.priceIndex
                )
            )
        );
        require(owner() == ECDSA.recover(digest, signature), "Signature invalid or unauthorized");
    }

    /// @dev Reserve NFT. The contract owner can mint NFTs regardless of the minting start and end time.
    function reserve(address to, uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY, "Exceed total supply");
        super._safeMint(to, amount);
    }

    /// @dev Withdraw. The contract owner can withdraw all ETH from the NFT sale
    function withdraw(uint256 percent) external {
        require(block.timestamp >= stageInfo.withdrawTime, "Withdraw not started");
        uint256 fullAmount = address(this).balance * percent / 100;
        uint256 devFee = fullAmount * 5 / 100;
        Address.sendValue(payable(devAddr), devFee);
        Address.sendValue(payable(teamAddr), fullAmount - devFee);
    }

    function setDevAddress(address _newAddr) external onlyOwner {
        devAddr = _newAddr;
    }

    function setTeamAddress(address _newAddr) external onlyOwner {
        teamAddr = _newAddr;
    }

    /// @dev Set new baseURI
    function setBaseURI(string memory baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    /// @dev override _baseURI()
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }
}