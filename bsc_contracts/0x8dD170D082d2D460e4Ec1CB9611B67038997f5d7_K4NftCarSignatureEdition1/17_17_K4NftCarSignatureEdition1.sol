// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract K4NftCarSignatureEdition1 is
    ERC721,
    Ownable,
    ReentrancyGuard
{
    uint256 private constant NFTTOTALSUPPLY = 1000 ;
    bool public isSaleActive = true;
    uint256 private constant _CONTRACTID = 11;

    event NFTMinted(
        address _from,
        uint256 indexed _tokenId,
        uint256 indexed _quantity,
        bool _success,
        uint256 _contractID
    );
    event TokenTransfered(
        address _token,
        address _from,
        address _to,
        uint256 indexed _amount
    );

    mapping(bytes => bool) private signatureUsed;

    constructor()
        ERC721("K4 Signature Edition #1 - Christof Klausner Memorial", "K4CARSE")
    {}

    function contractURI() public pure returns (string memory) {
        return "https://game.k4rally.io/nft/car/11/";
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://game.k4rally.io/nft/car/11/";
    }

    function safeMintUsingEther(
        uint256[] memory tokenId,
        uint256 quantity,
        bytes32 hash,
        bytes memory signature
    ) public payable nonReentrant {
        require(quantity <= 10, "Cannot buy more than 10 nfts");
        require(quantity != 0, "Insufficient quantity");
        require(isSaleActive, "Sale Inactive");
        require(msg.value != 0, "Insufficient amount");
        require(
            recoverSigner(hash, signature) == owner(),
            "Address is not authorized"
        );
        require(!signatureUsed[signature], "Already signature used");
        require(
            tokenId.length == quantity,
            "Invalid parameters"
        );
        for (uint i = 0; i < quantity; i++) {
            if(tokenId[i] <= NFTTOTALSUPPLY && !_exists(tokenId[i])){
                _safeMint(msg.sender, tokenId[i]);
                emit NFTMinted(msg.sender, tokenId[i], quantity, true,_CONTRACTID);
            }
            else{
                emit NFTMinted(msg.sender, tokenId[i], quantity, false,_CONTRACTID);
            }
        }
        signatureUsed[signature] = true;
    }

    function safeMintUsingToken(
        uint256[] memory tokenId,
        address tokenAddress,
        uint256 amount,
        uint256 quantity,
        bytes32 hash,
        bytes memory signature
    ) public {
        require(quantity <= 10, "Cannot buy more than 10 nfts");
        require(quantity != 0, "Insufficient quantity");
        require(isSaleActive, "Sale Inactive");
        require(amount != 0, "Insufficient amount");
        require(tokenAddress != address(0), "Address cannot be zero");
        require(
            recoverSigner(hash, signature) == owner(),
            "Address is not authorized"
        );
        require(!signatureUsed[signature], "Already signature used");
        require(
            tokenId.length == quantity,
            "Invalid parameter"
        );
        IERC20 token;
        token = IERC20(tokenAddress);
        require(token.allowance(msg.sender, address(this)) >= amount, "Check the token allowance");
        for (uint i = 0; i < quantity; i++) {
            if(tokenId[i] <= NFTTOTALSUPPLY && !_exists(tokenId[i])){
                _safeMint(msg.sender, tokenId[i]);
                emit NFTMinted(msg.sender, tokenId[i], quantity, true,_CONTRACTID);
            }
            else{
                emit NFTMinted(msg.sender, tokenId[i], quantity, false,_CONTRACTID);
            }
        }
        signatureUsed[signature] = true;
        emit TokenTransfered(
            tokenAddress,
            msg.sender,
            address(this),
            amount
        );
        SafeERC20.safeTransferFrom(
            token,
            msg.sender,
            address(this),
            amount
        );
    }

    function withdraw(address payable recipient) public onlyOwner {
        require(recipient != address(0), "Address cannot be zero");
        recipient.transfer(address(this).balance);
    }

    function withdrawToken(address tokenAddress, address recipient) public onlyOwner {
        require(recipient != address(0), "Address cannot be zero");
        IERC20 token;
        token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) > 0, "Insufficient balance");
        SafeERC20.safeTransfer(
            token,
            recipient,
            token.balanceOf(address(this))
        );
    }

    function flipSaleStatus() public onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function recoverSigner(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        bytes32 messageDigest = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
        return ECDSA.recover(messageDigest, signature);
    }
}