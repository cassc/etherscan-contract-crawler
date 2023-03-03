// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title UnicusWatchNFT
 * @dev ERC721 contract for UnicusWatch NFTs
 * UnicusWatch is a collection of NFTs that represent Collection Watches. Each watch is minted with a unique ID and has a unique set of attributes.
 * The attributes are:
 * 1. Brand - Name
 * 2. Serial No.
 * 3. Model No.
 * 4. Year
 * 5. Case
 * 6. Extras
 * Attributes and Img are stored in IPFS and the hash for the JSON is stored in the contract.
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract UnicusWatchNFT is ERC721, Ownable, IERC721Receiver {
    uint256 public totalSupply;

    mapping(address => bool) public creators;
    mapping(uint256 => string) private _tokenURI;
    mapping(uint256 => address) public tokenCreator;
    mapping(bytes32 => uint) private ipfsToID;
    mapping(uint => address) public mintOwner;

    string public contractURI = "";
    uint public publicFee;

    modifier checkCreator() {
        bool isCreator = creators[msg.sender];
        bool hasValue = msg.value >= publicFee;
        require(isCreator || (publicFee > 0 && hasValue), "UW: Unauthorized");
        _;
    }

    constructor() ERC721("UnicusWatch", "UW") {
        totalSupply = 0;
        creators[msg.sender] = true;
        publicFee = 0.15 ether;
    }

    function mint(
        string memory _uri
    ) public payable checkCreator returns (uint256) {
        // If value is sent, send it to the owner immediately
        if (msg.value > 0) {
            (bool succ, ) = owner().call{value: msg.value}("");
            require(succ, "Transfer failed.");
        }
        totalSupply++;
        uint256 _id = totalSupply;
        bytes32 hash = cidToBytes32(_uri);
        require(ipfsToID[hash] == 0, "UW: CID already exists");
        _tokenURI[_id] = _uri;
        ipfsToID[hash] = _id;
        tokenCreator[_id] = msg.sender;
        _safeMint(address(this), _id);
        return _id;
    }

    function claimMintedToken(uint256 _id) public {
        require(
            mintOwner[_id] == msg.sender && mintOwner[_id] != address(0),
            "UW: Not the owner"
        );
        mintOwner[_id] = address(0);
        _safeTransfer(address(this), msg.sender, _id, "");
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _ownerOf(tokenId);
        if (mintOwner[tokenId] != address(0)) {
            owner = mintOwner[tokenId];
        }
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://";
    }

    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        return string(abi.encodePacked(_baseURI(), _tokenURI[_tokenId]));
    }

    function setPublicFee(uint _fee) public onlyOwner {
        publicFee = _fee;
    }

    function setCreator(address _creator, bool _value) public onlyOwner {
        creators[_creator] = _value;
    }

    function getFees() external onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        (bool succ, ) = msg.sender.call{value: address(this).balance}("");
        require(succ, "Transfer failed.");
    }

    function isValidCid(string memory cid) public view returns (bool) {
        bytes32 hash = cidToBytes32(cid);
        return ipfsToID[hash] > 0;
    }

    function cidToBytes32(string memory cid) private pure returns (bytes32) {
        bytes32 result;
        assembly {
            result := mload(add(cid, 32))
        }
        return result;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata
    ) external override returns (bytes4) {
        require(from == address(0), "UW: only while mint");
        mintOwner[tokenId] = operator;
        return IERC721Receiver.onERC721Received.selector;
    }

    function setContractURI(string memory _uri) public onlyOwner {
        require(bytes(_uri).length > 0, "UW: URI cannot be empty");
        require(bytes(contractURI).length == 0, "UW: Contract URI already set");

        contractURI = _uri;
    }
}