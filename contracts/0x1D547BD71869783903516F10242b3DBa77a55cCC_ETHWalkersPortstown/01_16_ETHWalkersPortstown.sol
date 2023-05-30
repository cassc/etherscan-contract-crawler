// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import './ERC721A.sol';

abstract contract EWALKS is IERC721 {}

contract ETHWalkersPortstown is ERC721A, Ownable, ReentrancyGuard, Pausable {
    using Address for address;
    using Strings for uint256;

    EWALKS private ewalk;
    uint public preSale = 1655316000; // 6/15 at 11am PDT
    uint public publicSale = 1655359200; // 6/15 at 11pm PDT
    uint public endSale = 1655445600; // 6/16 at 11pm PDT
    uint16 public mintedTokenCount = 0;
    string public baseURI;
    mapping(uint256 => bool) walkerRedeemed;
    mapping(address => uint8) numberMinted;
    address public whitelistSigner = 0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC;

    constructor() ERC721A("ETH Walkers Portstown", "EWPortstown") {
        address EwalksAddress = 0x4691b302c37B53c68093f1F5490711d3B0CD2b9C;
        ewalk = EWALKS(EwalksAddress);
    }

    function getMintRedeemed(uint256 _id) public view returns (bool){
        return walkerRedeemed[_id];
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function setSaleTimes(uint[] memory _newTimes) external onlyOwner {
        require(_newTimes.length == 3, "You need to update all times at once");
        preSale = _newTimes[0];
        publicSale = _newTimes[1];
        endSale = _newTimes[2];
    }

    function setSignerAddress(address signer) public onlyOwner {
        whitelistSigner = signer;
    }

    function portstownSeasonOneClaim(uint256[] memory ids) external whenNotPaused {
        // ids is an array of seasonOne tokenIds
        require(block.timestamp >= preSale && block.timestamp <= endSale, "Pre-sale must be started");
        require(!isContract(msg.sender), "I fight for the user! No contracts");

        for(uint i = 0; i < ids.length; i++) {
            require(ewalk.ownerOf(ids[i]) == msg.sender, "Must own a ETH Walker to mint free Portstown");
            require(!walkerRedeemed[ids[i]], "This ETH Walker already redeemed for mint");
            walkerRedeemed[ids[i]] = true;
        }

        _mint(_msgSender(), ids.length);
    }

    //Constants for signing whitelist
    bytes32 constant DOMAIN_SEPERATOR = keccak256(abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256("Signer NFT Distributor"),
        keccak256("1"),
        uint256(1),
        address(0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC)
    ));

    bytes32 constant ENTRY_TYPEHASH = keccak256("Entry(uint256 index,address wallet)");

    function presaleMintETHWalkersPortstown(uint8 numberOfTokens, uint index, bytes memory signature) external whenNotPaused {
        require(block.timestamp >= preSale && block.timestamp <= endSale, "Pre-sale must be started");
        require(numberMinted[_msgSender()] + numberOfTokens <= 4, "Max of 4 ETH Walkers Portstown per wallet");
        require(!isContract(msg.sender), "I fight for the user! No contracts");

        // verify signature
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPERATOR,
            keccak256(abi.encode(
                ENTRY_TYPEHASH,
                index, 
                _msgSender()
            ))
        ));
        address claimSigner = ECDSA.recover(digest, signature);
        require(claimSigner == whitelistSigner, "Invalid Message Signer.");

        _mint(_msgSender(), numberOfTokens);
        numberMinted[_msgSender()] += numberOfTokens;
    }

    function publicMintETHWalkersPortstown(uint8 numberOfTokens) external whenNotPaused {
        require(block.timestamp >= publicSale && block.timestamp <= endSale, "Public sale not started");
        require(numberMinted[_msgSender()] + numberOfTokens <= 4, "Max of 4 ETH Walkers Portstown per wallet");
        require(!isContract(msg.sender), "I fight for the user! No contracts");

        _mint(_msgSender(), numberOfTokens);
        numberMinted[_msgSender()] += numberOfTokens;
        mintedTokenCount = mintedTokenCount + numberOfTokens;
    }

    function isContract(address _addr) private view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            uint256 current_token = 0;
            for (index = 0; index < totalSupply() && current_token < tokenCount; index++) {
                if (ownerOf(index) == _owner){
                    result[current_token] = index;
                    current_token++;
                }
            }
            return result;
        }
    }

}