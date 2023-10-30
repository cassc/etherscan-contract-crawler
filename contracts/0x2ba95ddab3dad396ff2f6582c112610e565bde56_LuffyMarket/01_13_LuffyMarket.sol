// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract LuffyMarket is Ownable, ERC721Holder, ReentrancyGuard {
    event NftMinted(
        address nftAddress,
        uint256 initialTokenId,
        uint256 finalTokenId,
        address owner,
        string uri
    );
    event CollectionCreated(address nftAddress, address owner);

    event NftPutOnSale(
        address indexed owner,
        address indexed nftAddress,
        uint256 tokenId,
        address indexed tokenPayment,
        uint256 price
    );

    event NftSold(
        address owner,
        address nftAddress,
        uint256 tokenId,
        address tokenPayment,
        uint256 price,
        address to
    );

    event NftPutOnAuction(
        address indexed owner,
        address indexed nftAddress,
        uint256 tokenId,
        address indexed tokenPayment,
        uint256 startingPrice,
        uint256 beginAuctionTimestamp
    );

    event AuctionBid(
        address owner,
        address nftAddress,
        uint256 tokenId,
        address tokenPayment,
        address bidder,
        uint256 bidPrice
    );

    event AuctionCompleted(
        address owner,
        address nftAddress,
        uint256 tokenId,
        address tokenPayment,
        address winner,
        uint256 price
    );

    event AuctionCanceled(
        address owner,
        address nftAddress,
        uint256 tokenId,
        address tokenPayment,
        address winner,
        uint256 price
    );

    event ErrorLog(bytes message);

    bytes32 public immutable DOMAIN_SEPARATOR;
    bytes32 public immutable BUY_SALT;

    mapping(address => uint256) public setFee;
    address[] public collectionsCreated;
    string public constant salt = "LUFFY MARKETPLACE";
    address burnAddr = 0x000000000000000000000000000000000000dEaD;

    bool public isValidTokenForPurchase = false;
    address public recoveredAddress;
    uint256 public feeDecimal = 10000;
    uint256 public getFee;
    uint256 public ethFee;
    uint256 public royalFee;
    uint256 public tokenFee;

    IERC20 public token;

    struct Sale {
        address payable owner;
        address tokenPayment;
        uint256 price;
        bool isBurn;
        uint256 burnRate;
        uint256 royalRate;
        address ownerCollection;
        bool isCompleted;
    }
    mapping(address => mapping(uint256 => Sale)) public sales;

    struct Auction {
        address payable owner;
        address tokenPayment;
        uint256 startingPrice;
        uint256 highestBidPrice;
        address highestBidder;
        uint256 beginAuctionTimestamp;
        uint256 endAuctionTimestamp;
        bool isBurn;
        uint256 burnRate;
        uint256 royalRate;
        address ownerCollection;
        bool isCompleted;
    }
    mapping(address => mapping(uint256 => Auction)) public auctions;

    constructor() {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    bytes(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    )
                ),
                keccak256("LUFFY MARKETPLACE"),
                keccak256("1"),
                137,
                address(this)
            )
        );
        BUY_SALT = keccak256(bytes("List(address nftAddress,uint256 tokenID,address from)"));
    }

    function collectionCreated() public {
        require(msg.sender != tx.origin, "Caller origin validation failed");
        collectionsCreated.push(address(msg.sender));
        emit CollectionCreated(msg.sender, tx.origin);
    }

    function nftMinted(uint256 initialTokenId, uint256 finalTokenId, string memory uri) public {
        require(msg.sender != tx.origin, "Caller origin validation failed");
        emit NftMinted(msg.sender, initialTokenId, finalTokenId, tx.origin, uri);
    }

    function applyTokenForPayment(address tokenAddr) public {
        token = IERC20(tokenAddr);
    }

    function putOnFixedPriceSale(
        address nftAddress,
        uint256 tokenId,
        address tokenPayment,
        uint256 price,
        bool isBurn,
        uint256 burnRate,
        uint256 royalRate,
        address ownerCollection
    ) external {
        IERC721 nftInstance = IERC721(nftAddress);
        require(nftInstance.ownerOf(tokenId) == msg.sender, "You do not own this NFT");
        require(burnRate < 10 ** 3, "Invalid burn rate");
        require(royalRate < 10 ** 3, "Invalid royal rate");
        require(ownerCollection != address(0), "Invalid owner collection");

        Sale storage sale = sales[nftAddress][tokenId];
        sale.owner = payable(msg.sender);
        sale.tokenPayment = tokenPayment;
        sale.price = price;
        sale.isBurn = isBurn;
        sale.burnRate = burnRate;
        sale.royalRate = royalRate;
        sale.ownerCollection = ownerCollection;
        sale.isCompleted = false;

        emit NftPutOnSale(msg.sender, nftAddress, tokenId, tokenPayment, price);
    }

    function purchaseWithFixedPrice(
        address nftAddress,
        uint256 tokenId,
        bytes memory signature
    ) public payable nonReentrant {
        Sale memory thisSale = sales[nftAddress][tokenId];

        require(!thisSale.isCompleted, "The NFT has sold");
        IERC721 nftInstance = IERC721(nftAddress);

        bytes32 byte32Message = keccak256(
            abi.encodePacked(
                uint8(0x19),
                uint8(0x01),
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(BUY_SALT, nftAddress, tokenId, thisSale.owner))
            )
        );
        bytes32 message = keccak256(abi.encodePacked(bytes32ToString(byte32Message)));
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(message);
        recoveredAddress = ECDSA.recover(messageHash, signature);

        require(recoveredAddress == thisSale.owner, "Invalid signature");
        require(nftInstance.ownerOf(tokenId) == thisSale.owner, "Wrong owner");
        require(
            nftInstance.getApproved(tokenId) == address(this),
            "Nft is not approved by the owner"
        );
        getFee = setFee[thisSale.tokenPayment];

        if (thisSale.tokenPayment == address(0)) {
            //buy by ETH
            require(msg.value >= thisSale.price, "Insufficient ETH amount");
            ethFee = (msg.value * getFee) / feeDecimal;
            royalFee = (msg.value * thisSale.royalRate) / 10 ** 3;
            if (royalFee > 0) {
                payable(thisSale.ownerCollection).transfer(royalFee);
            }
            payable(thisSale.owner).transfer(msg.value - royalFee - ethFee); //keep ethFee in marketplace
        } else {
            //buy by token
            applyTokenForPayment(thisSale.tokenPayment);
            require(token.balanceOf(msg.sender) >= thisSale.price, "Insufficient token balance");
            require(
                token.allowance(msg.sender, address(this)) >= thisSale.price,
                "Insufficient token allowance"
            );

            if (thisSale.isBurn == true) {
                uint256 burnFee = (thisSale.price * thisSale.burnRate) / 10 ** 3;
                royalFee = (thisSale.price * thisSale.royalRate) / 10 ** 3;
                if (royalFee > 0) {
                    require(
                        token.transferFrom(msg.sender, thisSale.ownerCollection, royalFee),
                        "Transfer royalty amount fail"
                    );
                }
                if (burnFee > 0) {
                    require(
                        token.transferFrom(msg.sender, burnAddr, burnFee),
                        "Transfer burn amount fail"
                    );
                }
                require(
                    token.transferFrom(
                        msg.sender,
                        thisSale.owner,
                        (thisSale.price - royalFee - burnFee)
                    ),
                    "Transfer token to owner fail"
                );
            } else {
                getFee = setFee[thisSale.tokenPayment];
                tokenFee = (thisSale.price * getFee) / feeDecimal;
                royalFee = (thisSale.price * thisSale.royalRate) / 10 ** 3;
                if (tokenFee > 0) {
                    require(
                        token.transferFrom(msg.sender, address(this), tokenFee),
                        "Transfer fee amount fail"
                    );
                }
                if (royalFee > 0) {
                    require(
                        token.transferFrom(msg.sender, thisSale.ownerCollection, royalFee),
                        "Transfer royalty amount fail"
                    );
                }
                require(
                    token.transferFrom(
                        msg.sender,
                        thisSale.owner,
                        (thisSale.price - tokenFee - royalFee)
                    ),
                    "Transfer token to owner fail"
                );
            }
        }
        try nftInstance.safeTransferFrom(thisSale.owner, msg.sender, tokenId) {} catch (
            bytes memory _error
        ) {
            emit ErrorLog(_error);
            revert("BUY FAIL");
        }
        sales[nftAddress][tokenId].isCompleted = true;
        emit NftSold(
            thisSale.owner,
            nftAddress,
            tokenId,
            thisSale.tokenPayment,
            thisSale.price,
            msg.sender
        );
    }

    function putOnAuction(
        address nftAddress,
        uint256 tokenId,
        address tokenPayment,
        uint256 startingPrice,
        uint256 beginAuctionTimestamp,
        uint256 endAuctionTimestamp,
        bool isBurn,
        uint256 burnRate,
        uint256 royalRate,
        address ownerCollection
    ) public {
        require(
            IERC721(nftAddress).ownerOf(tokenId) == msg.sender,
            "Only the token owner can put it on auction"
        );
        require(
            IERC721(nftAddress).getApproved(tokenId) == address(this),
            "Nft is not approved by the owner"
        );
        require(ownerCollection != address(0), "Invalid owner collection");
        try IERC721(nftAddress).transferFrom(msg.sender, address(this), tokenId) {} catch (
            bytes memory _error
        ) {
            emit ErrorLog(_error);
            revert("CREATE AUNCTION FAIL");
        }
        require(beginAuctionTimestamp > block.timestamp, "Auction timestamp must be in the future");
        require(
            endAuctionTimestamp > beginAuctionTimestamp,
            "End time must greater than begin time"
        );
        require(royalRate < 10 ** 3, "Invalid royal rate");
        require(burnRate < 10 ** 3, "Invalid burn rate");

        Auction storage auction = auctions[nftAddress][tokenId];
        auction.owner = payable(msg.sender);
        auction.tokenPayment = tokenPayment;
        auction.startingPrice = startingPrice;
        auction.highestBidPrice = 0;
        auction.highestBidder = address(0);
        auction.beginAuctionTimestamp = beginAuctionTimestamp;
        auction.endAuctionTimestamp = endAuctionTimestamp;
        auction.isBurn = isBurn;
        auction.royalRate = royalRate;
        auction.burnRate = burnRate;
        auction.ownerCollection = ownerCollection;
        auction.isCompleted = false;

        emit NftPutOnAuction(
            msg.sender,
            nftAddress,
            tokenId,
            tokenPayment,
            startingPrice,
            beginAuctionTimestamp
        );
    }

    function bidAuction(
        address nftAddress,
        uint256 tokenId,
        uint256 bidPrice
    ) public payable nonReentrant {
        Auction memory thisAuction = auctions[nftAddress][tokenId];
        require(thisAuction.beginAuctionTimestamp > 0, "The auction is not existed");
        require(thisAuction.beginAuctionTimestamp < block.timestamp, "Auction doesn't start yet");
        require(thisAuction.endAuctionTimestamp > block.timestamp, "Auction has finish");
        require(!thisAuction.isCompleted, "Auction has completed");
        require(
            bidPrice >= thisAuction.startingPrice,
            "The valid bid price must be higher than the starting price"
        );
        if (thisAuction.tokenPayment == address(0)) {
            //bid by ETH
            require(msg.value >= bidPrice, "Insufficient ETH amount");
            require(
                msg.value > thisAuction.highestBidPrice,
                "The valid bid price must be higher than the current highest price"
            );
            if (thisAuction.highestBidder != address(0) && thisAuction.highestBidPrice > 0) {
                payable(thisAuction.highestBidder).transfer(thisAuction.highestBidPrice); //return
            }
        } else {
            //bid by Tokens
            require(token.balanceOf(msg.sender) >= bidPrice, "Insufficient token balance");
            applyTokenForPayment(thisAuction.tokenPayment);
            require(
                bidPrice > thisAuction.highestBidPrice,
                "The valid bid price must be higher than the current highest price"
            );

            require(
                token.allowance(msg.sender, address(this)) >= bidPrice,
                "Payable is not allowed by bidder"
            );

            require(
                token.transferFrom(msg.sender, address(this), bidPrice),
                "Transfer bid amount fail"
            );

            if (thisAuction.highestBidder != address(0) && thisAuction.highestBidPrice > 0) {
                require(
                    token.balanceOf(address(this)) >= thisAuction.highestBidPrice,
                    "Not enough balance to payback to last bidder"
                );

                require(
                    token.transfer(thisAuction.highestBidder, thisAuction.highestBidPrice),
                    "Payback to last bidder fail"
                );
            }
        }

        auctions[nftAddress][tokenId].highestBidPrice = bidPrice;
        auctions[nftAddress][tokenId].highestBidder = msg.sender;

        emit AuctionBid(
            thisAuction.owner,
            nftAddress,
            tokenId,
            thisAuction.tokenPayment,
            msg.sender,
            bidPrice
        );
    }

    function finishAuction(
        address nftAddress,
        uint256 tokenId,
        bytes memory signature
    ) public payable nonReentrant {
        Auction storage thisAuction = auctions[nftAddress][tokenId];
        require(thisAuction.beginAuctionTimestamp > 0, "The auction is not existed");
        require(block.timestamp > thisAuction.endAuctionTimestamp, "Auction has not ended yet.");
        require(!thisAuction.isCompleted, "The auction has completed");
        require(thisAuction.owner == msg.sender, "You have no permission to finish this auction");
        IERC721 nftInstance = IERC721(nftAddress);

        bytes32 byte32Message = keccak256(
            abi.encodePacked(
                uint8(0x19),
                uint8(0x01),
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(BUY_SALT, nftAddress, tokenId, thisAuction.owner))
            )
        );
        bytes32 message = keccak256(abi.encodePacked(bytes32ToString(byte32Message)));
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(message);
        recoveredAddress = ECDSA.recover(messageHash, signature);
        require(recoveredAddress == thisAuction.owner, "Invalid signature");

        require(
            nftInstance.ownerOf(tokenId) == address(this),
            "This NFT is not belong to marketplace"
        );

        if (thisAuction.highestBidder != address(0) && thisAuction.highestBidPrice > 0) {
            if (thisAuction.tokenPayment == address(0)) {
                getFee = setFee[thisAuction.tokenPayment];
                ethFee = (msg.value * getFee) / feeDecimal;
                royalFee = (msg.value * thisAuction.royalRate) / 10 ** 3;
                require(
                    address(this).balance >= (thisAuction.highestBidPrice - ethFee),
                    "Insufficient ETH amount to pay winner"
                );
                if (royalFee > 0) {
                    payable(thisAuction.ownerCollection).transfer(royalFee);
                }
                payable(thisAuction.owner).transfer(
                    thisAuction.highestBidPrice - royalFee - ethFee
                ); //keep ethFee in marketplace
            } else {
                applyTokenForPayment(thisAuction.tokenPayment);
                if (thisAuction.isBurn == true) {
                    uint256 burnFee = (thisAuction.highestBidPrice * thisAuction.burnRate) /
                        10 ** 3;
                    royalFee = (thisAuction.highestBidPrice * thisAuction.royalRate) / 10 ** 3;
                    if (burnFee > 0) {
                        require(token.transfer(burnAddr, burnFee), "Transfer burn amount fail");
                    }
                    if (royalFee > 0) {
                        require(
                            token.transfer(thisAuction.ownerCollection, royalFee),
                            "Transfer royalty amount fail"
                        );
                    }
                    require(
                        token.transfer(
                            thisAuction.owner,
                            (thisAuction.highestBidPrice - royalFee - burnFee)
                        ),
                        "Transfer token to owner fail"
                    );
                } else {
                    getFee = setFee[thisAuction.tokenPayment];
                    tokenFee = (thisAuction.highestBidPrice * getFee) / feeDecimal;
                    royalFee = (thisAuction.highestBidPrice * thisAuction.royalRate) / 10 ** 3;
                    if (royalFee > 0) {
                        require(
                            token.transfer(thisAuction.ownerCollection, royalFee),
                            "Transfer burn amount fail"
                        );
                    }
                    require(
                        token.transfer(thisAuction.owner, (thisAuction.highestBidPrice - tokenFee)), //keeping tokenFee in Contract
                        "Transfer token to owner fail"
                    );
                }
            }

            try
                nftInstance.safeTransferFrom(address(this), thisAuction.highestBidder, tokenId)
            {} catch (bytes memory _error) {
                emit ErrorLog(_error);
                revert("FINISH AUCTION FAIL");
            }
            auctions[nftAddress][tokenId].isCompleted = true;
            emit AuctionCompleted(
                thisAuction.owner,
                nftAddress,
                tokenId,
                thisAuction.tokenPayment,
                thisAuction.highestBidder,
                thisAuction.highestBidPrice
            );
        } else {
            try nftInstance.safeTransferFrom(address(this), thisAuction.owner, tokenId) {} catch (
                bytes memory _error
            ) {
                emit ErrorLog(_error);
                revert("FINISH AUCTION FAIL");
            }
            auctions[nftAddress][tokenId].isCompleted = true;
            emit AuctionCompleted(
                thisAuction.owner,
                nftAddress,
                tokenId,
                thisAuction.tokenPayment,
                thisAuction.highestBidder,
                thisAuction.highestBidPrice
            );
        }
    }

    function cancelAuction(
        address nftAddress,
        uint256 tokenId,
        bytes memory signature
    ) public payable nonReentrant {
        Auction memory thisAuction = auctions[nftAddress][tokenId];
        require(thisAuction.beginAuctionTimestamp > 0, "The auction is not existed");
        require(!thisAuction.isCompleted, "The auction has completed");
        require(thisAuction.owner == msg.sender, "You have no permission to cancel this auction");
        IERC721 nftInstance = IERC721(nftAddress);

        bytes32 byte32Message = keccak256(
            abi.encodePacked(
                uint8(0x19),
                uint8(0x01),
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(BUY_SALT, nftAddress, tokenId, thisAuction.owner))
            )
        );
        bytes32 message = keccak256(abi.encodePacked(bytes32ToString(byte32Message)));
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(message);
        recoveredAddress = ECDSA.recover(messageHash, signature);
        require(recoveredAddress == thisAuction.owner, "Invalid signature");

        if (thisAuction.highestBidder != address(0) && thisAuction.highestBidPrice > 0) {
            if (thisAuction.tokenPayment == address(0)) {
                require(
                    address(this).balance >= thisAuction.highestBidPrice,
                    "Insufficient ETH amount to pay winner"
                );
                payable(thisAuction.highestBidder).transfer(thisAuction.highestBidPrice);
            } else {
                applyTokenForPayment(thisAuction.tokenPayment);
                require(
                    token.transferFrom(
                        address(this),
                        thisAuction.highestBidder,
                        thisAuction.highestBidPrice
                    ),
                    "Return token to last highest bidder fail"
                );
            }
        }
        try nftInstance.safeTransferFrom(address(this), thisAuction.owner, tokenId) {} catch (
            bytes memory _error
        ) {
            emit ErrorLog(_error);
            revert("CANCEL AUCTION FAIL");
        }
        auctions[nftAddress][tokenId].isCompleted = true;
        emit AuctionCanceled(
            thisAuction.owner,
            nftAddress,
            tokenId,
            thisAuction.tokenPayment,
            thisAuction.highestBidder,
            thisAuction.highestBidPrice
        );
    }

    function set_Fee(address tokenAddr, uint256 feeValue) public onlyOwner {
        require(feeValue >= 0 && feeValue <= 10000, "Invalid token fee");
        setFee[tokenAddr] = feeValue;
    }

    function delete_Fee(address tokenAddr) public onlyOwner {
        delete setFee[tokenAddr];
    }

    function bytes32ToString(bytes32 value) internal pure returns (string memory) {
        bytes16 _hexAlphabet = "0123456789abcdef";
        bytes memory result = new bytes(2 + 2 * 32);
        result[0] = "0";
        result[1] = "x";
        for (uint256 i = 0; i < 32; i++) {
            uint8 v = uint8(value[i]);
            result[2 + 2 * i] = _hexAlphabet[v >> 4];
            result[3 + 2 * i] = _hexAlphabet[v & 0x0f];
        }
        return string(result);
    }

    /**
     * @dev transfer token in emergency case
     */
    function transferTokenEmergency(address _token, uint256 _amount) public onlyOwner {
        require(_amount > 0, "Invalid amount");
        if (_token == address(0)) {
            require(address(this).balance >= _amount, "Native token balance is not enough");
            payable(msg.sender).transfer(_amount);
        } else {
            require(
                IERC20(token).balanceOf(address(this)) >= _amount,
                "Token balance is not enough"
            );
            require(IERC20(token).transfer(msg.sender, _amount), "Cannot withdraw token");
        }
    }

    /**
     * @dev transfer NFT in emergency case
     */
    function transferNftEmergency(address _nftAddress, uint256 _nftId) public onlyOwner {
        require(
            IERC721(_nftAddress).ownerOf(_nftId) == address(this),
            "Market do not own this NFT"
        );
        try IERC721(_nftAddress).safeTransferFrom(address(this), msg.sender, _nftId) {} catch (
            bytes memory _error
        ) {
            emit ErrorLog(_error);
            revert("TRANSFER EMERGENCY FAIL");
        }
    }
}