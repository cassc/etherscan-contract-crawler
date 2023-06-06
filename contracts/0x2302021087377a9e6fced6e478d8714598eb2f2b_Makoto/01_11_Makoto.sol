// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

contract Makoto is ERC721A, Ownable {
    using Strings for uint256;

    enum ContractMintState {
        PAUSED,
        PUBLIC
    }

    ContractMintState public state = ContractMintState.PUBLIC;

    string public uriPrefix = "https://ipfs.io/ipfs/QmdxvJwsdWiFGVhKwFcqgy8CxBLgKe45MP1h7wZry8GUQi/";

    uint256 public publicCost = 0.0222 ether;
    uint256 public freeMintSupply = 2222;
    uint256 public maxSupply = 8888;
    uint256 public maxMintAmountPerTx = 4;

    constructor() ERC721A("Makoto", "MKT") {}


    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

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

    function mint(uint256 amount) public payable mintCompliance(amount) {
        require(state == ContractMintState.PUBLIC, "Public mint is disabled");
        if (totalSupply() + amount > freeMintSupply) {
            require(msg.value >= publicCost * amount, "Insufficient funds");
        } else {
            require(numberMinted(msg.sender) < maxMintAmountPerTx);
        }
        _safeMint(msg.sender, amount);
    }

    function mintForAddress(uint256 amount, address _receiver)
        public
        onlyOwner
    {
        require(totalSupply() + amount <= maxSupply, "Max supply exceeded");
        _safeMint(_receiver, amount);
    }

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

        return string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        ".json"
                    )
                );
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

    function setState(ContractMintState _state) public onlyOwner {
        state = _state;
    }

    function setCosts(uint256 _publicCost)
        public
        onlyOwner
    {
        publicCost = _publicCost;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx)
        public
        onlyOwner
    {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        require(_maxSupply < maxSupply, "Cannot increase the supply");
        maxSupply = _maxSupply;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function withdraw() public onlyOwner {
        uint256 contractBalance = address(this).balance;
        bool success = true;

        (success, ) = payable(0x87e0128a8b232493d7e6Fb90DbA460566dbeF65b).call{
            value: contractBalance
        }("");
        require(success, "Transfer failed");
    }
}