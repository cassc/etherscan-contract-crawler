// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./lib/rarible/royalties/contracts/RoyaltiesV2.sol";
import "./lib/rarible/royalties/contracts/LibPart.sol";
import "./lib/rarible/royalties/contracts/LibRoyaltiesV2.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MetaKawaii is ERC721A, Ownable, ReentrancyGuard, RoyaltiesV2 {
    // max supply per phase
    uint256[] private _supplies;
    uint256 private _maxSupply;
    uint256 private _currentPhase;

    // phase => baseURI
    mapping(uint256 => string) public baseURI;
    mapping(uint256 => bool) public isStartPublicSale;
    mapping(uint256 => bool) public isStartPreSale;

    uint256 public preSaleMintPrice = 0.06 ether;
    uint256 public publicSaleMintPrice = 0.08 ether;
    uint256 private _maxPresaleMintCount = 3;

    // royalties settings
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    address payable public defaultRoyaltiesReceipientAddress;
    uint96 public defaultPercentageBasisPoints = 500; // 5%

    // whitelist settings
    // -- phase => merkleRoot
    mapping(uint256 => bytes32) public whiteListRoot;
    // -- address => phase => amount
    mapping(address => mapping(uint256 => uint256))
        private _whiteListToMintedCount;

    constructor() ERC721A("MetaKawaii", "DROP'S") {
        _currentPhase = 99999; // INITIAL_PHASE
        defaultRoyaltiesReceipientAddress = payable(address(this));
    }

    //start from tokenid=1
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _tokenCounter() internal view virtual returns (uint256) {
        return _nextTokenId() - 1;
    }

    function preSaleMint(bytes32[] calldata _merkleProof, uint256 _mintCount)
        external
        payable
        nonReentrant
    {
        require(_supplies.length > 0, "not set supply");
        require(
            _mintCount <= maxMintableCount(),
            "can not mint, over max size"
        );
        require(
            isStartPreSale[currentPhase()],
            "can not mint, is not start sale"
        );
        require(
            _mintCount <=
                _maxPresaleMintCount -
                    _whiteListToMintedCount[msg.sender][currentPhase()],
            "exceeded allocated count"
        );
        require(msg.value == preSaleMintPrice * _mintCount, "not enough ETH");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(
                _merkleProof,
                whiteListRoot[currentPhase()],
                leaf
            ),
            "MerkleProof: Invalid proof."
        );
        _whiteListToMintedCount[msg.sender][currentPhase()] += _mintCount;
        _safeMint(msg.sender, _mintCount);
    }

    function publicSaleMint(uint256 _mintCount) external payable nonReentrant {
        require(_supplies.length > 0, "not set supply");
        require(
            _mintCount <= maxMintableCount(),
            "can not mint, over max size"
        );
        require(
            isStartPublicSale[currentPhase()],
            "can not mint, is not start sale"
        );
        require(
            msg.value == publicSaleMintPrice * _mintCount,
            "not enough ETH"
        );
        require(_mintCount <= 5, "can not mint, over max mint batch size");
        require(tx.origin == msg.sender, "not eoa");
        _safeMint(msg.sender, _mintCount);
    }

    function ownerMint(address _to, uint256 _mintCount)
        external
        virtual
        onlyOwner
    {
        require(_supplies.length > 0, "not set supply");
        require(
            _mintCount <= maxMintableCount(),
            "can not mint, over max size"
        );
        _safeMint(_to, _mintCount);
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

        return
            string(
                abi.encodePacked(
                    baseURI[fetchPhase(_tokenId)],
                    Strings.toString(_tokenId),
                    ".json"
                )
            );
    }

    function setBaseURI(uint256 _phaseIndex, string memory _baseURI)
        external
        onlyOwner
    {
        baseURI[_phaseIndex] = _baseURI;
    }

    function currentPhase() public view returns (uint256) {
        return _currentPhase;
    }

    function fetchPhase(uint256 _tokenId) public view returns (uint256) {
        uint256 tokenOfPhase;
        uint256 total;
        for (uint256 i = 0; i < _supplies.length; i++) {
            total += _supplies[i];
            if (_tokenId <= total) {
                tokenOfPhase = i;
                break;
            }
        }
        return tokenOfPhase;
    }

    function setPublicSaleMintPrice(uint256 price) external onlyOwner {
        publicSaleMintPrice = price;
    }

    function setPreSaleMintPrice(uint256 price) external onlyOwner {
        preSaleMintPrice = price;
    }

    function setMaxPresaleMintCount(uint256 _count) external onlyOwner {
        _maxPresaleMintCount = _count;
    }

    function appendSupply(uint256 _appendSupply) external onlyOwner {
        require(_maxSupply == totalSupply(), "current phase is not sold out");
        _supplies.push(_appendSupply);
        _maxSupply += _appendSupply;
        if (_currentPhase == 99999) {
            _currentPhase = 0;
        } else {
            _currentPhase++;
        }
    }

    function startPublicSale(uint256 _phase) external onlyOwner {
        isStartPublicSale[_phase] = true;
    }

    function pausePublicSale(uint256 _phase) external onlyOwner {
        isStartPublicSale[_phase] = false;
    }

    function startPreSale(uint256 _phase) external onlyOwner {
        isStartPreSale[_phase] = true;
    }

    function pausePreSale(uint256 _phase) external onlyOwner {
        isStartPreSale[_phase] = false;
    }

    function setPresaleRoot(uint256 _phaseIndex, bytes32 _whitelistRoot)
        external
        onlyOwner
    {
        whiteListRoot[_phaseIndex] = _whitelistRoot;
    }

    function whiteListAllocatedCount(
        bytes32[] calldata _merkleProof,
        uint256 phase
    ) public view returns (uint256) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (MerkleProof.verify(_merkleProof, whiteListRoot[phase], leaf)) {
            return
                _maxPresaleMintCount -
                _whiteListToMintedCount[msg.sender][phase];
        } else {
            return 0;
        }
    }

    function maxMintableCount() public view returns (uint256) {
        require(_maxSupply >= _tokenCounter(), "can not mint, over max size");
        return _maxSupply - _tokenCounter();
    }

    function getMaxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    function getSupplies() public view returns (uint256[] memory) {
        return _supplies;
    }

    function withdraw(uint256 _amount) external onlyOwner {
        (bool result, ) = msg.sender.call{value: _amount}("");
        require(result, "transfer failed");
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A)
        returns (bool)
    {
        if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }
        if (interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }

    function setDefaultRoyaltiesReceipientAddress(
        address payable _defaultRoyaltiesReceipientAddress
    ) public onlyOwner {
        defaultRoyaltiesReceipientAddress = _defaultRoyaltiesReceipientAddress;
    }

    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        return (
            defaultRoyaltiesReceipientAddress,
            (_salePrice * defaultPercentageBasisPoints) / 10000
        );
    }

    function getRaribleV2Royalties(uint256)
        external
        view
        override
        returns (LibPart.Part[] memory)
    {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = defaultPercentageBasisPoints;
        _royalties[0].account = defaultRoyaltiesReceipientAddress;
        return _royalties;
    }
}