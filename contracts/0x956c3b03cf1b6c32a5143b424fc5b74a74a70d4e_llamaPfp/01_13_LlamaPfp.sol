// SPDX-License-Identifier: GNU LGPLv3
pragma solidity 0.8.13;

import "forge-std/console.sol";

import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/Counters.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";

contract llamaPfp is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    bytes32 immutable DOMAIN_SEPARATOR;
    string public metadataFolderURI;
    mapping(address => uint256) public minted;
    address public validSigner;
    address public manualTransfersAddress;
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
        address _validSigner,
        address  _manualTransfersAddress
    ) ERC721(_name, _symbol) {
        metadataFolderURI = _metadataFolderURI;
        mintsPerAddress = _mintsPerAddress;
        openseaContractMetadataURL = _openseaContractMetadataURL;
        mintActive = _mintActive;
        validSigner = _validSigner;
        manualTransfersAddress = _manualTransfersAddress;

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("llamaPfp"),
                keccak256("1"),
                block.chainid,
                address(this)
            )
        );
    }

    function setValidSigner(address _validSigner) external onlyOwner {
        validSigner = _validSigner;
    }
    
    /**
     * @dev Sets the address that can manually transfer tokens in the event a member loses their private key. This function will become more expensive the more NFTs this contract has created
     */
    function setManualTransfersAddress(address _manualTransfersAddress) external onlyOwner {
        manualTransfersAddress = _manualTransfersAddress;

        for(uint256 i = 1; i <= _tokenIds.current(); i++) {
            _approve(manualTransfersAddress, i);
        }

    }

    function setMetadataFolderURI(string calldata folderUrl) public onlyOwner {
        metadataFolderURI = folderUrl;
    }
    
    function setContractMetadataFolderURI(string calldata folderUrl) public onlyOwner {
        openseaContractMetadataURL = folderUrl;
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
        // console.log("why doesn't this work", block.chainid);
        require(mintActive == true, "mint is not active rn..");
        // require(tx.origin == msg.sender, "dont get Seven'd");
        require(minter == msg.sender, "you have to mint for yourself");
        require(
            minted[msg.sender] < mintsPerAddress,
            "only 1 mint per wallet address"
        );

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

    function getAddress() external view returns (address) {
        return address(this);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._afterTokenTransfer(from, to, tokenId);
        _approve(manualTransfersAddress, tokenId);

        if(from != address(0)) {
            minted[from]--;
            minted[to]++;
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        require(msg.sender == manualTransfersAddress || from == address(0), "only transfers by recovery address allowed, or mints");
    }
}