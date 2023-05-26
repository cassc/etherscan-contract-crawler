// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MFNFT is ERC721A, Ownable {
    using ECDSA for bytes32;

    enum Status {
        Waiting,
        Started
    }

    Status public status;
    address private _signer;
    uint256 public price = 0;

    mapping(uint256 => string) public tokenImageURIs;

    event Minted(address minter, uint256 tokenId);
    event StatusChanged(Status status);
    event PriceChanged(uint256 price);
    event SignerChanged(address signer);

    constructor(address signer) ERC721A("MyFirstNFT", "MFNFT") {
        _signer = signer;
    }

    function _hash(string memory hash) internal pure returns (bytes32) {
        return keccak256(abi.encode(hash));
    }

    function _verify(bytes32 hash, bytes memory token)
        internal
        view
        returns (bool)
    {
        return (_recover(hash, token) == _signer);
    }

    function _recover(bytes32 hash, bytes memory token)
        internal
        pure
        returns (address)
    {
        return hash.toEthSignedMessageHash().recover(token);
    }

    function mint(string calldata imageURI, bytes calldata signature)
        external
        payable
    {
        require(status == Status.Started, "MFNFT: Public mint is not active.");
        require(
            tx.origin == msg.sender,
            "MFNFT: contract is not allowed to mint."
        );
        require(numberMinted(msg.sender) == 0, "MFNFT: The wallet has already minted.");
        require(
            _verify(_hash(imageURI), signature),
            "MFNFT: Invalid signature."
        );

        uint256 currentIndex = _currentIndex;
        _safeMint(msg.sender, 1);
        tokenImageURIs[currentIndex] = imageURI;
        refundIfOver(price);

        emit Minted(msg.sender, currentIndex);
    }

    function refundIfOver(uint256 total) private {
        require(msg.value >= total, "MFNFT: Invalid value.");
        if (msg.value > total) {
            payable(msg.sender).transfer(msg.value - total);
        }
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function setStatus(Status _status) external onlyOwner {
        status = _status;
        emit StatusChanged(status);
    }

    function withdraw(address payable recipient) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "MFNFT: Transfer failed.");
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
        emit PriceChanged(_price);
    }

    function setSigner(address signer) external onlyOwner {
        _signer = signer;
        emit SignerChanged(signer);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        string memory imageURI = tokenImageURIs[tokenId];
        if (bytes(imageURI).length == 0) {
            return "";
        }

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "MFNFT #',
                        Strings.toString(tokenId),
                        '","description": "MyFirstNFT is a non-profit instructional project for Web3 newbies. Get a FREE NFT while learning about Web3, underlying values of NFT, and security principles.",',
                        '"image": "',
                        imageURI,
                        '","attributes": []}'
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }
}