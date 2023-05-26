// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/d5ca39e9a264ddcadd5742484b6d391ae1647a10/contracts/utils/cryptography/MerkleProof.sol";
import "./library/SafeMath.sol";
import "./interfaces/RAYC.sol";

contract Serum is ERC1155, Ownable, IERC1155Receiver {
    using Strings for uint256;
    using SafeMath for uint256;

    string public name = "Z1 Serum";
    string public symbol = "Z1";
    address public raycAddress;
    address public appointee;
    bytes32 public merkleRoot =
        0x65a05a4c27a2d29465cb0f58076bcb3218d7341d0a420c517a7cfedc82b32b45;

    mapping(uint256 => bool) public claimed;
    mapping(uint256 => address) private ownerships;

    uint256 public claimStart = 1667509200; // 9pm UTC (5pm EST) Nov 3
    uint256 public claimEnd = 1668718800; //  9pm UTC (5pm EST) Nov 17
    uint256 public totalSupply;
    uint256 public burned;
    address public zombiesContractAddress;

    bool private burnDone;
    uint256 private constant maxSupply = 10_000;
    uint256 private constant Z1_SERUM = 0;
    string public baseUri = "ipfs://Qmc6YpE8myy2R8qUyTnBtzEW78nXRdFzKs2Dytf2iGsgT3/";

    function setBaseUri(string calldata _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    constructor(address _raycAddress)
        ERC1155(string(abi.encodePacked(baseUri, "{id}", ".json")))
    {
        raycAddress = _raycAddress;
    }

    function claim(uint256[] calldata ids) public {
        require(!burnDone, "No claims after burn");
        require(tx.origin == msg.sender, "EOAs only");
        require(ids.length < 250, "Too many addresses");
        require(block.timestamp > claimStart, "Patience!");
        require(block.timestamp < claimEnd, "Too late!");

        checkApepesOwned();

        for (uint256 i = 0; i < ids.length; i++) {
            require(
                ownerships[ids[i]] == msg.sender,
                "Can't claim it if you don't own it"
            );
            require(claimed[ids[i]] != true, "Already claimed");
            claimed[ids[i]] = true;
        }

        _mint(msg.sender, Z1_SERUM, ids.length, abi.encodePacked(""));
        totalSupply += ids.length;
    }

    function claimForPrevious(
        bytes32[] calldata _merkleProof,
        address _recipient,
        uint256 _amount,
        uint256[] calldata _ids
    ) public {
        require(msg.sender == appointee, "Not allowed");
        require(_ids.length == _amount, "Length of ids is wrong");
        bytes32 leaf = keccak256(abi.encodePacked(_recipient, _amount, _ids));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid proof."
        );

        for (uint256 i = 0; i < _ids.length; i++) {
            require(claimed[_ids[i]] != true, "Already claimed");
            claimed[_ids[i]] = true;
        }

        _mint(_recipient, Z1_SERUM, _ids.length, abi.encodePacked(""));
        totalSupply += _ids.length;
    }

    function setAppointee(address _address) public onlyOwner {
        appointee = _address;
    }

    function burnRemaining() public onlyOwner {
        require(!burnDone, "Already burned.");

        uint256 remaining = maxSupply - totalSupply;
        burned = remaining;

        _mint(
            address(this),
            Z1_SERUM,
            remaining,
            abi.encodePacked("burn,baby,burn")
        );
        _burn(address(this), Z1_SERUM, remaining);
        burnDone = true;
    }

    function burn(address _address, uint256 _amount) public {
        require(
            msg.sender == zombiesContractAddress,
            "Not authorized to burn."
        );
        _burn(_address, Z1_SERUM, _amount);
        totalSupply = totalSupply - _amount;
    }

    function setMerkleRoot(bytes32 _root) public onlyOwner {
        merkleRoot = _root;
    }

    function setClaimStart(uint256 _claimStart) public onlyOwner {
        claimStart = _claimStart;
    }

    function setClaimEnd(uint256 _claimEnd) public onlyOwner {
        claimEnd = _claimEnd;
    }

    function checkApepesOwned() private {
        IRAYC rayc = IRAYC(raycAddress);
        uint256[] memory walletOfSender = rayc.walletOfOwner(msg.sender);
        for (uint256 i = 0; i < walletOfSender.length; i++) {
            ownerships[walletOfSender[i]] = msg.sender;
        }
    }

    function uri(uint256 _id) public view override returns (string memory) {
        require(_id == Z1_SERUM, "Type not recognized");
        return string(abi.encodePacked(baseUri, Z1_SERUM.toString(), ".json"));
    }

    function setZombiesContract(address _address) public onlyOwner {
        zombiesContractAddress = _address;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }
}