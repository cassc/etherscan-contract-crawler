// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../ERC721MarketplaceV6.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../IERC721Mintable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";

library ERC721MarketplaceHelper {
    function validateBidSign(
        UPYOERC721MarketPlaceV6.auction memory _auction,
        address _erc721,
        uint256 _tokenId,
        uint256 _nonce,
        address seller,
        bytes calldata sign
    ) external view {
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                address(this),
                _auction.seller,
                _erc721,
                _tokenId,
                _nonce,
                _auction.startingPrice,
                _auction.startingTime,
                _auction.closingTime,
                _auction.erc20Token
            )
        );

        bytes32 signedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
        );
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(sign);

        address signer_ = ecrecover(signedMessageHash, v, r, s);

        require(signer_ == seller, "ERC721Marketplace: Invalid Sign");
    }

    function validateBidSignBatch(
        UPYOERC721MarketPlaceV6.auction memory _auction,
        UPYOERC721MarketPlaceV6.bidInput calldata _bidInput,
        address seller // bytes calldata sign, // bytes32 root,
    ) external view // bytes32[] calldata proof
    {
        // Verify Merkle proof
        bytes32 leaf = keccak256(
            bytes.concat(
                keccak256(
                    abi.encode(
                        address(this),
                        _auction.seller,
                        _bidInput._erc721,
                        _bidInput._tokenId,
                        _bidInput._nonce,
                        _auction.startingPrice,
                        _auction.startingTime,
                        _auction.closingTime,
                        _auction.erc20Token
                    )
                )
            )
        );

        require(
            MerkleProofUpgradeable.verifyCalldata(
                _bidInput.proof,
                _bidInput.root,
                leaf
            ),
            "ERC721Marketplace: Invalid Root"
        );

        // Verify root sign
        bytes32 signedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", _bidInput.root)
        );
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_bidInput.sign);

        address signer_ = ecrecover(signedMessageHash, v, r, s);

        require(signer_ == seller, "ERC721Marketplace: Invalid Sign");
    }

    function handleBidFund(
        UPYOERC721MarketPlaceV6.auction memory _auction,
        uint256 amount,
        IERC721Mintable Token,
        uint256 _tokenId,
        address payable bidder
    ) external returns (UPYOERC721MarketPlaceV6.auction memory) {
        if (_auction.erc20Token == address(0)) {
            require(
                msg.value > _auction.currentBid,
                "ERC721Marketplace: Insufficient bidding amount."
            );

            if (_auction.highestBidder != address(0)) {
                _auction.highestBidder.transfer(_auction.currentBid);
            }
        } else {
            IERC20Upgradeable erc20Token = IERC20Upgradeable(
                _auction.erc20Token
            );
            require(
                erc20Token.allowance(msg.sender, address(this)) >= amount,
                "ERC721Marketplace: Allowance is less than amount sent for bidding."
            );
            require(
                amount > _auction.currentBid,
                "ERC721Marketplace: Insufficient bidding amount."
            );
            erc20Token.transferFrom(msg.sender, address(this), amount);

            if (_auction.highestBidder != address(0)) {
                erc20Token.transfer(
                    _auction.highestBidder,
                    _auction.currentBid
                );
            }
        }

        _auction.currentBid = _auction.erc20Token == address(0)
            ? msg.value
            : amount;

        if (Token.ownerOf(_tokenId) != address(this)) {
            Token.safeTransferFrom(
                Token.ownerOf(_tokenId),
                address(this),
                _tokenId
            );
        }
        _auction.highestBidder = bidder;
        return _auction;
    }

    function _getCreatorAndRoyalty(
        address _erc721,
        uint256 _tokenId,
        uint256 amount
    ) private view returns (address payable, uint256) {
        address creator;
        uint256 royalty;

        IERC721Mintable collection = IERC721Mintable(_erc721);

        try collection.royaltyInfo(_tokenId, amount) returns (
            address receiver,
            uint256 royaltyAmount
        ) {
            creator = receiver;
            royalty = royaltyAmount;
        } catch {
            try collection.royalities(_tokenId) returns (uint256 royalities) {
                try collection.creators(_tokenId) returns (
                    address payable receiver
                ) {
                    creator = receiver;
                    royalty = (royalities * amount) / (100 * 100);
                } catch {}
            } catch {}
        }
        return (payable(creator), royalty);
    }

    function splitSignature(bytes memory sig)
        private
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(
            sig.length == 65,
            "ERC721Marketplace: invalid signature length"
        );

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    function handleCollect(
        uint256 _tokenId,
        address _erc721,
        UPYOERC721MarketPlaceV6.auction memory _auction,
        UPYOERC721MarketPlaceV6._brokerage memory brokerage_,
        address payable broker
    ) external {
        IERC721Mintable Token = IERC721Mintable(_erc721);

        // Only allow collect without finishing the auction only if admin collects it.
        if (msg.sender != _auction.seller) {
            require(
                block.timestamp > _auction.closingTime,
                "ERC721Marketplace: Auction Not Over!"
            );
        }

        if (_auction.highestBidder != address(0)) {
            // Get royality and seller
            (address payable creator, uint256 royalty) = _getCreatorAndRoyalty(
                _erc721,
                _tokenId,
                _auction.currentBid
            );

            // Calculate seller fund
            uint256 sellerFund = _auction.currentBid -
                royalty -
                brokerage_.seller -
                brokerage_.buyer;

            // Transfer funds for native currency
            if (_auction.erc20Token == address(0)) {
                creator.transfer(royalty);
                _auction.seller.transfer(sellerFund);
                broker.transfer(brokerage_.seller + brokerage_.buyer);
            }
            // Transfer funds for ERC20 token
            else {
                IERC20Upgradeable erc20Token = IERC20Upgradeable(
                    _auction.erc20Token
                );
                erc20Token.transfer(creator, royalty);
                erc20Token.transfer(_auction.seller, sellerFund);
                erc20Token.transfer(
                    broker,
                    brokerage_.seller + brokerage_.buyer
                );
            }
            // Transfer the NFT to Buyer
            Token.safeTransferFrom(
                Token.ownerOf(_tokenId),
                _auction.highestBidder,
                _tokenId
            );
        }
    }

    function validateBuy(
        uint256 _tokenId,
        address _erc721,
        uint256 price,
        uint256 _nonce,
        bytes calldata sign,
        address _erc20Token,
        address seller
    ) external view {
        {
            bytes32 messageHash = keccak256(
                abi.encodePacked(
                    address(this),
                    _tokenId,
                    _erc721,
                    price,
                    _nonce,
                    _erc20Token
                )
            );

            bytes32 signedMessageHash = keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    messageHash
                )
            );
            (bytes32 r, bytes32 s, uint8 v) = splitSignature(sign);

            address signer_ = ecrecover(signedMessageHash, v, r, s);

            require(signer_ == seller, "ERC721Marketplace: Invalid Sign");
        }
    }

    function validateBuyBatch(
        uint256 _tokenId,
        address _erc721,
        uint256 price,
        uint256 _nonce,
        bytes calldata sign,
        address _erc20Token,
        address seller,
        bytes32 root,
        bytes32[] calldata proof
    ) external view {
        {
            // Verify MerkleRoot
            bytes32 leaf = keccak256(
                bytes.concat(
                    keccak256(
                        abi.encode(
                            address(this),
                            _tokenId,
                            _erc721,
                            price,
                            _nonce,
                            _erc20Token,
                            seller
                        )
                    )
                )
            );

            require(
                MerkleProofUpgradeable.verify(proof, root, leaf),
                "ERC721Marketplace: Invalid Root"
            );

            // Verify root signed by seller
            bytes32 signedMessageHash = keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", root)
            );

            (bytes32 r, bytes32 s, uint8 v) = splitSignature(sign);

            address signer_ = ecrecover(signedMessageHash, v, r, s);

            require(signer_ == seller, "ERC721Marketplace: Invalid Sign");
        }
    }

    function handleBuy(
        uint256 _tokenId,
        address _erc721,
        uint256 price,
        address _erc20Token,
        address buyer,
        UPYOERC721MarketPlaceV6._brokerage memory brokerage_,
        address payable broker,
        address seller
    ) external {
        IERC721Mintable Token = IERC721Mintable(_erc721);

        require(
            Token.getApproved(_tokenId) == address(this) ||
                Token.isApprovedForAll(seller, address(this)),
            "ERC721Marketplace: Broker Not approved"
        );

        // Get royality and creator
        (address payable creator, uint256 royalty) = _getCreatorAndRoyalty(
            _erc721,
            _tokenId,
            price
        );
        {
            // Calculate seller fund
            uint256 sellerFund = price - royalty - brokerage_.seller;

            // Transfer funds for natice currency
            if (_erc20Token == address(0)) {
                require(
                    msg.value >= price + brokerage_.buyer,
                    "ERC721Marketplace: Insufficient Payment"
                );
                creator.transfer(royalty);
                payable(seller).transfer(sellerFund);
                broker.transfer(msg.value - royalty - sellerFund);
            }
            // Transfer the funds for ERC20 token
            else {
                IERC20Upgradeable erc20Token = IERC20Upgradeable(_erc20Token);
                require(
                    erc20Token.allowance(msg.sender, address(this)) >=
                        price + brokerage_.buyer,
                    "ERC721Marketplace: Insufficient spent allowance "
                );
                // transfer royalitiy to creator
                erc20Token.transferFrom(msg.sender, creator, royalty);
                // transfer brokerage amount to broker
                erc20Token.transferFrom(
                    msg.sender,
                    broker,
                    brokerage_.seller + brokerage_.buyer
                );
                // transfer remaining  amount to Seller
                erc20Token.transferFrom(msg.sender, seller, sellerFund);
            }
        }
        Token.safeTransferFrom(seller, buyer, _tokenId);
    }

    function validateLazyMintAuction(
        UPYOERC721MarketPlaceV6.sellerVoucher memory _sellerVoucher,
        UPYOERC721MarketPlaceV6.buyerVoucher memory _buyerVoucher,
        bytes memory globalSign,
        address _signer
    ) external view {
        require(
            _sellerVoucher.erc20Token != address(0),
            "ERC721Marketplace: Must be ERC20 token address"
        );

        bytes32 messageHash = keccak256(
            abi.encodePacked(
                address(this),
                _sellerVoucher.to,
                _sellerVoucher.royalty,
                _sellerVoucher.tokenURI,
                _sellerVoucher.nonce,
                _sellerVoucher.erc721,
                _sellerVoucher.startingPrice,
                _sellerVoucher.startingTime,
                _sellerVoucher.endingTime,
                _sellerVoucher.erc20Token,
                _buyerVoucher.buyer,
                _buyerVoucher.time,
                _buyerVoucher.amount
            )
        );

        bytes32 signedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
        );
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(globalSign);

        address signer_ = ecrecover(signedMessageHash, v, r, s);

        require(
            _signer == signer_,
            "ERC721Marketplace: Signature not verfied."
        );

        require(
            _sellerVoucher.endingTime <= block.timestamp ||
                msg.sender == _sellerVoucher.to,
            "ERC721Marketplace: Auction not over yet."
        );
    }

    function handleLazyMintAuction(
        UPYOERC721MarketPlaceV6.sellerVoucher memory _sellerVoucher,
        UPYOERC721MarketPlaceV6.buyerVoucher memory _buyerVoucher,
        address WETH,
        uint256 mintingCharge,
        address payable broker,
        uint256 sellingBrokerage,
        uint256 buyingBrokerage
    ) external returns (uint256) {
        // Transfer the funds.
        IERC20Upgradeable erc20Token = IERC20Upgradeable(
            _sellerVoucher.erc20Token
        );

        if (WETH == _sellerVoucher.erc20Token) {
            require(
                erc20Token.allowance(_buyerVoucher.buyer, address(this)) >=
                    _buyerVoucher.amount + mintingCharge,
                "Allowance is less than amount sent for bidding."
            );

            erc20Token.transferFrom(
                _buyerVoucher.buyer,
                broker,
                sellingBrokerage + buyingBrokerage + mintingCharge
            );
        } else {
            require(
                erc20Token.allowance(_buyerVoucher.buyer, address(this)) >=
                    _buyerVoucher.amount,
                "Allowance is less than amount sent for bidding."
            );

            IERC20Upgradeable weth = IERC20Upgradeable(WETH);

            require(
                weth.allowance(_buyerVoucher.buyer, address(this)) >=
                    mintingCharge,
                "Allowance is less than minting charges"
            );

            erc20Token.transferFrom(
                _buyerVoucher.buyer,
                broker,
                sellingBrokerage + buyingBrokerage
            );

            weth.transferFrom(_buyerVoucher.buyer, broker, mintingCharge);
        }

        erc20Token.transferFrom(
            _buyerVoucher.buyer,
            _sellerVoucher.to,
            _buyerVoucher.amount - (sellingBrokerage + buyingBrokerage)
        );

        return
            IERC721Mintable(_sellerVoucher.erc721).delegatedMint(
                _sellerVoucher.tokenURI,
                _sellerVoucher.royalty,
                _sellerVoucher.to,
                _buyerVoucher.buyer
            );
    }

    function validateLazyMint(
        address collection,
        address to,
        uint96 _royalty,
        string memory _tokenURI,
        uint256 nonce,
        uint256 price,
        bytes memory sign
    ) external pure {
        bytes32 messageHash = keccak256(
            abi.encodePacked(collection, _royalty, nonce, _tokenURI, price)
        );

        bytes32 signedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
        );

        (bytes32 r, bytes32 s, uint8 v) = splitSignature(sign);

        address signer_ = ecrecover(signedMessageHash, v, r, s);

        require(to == signer_, "ERC721Marketplace: Signature not verfied.");
    }

    function validateAcceptLazyOffer(
        UPYOERC721MarketPlaceV6.lazySellerVoucher memory _sellerVoucher,
        UPYOERC721MarketPlaceV6.buyerVoucher memory _buyerVoucher,
        uint256 _nonce,
        bytes calldata _sign,
        address WETH
    ) external view {
        // Seller validation.
        {
            bytes32 messageHash = keccak256(
                abi.encodePacked(
                    _sellerVoucher.erc721,
                    _sellerVoucher.royalty,
                    _sellerVoucher.nonce,
                    _sellerVoucher.tokenURI,
                    _sellerVoucher.price
                )
            );

            bytes32 signedMessageHash = keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    messageHash
                )
            );

            (bytes32 r, bytes32 s, uint8 v) = splitSignature(
                _sellerVoucher.sign
            );

            address signer_ = ecrecover(signedMessageHash, v, r, s);

            require(
                _sellerVoucher.to == signer_,
                "ERC721Marketplace: Signature not verfied."
            );
            require(
                _sellerVoucher.to == msg.sender,
                "ERC721Marketplace: For seller only"
            );
        }

        // Buyer validation.
        {
            bytes32 messageHash = keccak256(
                abi.encodePacked(
                    address(this),
                    msg.sender,
                    _sellerVoucher.nonce, //Seller's nonce
                    _sellerVoucher.erc721,
                    _buyerVoucher.amount,
                    _buyerVoucher.time,
                    WETH,
                    _nonce // Buyer's offer nonce
                )
            );

            bytes32 signedMessageHash = keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    messageHash
                )
            );

            (bytes32 r, bytes32 s, uint8 v) = splitSignature(_sign);

            address signer_ = ecrecover(signedMessageHash, v, r, s);

            require(
                _buyerVoucher.buyer == signer_,
                "ERC721Marketplace: Signature not verfied."
            );

            require(
                _buyerVoucher.time >= block.timestamp,
                "ERC721Marketplace: Offer expired."
            );
        }
    }

    function handleAcceptOffer(
        uint256 _tokenId,
        address _erc721,
        uint256 _amount,
        uint256 _validTill,
        address _bidder,
        IERC20Upgradeable _erc20Token,
        uint256 _nonce,
        bytes calldata _sign,
        UPYOERC721MarketPlaceV6._brokerage memory brokerage_,
        address broker
    ) external {
        {
            bytes32 messageHash = keccak256(
                abi.encodePacked(
                    address(this),
                    msg.sender,
                    _tokenId,
                    _erc721,
                    _amount,
                    _validTill,
                    address(_erc20Token),
                    _nonce
                )
            );

            bytes32 signedMessageHash = keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    messageHash
                )
            );

            (bytes32 r, bytes32 s, uint8 v) = splitSignature(_sign);

            address signer_ = ecrecover(signedMessageHash, v, r, s);

            require(
                _bidder == signer_,
                "ERC721Marketplace: Signature not verfied."
            );

            require(
                address(_erc20Token) != address(0),
                "ERC721Marketplace: Native currencies are not supported for offers."
            );

            require(
                _validTill >= block.timestamp,
                "ERC721Marketplace: Offer expired."
            );
        }

        {
            require(
                _erc20Token.allowance(_bidder, address(this)) >= _amount &&
                    _erc20Token.balanceOf(_bidder) >= _amount,
                "ERC721Marketplace: Isufficient allowance or balance in bidder's account."
            );

            (address payable creator, uint256 royalty) = _getCreatorAndRoyalty(
                _erc721,
                _tokenId,
                _amount
            );

            // Calculate seller fund
            uint256 sellerFund = _amount -
                royalty -
                brokerage_.seller -
                brokerage_.buyer;

            _erc20Token.transferFrom(_bidder, creator, royalty);
            _erc20Token.transferFrom(_bidder, msg.sender, sellerFund);
            _erc20Token.transferFrom(
                _bidder,
                broker,
                brokerage_.seller + brokerage_.buyer
            );
        }

        IERC721Mintable Token = IERC721Mintable(_erc721);

        require(
            Token.getApproved(_tokenId) == address(this) ||
                Token.isApprovedForAll(msg.sender, address(this)),
            "ERC721Marketplace: Broker Not approved"
        );
        // Transfer the NFT to Buyer
        Token.safeTransferFrom(msg.sender, _bidder, _tokenId);
    }

    function validateCancelOffer(
        uint256 _tokenId,
        address _erc721,
        uint256 _amount,
        uint256 _validTill,
        address _seller,
        address _erc20Token,
        uint256 _nonce,
        bytes calldata _sign
    ) external view {
        {
            bytes32 messageHash = keccak256(
                abi.encodePacked(
                    address(this),
                    _seller,
                    _tokenId,
                    _erc721,
                    _amount,
                    _validTill,
                    address(_erc20Token),
                    _nonce
                )
            );

            bytes32 signedMessageHash = keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    messageHash
                )
            );

            (bytes32 r, bytes32 s, uint8 v) = splitSignature(_sign);

            address signer_ = ecrecover(signedMessageHash, v, r, s);

            require(
                msg.sender == signer_,
                "ERC721Marketplace: Signature not verfied."
            );
        }
    }
}