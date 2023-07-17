// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ERC721Tradable.sol";
import "./Bisect.sol";

interface ICurrencyPunks {
    function balanceOf(address owner) external returns (uint256);
}

contract MalevichPunks is ERC721Tradable, Bisect {
    using SafeMath for uint256;

    uint256 constant BLACK_SQUARE_ID = 741;
    uint256 constant BLACK_SQUARE_INDEX = 1115;

    uint256 constant MAX_SUPPLY = 10000;
    uint256 constant BIG_TREE = 8192;
    uint256 constant MEDIUM_TREE = 1024;
    uint256 constant SMALL_TREE = 512;
    uint256 constant SMALLEST_TREE = 256;

    uint256 constant HOLDERS_MINTING_PERIOD = 3 days;

    uint256 constant HOLDERS_CAP = 2000;
    uint256 constant FIRST_DROP_CAP = 750;
    uint256 constant SECOND_DROP_CAP = 650;
    uint256 constant THIRD_DROP_CAP = 600;
    uint256 constant LUCKYLIST_CAP = 1500;

    uint256 constant AUCTION_DURATION = 12 hours;
    uint256 constant AUCTION_PRICE = 0.05 ether;

    uint8 constant MAX_MINT_STAGES = 6;

    uint8 constant STAGE_HOLDERS = 1;
    uint8 constant STAGE_PUBLIC1 = 2;
    uint8 constant STAGE_PUBLIC2 = 3;
    uint8 constant STAGE_PUBLIC3 = 4;
    uint8 constant STAGE_2PLUS1 = 5;
    uint8 constant STAGE_AUCTION = 6;

    address public fundAddress;
    address public permitter;
    uint256 public immutable epoch;
    address public immutable currencyPunks;

    uint256 public auctionStart;
    uint256 private baseStageSupply = 1;
    uint8 public mintStage;

    bytes32 constant PERMIT_TYPEHASH =
        keccak256(bytes("Permit(address lucky,uint256 nonce)"));

    struct Permit {
        address lucky;
        uint256 nonce;
    }

    mapping(uint256 => bool) isLuckyMinted;

    constructor(
        address currencyPunks_,
        address permitter_,
        address fundAddress_,
        address _proxyRegistryAddress
    ) ERC721Tradable("MalevichPunks", "MAPU", _proxyRegistryAddress) {
        currencyPunks = currencyPunks_;
        permitter = permitter_;
        fundAddress = fundAddress_;

        epoch = _now();

        _safeMint(fundAddress, BLACK_SQUARE_ID);
    }

    function baseTokenURI() public pure override returns (string memory) {
        return "ipfs://QmSXBPcVAbnkczZYpQxk77N6ztDF69jmt1SVhWbf7R5ZSJ/";
    }

    function mint() public payable {
        require(_getTotalSupply() < MAX_SUPPLY, "max supply reached");

        if (mintStage == STAGE_HOLDERS) {
            require(
                _getTotalSupply() - baseStageSupply < HOLDERS_CAP,
                "limit reached"
            );
            require(
                _now() - epoch <= HOLDERS_MINTING_PERIOD,
                "holders minting has expired"
            );
            require(
                ICurrencyPunks(currencyPunks).balanceOf(_msgSender()) > 0,
                "current minting stage is for CurrencyPunks holders only"
            );
        } else if (mintStage == STAGE_PUBLIC1) {
            require(
                _getTotalSupply() - baseStageSupply < FIRST_DROP_CAP,
                "limit reached"
            );
        } else if (mintStage == STAGE_PUBLIC2) {
            require(
                _getTotalSupply() - baseStageSupply < SECOND_DROP_CAP,
                "limit reached"
            );
        } else if (mintStage == STAGE_PUBLIC3) {
            require(
                _getTotalSupply() - baseStageSupply < THIRD_DROP_CAP,
                "limit reached"
            );
        } else if (mintStage == STAGE_AUCTION) {
            require(msg.value >= mintPrice(), "amount is too low");
        } else {
            revert("minting is not available at the moment");
        }

        if (mintStage != STAGE_AUCTION) {
            require(
                balanceOf(_msgSender()) == 0,
                "only one token per address allowed"
            );
        }

        require(_msgSender() != owner(), "owner not allowed");
        require(_msgSender() != fundAddress, "fund not allowed");

        _mintTo(_msgSender());
    }

    function mintLucky(
        address lucky,
        uint256 nonce,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public {
        require(
            mintStage == STAGE_2PLUS1,
            "LuckyList minting is not available at the moment"
        );
        require(
            isLuckyMinted[nonce] == false,
            "token has already been claimed"
        );
        require(_getTotalSupply() + 3 <= LUCKYLIST_CAP, "limit reached");
        require(
            balanceOf(_msgSender()) == 0,
            "only one token per address allowed"
        );
        require(_msgSender() != owner(), "owner not allowed");
        require(_msgSender() != fundAddress, "fund not allowed");

        Permit memory permit = Permit({lucky: lucky, nonce: nonce});

        require(
            verifySignature(permitter, _hashPermit(permit), r, s, v),
            "invalid lucky address"
        );

        isLuckyMinted[nonce] = true;

        _mintTo(_msgSender());
        _mintTo(lucky);
        _mintTo(_msgSender());
    }

    function mintPrice() public view returns (uint256) {
        if (mintStage != STAGE_AUCTION) {
            return 0;
        }

        uint256 auctionStage = (_now() - auctionStart) / AUCTION_DURATION;
        (bool _success, uint256 result) = AUCTION_PRICE.trySub(
            auctionStage * 0.01 ether
        );
        return result;
    }

    function nextMintStage() public onlyOwner {
        require(mintStage < MAX_MINT_STAGES, "final mint stage reached");

        baseStageSupply = _getTotalSupply();
        mintStage++;

        if (mintStage == STAGE_AUCTION) {
            auctionStart = _now();
        }
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    //
    //
    //  PRIVATE
    //
    //
    function _hashPermit(Permit memory permit) private pure returns (bytes32) {
        return
            keccak256(abi.encode(PERMIT_TYPEHASH, permit.lucky, permit.nonce));
    }

    function _now() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    function _getTotalSupply() internal view virtual returns (uint256) {
        return totalSupply();
    }

    function _addTreesToTokenId(uint256 tree, uint256 tokenId)
        internal
        pure
        returns (uint256)
    {
        if (tree == MEDIUM_TREE) {
            tokenId += BIG_TREE;
        } else if (tree == SMALL_TREE) {
            tokenId += BIG_TREE + MEDIUM_TREE;
        } else if (tree == SMALLEST_TREE) {
            tokenId += BIG_TREE + MEDIUM_TREE + SMALL_TREE;
        }

        return tokenId + 1;
    }

    function _getNextTokenId() internal view override returns (uint256) {
        uint256 totalSupply = _getTotalSupply();
        uint256 tree;
        uint256 index;

        if (totalSupply < BIG_TREE) {
            tree = BIG_TREE;
            index = totalSupply - 1; // - BLACK SQUARE
        } else if (totalSupply < BIG_TREE + MEDIUM_TREE) {
            tree = MEDIUM_TREE;
            index = totalSupply - BIG_TREE;
        } else if (totalSupply < BIG_TREE + MEDIUM_TREE + SMALL_TREE) {
            tree = SMALL_TREE;
            index = totalSupply - BIG_TREE - MEDIUM_TREE;
        } else if (
            totalSupply < BIG_TREE + MEDIUM_TREE + SMALL_TREE + SMALLEST_TREE
        ) {
            tree = SMALLEST_TREE;
            index = totalSupply - BIG_TREE - MEDIUM_TREE - SMALL_TREE;
        } else if (totalSupply == MAX_SUPPLY) {
            return totalSupply;
        } else {
            return totalSupply + 1;
        }

        if (index >= BLACK_SQUARE_INDEX) {
            index++;
        }

        uint256 tokenId = _getBisectNode(index + 1, tree);
        tokenId = _addTreesToTokenId(tree, tokenId);

        if (tokenId == BLACK_SQUARE_ID) {
            tokenId = _getBisectNode(index + 2, tree);
            tokenId = _addTreesToTokenId(tree, tokenId);
        }

        return tokenId;
    }
}