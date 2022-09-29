// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @author Brewlabs
 * This contract has been developed by brewlabs.info
 */
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract RabblePassNft is Ownable, ERC721URIStorage, ReentrancyGuard {
    using Strings for uint256;

    uint256 private constant MAX_SUPPLY = 4000;
    uint256 private constant TIME_UNITS = 1 hours;

    string private _tokenBaseURI = "";
    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    bool public mintAllowed = false;
    uint256 private premine = 200;
    uint256 public totalSupply = 0;
    uint256 public mintStartBlock;
    uint256 public mintStartTime;

    bytes32 private merkleRoot;
    mapping(address => uint256[3]) private numOfMints;

    uint256 private numAvailableItems = 4000;
    uint256[4000] private availableItems;

    event MintEnabled();
    event MintDisabled();
    event Mint(address indexed user, uint256 tokenId);
    event BaseURIUpdated(string uri);
    event SetWhitelist(bytes32 whitelistMerkleRoot);

    modifier onlyMintable() {
        require(mintAllowed && totalSupply < MAX_SUPPLY, "cannot mint");
        _;
    }

    constructor() ERC721("RabblePass", "RabblePass") {}

    function preMint(address _to, uint256 _count) external onlyOwner {
        require(_count <= 50, "exceed one time limit");
        require(totalSupply < premine, "premine already finished");
        require(totalSupply + _count <= premine, "exceed premine");

        _randomMint(_to, _count);
    }

    function mint(bytes32[] memory _merkleProof, uint256 _numToMint) external payable onlyMintable nonReentrant {
        require(_numToMint > 0, "invalid amount");
        require(totalSupply + _numToMint <= MAX_SUPPLY, "Exceed supply limit");
        require(msg.value >= 0.00001 ether, "should hold small eth to mint");
        payable(msg.sender).transfer(msg.value);

        uint256 phase = currentPhase();
        _checkCondition(_merkleProof, phase, _numToMint);
        _randomMint(msg.sender, _numToMint);

        numOfMints[msg.sender][phase - 1] += _numToMint;
        if(phase < 3) numOfMints[msg.sender][2] += _numToMint;
    }

    function _checkCondition(bytes32[] memory _merkleProof, uint256 phase, uint256 _numToMint) internal view {
        if(phase < 3) {
            // check if minter exists in whitelist
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "invalid merkle proof");
        }

        require(numOfMints[msg.sender][phase - 1] < phase, "already mint");
        require(numOfMints[msg.sender][phase - 1] + _numToMint <= phase, "Exceed mint limit in this phase");
    }

    function _randomMint(address _user, uint256 _numToMint) internal {
        for(uint256 i = 0; i < _numToMint; i++) {
            uint256 tokenId = _randomAvailableTokenId(_numToMint, i);
            tokenId = tokenId + 1;

            _safeMint(_user, tokenId);
            _setTokenURI(tokenId, tokenId.toString());
            super._setTokenURI(tokenId, tokenId.toString());

            totalSupply++;
            if (totalSupply == MAX_SUPPLY) {
                mintAllowed = false;
            }
            numAvailableItems--;

            emit Mint(_user, tokenId);
        }
    }

    function _randomAvailableTokenId(uint256 _numToMint, uint256 i) internal returns (uint256) {
        uint256 randomNum = uint256(
            keccak256(
                abi.encode(
                    msg.sender,
                    tx.gasprice,
                    block.number,
                    block.timestamp,
                    blockhash(block.number - 1),
                    _numToMint,
                    i
                )
            )
        );

        uint256 randomIndex = randomNum % numAvailableItems;

        uint256 valAtIndex = availableItems[randomIndex];
        uint256 result;
        if (valAtIndex == 0) {
            // This means the index itself is still an available token
            result = randomIndex;
        } else {
            // This means the index itself is not an available token, but the val at that index is.
            result = valAtIndex;
        }

        uint256 lastIndex = numAvailableItems - 1;
        if (randomIndex != lastIndex) {
            // Replace the value at randomIndex, now that it's been used.
            // Replace it with the data from the last index in the array, since we are going to decrease the array size afterwards.
            uint256 lastValInArray = availableItems[lastIndex];
            if (lastValInArray == 0) {
                // This means the index itself is still an available token
                availableItems[randomIndex] = lastIndex;
            } else {
                // This means the index itself is not an available token, but the val at that index is.
                availableItems[randomIndex] = lastValInArray;
            }
        }

        return result;
    }

    function currentPhase() public view returns (uint256) {
        if (mintStartBlock == 0) return 0;

        uint256 _passTime = (block.number - mintStartBlock) * 3;
        if(_passTime <= 24 * TIME_UNITS) return 1;
        if(_passTime > 36 * TIME_UNITS) return 3;
        return 2;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "RabblePass: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(_baseURI(), _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    function enableMint() external onlyOwner {
        require(totalSupply >= premine, "premine not finished yet");
        require(merkleRoot != "", "Whitelist not set");
        require(!mintAllowed, "already enabled");

        mintAllowed = true;
        mintStartBlock = block.number;
        mintStartTime = block.timestamp;
        emit MintEnabled();
    }

    function setWhiteList(bytes32 _merkleRoot) external onlyOwner {
        require(_merkleRoot != "", "invalid merkle root");
        merkleRoot = _merkleRoot;
        emit SetWhitelist(_merkleRoot);
    }

    function setTokenBaseUri(string memory _uri) external onlyOwner {
        _tokenBaseURI = _uri;
        emit BaseURIUpdated(_uri);
    }

    function _baseURI() internal view override returns (string memory) {
        return _tokenBaseURI;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal override {
        require(_exists(tokenId), "RabblePassNft: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    receive() external payable {}
}