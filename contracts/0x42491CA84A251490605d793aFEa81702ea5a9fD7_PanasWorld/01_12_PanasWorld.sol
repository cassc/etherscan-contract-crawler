// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/// @author narghev dactyleth

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";

contract PanasWorld is ERC721A, Ownable {
    using Strings for uint256;

    enum ContractMintState {
        PAUSED,
        ALLOWLIST
    }

    ContractMintState public state = ContractMintState.PAUSED;

    string public uriPrefix = "";
    string public hiddenMetadataUri =
        "ipfs://QmXEatCCXQ9qzAVftPg14twV7d1RUU7k9EdXhmT2twLTyX";

    uint256 public allowlistCost = 0.015 ether;
    uint256 public maxSupply = 4444;

    bytes32 public whitelistMerkleRoot =
        0x500787e8213ffae9b26b481fd9f19440ba4020d31a14724628644b1498caec04;

    constructor() ERC721A("PanasWorld", "PANA") {}

    // OVERRIDES
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    // MERKLE TREE
    function _verify(bytes32 leaf, bytes32[] memory proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(proof, whitelistMerkleRoot, leaf);
    }

    function _leaf(address account, uint256 allowance)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(account, allowance));
    }

    // MINTING FUNCTIONS
    function mintAllowList(
        uint256 amount,
        uint256 allowance,
        bytes32[] calldata proof
    ) public payable {
        require(totalSupply() + amount <= maxSupply, "Max supply exceeded");
        require(
            state == ContractMintState.ALLOWLIST,
            "Allowlist mint is disabled"
        );

        uint256 amountAfterMint = amount + numberMinted(msg.sender);
        require(
            amountAfterMint > 0 && amountAfterMint <= 2,
            "Invalid mint amount"
        );
        require(
            amountAfterMint == 1 || msg.value >= allowlistCost,
            "Insufficient funds"
        );

        // Verification
        require(amountAfterMint <= allowance, "Can't mint that many");
        require(_verify(_leaf(msg.sender, allowance), proof), "Invalid proof");

        _safeMint(msg.sender, amount);
    }

    function mintForAddress(uint256 amount, address _receiver)
        public
        onlyOwner
    {
        require(totalSupply() + amount <= maxSupply, "Max supply exceeded");
        _safeMint(_receiver, amount);
    }

    // GETTERS
    function numberMinted(address _minter) public view returns (uint256) {
        return _numberMinted(_minter);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();

        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        ".json"
                    )
                )
                : hiddenMetadataUri;
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownerTokens = new uint256[](ownerTokenCount);
        uint256 ownerTokenIdx = 0;
        for (
            uint256 tokenIdx = _startTokenId();
            tokenIdx <= totalSupply();
            tokenIdx++
        ) {
            if (ownerOf(tokenIdx) == _owner) {
                ownerTokens[ownerTokenIdx] = tokenIdx;
                ownerTokenIdx++;
            }
        }
        return ownerTokens;
    }

    // SETTERS
    function setState(ContractMintState _state) public onlyOwner {
        state = _state;
    }

    function setCost(uint256 _allowlistCost) public onlyOwner {
        allowlistCost = _allowlistCost;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        require(_maxSupply < maxSupply, "Cannot increase the supply");
        maxSupply = _maxSupply;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot)
        external
        onlyOwner
    {
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    // WITHDRAW
    function withdraw() public onlyOwner {
        uint256 contractBalance = address(this).balance;
        bool success = true;

        (success, ) = payable(0x37396E07B22A0De9af21382F966f974Ae1f4aDBb).call{
            value: (90 * contractBalance) / 100
        }("");
        require(success, "Transfer failed");

        (success, ) = payable(0x44230C74E406d5690333ba81b198441bCF02CEc8).call{
            value: (5 * contractBalance) / 100
        }("");
        require(success, "Transfer failed");

        (success, ) = payable(0xFA9A358b821f4b4A1B5ac2E0c594bB3f860AFbd8).call{
            value: (5 * contractBalance) / 100
        }("");
        require(success, "Transfer failed");
    }
}