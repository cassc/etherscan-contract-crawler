//SPDX-License-Identifier: UNLICENSED

/*

██╗  ██╗██╗   ██╗███╗   ███╗ █████╗ ███╗   ██╗████████╗ ██████╗ ██╗   ██╗ ██████╗ ██╗   ██╗████████╗██╗  ██╗
██║  ██║██║   ██║████╗ ████║██╔══██╗████╗  ██║╚══██╔══╝██╔═══██╗╚██╗ ██╔╝██╔═══██╗██║   ██║╚══██╔══╝██║  ██║
███████║██║   ██║██╔████╔██║███████║██╔██╗ ██║   ██║   ██║   ██║ ╚████╔╝ ██║   ██║██║   ██║   ██║   ███████║
██╔══██║██║   ██║██║╚██╔╝██║██╔══██║██║╚██╗██║   ██║   ██║   ██║  ╚██╔╝  ██║   ██║██║   ██║   ██║   ██╔══██║
██║  ██║╚██████╔╝██║ ╚═╝ ██║██║  ██║██║ ╚████║   ██║   ╚██████╔╝   ██║   ╚██████╔╝╚██████╔╝   ██║   ██║  ██║
╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝    ╚═════╝    ╚═╝    ╚═════╝  ╚═════╝    ╚═╝   ╚═╝  ╚═╝

                                Powered by YouthQuake & MTBrains
                                  https://mint.humantoyouth.io/
*/
pragma solidity >=0.8.9 <0.9.0;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IHumanToYouth.sol";

contract HumanToYouth is ERC721A, Ownable, ReentrancyGuard, IHumanToYouth {
    using Strings for uint256;

    string public uriPrefix = "";
    string public uriSuffix = "";
    string public notRevealedUri;

    NFTRelease[] public releases;
    uint8 public currentReleaseIndex;

    mapping(address => FreeMintData) freeMintData;
    uint256 public maxSupply;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _maxSupply,
        string memory _notRevealedUri,
        NFTRelease[] memory _releases
    ) ERC721A(_tokenName, _tokenSymbol) {
        maxSupply = _maxSupply;

        require(_releases.length > 0, "Invalid Releases data");
        for (uint8 i = 0; i < _releases.length; i++) {
            releases.push(_releases[i]);
        }
        setCurrentReleaseIndex(0);
        setNotRevealedUri(_notRevealedUri);
    }

    function mint(uint256 _mintAmount)
        public
        payable
        mintCompliance(_mintAmount)
        mintPriceCompliance(
            _mintAmount,
            releases[currentReleaseIndex].publicCost
        )
    {
        uint tokenReleaseIndex = getTokenReleaseIndex(
            totalSupply() + _mintAmount
        );
        NFTRelease memory tokenRelease = releases[tokenReleaseIndex];

        require(
            tokenRelease.status == NFTReleaseStatus.OPEN_MINT,
            "Public mint is not available yet"
        );

        _safeMint(_msgSender(), _mintAmount);
    }

    function whitelistMint(uint256 _mintAmount, bytes32[] calldata merkleProof)
        public
        payable
        mintCompliance(_mintAmount)
        mintPriceCompliance(
            _mintAmount,
            releases[currentReleaseIndex].whitelistCost
        )
    {
        address receiver = _msgSender();
        uint tokenReleaseIndex = getTokenReleaseIndex(
            totalSupply() + _mintAmount
        );
        NFTRelease memory tokenRelease = releases[tokenReleaseIndex];

        require(
            tokenRelease.status == NFTReleaseStatus.WHITELIST_MINT,
            "Whitelist mint is not enabled"
        );
        bool allowed = isInWhitelist(
            receiver,
            tokenRelease.merkleRoot,
            merkleProof
        );
        require(allowed, "User in not in the whitelist");

        _safeMint(receiver, _mintAmount);
    }

    function freeMint() public mintCompliance(1) {
        address receiver = _msgSender();
        FreeMintData memory d = freeMintData[receiver];

        require(d.allowed && !d.minted, "User is not allowed to freemint");

        _safeMint(receiver, 1);
        freeMintData[receiver].minted = true;
    }

    function updateNFTRelease(uint8 _index, NFTRelease memory _release)
        public
        onlyOwner
        releaseIndexCompliance(_index)
    {
        releases[_index] = _release;
    }

    function addToFreemintList(address receiver) public onlyOwner {
        freeMintData[receiver] = FreeMintData({allowed: true, minted: false});
    }

    function isInFreemintList(address receiver) public view returns (bool) {
        return (freeMintData[receiver].allowed &&
            !freeMintData[receiver].minted);
    }

    function isInWhitelist(
        address receiver,
        bytes32 merkleRoot,
        bytes32[] calldata merkleProof
    ) public pure returns (bool) {
        bytes32 node = bytes32(uint256(uint160(receiver)));
        return MerkleProof.verify(merkleProof, merkleRoot, node);
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
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
            ownedTokenIndex < ownerTokenCount && currentTokenId < _currentIndex
        ) {
            TokenOwnership memory ownership = _ownerships[currentTokenId];

            if (!ownership.burned) {
                if (ownership.addr != address(0)) {
                    latestOwnerAddress = ownership.addr;
                }

                if (latestOwnerAddress == _owner) {
                    ownedTokenIds[ownedTokenIndex] = currentTokenId;
                    ownedTokenIndex++;
                }
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function getAvailableSupply(uint8 _supplyPercentage)
        private
        view
        returns (uint256)
    {
        return (_supplyPercentage * maxSupply) / 100;
    }

    function getMintPercentage(uint256 _tokenId) public view returns (uint8) {
        return uint8((_tokenId * 100) / maxSupply);
    }

    function getTokenReleaseIndex(uint256 _tokenId)
        public
        view
        returns (uint8)
    {
        uint8 tokenPercentage = getMintPercentage(_tokenId);
        uint8 nextReleaseThreshold = 0;
        uint8 tokenReleaseIndex;

        uint8 i = 0;

        do {
            nextReleaseThreshold += releases[i].supplyPercentage;
            tokenReleaseIndex = i;
            i++;
        } while (i < releases.length && tokenPercentage > nextReleaseThreshold);

        return tokenReleaseIndex;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setNotRevealedUri(string memory _notRevealedUri) public onlyOwner {
        notRevealedUri = _notRevealedUri;
    }

    function setCurrentReleaseIndex(uint8 _index) public onlyOwner {
        currentReleaseIndex = _index;
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

        uint tokenReleaseIndex = getTokenReleaseIndex(_tokenId);
        if (releases[tokenReleaseIndex].revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        (_tokenId - 1).toString(),
                        uriSuffix
                    )
                )
                : "";
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    modifier mintPriceCompliance(uint256 _mintAmount, uint256 _cost) {
        require(msg.value >= _cost * _mintAmount, "Insufficient funds!");
        _;
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(_mintAmount > 0, "Invalid mint amount!");

        uint8 availablePercentage = 0;
        for (uint8 i = 0; i < releases.length; i++) {
            if (releases[i].status != NFTReleaseStatus.DISABLED) {
                availablePercentage += releases[i].supplyPercentage;
            }
        }

        require(
            (totalSupply() + _mintAmount) <=
                getAvailableSupply(availablePercentage),
            "Max supply exceeded!"
        );
        _;
    }

    modifier releaseIndexCompliance(uint8 _index) {
        require(_index >= 0 && _index < releases.length, "Invalid index");
        _;
    }
}