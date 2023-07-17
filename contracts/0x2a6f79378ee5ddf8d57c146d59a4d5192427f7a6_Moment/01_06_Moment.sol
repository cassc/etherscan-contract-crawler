// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 *
 *  |ˉˉˉˉˉˉˉˉˉˉˉ| /ˉˉˉˉˉˉˉˉ\ |ˉˉˉˉˉˉˉˉˉˉˉ||ˉˉˉˉˉˉˉˉˉˉ||ˉˉˉ\    |ˉ||ˉˉˉˉˉˉˉˉˉˉˉ||ˉˉˉˉˉˉˉˉˉˉ\
 *  | |ˉˉ| |ˉˉ| |/ /ˉˉˉˉˉˉ\ \| |ˉˉ| |ˉˉ| || |ˉˉˉˉˉˉˉˉ | |\ \   | | ˉˉˉˉ| |ˉˉˉˉ  ˉˉˉˉˉˉˉˉ| |
 *  | |  | |  | || |      | || |  | |  | ||  ˉˉˉˉˉˉˉˉ|| | \ \  | |     | |     |ˉˉˉˉˉˉˉˉ  /
 *  | |  | |  | || |      | || |  | |  | || |ˉˉˉˉˉˉˉˉ | |  \ \ | |     | |      ˉˉˉˉˉˉˉˉ| \
 *  | |  | |  | |\ \      / /| |  | |  | || |         | |   \ \| |     | |              / |
 *  | |  | |  | | \ ˉˉˉˉˉˉ / | |  | |  | ||  ˉˉˉˉˉˉˉˉ|| |    \ ˉ |     | |     |ˉˉˉˉˉˉˉˉ  /
 *  ˉˉˉ  ˉˉˉ  ˉˉˉ  ˉˉˉˉˉˉˉˉ  ˉˉˉ  ˉˉˉ  ˉˉˉ ˉˉˉˉˉˉˉˉˉˉ  ˉ      ˉˉˉ      ˉˉˉ      ˉˉˉˉˉˉˉˉˉˉ
 *  Every Moment is Non-Fungible.
 *
 */

contract Moment is ERC721A, Ownable {
    uint256 public constant collectionSize = 5555;
    uint256 public perAddressMaxMintAmount = 1;
    bytes32 public allowListMerkleRoot;
    uint256 public allowListStartTime;
    uint256 public allowListEndTime;
    uint256 public publicStartTime;
    string public baseURI;

    constructor(
        bytes32 allowListMerkleRoot_,
        uint256 allowListStartTime_,
        uint256 allowListEndTime_,
        uint256 publicStartTime_,
        string memory baseURI_
    ) ERC721A("The Moment3!", "MOMENT") {
        allowListMerkleRoot = allowListMerkleRoot_;
        allowListStartTime = allowListStartTime_;
        allowListEndTime = allowListEndTime_;
        publicStartTime = publicStartTime_;
        baseURI = baseURI_;
    }

    function mint(
        uint256 amount,
        uint256 allowListTotalAmount,
        bytes32[] calldata allowListMerkleProof
    ) public payable callerIsUser {
        require(amount > 0 && totalMinted() + amount <= collectionSize);
        if (
            block.timestamp >= allowListStartTime &&
            block.timestamp <= allowListEndTime
        ) {
            uint256 allowListRemainAmount = getAllowListRemainAmount(
                msg.sender,
                allowListTotalAmount,
                allowListMerkleProof
            );
            require(allowListRemainAmount == amount);
            _setAux(msg.sender, _getAux(msg.sender) + uint64(amount));
        } else {
            require(block.timestamp >= publicStartTime);
            require(
                numberMinted(msg.sender) + amount <= perAddressMaxMintAmount
            );
        }
        _safeMint(msg.sender, amount);
    }

    function getAllowListRemainAmount(
        address user,
        uint256 allowListTotalAmount,
        bytes32[] calldata allowListMerkleProof
    ) public view returns (uint256) {
        if (allowListTotalAmount <= _getAux(user)) return 0;
        require(
            MerkleProof.verify(
                allowListMerkleProof,
                allowListMerkleRoot,
                keccak256(abi.encodePacked(user, ":", allowListTotalAmount))
            )
        );
        return allowListTotalAmount - _getAux(user);
    }

    function airdrop(address user, uint256 amount) public onlyOwner {
        require(amount > 0 && totalMinted() + amount <= collectionSize);
        _safeMint(user, amount);
    }

    function airdropList(
        address[] calldata userList,
        uint256[] calldata amountList
    ) public onlyOwner {
        require(userList.length == amountList.length);
        for (uint256 i = 0; i < userList.length; i++) {
            airdrop(userList[i], amountList[i]);
        }
    }

    function setConfig(
        uint256 perAddressMaxMintAmount_,
        bytes32 allowListMerkleRoot_,
        uint256 allowListStartTime_,
        uint256 allowListEndTime_,
        uint256 publicStartTime_,
        string calldata baseURI_
    ) public onlyOwner {
        perAddressMaxMintAmount = perAddressMaxMintAmount_;
        allowListMerkleRoot = allowListMerkleRoot_;
        allowListStartTime = allowListStartTime_;
        allowListEndTime = allowListEndTime_;
        publicStartTime = publicStartTime_;
        baseURI = baseURI_;
    }

    function withdraw() public onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success);
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function numberMinted(address user) public view returns (uint256) {
        return _numberMinted(user);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender);
        _;
    }
}