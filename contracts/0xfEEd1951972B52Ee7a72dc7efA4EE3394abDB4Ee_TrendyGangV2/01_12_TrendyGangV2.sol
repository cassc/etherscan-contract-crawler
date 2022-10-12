//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract TrendyGangV2 is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;

    bool public paused = true;
    bool public claimAllowed = true;
    uint256 mintPrice = 100000000000000000;   // 0.1

    uint256 public trendyGangV1Minted = 0;
    uint256 public nvlpeMinted = 0;
    uint256 public immutable nvlpeMintStartIndex;

    uint256 public constant MAX_SUPPLY = 8888;
    uint256 public immutable nvlpeSupply;

    uint256 public constant START_INDEX = 1;

    address public immutable trendyGangV1Address;
    mapping(address => NVLPE_CONTRACT) public nvlpeContracts;
    mapping(bytes => bool) public sigClaimed;

    address public authSigner;

    struct NVLPE_CONTRACT {
        IERC721 _contract;
        uint256 _totalSupply;
        mapping(uint256 => bool) claimed;
    }

    struct addressCollection {
        address contractAddress;
        uint256 contractSupply;
    }

    struct NVLPE_CLAIM {
        address contractAddress;
        uint256 tokenId;
    }

    event Collection(
        address indexed contractAddress,
        uint256 indexed contractSupply
    );

    event AuthSignerSet(address indexed newSigner);

    constructor(addressCollection[] memory _collection)
        ERC721("TrendyGangV2", "TGV2")
    {
        authSigner = msg.sender;
        trendyGangV1Address = _collection[0].contractAddress;
        nvlpeMintStartIndex = START_INDEX + _collection[0].contractSupply;
        nvlpeSupply = MAX_SUPPLY - _collection[0].contractSupply;
        for (uint256 i = 0; i < _collection.length; i++) {
            NVLPE_CONTRACT storage nvlpeContract = nvlpeContracts[
                _collection[i].contractAddress
            ];
            nvlpeContract._contract = IERC721(_collection[i].contractAddress);
            nvlpeContract._totalSupply = _collection[i].contractSupply;

            emit Collection(
                _collection[i].contractAddress,
                _collection[i].contractSupply
            );
        }
    }

    function setAuthSigner(address _authSigner) external onlyOwner {
        authSigner = _authSigner;
        emit AuthSignerSet(_authSigner);
    }

    function airdropToTrendyGangV1Owner(
        address _trendyGangV1Address,
        uint256 mintAmount
    ) external onlyOwner nonReentrant {
        require(
            trendyGangV1Minted + mintAmount < nvlpeMintStartIndex,
            "TokenId is out of range"
        );

        uint256 _startIndex = START_INDEX + trendyGangV1Minted;
        for (
            uint256 i = _startIndex;
            i < _startIndex + mintAmount;
            i++
        ) {
            trendyGangV1OwnerMint(_trendyGangV1Address, i);
        }
    }

    function trendyGangV1OwnerMint(
        address _trendyGangV1Address,
        uint256 tokenId
    ) internal {
        require(_trendyGangV1Address == trendyGangV1Address, "Invalid contract address");
        require(
            !nvlpeContracts[_trendyGangV1Address].claimed[tokenId],
            "tokenId has already been claimed"
        );

        address ownerOftrendyGangV1 = fetchOwnerOfTokenId(
            _trendyGangV1Address,
            tokenId
        );
        nvlpeContracts[_trendyGangV1Address].claimed[tokenId] = true;
        _safeMint(ownerOftrendyGangV1, tokenId);
        trendyGangV1Minted++;
    }

    function nvlpeOwnerBatchClaim(NVLPE_CLAIM[] calldata nvlpeItem) external nonReentrant {
        require(!paused, "Contract is paused");
        require(claimAllowed, "Claims are not currently allowed");

        for (uint256 i = 0; i < nvlpeItem.length; i++) {
            require(nvlpeItem[i].contractAddress != trendyGangV1Address, "Invalid contract address");
            nvlpeOwnerMint(nvlpeItem[i].contractAddress, nvlpeItem[i].tokenId);
        }
    }

    function nvlpeOwnerMint(address _contractAddress, uint256 tokenId)
        internal
    {
        require(nvlpeContracts[_contractAddress]._totalSupply != 0, "invalid contract address");
        require(
            !nvlpeContracts[_contractAddress].claimed[tokenId],
            "tokenId has already been claimed"
        );
        require(
            tokenId <= nvlpeContracts[_contractAddress]._totalSupply,
            "TokenId is out of range"
        ); 
        require(
            nvlpeMinted + 1 <= nvlpeSupply,
            "Out of supply"
        );

        address nvlpeOwner = fetchOwnerOfTokenId(_contractAddress, tokenId);

        require(nvlpeOwner == msg.sender, "Not Owner");
        nvlpeContracts[_contractAddress].claimed[tokenId] = true;
        _safeMint(msg.sender, nvlpeMintStartIndex + nvlpeMinted);
        nvlpeMinted++;
    }

    function mint() external nonReentrant payable {
        require(!paused, "Contract is paused");
        require(!claimAllowed, "Public mint not permitted during claim period");
        require(msg.value >= mintPrice, "Not enough ETH sent");
        require(nvlpeMinted + 1 <= nvlpeSupply, "Out of supply");
        _safeMint(msg.sender, nvlpeMintStartIndex + nvlpeMinted);
        nvlpeMinted++;
    }

    function claimBySig(
        uint256 nonce,
        uint256 amount,
        bytes calldata sig
    ) external nonReentrant {
        require(!paused, "Contract is paused");
        require(
            nvlpeMinted + amount <= nvlpeSupply,
            "Out of supply"
        );

        bytes32 hashes = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(nonce, amount, msg.sender))
            )
        );
        require(recoverSigner(hashes, sig) == authSigner, "Invalid sig");
        require(!sigClaimed[sig], "Signature used");
        sigClaimed[sig] = true;
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, nvlpeMintStartIndex + nvlpeMinted);
            nvlpeMinted++;
        }
    }

    function fetchOwnerOfTokenId(address _contractAddress, uint256 _tokenId)
        public
        view
        returns (address)
    {
        return nvlpeContracts[_contractAddress]._contract.ownerOf(_tokenId);
    }

    function checkClaimed(address _contractAddress, uint256 _tokenId)
        public
        view
        returns (bool)
    {
        return nvlpeContracts[_contractAddress].claimed[_tokenId];
    }

    // metadata
    string public baseURI = "https://trendygang.io/media/pre-reveal.json";
    bool public revealed = false;
    string public constant BASE_EXTENSION = ".json";

    function setReveal(bool _reveal) public onlyOwner {
        revealed = _reveal;
    }
    
    function setClaimAllowed(bool _claimAllowed) public onlyOwner {
        claimAllowed = _claimAllowed;
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice  = _mintPrice;
    }


    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newURI) public onlyOwner {
        baseURI = newURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (!revealed) return baseURI;

        return
            string(
                abi.encodePacked(
                    baseURI,
                    Strings.toString(_tokenId),
                    BASE_EXTENSION
                )
            );
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        require(sig.length == 65, "invalid sig");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);
        return ecrecover(message, v, r, s);
    }
}