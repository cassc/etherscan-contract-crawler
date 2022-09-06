// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// Story DAO PRODUCER TOKEN
// come build worlds with us
// storydao.xyz

// decentralizing IP one smart contract at a time

contract StoryDAOProducerToken is ERC1155, Ownable, Pausable {
    // token data
    string public name;
    string public symbol;
    uint256 public PRICE = 0.1 ether;
    uint256 maxSupply = 300;

    // mint mechanics
    bool public publicSaleLive = false;
    uint256 mintedSupply = 0;
    bytes32 public merkleRoot;
    mapping(address => uint256) public mintsPerAddress;
    bool public transferrable = false;
    // mapping(uint256 => uint256) public totalSupply;

    // Story DAO multisig
    address treasuryWallet;

    constructor(string memory _uri, address _treasuryWallet) ERC1155(_uri) {
        name = "StoryDAOProducerToken";
        symbol = "SDP";
        treasuryWallet = _treasuryWallet;
    }

    function mintPublic(bytes32[] calldata _merkleProof) external payable {
        unchecked {
            require(msg.value >= PRICE, "insufficient eth");
            require(mintsPerAddress[msg.sender] == 0, "max mint for user exceeded");
            require(mintedSupply + 1 <= maxSupply, "supply is exceeded");
            require(publicSaleLive, "sale is not live");
        }

        bytes32 merkleLeaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, merkleLeaf), "Invalid proof.");

        unchecked {
            mintsPerAddress[msg.sender] += 1;
            mintedSupply += 1;
        }

        _mint(msg.sender, 0, 1, "");
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    function setCost(uint256 _newCost) public onlyOwner {
        PRICE = _newCost;
    }

    function setSupply(uint256 _newSupply) public onlyOwner {
        maxSupply = _newSupply;
    }

    function setPublicSaleLive(bool _publicSaleLive) public onlyOwner {
        publicSaleLive = _publicSaleLive;
    }

    function setTransferrable(bool _transferrable) public onlyOwner {
        transferrable = _transferrable;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot  = _merkleRoot;
    }

    function setTreasuryWallet(address _treasuryWallet) external onlyOwner {
        treasuryWallet = _treasuryWallet;
    }

    function uri(uint256 _tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(super.uri(_tokenId), Strings.toString(_tokenId)));
    }

    function setUri(string memory _uri) external onlyOwner {
        _setURI(_uri);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function withdraw() external onlyOwner {
        (bool transfer, ) = payable(treasuryWallet).call{value: address(this).balance}("");
        require(transfer);
    }    

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override
    {
        require(from == address(0) || to == address(0) || transferrable, "NonTransferrableERC1155Token: non transferrable");
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}