// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/// @author narghev dactyleth

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";

contract ToyMories is ERC721A, Ownable {
    using Strings for uint256;

    enum ContractMintState {
        PAUSED,
        ALLOWLIST,
        PUBLIC
    }

    ContractMintState public state = ContractMintState.PAUSED;

    string public uriPrefix = "";
    string public hiddenMetadataUri =
        "ipfs://QmdSUVCfbvTePKykABbCbQq2xKgSH5ARMBFjTjf1N9RYsz";

    uint256 public allowlistCost = 0 ether;
    uint256 public publicCost = 0.03 ether;
    uint256 public maxSupply = 7500;
    uint256 public maxMintAmountPerTx = 10;

    bytes32 public whitelistMerkleRoot;

    constructor() ERC721A("ToyMories", "TOYMORIES") {}

    // OVERRIDES
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    // MODIFIERS
    modifier mintCompliance(uint256 _mintAmount) {
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount"
        );
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded"
        );
        _;
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
    function mint(uint256 amount) public payable mintCompliance(amount) {
        require(state == ContractMintState.PUBLIC, "Public mint is disabled");
        require(msg.value >= publicCost * amount, "Insufficient funds");

        _safeMint(msg.sender, amount);
    }

    function mintAllowList(
        uint256 amount,
        uint256 allowance,
        bytes32[] calldata proof
    ) public payable mintCompliance(amount) {
        require(
            state == ContractMintState.ALLOWLIST,
            "Allowlist mint is disabled"
        );
        require(msg.value >= allowlistCost * amount, "Insufficient funds");
        require(
            numberMinted(msg.sender) + amount <= allowance,
            "Can't mint that many"
        );
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

    function setCosts(uint256 _allowlistCost, uint256 _publicCost)
        public
        onlyOwner
    {
        allowlistCost = _allowlistCost;
        publicCost = _publicCost;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        require(_maxSupply < maxSupply, "Cannot increase the supply");
        maxSupply = _maxSupply;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx)
        public
        onlyOwner
    {
        maxMintAmountPerTx = _maxMintAmountPerTx;
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

        (success, ) = payable(0x9f2F31d1d4cba2D61F457378EFD9F082307949eD).call{
            value: (45 * contractBalance) / 100
        }("");
        require(success, "Transfer failed");

        (success, ) = payable(0xA099C36078b8cB8BE1Cc3bD39e5CbC70F1fb5111).call{
            value: (45 * contractBalance) / 100
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