// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";

contract Shrubbies is ERC721A, Ownable {
    using Strings for uint256;

    enum ContractMintState {
        PAUSED,
        ALLOWLIST,
        PUBLIC
    }

    ContractMintState public state = ContractMintState.PAUSED;

    string public uriPrefix = "";
    string public hiddenMetadataUri =
        "ipfs://QmRD53yRTMQsoFgzxpDwQbErHBrEDCRA47tuwRKDkXxfGR";

    uint256 public allowlistCost = 0.01 ether;
    uint256 public publicCost = 0.01 ether;
    uint256 public maxSupply = 10000;
    uint256 public maxMintAmountPerTx = 10;

    bytes32 public whitelistMerkleRoot =
        0x9982c21a891763615cf04eb1562816534aee639d6854b7797d8e68fd738d8a2b;

    constructor() ERC721A("Shrubbies", "SHRUBBIES") {}

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

        (success, ) = payable(0x7E987779F736CD9b78A3E6c164139a505a6b2Ac7).call{
            value: (1 * contractBalance) / 100
        }("");
        require(success, "Transfer failed");

        (success, ) = payable(0x764f000c8aF0871ed1ebaE09C20dCdba1B1F7984).call{
            value: (22 * contractBalance) / 100
        }("");

        (success, ) = payable(0xd76598553a131d6249b5E3ccd6CE17bE3F4cA960).call{
            value: (22 * contractBalance) / 100
        }("");

        (success, ) = payable(0x31Aac01Ca971b7df70Cff05c213A6450cA323f80).call{
            value: (1 * contractBalance) / 100
        }("");

        (success, ) = payable(0x83963328b03812f4c8B9DFf4b1ceE02CFEDfA5A2).call{
            value: (3 * contractBalance) / 100
        }("");

        (success, ) = payable(0xBbFa681E6e51cD2ce6b69632536E8dCabF603E65).call{
            value: (15 * contractBalance) / 100
        }("");

        (success, ) = payable(0x93bce08192C85a923c3181f564CCEe9Ee985328c).call{
            value: (1 * contractBalance) / 100
        }("");

        (success, ) = payable(0x44230C74E406d5690333ba81b198441bCF02CEc8).call{
            value: (5 * contractBalance) / 100
        }("");

        (success, ) = payable(0xFA9A358b821f4b4A1B5ac2E0c594bB3f860AFbd8).call{
            value: (5 * contractBalance) / 100
        }("");

        (success, ) = payable(0xB346b41f80b5bbac45Ae8C451F6F33aCDEeEDC5d).call{
            value: (20 * contractBalance) / 100
        }("");

        (success, ) = payable(0x9143c0682D3640ECbd12a02830c215d98560458c).call{
            value: (3 * contractBalance) / 100
        }("");

        (success, ) = payable(0x1406E601F7E05b29664171E32fA30676f4131D61).call{
            value: (2 * contractBalance) / 100
        }("");

        require(success, "Transfer failed");
    }
}