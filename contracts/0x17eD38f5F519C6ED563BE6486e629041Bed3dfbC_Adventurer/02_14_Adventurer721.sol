// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title Adventurer ERC721Tradable
 * ERC721Tradable - ERC721 contract that whitelists a trading address, and has minting functionality, merkel root setting and token meta randomisation
 */
abstract contract Adventurer721 is ERC721, Ownable {
    using Address for address;
    using ECDSA for bytes32;

    // Supply Variables (e.g. 7500 - max inc bebes,14,0,5000,0 )
    uint256 public maxSupply;
    uint256 private fixedSupply;
    uint256 public currentSupply;
    uint256 public maxGenCount;
    uint256 public gen2Count;

    // Sale State Variables
    bool public presaleActive;
    bool public saleActive;
    uint256 public startSaleTimestamp;

    uint256 public price = 0.125 ether;
    address public whitelistAdmin;

    mapping(address => bool) public mintedList;
    mapping(address => bool) public publicMintedList;

    // Meta randomisation
    uint256 private metaoffset = 10000;
    bool public hashlocked;
    string public _merkelroot = "0";

    string private baseURI;
    string private contURI;

    constructor(
        string memory _name,
        string memory _symbol,
        address _whitelistAdmin,
        uint256 supply,
        uint256 genCount,
        uint256 fixSupply,
        uint256 pubStart
    ) ERC721(_name, _symbol) {
        maxSupply = supply;
        maxGenCount = genCount;
        fixedSupply = fixSupply;
        whitelistAdmin = _whitelistAdmin;
        currentSupply = 0;
        startSaleTimestamp = pubStart;
    }

    /** *********************************** **/
    /** ********* Internal Functions ****** **/
    /** *********************************** **/
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /** *********************************** **/
    /** ********* Minting Functions ******* **/
    /** *********************************** **/
    function mintLeg() public onlyOwner {
        require(currentSupply < fixedSupply, "Legendaries already minted.");
        for (uint256 i = 1; i <= fixedSupply; i++) {
            _safeMint(msg.sender, currentSupply + 1);
            currentSupply++;
        }
    }

    function _isvalidsig(
        bytes32 data,
        bytes memory signature,
        address signerAddress
    ) private pure returns (bool) {
        return
            data.toEthSignedMessageHash().recover(signature) == signerAddress;
    }

    function mintPresale(
        address _contractAddress,
        uint256 _vol,
        uint256 _expiry,
        uint256 _option,
        bytes memory _signature
    ) external payable {
        require(presaleActive, "Presale must be active to mint");
        require(
            currentSupply + _vol <= maxGenCount,
            "Purchase would exceed max supply of Genesis Adventurers"
        );
        require(mintedList[msg.sender] == false, "You have already minted");
        require(tx.origin == msg.sender, "Contracts not allowed");
        require(
            _isvalidsig(
                keccak256(
                    abi.encodePacked(
                        _contractAddress,
                        msg.sender,
                        _vol,
                        _expiry,
                        _option
                    )
                ),
                _signature,
                whitelistAdmin
            ),
            "Signature was not valid"
        );
        if (_option != 0) {
            require(
                price * _vol == msg.value,
                "Ether value sent is not correct"
            );
        }

        mintedList[msg.sender] = true;
        // we are 1 indexing, not zero
        for (uint256 i = 1; i <= _vol; i++) {
            _safeMint(msg.sender, currentSupply + 1);
            currentSupply++;
        }
    }

    function mint() external payable {
        require(saleActive, "Public sale must be active to mint");
        require(
            block.timestamp >= startSaleTimestamp,
            "Public sale has not started"
        );
        require(
            publicMintedList[msg.sender] == false,
            "You have already minted"
        );
        require(
            currentSupply < maxGenCount,
            "Purchase would exceed max supply of Genesis Adventurers"
        );
        require(price == msg.value, "Ether value sent is not correct");
        require(tx.origin == msg.sender, "Contracts not allowed");
        require(isContract(msg.sender) == false, "Cannot mint from a contract");
        publicMintedList[msg.sender] = true;
        _safeMint(msg.sender, currentSupply + 1);
        currentSupply++;
    }

    function tokensOfOwner(
        address _owner,
        uint256 startId,
        uint256 endId
    ) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;

            for (uint256 tokenId = startId; tokenId < endId; tokenId++) {
                if (index == tokenCount) break;

                if (ownerOf(tokenId) == _owner) {
                    result[index] = tokenId;
                    index++;
                }
            }

            return result;
        }
    }

    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        return _owners[tokenId];
    }

    function walletOfOwner(address address_)
        external
        view
        returns (uint256[] memory)
    {
        uint256 _balance = balanceOf(address_);
        if (_balance == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory _tokens = new uint256[](_balance);
            uint256 _index;

            for (uint256 i = 0; i < maxSupply; i++) {
                if (address_ == ownerOf(i)) {
                    _tokens[_index] = i;
                    _index++;
                }
            }

            return _tokens;
        }
    }

    /** *********************************** **/
    /** ********* Owner Functions ********* **/
    /** *********************************** **/

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function togglePresale() public onlyOwner {
        presaleActive = !presaleActive;
    }

    function toggleSale() public onlyOwner {
        saleActive = !saleActive;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        price = (1 ether * newPrice) / 100;
    }

    // generate random offset for token metadata URI
    function setRandomMetaOffset() public onlyOwner {
        require(metaoffset == 10000, "Offset already randomised.");
        require(
            hashlocked == true,
            "Merkelroot hash of metadata has not been set"
        );
        uint256 number = uint256(
            keccak256(
                abi.encodePacked(
                    blockhash(block.number - 1),
                    block.coinbase,
                    block.difficulty
                )
            )
        );
        metaoffset = number % maxGenCount;
    }

    // set root hash of merkel tree for metadata
    function setMerkelRoot(string memory _roothash) public onlyOwner {
        require(hashlocked == false, "Merkel is already set");
        _merkelroot = _roothash;
        hashlocked = true;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setContractURI(string memory uri) public onlyOwner {
        contURI = uri;
    }

    /** *********************************** **/
    /** ********* View Functions ********* **/
    /** *********************************** **/

    function totalSupply() public view returns (uint256) {
        return currentSupply;
    }

    function getOffset() external view returns (uint256) {
        return metaoffset;
    }

    function getMerkelRoot() external view returns (string memory) {
        return _merkelroot;
    }

    //base url for returning info about an individual adventurer
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    //base url for returning info about the token collection contract
    function contractURI() external view returns (string memory) {
        return contURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        uint256 offsetid = _tokenId;
        if ((_tokenId > fixedSupply) && (_tokenId <= maxGenCount)) {
            offsetid = _tokenId + metaoffset;
            if (metaoffset != 10000) {
                if (offsetid > maxGenCount) {
                    offsetid = offsetid - maxGenCount;
                }
            }
        }
        return string(abi.encodePacked(_baseURI(), Strings.toString(offsetid)));
    }
}