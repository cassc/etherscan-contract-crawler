// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract HDPass is ERC1155, Ownable, ERC1155Supply {
    // checks if address redeemed
    mapping(address => bool) public hasRedeemed;

    string public uriSuffix = ".json";
    string public uriPrefix = "";

    string public name = "HD Pass";
    string public symbol = "HDPass";

    uint256 public minted;
    string private baseURI;

    // minting
    bool public mintActive;

    // whitelist of addresses that can mint tokens
    bytes32 public whitelistMerkle =
        0x4cbabb208100577bdfdbda280f89eaaca23c709113398405b3085f54714a83b2;

    constructor(string memory _IPFSURL, string memory _prefix) ERC1155("") {
        baseURI = string(abi.encodePacked(_prefix, _IPFSURL, "/"));
        // set prefix
        uriPrefix = _prefix;
        // deployer minting 1
        _mint(msg.sender, 1, 1, "0");
        minted = 1;
    }

    // Owner functions
    function updateBaseURI(string calldata base) external onlyOwner {
        baseURI = string(abi.encodePacked(uriPrefix, base, "/"));
    }

    function setWhitelistMerkle(bytes32 _merkleRoot) public onlyOwner {
        whitelistMerkle = _merkleRoot;
    }

    /// @notice Start/Stop free mint
    function setMintStatus(bool _status) public onlyOwner {
        mintActive = _status;
    }

    /// @notice Set NFT Prefix
    function setPrefix(string memory _prefix) public onlyOwner {
        uriPrefix = _prefix;
    }

    /// @notice Set NFT Suffix
    function setSuffix(string memory _suffix) public onlyOwner {
        uriSuffix = _suffix;
    }

    /// @notice Check whitelist wallet
    function checkWhitelist(bytes32[] calldata _merkleProof, address _address)
        public
        view
        returns (bool)
    {
        // check if whitelisted
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        return MerkleProof.verify(_merkleProof, whitelistMerkle, leaf);
    }

    /// @notice Mint Free NFT, 1 per WL address
    function mint(bytes32[] calldata _merkleProof) public payable {
        require(mintActive, "Minting is not active");
        // minting has ended
        require(minted < 333, "Minting has ended");
        // check if msg.sender already minted
        require(
            !hasRedeemed[msg.sender],
            "You have already redeemed your pass"
        );
        // check if whitelisted
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, whitelistMerkle, leaf),
            "Invalid proof (not on whitelist?)."
        );
        _mint(msg.sender, 1, 1, "0");
        // set Redeemed to true
        hasRedeemed[msg.sender] = true;
        // increment minted
        minted += 1;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function uri(uint256 id) public view override returns (string memory) {
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, Strings.toString(id), uriSuffix)
                )
                : baseURI;
    }
}