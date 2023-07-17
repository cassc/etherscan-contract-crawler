// SPDX-License-Identifier: Do whatever you want
pragma solidity ^0.8.13;

// import {ERC1155} from "solmate/tokens/ERC1155.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {Strings} from "openzeppelin/utils/Strings.sol";
import {Ownable} from "openzeppelin/access/Ownable.sol";
import {MerkleProof} from "openzeppelin/utils/cryptography/MerkleProof.sol";
import {ERC1155Receiver} from "openzeppelin/token/ERC1155/utils/ERC1155Receiver.sol";
import {INameWrapper} from "./INameWrapper.sol";

contract ENSHood is Ownable, ERC1155Receiver {
    using SafeTransferLib for address payable;

    // for airdrop
    bytes32 private _walletsRoot;
    bytes32 private _namesRoot;

    INameWrapper public nameWrapper;
    address public resolver;

    bytes32 public parentNode;

    uint256 public pricePerTree = 0.001 ether; // ~$2 per tree @ $1900 eth

    address payable public nonProfit;
    uint256 public nonProfitEarnings;

    uint256 public constant RESOLUTION = 1000000000000000; // to not forget multiplier when passing lat longs to plant tree events

    struct SellMetadata {
        address owner;
        uint256 id;
        uint256 price;
        string subdomain;
    }

    mapping(uint256 => SellMetadata) public sellData;
    mapping(address => bool) public userClaimed;
    mapping(string => bool) public domainClaimed;

    event TreePlanted(
        uint256 indexed fromId,
        int256 lat,
        int256 long,
        uint256 qty
    );
    event Sold(uint256 indexed id, uint256 price);
    event Listed(address indexed owner, uint256 indexed id, uint256 price);
    event CancelListing(uint256 indexed id);

    constructor(
        INameWrapper _nameWrapper,
        bytes32 _parentId,
        bytes32 walletsRoot,
        bytes32 namesRoot,
        address _resolver
    ) {
        nameWrapper = _nameWrapper;
        parentNode = _parentId;
        _walletsRoot = walletsRoot;
        _namesRoot = namesRoot;
        resolver = _resolver;
    }

    // AIRDROP()

    function claim(
        string memory subdomain,
        bytes32[] memory walletProof,
        bytes32[] memory nameProof
    ) external {
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(msg.sender)))
        );
        bytes32 nameLeaf = keccak256(
            bytes.concat(keccak256(abi.encode(subdomain)))
        );

        // check is valid wallet
        require(
            MerkleProof.verify(walletProof, _walletsRoot, leaf),
            "Invalid wallet proof"
        );

        // check is valid domain
        require(
            MerkleProof.verify(nameProof, _namesRoot, nameLeaf),
            "Invalid name proof"
        );

        require(!userClaimed[msg.sender], "already claimed");
        require(!domainClaimed[subdomain], "already claimed");

        userClaimed[msg.sender] = true;
        domainClaimed[subdomain] = true;

        nameWrapper.setSubnodeRecord(
            parentNode, //parentNode
            subdomain, //name
            msg.sender, //new owner
            resolver, //resolver
            0, //ttl
            0, //fuses
            0 //expiry0
        );
    }

    // METHODS()

    function list(uint256 id, uint256 price, string memory subdomain) external {
        require(isValidDomain(id, subdomain), "not valid domain");

        nameWrapper.safeTransferFrom(msg.sender, address(this), id, 1, "");

        sellData[id] = SellMetadata({
            owner: msg.sender,
            id: id,
            price: price,
            subdomain: subdomain
        });

        emit Listed(msg.sender, id, price);
    }

    function buy(uint256 id) external payable {
        SellMetadata memory sellMetadata = sellData[id];
        require(msg.value >= sellMetadata.price, "wrong price");

        nameWrapper.safeTransferFrom(address(this), msg.sender, id, 1, "");

        emit Sold(id, sellMetadata.price);

        // payments
        uint256 fees = msg.value / 10;
        payable(sellMetadata.owner).safeTransferETH(msg.value - fees);

        payable(getHoodBoss(sellMetadata.subdomain)).safeTransferETH(fees / 2);

        delete sellData[id];
    }

    function cancelListing(uint256 id) external {
        SellMetadata memory sellMetadata = sellData[id];
        require(sellMetadata.owner == msg.sender);
        nameWrapper.safeTransferFrom(address(this), msg.sender, id, 1, "");

        delete sellData[id];

        emit CancelListing(id);
    }

    function plantTree(
        uint256 fromId,
        uint256 qty,
        int256 lat,
        int256 long
    ) external payable {
        require(msg.value >= (qty * pricePerTree));

        nonProfitEarnings = nonProfitEarnings + msg.value;

        // emit event to create leadaerboard off chain. whitelist for new land claims based on rules that can also change if a community forms
        emit TreePlanted(fromId, lat, long, qty);
    }

    function withdrawEth() external {
        uint256 toNonProfit = nonProfitEarnings;
        nonProfitEarnings = 0;

        payable(nonProfit).safeTransferETH(toNonProfit);

        payable(owner()).safeTransferETH(address(this).balance);
    }

    function _removeUnicode(
        string memory str
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory resultBytes = new bytes(strBytes.length);
        uint256 resultIndex = 0;

        for (uint256 i = 0; i < strBytes.length; i++) {
            if (uint8(strBytes[i]) < 128) {
                resultBytes[resultIndex] = strBytes[i];
                resultIndex++;
            }
        }

        bytes memory result = new bytes(resultIndex);
        for (uint256 i = 0; i < resultIndex; i++) {
            result[i] = resultBytes[i];
        }

        return string(result);
    }

    function _getHash(string memory label) internal pure returns (bytes32) {
        bytes32 labelhash = keccak256(bytes(label));
        return labelhash;
    }

    function _getNode(bytes32 labelhash) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(parentNode, labelhash));
    }

    // GETTERS()

    function getHoodBoss(
        string memory domain
    ) public view returns (address payable) {
        string memory bossDomain = _removeUnicode(domain);

        uint256 id = domainToId(bossDomain);

        return payable(nameWrapper.ownerOf(id));
    }

    // we check if passed domain belongs to the parent enshood.eth
    function isValidDomain(
        uint256 id,
        string memory subdomain
    ) public view returns (bool) {
        return domainToId(subdomain) == id;
    }

    // returns name of a domain based on nft id
    function idToName(uint256 id) public view returns (string memory) {
        bytes memory _id = abi.encodePacked(id);

        bytes memory nameBytes = nameWrapper.names(bytes32(_id));

        return string(nameBytes);
    }

    function domainToId(string memory domain) public view returns (uint256) {
        bytes32 labelhash = _getHash(domain);

        bytes32 node = _getNode(labelhash);
        return uint256(node);
    }

    function isListed(uint256 id) external view returns (bool) {
        SellMetadata memory sellMetadata = sellData[id];

        return sellMetadata.price > 0;
    }

    function roadmap() external pure returns (string memory) {
        return
            "Airdrop. No roadmap. No promises. Project is completed. Dev dead.";
    }

    // ADMIN()
    function setNonProfit(address payable _nonProfit) external onlyOwner {
        nonProfit = _nonProfit;
    }

    // withdraw parent for future city creation airdrop contracts based on tree planting leaderboard
    function withdrawENS() external onlyOwner {
        nameWrapper.safeTransferFrom(
            address(this),
            owner(),
            uint256(parentNode),
            1,
            ""
        );
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public pure returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"
                )
            );
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }

    receive() external payable {}
}