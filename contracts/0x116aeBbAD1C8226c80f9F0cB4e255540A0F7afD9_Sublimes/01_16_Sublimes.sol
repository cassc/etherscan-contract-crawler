// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC2981/ERC2981Base.sol";

contract Sublimes is ERC721Enumerable, ERC2981Base, Ownable {
    using Strings for uint256;

    uint256 public constant COST = 0.1 ether;
    uint256 public constant SALE_MAX_MINT_AMOUNT = 3;
    uint256 public constant ROYALTIES_PERCENTAGE = 5;
    string public constant BASE_EXTENSION = ".json";

    string public baseURI;
    uint256 public maxSupply;
    bool public mintActive = true;
    bool public revealed = false;
    bool public publicSale = false;
    bytes32 public whitelistRoot;
    mapping(address => uint256) public whitelistMintBalance;

    address private royaltiesReceiver;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _notRevealedUri,
        uint256 _maxSupply,
        bytes32 _whitelistRoot,
        address _royaltiesReceiver
    ) ERC721(_name, _symbol) {
        maxSupply = _maxSupply;
        setBaseURI(_notRevealedUri);
        setWhitelistRoot(_whitelistRoot);
        setRoyaltiesReceiver(_royaltiesReceiver);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _mintAmount(uint256 _amount) internal {
        require(mintActive, "minting not active");
        require(_amount > 0, "need to mint at least 1 NFT");
        uint256 supply = totalSupply();
        require(supply + _amount <= maxSupply, "max supply exceeded");
        require(msg.value >= COST * _amount, "insufficient funds");

        for (uint256 i = 1; i <= _amount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    // public
    function mint(uint256 _amount) external payable {
        require(publicSale, "not in public sale");
        require(
            _amount <= SALE_MAX_MINT_AMOUNT,
            "max mint amount per tx exceeded"
        );
        _mintAmount(_amount);
    }

    function mintPresale(
        uint256 _amount,
        uint256 _allowance,
        bytes32[] calldata _proof
    ) external payable {
        require(
            isWhitelisted(msg.sender, _allowance, _proof),
            "user is not whitelisted or allowance is incorrect"
        );
        require(
            whitelistMintBalance[msg.sender] + _amount <= _allowance,
            "allowance exceeded"
        );
        _mintAmount(_amount);
        whitelistMintBalance[msg.sender] += _amount;
    }

    function isWhitelisted(
        address _user,
        uint256 _allowance,
        bytes32[] memory _proof
    ) public view returns (bool) {
        return
            MerkleProof.verify(
                _proof,
                whitelistRoot,
                keccak256(abi.encodePacked(_user, _allowance))
            );
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
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
        string memory uri = _baseURI();
        if (revealed) {
            return
                bytes(uri).length > 0
                    ? string(
                        abi.encodePacked(
                            uri,
                            _tokenId.toString(),
                            BASE_EXTENSION
                        )
                    )
                    : "";
        }
        return uri;
    }

    function royaltyInfo(uint256, uint256 _value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = royaltiesReceiver;
        royaltyAmount = (_value * ROYALTIES_PERCENTAGE) / 100;
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC2981Base)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }

    //only owner
    function mintTo(address[] calldata _recipients) external onlyOwner {
        uint256 supply = totalSupply();
        require(
            supply + _recipients.length <= maxSupply,
            "max supply exceeded"
        );
        for (uint256 i = 0; i < _recipients.length; i++) {
            uint256 nextTokenId = supply + i + 1;
            _safeMint(_recipients[i], nextTokenId);
        }
    }

    function reveal() external onlyOwner {
        revealed = true;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setMintActive(bool _state) external onlyOwner {
        mintActive = _state;
    }

    function setPublicSale(bool _state) external onlyOwner {
        publicSale = _state;
    }

    function setWhitelistRoot(bytes32 _root) public onlyOwner {
        whitelistRoot = _root;
    }

    function setRoyaltiesReceiver(address _receiver) public onlyOwner {
        royaltiesReceiver = _receiver;
    }

    function withdraw() external onlyOwner {
        (bool sent, ) = payable(owner()).call{value: address(this).balance}("");
        require(sent, "failed to send funds to owner");
    }
}