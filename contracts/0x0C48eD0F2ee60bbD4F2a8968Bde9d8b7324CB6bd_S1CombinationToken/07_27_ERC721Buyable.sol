pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "../opensea/ERC721Tradable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

abstract contract ERC721Buyable is EIP712, ERC721Tradable, ReentrancyGuard {
    using ECDSA for bytes32;
    using SignatureChecker for address;

    uint256 public saleTax = 1_000;
    uint256 public saleTaxDenumerator = 10_000;
    IERC20 public paymentToken;
    address public treasury;
    mapping(address => mapping(uint256 => uint256)) public nonces;

    event SellOfferAcceptedETH(
        address seller,
        address buyer,
        uint256 tokenId,
        uint256 price
    );
    event SellOfferAcceptedWETH(
        address seller,
        address buyer,
        uint256 tokenId,
        uint256 price
    );
    event BuyOfferAcceptedWETH(
        address seller,
        address buyer,
        uint256 tokenId,
        uint256 price
    );

    // onlyOwner events
    event SetSaleTax(uint256 tax);
    event SetTreasury(address treasury);

    // _paymentToken - Wrapped ETH
    // _name - Contract name from EIP712
    // _version - Contract version from EIP712
    constructor(
        address _paymentToken,
        string memory _name,
        string memory _version
    ) EIP712(_name, _version) ReentrancyGuard() {
        treasury = msg.sender;
        paymentToken = IERC20(_paymentToken);
    }

    function setSaleTax(uint256 _tax) external onlyOwner {
        require(_tax <= 1_000, "ERC721Buyable: Looks like this tax is too big");
        saleTax = _tax;
        emit SetSaleTax(_tax);
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;

        emit SetTreasury(_treasury);
    }

    function buyAcceptingSellOfferETH(
        address _seller,
        address _buyer,
        uint256 _tokenId,
        uint256 nonce,
        uint256 _deadline,
        uint256 _price,
        bytes memory _sellerSignature
    ) external payable nonReentrant {
        bytes32 digest = _hashSellOfferETH(
            _seller,
            _buyer,
            _tokenId,
            _deadline,
            _price
        );
        require(
            _price == msg.value,
            "ERC721Buyable: Not enought ETH to buy token"
        );
        require(
            SignatureChecker.isValidSignatureNow(
                _seller,
                digest,
                _sellerSignature
            ),
            "ERC721Buyable: Invalid signature"
        );
        require(
            block.timestamp < _deadline,
            "ERC721Buyable: Signed transaction expired"
        );
        nonces[_seller][_tokenId]++;
        if (_buyer == address(0)) {
            _buyer = msg.sender;
        }
        uint256 tax = (_price * saleTax) / saleTaxDenumerator;
        if (tax > 0) {
            payable(treasury).transfer(tax);
        }

        payable(_seller).transfer(_price - tax);
        _transfer(_seller, _buyer, _tokenId);

        emit SellOfferAcceptedETH(_seller, _buyer, _tokenId, _price);
    }

    function _hashSellOfferETH(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _deadline,
        uint256 _price
    ) internal view returns (bytes32) {
        return
        _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "SellOfferETH(address from,address to,uint256 tokenId,uint256 nonce,uint256 deadline,uint256 price)"
                    ),
                    _from,
                    _to,
                    _tokenId,
                    nonces[_from][_tokenId],
                    _deadline,
                    _price
                )
            )
        );
    }

    function buyAcceptingSellOfferWETH(
        address _seller,
        uint256 _tokenId,
        uint256 nonce,
        uint256 _deadline,
        uint256 _price,
        bytes memory _sellerSignature
    ) external {
        bytes32 digest = _hashSellOfferWETH(
            _seller,
            _tokenId,
            _deadline,
            _price
        );
        require(
            SignatureChecker.isValidSignatureNow(
                _seller,
                digest,
                _sellerSignature
            ),
            "ERC721Buyable: Invalid signature"
        );
        require(
            block.timestamp < _deadline,
            "ERC721Buyable: signed transaction expired"
        );
        nonces[_seller][_tokenId]++;
        uint256 tax = (_price * saleTax) / saleTaxDenumerator;
        if (tax > 0) {
            bool _success = paymentToken.transferFrom(_msgSender(), treasury, tax);
            require(_success, "ERC721Buyable: transfer failed");
        }
        bool _success = paymentToken.transferFrom(_msgSender(), _seller, _price - tax);
        require(_success, "ERC721Buyable: transfer failed");
        _transfer(_seller, _msgSender(), _tokenId);

        emit SellOfferAcceptedWETH(_seller, _msgSender(), _tokenId, _price);
    }

    function _hashSellOfferWETH(
        address _from,
        uint256 _tokenId,
        uint256 _deadline,
        uint256 _price
    ) internal view returns (bytes32) {
        return
        _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "SellOfferWETH(address from,uint256 tokenId,uint256 nonce,uint256 deadline,uint256 price)"
                    ),
                    _from,
                    _tokenId,
                    nonces[_from][_tokenId],
                    _deadline,
                    _price
                )
            )
        );
    }

    function sellAcceptingBuyOfferWETH(
        address _buyer,
        uint256 _tokenId,
        uint256 nonce,
        uint256 _deadline,
        uint256 _price,
        bytes memory _sellerSignature
    ) external {
        bytes32 digest = _hashBuyOfferWETH(_buyer, _tokenId, _deadline, _price);
        require(
            _buyer.isValidSignatureNow(digest, _sellerSignature),
            "ERC721Buyable: Invalid signature"
        );
        require(
            block.timestamp < _deadline,
            "ERC721Buyable: signed transaction expired"
        );
        nonces[_buyer][_tokenId]++;
        uint256 tax = (_price * saleTax) / saleTaxDenumerator;
        if (tax > 0) {
            bool _success = paymentToken.transferFrom(_buyer, treasury, tax);
            require(_success, "ERC721Buyable: transfer failed");
        }
        bool _success = paymentToken.transferFrom(_buyer, _msgSender(), _price - tax);
        require(_success, "ERC721Buyable: transfer failed");
        _transfer(_msgSender(), _buyer, _tokenId);

        emit BuyOfferAcceptedWETH(_msgSender(), _buyer, _tokenId, _price);
    }

    function _hashBuyOfferWETH(
        address _to,
        uint256 _tokenId,
        uint256 _deadline,
        uint256 _price
    ) internal view returns (bytes32) {
        return
        _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "BuyOfferWETH(address to,uint256 tokenId,uint256 nonce,uint256 deadline,uint256 price)"
                    ),
                    _to,
                    _tokenId,
                    nonces[_to][_tokenId],
                    _deadline,
                    _price
                )
            )
        );
    }
}