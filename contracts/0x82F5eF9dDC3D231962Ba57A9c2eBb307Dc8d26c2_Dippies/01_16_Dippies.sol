// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract Dippies is ERC721A, Ownable, VRFConsumerBase {
    using Strings for uint256;

    enum Status { SALE_NOT_LIVE, PRESALE_LIVE, SALE_LIVE }

    uint256 public constant SUPPLY_MAX = 8888;
    uint256 public constant PRESALE_MAX = 4394;
    uint256 public constant RESERVE_MAX = 100;
    uint256 public constant PRICE = 0.06 ether;
    
    Status public state;
    bool public revealed;
    string public baseURI;
    string public provenance;
    uint256 public offset;

    uint256 private _reservedTeamTokens;
    address private _signer = 0xe93f0858AC8DE80197BE29af2113DddA86860091;
    address private _linkToken = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    address private _vrfAddress = 0xf0d54349aDdcf704F77AE15b96510dEA15cb7952;
    bytes32 internal _keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
    uint256 private _fee = 2 ether;
    mapping(bytes32 => bool) _nonceUsed;
 
    constructor() ERC721A("Dippies", "DIPPIES") VRFConsumerBase(_vrfAddress, _linkToken) {
        _safeMint(address(this), 1);
        _burn(0);
    }

    function reserveTeamTokens(address to, uint256 quantity) external onlyOwner {
        require(_reservedTeamTokens + quantity <= RESERVE_MAX, "Dippies: Team Tokens Already Minted");
        _reservedTeamTokens += quantity;
        _safeMint(to, quantity);
    }

    function mint(uint256 quantity, bytes calldata signature, bytes32 nonce) external payable {
        require((state == Status.SALE_LIVE || state == Status.PRESALE_LIVE), "Dippies: Sale Not Live");
        require(msg.sender == tx.origin, "Dippies: Contract Interaction Not Allowed");
        require(ECDSA.recover(keccak256(abi.encodePacked(msg.sender, quantity, state, nonce)), signature) == _signer, "Dippies: Invalid Signer");
        require(totalSupply() + quantity <= SUPPLY_MAX, "Dippies: Exceed Max Supply");
        require(quantity <= 2, "Dippies: Exceeds Max Per TX");
        require(msg.value >= PRICE * quantity, "Dippies: Insufficient ETH");

        if(state == Status.PRESALE_LIVE) {
            require(_numberMinted(msg.sender) + quantity <= 2, "Dippies: Exceeds Max Per Wallet");
        } else {
            require(!_nonceUsed[nonce], "Dippies: Nonce Used");
            _nonceUsed[nonce] = true;
        }
        
        _safeMint(msg.sender, quantity);
    }

    function setSaleState(Status _state) external onlyOwner {
        state = _state;
    }

    function setProvenanceHash(string memory _provenance) external onlyOwner {
        require(bytes(provenance).length == 0);
        provenance = _provenance;
    }

    function updateBaseURI(string memory newURI, bool reveal) external onlyOwner {
        baseURI = newURI;
        if(reveal) {
            revealed = reveal;
        }
    }

    function setLinkParams(uint256 fee, bytes32 keyhash) external onlyOwner {
        _fee = fee;
        _keyHash = keyhash;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(0x1fcEFF7E5Ebeb91adf2465e703Fc3f35c3cc7dF4).transfer(balance * 157 / 400);
        payable(0x3428baB379a1D3091653938338d4BBB8b4B07547).transfer(balance * 157 / 400);
        payable(0x1E76a475d10f3CFEd086c238e12017e5565b09ce).transfer(balance * 34 / 400);
        payable(0xaAA217e121433F6482f78371910930FC1AcA226b).transfer(balance * 8 / 400);
        payable(0xEFae49Bd1D8A16F88F190B0464626030c3966126).transfer(balance * 4 / 400);
        payable(0x2795033F658E8E2a8DeB1A28C7c65d743aA3154C).transfer(balance * 20 / 400);
        payable(0x0fa34a4aAf07D86881046B49789dECe58c861729).transfer(address(this).balance);
    }

    function setSigner(address signer) external onlyOwner {
        _signer = signer;
    }

    function setOffset() external onlyOwner returns (bytes32 requestId) {
        require(offset == 0, "Dippies: Offset Already Declared");
        return requestRandomness(_keyHash, _fee);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (!revealed) return _baseURI();
        uint256 shiftedTokenId = (tokenId + offset) % SUPPLY_MAX;
        return string(abi.encodePacked(_baseURI(), shiftedTokenId.toString()));
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override
    {
        require(!revealed);
        offset = randomness % SUPPLY_MAX;
    }
}