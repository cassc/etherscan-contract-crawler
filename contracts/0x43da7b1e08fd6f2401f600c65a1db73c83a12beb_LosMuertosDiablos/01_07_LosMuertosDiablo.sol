// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/// @author narghev dactyleth

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";

interface ILosMuertosDiabloMintPass {
    function burnOnMint(address burnTokenAddress, uint256 amount) external;
}

contract LosMuertosDiablos is ERC721A, Ownable {
    using Strings for uint256;

    enum ContractMintState {
        PAUSED,
        PASS,
        ALLOWLIST
    }

    ContractMintState public state = ContractMintState.PAUSED;

    ILosMuertosDiabloMintPass public mintPassContract;

    string public uriPrefix = "";
    string public hiddenMetadataUri =
        "ipfs://QmfG7WFBiyaiR5tdvdY6joqF4xFzfMMxEY4wNKS7dyxmb5";

    uint256 public maxSupply = 1000;

    bytes32 public whitelistMerkleRoot =
        0x9922b90215991ab2080f6b855b3e981f9f8f1b39bfd8d109de7cf59753feafe7;

    constructor(address _mintPassContract)
        ERC721A("Los Muertos Diablos", "LOSMUERTOSDIABLOS")
    {
        mintPassContract = ILosMuertosDiabloMintPass(_mintPassContract);
    }

    // OVERRIDES
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    // MODIFIERS
    modifier mintCompliance(uint256 _mintAmount) {
        require(_mintAmount > 0, "Invalid mint amount");
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

    function mintWithPass(uint256 amount) public mintCompliance(amount) {
        require(state == ContractMintState.PASS, "Pass mint is disabled");

        mintPassContract.burnOnMint(msg.sender, amount);
        _safeMint(msg.sender, amount);
    }

    function mintAllowList(
        uint256 amount,
        uint256 allowance,
        bytes32[] calldata proof
    ) public mintCompliance(amount) {
        require(
            state == ContractMintState.ALLOWLIST,
            "Allowlist mint is disabled"
        );
        require(
            numberMinted(msg.sender) + amount <= allowance && amount == 1,
            "Can't mint that many"
        );
        require(_verify(_leaf(msg.sender, allowance), proof), "Invalid proof");

        _safeMint(msg.sender, amount);
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId, true);
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

    // SETTERS
    function setState(ContractMintState _state) public onlyOwner {
        state = _state;
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
}