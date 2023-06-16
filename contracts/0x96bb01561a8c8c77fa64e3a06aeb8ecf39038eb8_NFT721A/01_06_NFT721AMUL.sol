// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFT721A is ERC721A, Ownable {
    using SafeMath for uint256;
    address public signer;
    mapping(string => bool) internal nonceMap;
    mapping(address => uint256) internal mintCountMap;
    string public baseUri;
    uint256 public maxCount;
    bool whiteListMintAvailable = false;
    uint256 public whiteListMintPrice = 300000000000000000;
    uint256 public individualWhiteListMintLimit = 1;
    bool mintAvailable = false;
    uint256 public safeMintPrice = 400000000000000000;
    uint256 public mintPrice = 500000000000000000;
    uint256 public individualMintLimit = 2;

    constructor() ERC721A("OHDAT Genesis Pass", "OHDAT-GENESIS-PASS") {}

    //******SET UP******
    function setMaxCount(uint256 _maxCount) public onlyOwner {
        require(_maxCount > 0, "the max id must more than 0!");
        maxCount = _maxCount;
    }

    function setWhiteListMintPrice(uint256 _whiteListMintPrice) public onlyOwner {
        require(_whiteListMintPrice > 0, "the price must more than 0!");
        whiteListMintPrice = _whiteListMintPrice;
    }

    function setSafeMintPrice(uint256 _safeMintPrice) public onlyOwner {
        require(_safeMintPrice > 0, "the price must more than 0!");
        safeMintPrice = _safeMintPrice;
    }


    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        require(_mintPrice > 0, "the price must more than 0!");
        mintPrice = _mintPrice;
    }

    function setSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseUri = _newURI;
    }

    function setWhiteListMintAvailable(bool _whiteListMintAvailable) public onlyOwner {
        whiteListMintAvailable = _whiteListMintAvailable;
    }

    function setMintAvailable(bool _mintAvailable) public onlyOwner {
        mintAvailable = _mintAvailable;
    }

    function setIndividualWhiteListMintLimit(uint256 _individualWhiteListMintLimit) public onlyOwner {
        require(_individualWhiteListMintLimit > 0, "the individual white list mint limit must more than 0!");
        individualWhiteListMintLimit = _individualWhiteListMintLimit;
    }

    function setIndividualMintLimit(uint256 _individualMintLimit) public onlyOwner {
        require(_individualMintLimit > 0, "the individual mint limit must more than 0!");
        individualMintLimit = _individualMintLimit;
    }
    //******END SET UP******

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function whiteListMint(
        uint256 quantity,
        bytes32 hash,
        bytes memory signature,
        uint256 blockHeight,
        string memory nonce
    ) external payable {
        require(whiteListMintAvailable, "White list mint not available!");
        require(quantity > 0, "The quantity must more than 0!");
        require(
            _nextTokenId() + quantity <= maxCount,
            "Not enough stock!"
        );
        require(
            mintCountMap[msg.sender] + quantity <= individualWhiteListMintLimit,
            "You have reached individual white list mint limit!"
        );
        //require(blockHeight >= block.number, "The block has expired!");
        require(!nonceMap[nonce], "Nonce already exist!");
        require(hashMint(quantity, blockHeight, nonce, "ohdat_pass_white_list_mint") == hash, "Invalid hash!");
        require(matchAddressSigner(hash, signature), "Invalid signature!");

        uint256 totalPrice = quantity.mul(whiteListMintPrice);
        require(msg.value >= totalPrice, "Not enough money!");
        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }

        _safeMint(msg.sender, quantity);
        nonceMap[nonce] = true;
        mintCountMap[msg.sender] = mintCountMap[msg.sender] + quantity;
    }

    function safeMint(
        uint256 quantity,
        bytes32 hash,
        bytes memory signature,
        uint256 blockHeight,
        string memory nonce
    ) external payable {
        require(mintAvailable, "Mint not available!");
        require(quantity > 0, "The quantity must more than 0!");
        require(
            _nextTokenId() + quantity <= maxCount,
            "Not enough stock!"
        );
        require(
            mintCountMap[msg.sender] + quantity <= individualMintLimit,
            "You have reached individual safe mint limit!"
        );
        //require(blockHeight >= block.number, "The block has expired!");
        require(!nonceMap[nonce], "Nonce already exist!");
        require(hashMint(quantity, blockHeight, nonce, "ohdat_pass_safe_mint") == hash, "Invalid hash!");
        require(matchAddressSigner(hash, signature), "Invalid signature!");

        uint256 totalPrice = quantity.mul(safeMintPrice);
        require(msg.value >= totalPrice, "Not enough money!");
        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }

        _safeMint(msg.sender, quantity);
        nonceMap[nonce] = true;
        mintCountMap[msg.sender] = mintCountMap[msg.sender] + quantity;
    }

    function mint(uint256 quantity) external payable {
        require(mintAvailable, "Mint not available!");
        require(quantity > 0, "The quantity is less than 0!");
        require(
            _nextTokenId() + quantity <= maxCount,
            "Not enough stock!"
        );
        require(
            mintCountMap[msg.sender] + quantity <= individualMintLimit,
            "You have reached individual mint limit!"
        );

        uint256 totalPrice = quantity.mul(mintPrice);
        require(msg.value >= totalPrice, "Not enough money!");
        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }

        _safeMint(msg.sender, quantity);
        mintCountMap[msg.sender] = mintCountMap[msg.sender] + quantity;
    }

    function airdrop(address to, uint256 quantity) public onlyOwner {
        require(quantity > 0, "The quantity is less than 0!");
        require(
            _nextTokenId() + quantity <= maxCount,
            "The quantity exceeds the stock!"
        );
        _safeMint(to, quantity);
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId, true);
    }

    function hashMint(uint256 quantity, uint256 blockHeight, string memory nonce, string memory code)
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