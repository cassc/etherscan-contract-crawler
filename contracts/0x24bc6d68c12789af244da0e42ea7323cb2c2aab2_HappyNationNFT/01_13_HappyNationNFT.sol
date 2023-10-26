//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract HappyNationNFT is ERC721A, Ownable {
    event TotalSupply(uint256 totalSupply);

    // states
    enum SaleState {
        NO_SALE,
        PRE_SALE,
        PUBLIC_SALE,
        SOLD_OUT
    }
    SaleState public state = SaleState.NO_SALE;

    // general settings
    uint256 public constant MAX_SUPPLY = 10000;
    string public provenanceHash;
    string private baseURI = "https://nft.happy-nation.xyz/nft/";

    // no sale state
    //uint256 private state = NO_SALE_STATE;
    uint256 private reserved = 333;

    // pre sale state
    bytes32 public merkleRoot;
    uint256 public maxAllowListMints = 3;
    uint256 public allowListTokenPrice = 0.06 ether;

    // public sale state
    uint256 public maxMints = 10;
    uint256 public tokenPrice = 0.07 ether;

    // reveale state
    uint256 public startingIndex;

    constructor() ERC721A("HappyNationNFT", "hn") {}

    function setState(SaleState _state) public onlyOwner {
        state = _state;
    }

    function mint(uint256 number) public payable {
        require(isPublicSale(), "MINTING_DISABLED");
        require(isValidRequest(number), "EXCEED_NUMBER_OF_MINTS");
        require(hasExceededTotalSupply(number), "NO_TOKENS");
        require(hasRequestedValue(number), "WRONG_CHARGE");

        _mint(number);
        emit TotalSupply(totalSupply());
    }

    function isPublicSale() internal view returns (bool) {
        return state == SaleState.PUBLIC_SALE;
    }

    function isValidRequest(uint256 number) internal view returns (bool) {
        return number <= maxMints;
    }

    function hasExceededTotalSupply(uint256 number) internal view returns (bool) {
        return MAX_SUPPLY - uint256(totalSupply()) >= number;
    }

    function hasRequestedValue(uint256 number) internal view returns (bool) {
        return tokenPrice * number == msg.value;
    }

    function _mint(uint256 number) internal {
        _safeMint(payable(msg.sender), number);
    }

    function allowListMint(uint256 number, bytes32[] calldata _merkleProof) public payable {
        require(isPreSale(), "MINTING_DISABLED");
        require(isAllowListMinter(_merkleProof), "NOT_A_WHITE_MINTER");
        require(hasExceededTotalSupply(number), "NO_TOKENS");
        require(isValidAllowListMintRequest(number), "EXCEED_NUMBER_OF_MINTS");
        require(hasRequestedAllowListMintValue(number), "WRONG_CHARGE");
        _mint(number);
    }

   function isPreSale() internal view returns (bool) {
        return state == SaleState.PRE_SALE;
    }

    function isAllowListMinter(bytes32[] calldata _merkleProof) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    function isValidAllowListMintRequest(uint256 number) internal view returns (bool) {
        return number + numberMinted(msg.sender) <= maxAllowListMints;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function hasRequestedAllowListMintValue(uint256 number) internal view returns (bool) {
        return allowListTokenPrice * number == msg.value;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setTokenPrice(uint256 price) public onlyOwner {
        tokenPrice = price;
    }

    function setAllowListTokenPrice(uint256 price) public onlyOwner {
        allowListTokenPrice = price;
    }

    function setMaxMints(uint256 max) public onlyOwner {
        maxMints = max;
    }

    function setMaxAllowListMints(uint256 max) public onlyOwner {
        maxAllowListMints = max;
    }

    function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
        provenanceHash = _provenanceHash;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setBaseURI(string memory URI) public onlyOwner {
        baseURI = URI;
    }

    function withdraw(address reciver) public onlyOwner {
        require(payable(reciver).send(address(this).balance));
    }

    function setStartingIndex() public onlyOwner {
        require(startingIndex == 0, "ALREADY_INDEXED");

        // BlockHash only works for the most 256 recent blocks.
        uint256 _block_shift = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        _block_shift = 1 + (_block_shift % 255);

        // This shouldn't happen, but just in case the blockchain gets a reboot?
        if (block.number < _block_shift) {
            _block_shift = 1;
        }

        uint256 _block_ref = block.number - _block_shift;
        startingIndex = uint256(blockhash(_block_ref)) % MAX_SUPPLY;

        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex + 1;
        }
    }

    function claimReserved(uint256 _number, address _receiver) external onlyOwner {
        require(_number <= reserved, "EXCEED_NUMBER_OF_CLAIMS");
        _safeMint(_receiver, _number);
        reserved = reserved - _number;
    }

    // derecated
    function getTokensByAddress(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256 counter = 0;
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < totalSupply(); i++) {
            if (ownerOf(i) == _owner) {
                tokensId[counter++] = i;
            }
        }
        return tokensId;
    }
}