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
    bool mintAvailable = false;
    string public baseUri;
    uint256 public maxCount = 7777;
    uint256 public firstPrice = 20000000000000000;
    uint256 public lastPrice = 30000000000000000;
    uint256 public individualMintLimit = 3;
    uint256 public separateLine = 4500;

    constructor() ERC721A("XIA ONE", "XIA ONE") {}

    //******SET UP******
    function setMaxCount(uint256 _maxCount) public onlyOwner {
        require(_maxCount > 0, "the max id must more than 0!");
        maxCount = _maxCount;
    }

    function setSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseUri = _newURI;
    }

    function setFirstPrice(uint256 _firstPrice) public onlyOwner {
        require(_firstPrice > 0, "the price must more than 0!");
        firstPrice = _firstPrice;
    }

    function setLastPrice(uint256 _lastPrice) public onlyOwner {
        require(_lastPrice > 0, "the price must more than 0!");
        lastPrice = _lastPrice;
    }

    function setIndividualMintLimit(uint256 _individualMintLimit) public onlyOwner {
        require(_individualMintLimit > 0, "the individual mint limit must more than 0!");
        individualMintLimit = _individualMintLimit;
    }

    function setMintAvailable(bool _mintAvailable) public onlyOwner {
        mintAvailable = _mintAvailable;
    }

    function setSeparateLine(uint256 _separateLine) public onlyOwner {
        separateLine = _separateLine;
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
        require(mintAvailable, "Mint not available!");
        require(quantity > 0, "The quantity must more than 0!");
        uint256 nextId = _nextTokenId();
        require(
            nextId + quantity <= maxCount,
            "Not enough stock!"
        );
        require(
            mintCountMap[msg.sender] + quantity <= individualMintLimit,
            "You have reached individual mint limit!"
        );
        //require(blockHeight >= block.number, "The block has expired!");
        require(!nonceMap[nonce], "Nonce already exist!");
        require(hashMint(quantity, blockHeight, nonce, "xia_one_white_list_mint") == hash, "Invalid hash!");
        require(matchAddressSigner(hash, signature), "Invalid signature!");

        uint256 freeQuantity = 0;
        uint256 totalPrice;
        if (mintCountMap[msg.sender] == 0) {
            freeQuantity = 1;
        }
        if (nextId >= separateLine) {
            totalPrice = lastPrice * (quantity - freeQuantity);
        } else {
            if (nextId + quantity <= separateLine) {
                totalPrice = firstPrice * (quantity - freeQuantity);
            } else {
                totalPrice = lastPrice * quantity - (separateLine - nextId) * (lastPrice - firstPrice) - firstPrice * freeQuantity;
            }
        }
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
        uint256 nextId = _nextTokenId();
        require(
            nextId + quantity <= maxCount,
            "Not enough stock!"
        );
        require(
            mintCountMap[msg.sender] + quantity <= individualMintLimit,
            "You have reached individual mint limit!"
        );

        uint256 totalPrice;
        if (nextId >= separateLine) {
            totalPrice = lastPrice * quantity;
        } else {
            if (nextId + quantity <= separateLine) {
                totalPrice = firstPrice * quantity;
            } else {
                totalPrice = lastPrice * quantity - (separateLine - nextId) * (lastPrice - firstPrice);
            }
        }

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