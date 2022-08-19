// SPDX-License-Identifier: GNU LGPLv3
pragma solidity 0.8.13;

import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/Counters.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";

contract whitehat is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    bytes32 immutable DOMAIN_SEPARATOR;
    string public metadataFolderURI;
    mapping(address => uint256) public minted;
    uint256 public constant price = 0.0 ether;
    address public validSigner;
    bool public mintActive;
    uint256 public mintsPerAddress;
    string public openseaContractMetadataURL;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _metadataFolderURI,
        uint256 _mintsPerAddress,
        string memory _openseaContractMetadataURL,
        bool _mintActive,
        address _validSigner
    ) ERC721(_name, _symbol) {
        metadataFolderURI = _metadataFolderURI;
        mintsPerAddress = _mintsPerAddress;
        openseaContractMetadataURL = _openseaContractMetadataURL;
        mintActive = _mintActive;
        validSigner = _validSigner;

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("Metagame Nomad Whitehat"),
                keccak256("1"),
                block.chainid,
                address(this)
            )
        );
    }

    function setValidSigner(address _validSigner) external onlyOwner {
        validSigner = _validSigner;
    }

    function setMetadataFolderURI(string calldata folderUrl) public onlyOwner {
        metadataFolderURI = folderUrl;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI query for nonexistent token"
        );
        return
            string(
                abi.encodePacked(metadataFolderURI, Strings.toString(tokenId))
            );
    }

    function contractURI() public view returns (string memory) {
        return openseaContractMetadataURL;
    }

    function mintWithSignature(
        address minter,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public payable returns (uint256) {
        require(mintActive == true, "mint is not active rn..");
        // require(tx.origin == msg.sender, "dont get Seven'd");
        require(minter == msg.sender, "you have to mint for yourself");
        require(
            minted[msg.sender] < mintsPerAddress,
            "only 1 mint per wallet address"
        );

        require(msg.value == price, "This mint is free");
        

        bytes32 payloadHash = keccak256(abi.encode(DOMAIN_SEPARATOR, minter));
        bytes32 messageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", payloadHash)
        );

        address actualSigner = ecrecover(messageHash, v, r, s);

        require(actualSigner != address(0), "ECDSA: invalid signature");
        require(actualSigner == validSigner, "Invalid signer");

        _tokenIds.increment();

        minted[msg.sender]++;

        uint256 tokenId = _tokenIds.current();
        _safeMint(msg.sender, tokenId);
        return tokenId;
    }

    function mintedCount() external view returns (uint256) {
        return _tokenIds.current();
    }

    function setMintActive(bool _mintActive) public onlyOwner {
        mintActive = _mintActive;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function pay(address payee, uint256 amountInEth) public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance >= amountInEth, "We dont have that much to pay!");
        payable(payee).transfer(amountInEth);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getAddress() external view returns (address) {
        return address(this);
    }
}