// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";
import "./DogTag.sol";
import "erc721a/contracts/IERC721A.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "closedsea/src/OperatorFilterer.sol";
import "hardhat/console.sol";

contract CarbonizedSoul is ERC721A, ERC2981, Ownable, ReentrancyGuard, Pausable, OperatorFilterer {
    event Minted(address indexed receiver, uint256 quantity);

    bool public operatorFilteringEnabled;

    IERC721A public genesis;
    DogTag public dogTag;
    uint256 public constant MAX_SUPPLY = 5500;

    uint16[] private stakedNftList;

    string private baseURI;
    bool private isRevealed = false;
    uint256 private mintStartTime;

    mapping(address => uint256) public burnCounts;

    constructor(
        address genesisAddress,
        address dogTagAddress,
        string memory _baseURI,
        uint256 _mintStartTime
    ) ERC721A("CarbonizedSoul", "CS") {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;

        genesis = IERC721A(genesisAddress);
        dogTag = DogTag(dogTagAddress);
        baseURI = _baseURI;
        mintStartTime = _mintStartTime;
        _setDefaultRoyalty(msg.sender, 750);
    }

    function mint(uint256[] memory _burningTokenIdList) external whenNotPaused isNotContract {
        require(mintStartTime <= block.timestamp, "CarbonizedSoul: mint is not started");
        require(_totalMinted() + _burningTokenIdList.length <= MAX_SUPPLY, "Sold out");

        for (uint256 i = 0; i < _burningTokenIdList.length; i++) {
            genesis.transferFrom(msg.sender, address(this), _burningTokenIdList[i]);
            stakedNftList.push(uint16(_burningTokenIdList[i]));
        }
        _mint(msg.sender, _burningTokenIdList.length);
        _mintDogTag(_burningTokenIdList.length);
        emit Minted(msg.sender, _burningTokenIdList.length);
    }

    function _mintDogTag(uint256 burnCount) internal {
        uint256 previousBurnCount = burnCounts[msg.sender];
        uint256 newBurnCount = previousBurnCount + burnCount;
        burnCounts[msg.sender] = newBurnCount;

        uint256 count0 = 0;
        uint256 count1 = 0;
        uint256 count2 = 0;

        for (uint256 i = previousBurnCount + 1; i <= newBurnCount; i++) {
            uint256 remainder = i % 10;

            if (remainder == 0 && i != 0) {
                count2++;
            } else if (remainder % 5 == 0) {
                count0++;
            } else if (remainder % 7 == 0) {
                count1++;
            }
        }

        if (count0 > 0) {
            dogTag.mint(msg.sender, 0, count0, "");
        }
        if (count1 > 0) {
            dogTag.mint(msg.sender, 1, count1, "");
        }
        if (count2 > 0) {
            dogTag.mint(msg.sender, 2, count2, "");
        }
    }

    function unstake() external onlyOwner {
        for (uint256 i = 0; i < stakedNftList.length; i++) {
            genesis.transferFrom(address(this), msg.sender, stakedNftList[i]);
        }

        delete stakedNftList;
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setIsReveal(bool _isRevealed) external onlyOwner {
        isRevealed = _isRevealed;
    }

    function setMintStartTime(uint256 _mintStartTime) external onlyOwner {
        mintStartTime = _mintStartTime;
    }

    function setGenesis(address genesisAddress) external onlyOwner {
        genesis = IERC721A(genesisAddress);
    }

    function setDogtag(address dogTagAddress) external onlyOwner {
        dogTag = DogTag(dogTagAddress);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (!isRevealed) {
            return string(abi.encodePacked(baseURI, "prereveal"));
        }
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(baseURI, "contractURI"));
    }

    function getStakedNftCount() public view returns (uint256) {
        return stakedNftList.length;
    }

    // =========================================================================
    //                           Operator filter
    // =========================================================================

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
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

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

    // =========================================================================
    //                                 ERC2891
    // =========================================================================

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    // =========================================================================
    //                                  ERC165
    // =========================================================================

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    modifier isNotContract() {
        require(msg.sender == tx.origin, "Sender is not EOA");
        _;
    }
}