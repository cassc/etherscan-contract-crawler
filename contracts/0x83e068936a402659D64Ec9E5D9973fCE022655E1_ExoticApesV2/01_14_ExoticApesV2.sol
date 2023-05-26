// SPDX-License-Identifier: MIT

/**
 * BBBBBBBBBBBBBBBBB   BBBBBBBBBBBBBBBBB                                           EEEEEEEEEEEEEEEEEEEEEE               AAA
 * B::::::::::::::::B  B::::::::::::::::B                                          E::::::::::::::::::::E              A:::A
 * B::::::BBBBBB:::::B B::::::BBBBBB:::::B                                         E::::::::::::::::::::E             A:::::A
 * BB:::::B     B:::::BBB:::::B     B:::::B                                        EE::::::EEEEEEEEE::::E            A:::::::A
 *   B::::B     B:::::B  B::::B     B:::::Bvvvvvvv           vvvvvvv  ssssssssss     E:::::E       EEEEEE           A:::::::::A
 *   B::::B     B:::::B  B::::B     B:::::B v:::::v         v:::::v ss::::::::::s    E:::::E                       A:::::A:::::A
 *   B::::BBBBBB:::::B   B::::BBBBBB:::::B   v:::::v       v:::::vss:::::::::::::s   E::::::EEEEEEEEEE            A:::::A A:::::A
 *   B:::::::::::::BB    B:::::::::::::BB     v:::::v     v:::::v s::::::ssss:::::s  E:::::::::::::::E           A:::::A   A:::::A
 *   B::::BBBBBB:::::B   B::::BBBBBB:::::B     v:::::v   v:::::v   s:::::s  ssssss   E:::::::::::::::E          A:::::A     A:::::A
 *   B::::B     B:::::B  B::::B     B:::::B     v:::::v v:::::v      s::::::s        E::::::EEEEEEEEEE         A:::::AAAAAAAAA:::::A
 *   B::::B     B:::::B  B::::B     B:::::B      v:::::v:::::v          s::::::s     E:::::E                  A:::::::::::::::::::::A
 *   B::::B     B:::::B  B::::B     B:::::B       v:::::::::v     ssssss   s:::::s   E:::::E       EEEEEE    A:::::AAAAAAAAAAAAA:::::A
 * BB:::::BBBBBB::::::BBB:::::BBBBBB::::::B        v:::::::v      s:::::ssss::::::sEE::::::EEEEEEEE:::::E   A:::::A             A:::::A
 * B:::::::::::::::::B B:::::::::::::::::B          v:::::v       s::::::::::::::s E::::::::::::::::::::E  A:::::A               A:::::A
 * B::::::::::::::::B  B::::::::::::::::B            v:::v         s:::::::::::ss  E::::::::::::::::::::E A:::::A                 A:::::A
 * BBBBBBBBBBBBBBBBB   BBBBBBBBBBBBBBBBB              vvv           sssssssssss    EEEEEEEEEEEEEEEEEEEEEEAAAAAAA       .com        AAAAAAA
 */

pragma solidity >=0.8.9 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ExoticApesV2 is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    bytes32 public merkleRoot;
    mapping(address => bool) public whitelistClaimed;

    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;

    uint256 public cost;
    uint256 public maxSupply;
    uint256 public maxMintAmountPerTx;

    bool public paused = true;
    bool public whitelistMintEnabled = false;
    bool public revealed = false;

    address payable private _t0x0 =
        payable(0xC83aCDC2A913282E55710e6D6ACa5De034cB74FF);
    address payable private _x0x0 =
        payable(0x7d6983D3A336bBfDF940A56226DCc65242e2cBEA);
    address payable private _m0x0 =
        payable(0x7e3a955CF25553c7893062153B42eefF0c102872);

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _cost,
        uint256 _maxSupply,
        uint256 _maxMintAmountPerTx,
        string memory _hiddenMetadataUri
    ) ERC721A(_tokenName, _tokenSymbol) {
        cost = _cost;
        maxSupply = _maxSupply;
        maxMintAmountPerTx = _maxMintAmountPerTx;
        setHiddenMetadataUri(_hiddenMetadataUri);
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");
        _;
    }

    function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        public
        payable
        mintCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount)
    {
        // Verify whitelist requirements
        require(whitelistMintEnabled, "The whitelist sale is not enabled!");
        require(!whitelistClaimed[_msgSender()], "Address already claimed!");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid proof!"
        );

        whitelistClaimed[_msgSender()] = true;
        _safeMint(_msgSender(), _mintAmount);
    }

    function mint(uint256 _mintAmount)
        public
        payable
        mintCompliance(_mintAmount)
        mintPriceCompliance(_mintAmount)
    {
        require(!paused, "The contract is paused!");

        _safeMint(_msgSender(), _mintAmount);
    }

    function mintForAddress(uint256 _mintAmount, address _receiver)
        public
        mintCompliance(_mintAmount)
        onlyOwner
    {
        _safeMint(_receiver, _mintAmount);
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = _startTokenId();
        uint256 ownedTokenIndex = 0;
        address latestOwnerAddress;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply
        ) {
            TokenOwnership memory ownership = _ownerships[currentTokenId];

            if (!ownership.burned && ownership.addr != address(0)) {
                latestOwnerAddress = ownership.addr;
            }

            if (latestOwnerAddress == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
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

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
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

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setWhitelistMintEnabled(bool _state) public onlyOwner {
        whitelistMintEnabled = _state;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function withdrawSplit() public onlyOwner nonReentrant {
        uint256 _tc = (address(this).balance / 100) * 20;
        uint256 _mc = (address(this).balance / 100) * 30;
        uint256 _xc = (address(this).balance / 100) * 50;
        _t0x0.transfer(_tc);
        _m0x0.transfer(_mc);
        _x0x0.transfer(_xc);
        payable(owner()).transfer(address(this).balance);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}