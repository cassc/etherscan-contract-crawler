// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Gift is ERC1155, Ownable, Pausable, ReentrancyGuard {
    string public name;
    string public symbol;

    uint256 public currentGoldAmount = 0;
    uint256 public currentSilverAmount = 0;
    uint256 public currentBronzeAmount = 0;

    uint256 public constant goldMaxSupply = 17;
    uint256 public constant silverMaxSupply = 87;
    uint256 public constant bronzeMaxSupply = 1809;

    // Mapping from address to nft hold amount
    mapping(address => uint256) public currentSupply;
    mapping(address => bool) public holderClaimed;

    string public baseUri;

    bytes32 public goldRoot =
        0x700a10cfe7b7da28297f3a9f1142446d56a8b52f2ccdf00f92abe42de762bbbb;
    bytes32 public silverRoot =
        0x568f6ee65a6487eec8c8a9eb83c3c3e3bd731ba1294bdb143ec2c0ddde277fdc;
    bytes32 public bronzeRoot =
        0x2f1a32d59e478d25425b73eda60bbce9151de6044e824b004d0d3e61c29921e7;

    constructor()
        ERC1155(
            "https://ipfs.io/ipfs/QmavUmHohT97suJ5oMDSVhCCjx2qMg3uKLjTfiF2kEg5Ys/{id}.json"
        )
    {}

    // check msg.sender hold nft and returns level of msg.sender
    function checkNftHolder(bytes32[] calldata _merkleProof)
        public
        view
        returns (uint256)
    {
        //Basic data validation to ensure the wallet hasn't already claimed.
        require(!holderClaimed[msg.sender], "Address has already claimed");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (MerkleProof.verify(_merkleProof, goldRoot, leaf)) {
            return 1;
        } else if (MerkleProof.verify(_merkleProof, silverRoot, leaf)) {
            return 2;
        } else if (MerkleProof.verify(_merkleProof, bronzeRoot, leaf)) {
            return 3;
        }
        return 0;
    }

    function mint(bytes32[] calldata _merkleProof)
        public
        payable
        whenNotPaused
        nonReentrant
    {
        require(checkNftHolder(_merkleProof) != 0, "Not a Holder!");

        //checking msg.sender is a nft holder If so get hold amount

        if (checkNftHolder(_merkleProof) == 1) {
            require(currentGoldAmount < goldMaxSupply, "Gold Gift Supply");
            currentGoldAmount += 1;
            currentSupply[msg.sender] = 1;
            _mint(msg.sender, 1, 1, "");
            holderClaimed[msg.sender] = true;
        } else if (checkNftHolder(_merkleProof) == 2) {
            require(
                currentSilverAmount < silverMaxSupply,
                "Silver Gift Supply"
            );
            currentSilverAmount += 1;
            currentSupply[msg.sender] = 2;
            _mint(msg.sender, 2, 1, "");
            holderClaimed[msg.sender] = true;
        } else if (checkNftHolder(_merkleProof) == 3) {
            require(
                currentBronzeAmount < bronzeMaxSupply,
                "Brozne Gift Supply"
            );
            currentBronzeAmount += 1;
            currentSupply[msg.sender] = 3;
            _mint(msg.sender, 3, 1, "");
            holderClaimed[msg.sender] = true;
        }
    }

    function burn(address account, uint256 _id) public onlyOwner {
        _burn(account, _id, 1);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // Allow owner to update the base URI
    function setBaseUri(string memory _newUri) public onlyOwner {
        baseUri = _newUri;
    }

    function setURI(string memory _uri) external onlyOwner {
        _setURI(_uri);
    }

    function baseURI(uint256 _tokenID) public pure returns (string memory) {
        return uri(_tokenID);
    }

    function uri(uint256 _tokenid)
        public
        pure
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "https://ipfs.io/ipfs/QmavUmHohT97suJ5oMDSVhCCjx2qMg3uKLjTfiF2kEg5Ys/",
                    Strings.toString(_tokenid),
                    ".json"
                )
            );
    }

    function withdraw() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Balance must be positive");
        address payable to = payable(msg.sender);
        to.transfer(balance);
    }

    function TransferOwnership(address newOwner) public onlyOwner {
        transferOwnership(newOwner);
    }
}