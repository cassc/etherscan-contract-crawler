//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2; // required to accept structs as function parameters

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "./ERC721A.sol";

//////////////////////////////////////////////////////
//                                                  //
// We are Blackchain.                               //
// [email protected]                         //
//                                                  //
//////////////////////////////////////////////////////

/**
 @title Renaissance Art NFT 
 @author Jeffrey Lin, Justa Liang
 */
contract RenArt is ERC721A, Ownable, EIP712, PaymentSplitter {
    using Address for address;

    // Stage info (packed)
    struct StageInfo {
        bool publicStage;
        uint8 stageId;
        uint16 maxSupply;
        uint32 startTime;
        uint32 endTime;
        uint160 mintPrice;
    }
    StageInfo public stageInfo;

    // Maximum limit of tokens that can ever exist
    uint16 constant MAX_SUPPLY = 9500;

    // Maximum reserve
    uint16 constant MAX_RESERVE = 500;

    // Reserved
    uint256 private _reservedCount;

    // Maximum limit of mint amount per time in public stage
    uint8 constant MAX_MINT_PER_TIME = 2;

    // The base link that leads to the image / video of the token
    string private _baseTokenURI;

    struct MinterInfo {
        uint8 nonce;
        uint8 stageId;
        uint240 remain;
    }
    // Stage ID check
    mapping(address => MinterInfo) public whitelistInfo;

    // voucher for user to redeem
    struct NFTVoucher {
        address redeemer; // specify user to redeem this voucher
        uint8 stageId; // ID to check if voucher has been redeemed
        uint8 amount; // max amount to mint in stage
        uint8 nonce; // nonce to make different voucher
        uint72 price; // mint price
    }

    /// @dev Setup ERC721A, EIP712 and first stage info
    constructor(
        StageInfo memory _initStageInfo,
        string memory _initBaseURI,
        address[] memory payees,
        uint256[] memory shares
    )
        ERC721A("RenArt", "RENA", 5)
        EIP712("RenArt-Voucher", "1")
        PaymentSplitter(payees, shares)
    {
        _baseTokenURI = _initBaseURI;
        stageInfo = _initStageInfo;
        _reservedCount = 0;
    }

    /// @notice Whitelist mint using the voucher
    function whitelistMint(
        NFTVoucher calldata voucher,
        bytes calldata signature,
        uint8 amount
    ) external payable {
        MinterInfo storage minterInfo = whitelistInfo[_msgSender()];
        // make sure voucher is valid
        _verify(voucher, signature);
        // if haven't redeemed then redeem first
        if (voucher.nonce > minterInfo.nonce) {
            // update minter info
            minterInfo.stageId = voucher.stageId;
            minterInfo.remain = voucher.amount;
            minterInfo.nonce = voucher.nonce;
        }
        // check stage
        require(voucher.stageId == stageInfo.stageId, "Wrong stage");
        // check time
        require(block.timestamp >= stageInfo.startTime, "Sale not started");
        require(block.timestamp <= stageInfo.endTime, "Sale already ended");
        // check if enough remain
        require(amount <= minterInfo.remain, "Not enough remain");
        // check if exceed
        require(
            totalSupply() + amount <= stageInfo.maxSupply,
            "Exceed stage max supply"
        );
        // check fund
        require(msg.value >= voucher.price * amount, "Not enough fund");
        super._safeMint(_msgSender(), amount);
        minterInfo.remain -= amount;
    }

    /// @notice Public mint
    function publicMint(uint8 amount) external payable {
        // check public mint stage
        require(stageInfo.publicStage, "Public mint not started");
        // check time
        require(block.timestamp >= stageInfo.startTime, "Sale not started");
        require(block.timestamp <= stageInfo.endTime, "Sale already ended");
        // check if exceed max per time
        require(amount <= MAX_MINT_PER_TIME, "Exceed max mint amount");
        // check if exceed total supply
        require(totalSupply() + amount <= MAX_SUPPLY, "Exceed total supply");
        // check fund
        require(msg.value >= stageInfo.mintPrice * amount, "Not enough fund");
        // batch mint
        super._safeMint(_msgSender(), amount);
    }

    /// @dev Verify voucher
    function _verify(NFTVoucher calldata voucher, bytes calldata signature)
        private
        view
    {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "NFTVoucher(address redeemer,uint8 stageId,uint8 amount,uint8 nonce,uint72 price)"
                    ),
                    _msgSender(),
                    voucher.stageId,
                    voucher.amount,
                    voucher.nonce,
                    voucher.price
                )
            )
        );
        require(
            owner() == ECDSA.recover(digest, signature),
            "invalid or unauthorized"
        );
    }

    /// @dev Reserve NFT
    function reserve(address to, uint256 amount) external onlyOwner {
        require(_reservedCount + amount <= MAX_RESERVE, "Exceed reserve max");
        super._safeMint(to, amount);
        _reservedCount += amount;
    }

    /// @dev Go to next stage
    function nextStage(StageInfo memory _stageInfo) external onlyOwner {
        require(
            _stageInfo.stageId >= stageInfo.stageId,
            "Cannot set to previous stage"
        );
        require(_stageInfo.maxSupply <= MAX_SUPPLY, "Set exceed max supply");
        require(_stageInfo.stageId <= 3, "Can only have three stage");
        stageInfo = _stageInfo;
    }

    /// @dev Set new baseURI
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    /// @dev override _baseURI()
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
}