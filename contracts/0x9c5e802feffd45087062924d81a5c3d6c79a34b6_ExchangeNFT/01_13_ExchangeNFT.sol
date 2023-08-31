//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./interfaces/IERC721.sol";
import "./interfaces/IStableToken.sol";
import "./libraries/ECDSA.sol";
import "./libraries/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract ExchangeNFT is Ownable {
    using ECDSA for bytes32;
    using SafeERC20 for ERC20;
    using SafeMath for uint256;

    address public ERC721;

    // Address is owner of ERC721
    address public admin;

    // Mitigating Replay Attacks
    mapping(address => mapping(uint256 => bool)) seenNonces;

    // Addresses running auction NFT
    mapping(address => bool) public whitelistAddress;

    struct Data {
        address[5] tradeAddress;
        uint256[4] attributes;
    }

    // Events
    // addrs: from, to, token
    event BuyNFTNormal(address[3] addrs, uint256 tokenId, uint256 amount);
    event BuyNFTETH(address[3] addrs, uint256 tokenId, uint256 amount);
    event AuctionNFT(address[3] addrs, uint256 tokenId, uint256 amount);
    event AcceptOfferNFT(address[3] addrs, uint256 tokenId, uint256 amount);

    constructor(address _erc721) public {
        ERC721 = _erc721;
        whitelistAddress[msg.sender] = true;
        admin = msg.sender;
    }

    function setNFTAddress(address _nft) public onlyOwner {
        ERC721 = _nft;
    }

    function setWhitelistAddress(address _address, bool approved)
        public
        onlyOwner
    {
        whitelistAddress[_address] = approved;
    }

    function setAdminAddress(address _admin) public onlyOwner {
        admin = _admin;
    }

    modifier verifySignature(
        uint256 nonce,
        address[5] memory _tradeAddress,
        uint256[4] memory _attributes,
        bytes memory signature
    ) {
        // This recreates the message hash that was signed on the client.
        bytes32 hash = keccak256(
            abi.encodePacked(
                msg.sender,
                nonce,
                _tradeAddress,
                _attributes
            )
        );
        bytes32 messageHash = hash.toEthSignedMessageHash();
        // Verify that the message's signer is the owner of the order
        require(messageHash.recover(signature) == owner(), "Invalid signature");
        require(!seenNonces[msg.sender][nonce], "Used nonce");
        seenNonces[msg.sender][nonce] = true;
        _;
    }

    function checkFeeProductExits(
        address[5] memory _tradeAddress,
        uint256[4] memory _attributes
    ) private returns (uint256 amount, uint256 feeOwner, uint256 feeAdmin) {
        uint256 totalFeeTrade;
        // Check fee for owner
        if (_tradeAddress[3] != address(0)) {
            feeOwner = _attributes[0].mul(_attributes[2]).div(1000);
            totalFeeTrade += feeOwner;
        }
        // Check fee for admin
        if (_tradeAddress[4] != address(0)) {
            feeAdmin = _attributes[0].mul(_attributes[3]).div(1000);
            totalFeeTrade += feeAdmin;
        }
        amount = _attributes[0].sub(totalFeeTrade);
    }

    // Buy NFT normal by token ERC-20
    // address[5]: buyer, seller, token, fee, feeAdmin
    // uint256[4]: amount, tokenId, feePercent, feePercentAdmin
    function buyNFTNormal(
        address[5] memory _tradeAddress,
        uint256[4] memory _attributes,
        uint256 nonce,
        bytes memory signature
    ) external verifySignature(nonce, _tradeAddress, _attributes, signature) {
        Data memory tradeInfo = Data({
            tradeAddress: _tradeAddress,
            attributes: _attributes
        });
        // check allowance of buyer
        require(
            IERC20(tradeInfo.tradeAddress[2]).allowance(msg.sender, address(this)) >=
                tradeInfo.attributes[0],
            "token allowance too low"
        );
        (uint256 amount, uint256 feeOwner, uint256 feeAdmin) = checkFeeProductExits(
            tradeInfo.tradeAddress,
            tradeInfo.attributes
        );

        if (feeOwner != 0) {
            // transfer token to fee address
            ERC20(tradeInfo.tradeAddress[2]).safeTransferFrom(
                tradeInfo.tradeAddress[0],
                tradeInfo.tradeAddress[3],
                feeOwner
            );
        }

        if (feeAdmin != 0) {
            // transfer token to fee address
            ERC20(tradeInfo.tradeAddress[2]).safeTransferFrom(
                tradeInfo.tradeAddress[0],
                tradeInfo.tradeAddress[4],
                feeAdmin
            );
        }

        // transfer token from buyer to seller
        ERC20(tradeInfo.tradeAddress[2]).safeTransferFrom(
            msg.sender,
            tradeInfo.tradeAddress[1],
            amount
        );
        IERC721(ERC721).safeTransferFrom(
            tradeInfo.tradeAddress[1],
            msg.sender,
            tradeInfo.attributes[1]
        );
        emit BuyNFTNormal(
            [msg.sender, tradeInfo.tradeAddress[1], tradeInfo.tradeAddress[2]],
            tradeInfo.attributes[1],
            tradeInfo.attributes[0]
        );
    }

    // Buy NFT normal by ETH
    // address[5]: buyer, seller, token, fee, feeAdmin
    // uint256[4]: amount, tokenId, feePercent, feePercentAdmin
    function buyNFTETH(
        address[5] memory _tradeAddress,
        uint256[4] memory _attributes,
        uint256 nonce,
        bytes memory signature
    )
        external
        payable
        verifySignature(nonce, _tradeAddress, _attributes, signature)
    {
        Data memory tradeInfo = Data({
            tradeAddress: _tradeAddress,
            attributes: _attributes
        });
        (uint256 amount, uint256 feeOwner, uint256 feeAdmin) = checkFeeProductExits(
            tradeInfo.tradeAddress,
            tradeInfo.attributes
        );
        // transfer eth to fee address
        if (feeOwner != 0) {
            TransferHelper.safeTransferETH(tradeInfo.tradeAddress[3], feeOwner);
        }

        // transfer eth to admin address
        if (feeAdmin != 0) {
            TransferHelper.safeTransferETH(tradeInfo.tradeAddress[4], feeAdmin);
        }

        TransferHelper.safeTransferETH(tradeInfo.tradeAddress[1], amount);

        IERC721(ERC721).safeTransferFrom(
            tradeInfo.tradeAddress[1],
            msg.sender,
            tradeInfo.attributes[1]
        );
        // refund dust eth, if any
        if (msg.value > tradeInfo.attributes[0])
            TransferHelper.safeTransferETH(
                msg.sender,
                msg.value - tradeInfo.attributes[0]
            );
        emit BuyNFTETH(
            [msg.sender, tradeInfo.tradeAddress[1], tradeInfo.tradeAddress[2]],
            tradeInfo.attributes[1],
            tradeInfo.attributes[0]
        );
    }

    // Auction NFT
    // address[5]: buyer, seller, token, fee, feeAdmin
    // uint256[4]: amount, tokenId, feePercent, feePercentAdmin
    function auctionNFT(
        address[5] memory _tradeAddress,
        uint256[4] memory _attributes
    ) external {
        Data memory tradeInfo = Data({
            tradeAddress: _tradeAddress,
            attributes: _attributes
        });
        // Check address execute auction
        require(
            whitelistAddress[msg.sender] == true,
            "Address is not in whitelist"
        );
        // check allowance of buyer
        require(
            IERC20(tradeInfo.tradeAddress[2]).allowance(
                tradeInfo.tradeAddress[0],
                address(this)
            ) >= tradeInfo.attributes[0],
            "token allowance too low"
        );
        if (tradeInfo.tradeAddress[1] == admin) {
            require(
                IERC721(ERC721).isApprovedForAll(admin, address(this)),
                "tokenId do not approve for contract"
            );
        } else {
            require(
                IERC721(ERC721).getApproved(tradeInfo.attributes[1]) == address(this),
                "tokenId do not approve for contract"
            );
        }

        (uint256 amount, uint256 feeOwner, uint256 feeAdmin) = checkFeeProductExits(
            tradeInfo.tradeAddress,
            tradeInfo.attributes
        );
        if (feeOwner != 0) {
            // transfer token to fee address
            ERC20(tradeInfo.tradeAddress[2]).safeTransferFrom(
                tradeInfo.tradeAddress[0],
                tradeInfo.tradeAddress[3],
                feeOwner
            );
        }

        if (feeAdmin != 0) {
            // transfer token to fee address
            ERC20(tradeInfo.tradeAddress[2]).safeTransferFrom(
                tradeInfo.tradeAddress[0],
                tradeInfo.tradeAddress[4],
                feeAdmin
            );
        }

        // transfer token from buyer to seller
        ERC20(tradeInfo.tradeAddress[2]).safeTransferFrom(
            tradeInfo.tradeAddress[0],
            tradeInfo.tradeAddress[1],
            amount
        );
        IERC721(ERC721).safeTransferFrom(
            tradeInfo.tradeAddress[1],
            tradeInfo.tradeAddress[0],
            tradeInfo.attributes[1]
        );
        emit AuctionNFT(
            [msg.sender, tradeInfo.tradeAddress[1], tradeInfo.tradeAddress[2]],
            tradeInfo.attributes[1],
            tradeInfo.attributes[0]
        );
    }

    // Accept offer from buyer
    // address[5]: buyer, seller, token, fee, feeAdmin
    // uint256[4]: amount, tokenId, feePercent, feePercentAdmin
    function acceptOfferNFT(
        address[5] memory _tradeAddress,
        uint256[4] memory _attributes,
        uint256 nonce,
        bytes memory signature
    ) external verifySignature(nonce, _tradeAddress, _attributes, signature) {
        Data memory tradeInfo = Data({
            tradeAddress: _tradeAddress,
            attributes: _attributes
        });

        require(
            IERC721(ERC721).getApproved(tradeInfo.attributes[1]) == address(this),
            "tokenId do not approve for contract"
        );
        // check allowance of buyer
        require(
            IERC20(tradeInfo.tradeAddress[2]).allowance(
                tradeInfo.tradeAddress[0],
                address(this)
            ) >= tradeInfo.attributes[0],
            "token allowance too low"
        );

        (uint256 amount, uint256 feeOwner, uint256 feeAdmin) = checkFeeProductExits(
            tradeInfo.tradeAddress,
            tradeInfo.attributes
        );
        if (feeOwner != 0) {
            // transfer token to fee address
            ERC20(tradeInfo.tradeAddress[2]).safeTransferFrom(
                tradeInfo.tradeAddress[0],
                tradeInfo.tradeAddress[3],
                feeOwner
            );
        }

        if (feeAdmin != 0) {
            // transfer token to fee address
            ERC20(tradeInfo.tradeAddress[2]).safeTransferFrom(
                tradeInfo.tradeAddress[0],
                tradeInfo.tradeAddress[4],
                feeAdmin
            );
        }

        // transfer token from buyer to seller
        ERC20(tradeInfo.tradeAddress[2]).safeTransferFrom(
            tradeInfo.tradeAddress[0],
            msg.sender,
            amount
        );

        IERC721(ERC721).safeTransferFrom(
            tradeInfo.tradeAddress[1],
            tradeInfo.tradeAddress[0],
            tradeInfo.attributes[1]
        );
        emit AcceptOfferNFT(
            [msg.sender, tradeInfo.tradeAddress[1], tradeInfo.tradeAddress[2]],
            tradeInfo.attributes[1],
            tradeInfo.attributes[0]
        );
    }
}