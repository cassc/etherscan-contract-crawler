// SPDX-License-Identifier: MIT

//Developer : FazelPejmanfar , Twitter :@Pejmanfarfazel

pragma solidity >=0.7.0 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract SpaceAddictsMemoryProtocol is
    ERC721A,
    Ownable,
    ReentrancyGuard,
    DefaultOperatorFilterer
{
    uint256 public cost = 0 ether;
    uint256 public upgradecost = 0 ether;
    uint256 public maxSupply = 5555;
    uint256 public MaxperWallet = 10;
    uint256 public NFTsToBurn = 5;
    bool public paused = false;
    string private websitehash;
    bytes32 public merkleRoot =
        0xa2a2bfe560ea50b514c8ae0f738fafb78c2cbc8978dfbe411288262f42990de5;
    bool public PublicSale = false;
    mapping(uint256 => string) public NFTURI;
    mapping(uint256 => bool) public onMission;
    address public SPMissionBase;
    IERC721 public FactionContract;
    address private deadAddr = 0x000000000000000000000000000000000000dEaD;

    constructor(string memory _hash, address _factionaddress)
        ERC721A("Space Addicts Memory Protocol", "SPACEMP")
    {
        websitehash = _hash;
        FactionContract = IERC721(_factionaddress);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function mint(string memory cid, string memory _hash)
        public
        payable
        nonReentrant
    {
        require(PublicSale, "Sale is paused");
        require(!paused, "contract is paused");
        require(totalSupply() + 1 <= maxSupply, "We Soldout");
        require(
            numberMinted(_msgSenderERC721A()) + 1 <= MaxperWallet,
            "Max NFT Per Wallet exceeded"
        );
        require(
            keccak256(abi.encodePacked(websitehash)) ==
                keccak256(abi.encodePacked(_hash)),
            "NOT authrized"
        );
        require(msg.value >= cost, "insufficient funds");
        uint256 nextid = nextidtomint();
        NFTURI[nextid] = cid;
        _mint(_msgSenderERC721A(), 1);
    }

    function burnToMint(uint256[] calldata tokenIds, string memory cid)
        external
    {
        uint256 Tokenslength = tokenIds.length;
        require(!paused, "contract is paused");
        require(Tokenslength == NFTsToBurn, "Must Burn 5 NFT");
        require(totalSupply() + 1 <= maxSupply, "We Soldout");
        require(
            numberMinted(_msgSenderERC721A()) + 1 <= MaxperWallet,
            "Max NFT Per Wallet exceeded" 
        );
        for (uint256 i; i < Tokenslength; ) {
            uint256 tokenId = tokenIds[i];
            address owner = FactionContract.ownerOf(tokenId);
            require(_msgSenderERC721A() == owner, "Not owner");
            FactionContract.transferFrom(owner, deadAddr, tokenId);
            unchecked {
                ++i;
            }
        }
        uint256 nextid = nextidtomint();
        NFTURI[nextid] = cid;
        _mint(_msgSenderERC721A(), 1);
    }

    function burnFaction(
        uint256 tokenId,
        string calldata factionid,
        bytes32[] calldata merkleProof,
        string memory cid
    ) public payable nonReentrant {
        require(!paused, "Sale is paused");
        require(
            FactionContract.ownerOf(tokenId) == _msgSenderERC721A(),
            "Not owner"
        );
        require(
            MerkleProof.verify(
                merkleProof,
                merkleRoot,
                keccak256(abi.encodePacked(factionid))
            ),
            "Not A Faction NFT"
        );
        require(
            numberMinted(_msgSenderERC721A()) + 1 <= MaxperWallet,
            "Max NFT Per Wallet exceeded"
        );
        require(totalSupply() + 1 <= maxSupply, "MaxSupply exceeded");
        FactionContract.transferFrom(_msgSenderERC721A(), deadAddr, tokenId);
        uint256 nextid = nextidtomint();
        NFTURI[nextid] = cid;
        _mint(_msgSenderERC721A(), 1);
    }

    function upgrade(
        string memory newcid,
        uint256 tokenId,
        string memory _hash
    ) public payable nonReentrant {
        require(ownerOf(tokenId) == _msgSenderERC721A(), "Not the Owner");
        require(msg.value >= upgradecost, "insufficient funds");
        require(
            keccak256(abi.encodePacked(websitehash)) ==
                keccak256(abi.encodePacked(_hash)),
            "NOT authrized"
        );
        NFTURI[tokenId] = newcid;
    }

    function airdrop(address destination, string memory cid)
        public
        onlyOwner
        nonReentrant
    {
        require(totalSupply() + 1 <= maxSupply, "max NFT limit exceeded");
        uint256 nextid = nextidtomint();
        NFTURI[nextid] = cid;
        _safeMint(destination, 1);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721AMetadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = NFTURI[tokenId];
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked("ipfs://", currentBaseURI))
                : "";
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function nextidtomint() public view returns (uint256) {
        return _nextTokenId();
    }

    function tokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory)
    {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (
                uint256 i = _startTokenId();
                tokenIdsIdx != tokenIdsLength;
                ++i
            ) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }

    function changeNftMissionStatus(uint256 tokenid, bool status) external {
        require(msg.sender == SPMissionBase, "Not Allowed");
        onMission[tokenid] = status;
    }

    function nftMissionStatus(uint256 tokenid) external view returns (bool) {
        return onMission[tokenid];
    }

    function setMaxPerWallet(uint256 _limit) public onlyOwner {
        MaxperWallet = _limit;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setupgradeCost(uint256 _newCost) public onlyOwner {
        upgradecost = _newCost;
    }

    function setMaxsupply(uint256 _newsupply) public onlyOwner {
        maxSupply = _newsupply;
    }

    function setMissionBaseAddress(address _spaddress) public onlyOwner {
        SPMissionBase = _spaddress;
    }

    function setNumNFTsBurn(uint256 _amount) public onlyOwner {
        NFTsToBurn = _amount;
    }

    /// @dev change the merkle root for the whitelist phase
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setNFTURI(string memory _newURI, uint256 tokenId)
        public
        onlyOwner
    {
        NFTURI[tokenId] = _newURI;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setPublicSale(bool _state) public onlyOwner {
        PublicSale = _state;
    }

    function withdraw() public payable onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        payable(_msgSenderERC721A()).transfer(balance);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        require(!onMission[tokenId], "NFT is on Mission");
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}